-- Recursive function to ensure all parent folders exist
CREATE OR REPLACE FUNCTION public.ensure_folder_path_exists(
    p_path TEXT, 
    p_owner_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_current_path TEXT;
    v_parent_path TEXT;
    v_folder_id UUID;
    v_parent_folder_id UUID;
BEGIN
    -- Normalize the path (remove leading/trailing slashes)
    IF p_owner_id is null THEN 
        return NULL;
    END IF;
    p_path := trim(both '/' FROM p_path);
    
    -- If path is empty, return NULL (root folder)
    IF p_path = '' THEN
        RETURN NULL;
    END IF;
    
    -- Check if folder already exists
    SELECT id INTO v_folder_id
    FROM public.files
    WHERE 
        path = p_path || '/' AND 
        is_folder = TRUE AND 
        user_id = p_owner_id;
    
    IF v_folder_id IS NOT NULL THEN
        RETURN v_folder_id;
    END IF;
    
    -- Split the path into parent and current folder
    v_current_path := substring(p_path FROM '([^/]+)$');
    v_parent_path := substring(p_path FROM '^(.+)/[^/]+$');
    
    -- Recursively ensure parent path exists
    IF v_parent_path IS NOT NULL THEN
        v_parent_folder_id := public.ensure_folder_path_exists(v_parent_path, p_owner_id);
    ELSE
        v_parent_folder_id := NULL;
    END IF;
    
    -- Create the current folder
    v_folder_id := public.create_folder(
        p_path, 
        v_parent_folder_id, 
        p_owner_id
    );
    
    RETURN v_folder_id;
END;
$$;

-- Updated trigger function for file upload
CREATE OR REPLACE FUNCTION public.handle_storage_file_upload()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_parent_id UUID;
    v_path TEXT;
    v_filename TEXT;
    v_folder_path TEXT;
    v_owner_id UUID;
BEGIN
    -- In storage.objects, the file path is stored in the 'name' column
    v_path := NEW.name;
    
    -- Extract the filename from the path
    v_filename := regexp_replace(v_path, '^.*/', '');
    
    -- Extract the folder path (everything before the filename)
    IF v_filename = v_path THEN
        -- File is in the root directory
        v_folder_path := '';
    ELSE
        v_folder_path := substring(v_path, 1, length(v_path) - length(v_filename));
    END IF;
    
    -- Convert the owner_id to UUID
    v_owner_id := (NEW.owner_id)::UUID;
    
    -- Ensure the entire folder path exists, get the parent folder ID
    v_parent_id := public.ensure_folder_path_exists(
        rtrim(v_folder_path, '/'), 
        v_owner_id
    );

    -- Register the uploaded file
    PERFORM public.register_uploaded_file(
        NEW.id,           -- storage_object_id
        v_filename,       -- name (extract filename from path)
        v_path,           -- path (full path including filename)
        NEW.metadata->>'mimetype', -- mime_type
        (NEW.metadata->>'size')::BIGINT, -- size
        v_parent_id,       -- parent_id
        v_owner_id
    );
    RETURN NEW;
END;
$$;

CREATE EXTENSION IF NOT EXISTS pg_net;

-- Corrected webhook function using correct http_post signature
CREATE OR REPLACE FUNCTION public.get_object_name_webhook()
RETURNS TRIGGER AS $$
DECLARE
  webhook_url TEXT;
  payload JSONB;
  request_id UUID;
BEGIN
  webhook_url := 'https://uonjdjehvwdhyaegbfer.supabase.co/functions/v1/process-file-content';
  payload := jsonb_build_object(
    'record', NEW
  );
  -- Use pg_net.http_post for async HTTP call
  perform net.http_post(
    url := webhook_url,
    body := payload
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Re-create the trigger to use the corrected function
DROP TRIGGER IF EXISTS update_object_name_webhook ON storage.objects;
CREATE TRIGGER update_object_name_webhook
AFTER INSERT OR UPDATE ON storage.objects
FOR EACH ROW EXECUTE FUNCTION public.get_object_name_webhook();

-- Trigger function for file update
CREATE OR REPLACE FUNCTION public.handle_storage_file_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_path TEXT;
    v_filename TEXT;
    v_existing_file_id UUID;
    v_owner_id UUID;
BEGIN
    v_path := NEW.name;
    v_filename := regexp_replace(v_path, '^.*/', '');
    v_owner_id := (new.owner_id)::UUID;
    -- Find the existing file record
    SELECT id INTO v_existing_file_id
    FROM files
    WHERE 
        storage_object_id = NEW.id AND 
        user_id = v_owner_id;
    
    IF v_existing_file_id IS NOT NULL THEN
        -- Update the file record
        PERFORM public.update_file(
            v_existing_file_id,
            p_name := v_filename,
            p_mime_type := NEW.metadata->>'mimetype',
            p_size := (NEW.metadata->>'size')::BIGINT,
            p_storage_object_id := NEW.id
        );
    END IF;

    RETURN NEW;
END;
$$;

-- Function to recursively remove empty folders
CREATE OR REPLACE FUNCTION public.cleanup_empty_folders(
    p_path TEXT, 
    p_owner_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_parent_path TEXT;
    v_parent_id UUID;
    v_folder_id UUID;
    v_child_count INTEGER;
BEGIN
    -- Normalize the path (remove leading/trailing slashes)
    p_path := trim(both '/' FROM p_path);
    
    -- If path is empty, stop recursion
    IF p_path = '' THEN
        RETURN;
    END IF;
    
    -- Check if the folder exists and has no children
    SELECT id, parent_id INTO v_folder_id, v_parent_id
    FROM public.files
    WHERE 
        path = p_path || '/' AND 
        is_folder = TRUE AND 
        user_id = p_owner_id;
    
    -- Count children (files and folders) in this path
    SELECT COUNT(*) INTO v_child_count
    FROM public.files
    WHERE 
        (path LIKE p_path || '/%') AND 
        user_id = p_owner_id;
    
    -- If no children, delete the folder
    IF v_folder_id IS NOT NULL AND v_child_count < 2 AND v_parent_id IS NOT NULL THEN
        -- Delete the folder
        DELETE FROM public.files 
        WHERE 
            id = v_folder_id AND 
            is_folder = TRUE;
        
        -- Extract parent path
        v_parent_path := substring(p_path FROM '^(.+)/[^/]+$');
        
        -- Recursively clean up parent if it exists
        IF v_parent_path IS NOT NULL THEN
            PERFORM public.cleanup_empty_folders(v_parent_path, p_owner_id);
        END IF;
    END IF;
END;
$$;

-- Updated trigger function for file deletion
CREATE OR REPLACE FUNCTION public.handle_storage_file_delete()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_file_path TEXT;
    v_folder_path TEXT;
    v_owner_id UUID;
BEGIN
    -- Get the file path and owner
    v_file_path := OLD.name;
    v_owner_id := (OLD.owner_id)::UUID;
    
    -- Extract the folder path (everything before the filename)
    v_folder_path := substring(v_file_path, 1, length(v_file_path) - length(regexp_replace(v_file_path, '^.*/', '')));
    
    -- Delete the corresponding record in public.files
    DELETE FROM public.files
    WHERE storage_object_id = OLD.id;
    
    -- Attempt to clean up empty parent folders
    IF v_folder_path != '' THEN
        PERFORM public.cleanup_empty_folders(
            rtrim(v_folder_path, '/'), 
            v_owner_id
        );
    END IF;
    
    -- Return OLD to allow the original delete operation to proceed
    RETURN OLD;
END;
$$;

-- Create triggers for storage operations
CREATE TRIGGER storage_file_upload_trigger
AFTER INSERT ON storage.objects
FOR EACH ROW
WHEN (NEW.metadata->>'mimetype' IS NOT NULL)
EXECUTE FUNCTION public.handle_storage_file_upload();

CREATE TRIGGER storage_file_update_trigger
AFTER UPDATE ON storage.objects
FOR EACH ROW
WHEN (NEW.metadata->>'mimetype' IS NOT NULL)
EXECUTE FUNCTION public.handle_storage_file_update();

CREATE TRIGGER storage_file_delete_trigger
AFTER DELETE ON storage.objects
FOR EACH ROW
EXECUTE FUNCTION public.handle_storage_file_delete();


