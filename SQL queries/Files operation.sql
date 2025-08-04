-- Function to register a file after upload to storage
CREATE OR REPLACE FUNCTION public.register_uploaded_file(
    p_storage_object_id UUID,
    p_name TEXT,
    p_path TEXT,
    p_mime_type TEXT,
    p_size BIGINT,
    p_parent_id UUID DEFAULT NULL,
    p_user_id UUID DEFAULT NULL -- Add user_id parameter
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_file_id UUID;
    v_user_id UUID;
BEGIN
    -- Use provided user_id or fall back to auth.uid()
    v_user_id := COALESCE(p_user_id, auth.uid());
    
    -- Insert the file record
    INSERT INTO public.files (
        user_id,
        name,
        path,
        is_folder,
        mime_type,
        size,
        parent_id,
        storage_object_id,
        created_at,
        updated_at,
        is_deleted
    ) VALUES (
        v_user_id,        -- Use the determined user_id
        p_name,
        p_path,
        FALSE,
        p_mime_type,
        p_size,
        p_parent_id,
        p_storage_object_id,
        NOW(),           -- created_at
        NOW(),           -- updated_at
        FALSE            -- is_deleted
    )
    RETURNING id INTO v_file_id;
    
    RETURN v_file_id;
END;
$$;

-- Function to create a folder
CREATE OR REPLACE FUNCTION public.create_folder(
    p_path TEXT,
    p_parent_id UUID DEFAULT NULL,
    p_user_id UUID DEFAULT NULL -- Add user_id parameter
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_folder_id UUID;
    v_folder_name TEXT;
    v_user_id UUID;
BEGIN
    -- Use provided user_id or fall back to auth.uid()
    v_user_id := COALESCE(p_user_id, auth.uid());
    
    -- Extract folder name from path
    v_folder_name := regexp_replace(p_path, '^.*/', '');
    IF v_folder_name = '' OR v_folder_name = p_path THEN
        v_folder_name := p_path;
    END IF;
    
    -- Check if folder already exists
    SELECT id INTO v_folder_id
    FROM public.files
    WHERE 
        path = p_path || '/'
        AND is_folder = TRUE
        AND user_id = v_user_id
        AND is_deleted = FALSE;
    
    -- If folder doesn't exist, create it
    IF v_folder_id IS NULL THEN
        INSERT INTO public.files (
            user_id,
            name,
            path,
            is_folder,
            mime_type,
            size,
            parent_id,
            created_at,
            updated_at,
            is_deleted
        ) VALUES (
            v_user_id,
            v_folder_name,
            p_path || '/',
            TRUE,
            'folder',
            0,
            p_parent_id,
            NOW(),
            NOW(),
            FALSE
        )
        RETURNING id INTO v_folder_id;
    END IF;
    
    RETURN v_folder_id;
END;
$$;

-- Function to update file content and metadata
CREATE OR REPLACE FUNCTION public.update_file(
    p_file_id UUID,
    p_name TEXT DEFAULT NULL,
    p_mime_type TEXT DEFAULT NULL,
    p_size BIGINT DEFAULT NULL,
    p_storage_object_id UUID DEFAULT NULL,
    p_parent_id UUID DEFAULT NULL,
    p_user_id UUID DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_user_id UUID;
    v_update_count INT;
BEGIN
    -- Check file ownership
    SELECT user_id INTO v_user_id
    FROM public.files
    WHERE id = p_file_id AND is_folder = FALSE;
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    IF v_user_id != COALESCE(auth.uid(), p_user_id) THEN
        RETURN FALSE;
    END IF;

    -- Update the file record
    UPDATE public.files
    SET 
        name = COALESCE(p_name, name),
        mime_type = COALESCE(p_mime_type, mime_type),
        size = COALESCE(p_size, size),
        storage_object_id = COALESCE(p_storage_object_id, storage_object_id),
        parent_id = COALESCE(p_parent_id, parent_id),
        updated_at = NOW(),
        user_id = COALESCE(p_user_id, v_user_id)
    WHERE 
        id = p_file_id;
    
    GET DIAGNOSTICS v_update_count = ROW_COUNT;
    
    RETURN v_update_count > 0;
END;
$$;

-- Updated trash_file function 
CREATE OR REPLACE FUNCTION public.trash_file(
    p_file_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_user_id UUID;
    v_is_folder BOOLEAN;
BEGIN
    -- Get file info and check ownership
    SELECT user_id, is_folder INTO v_user_id, v_is_folder
    FROM public.files
    WHERE id = p_file_id;
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    IF v_user_id != auth.uid() THEN
        RETURN FALSE;
    END IF;
    
    -- Mark the file as deleted
    UPDATE public.files
    SET 
        is_deleted = TRUE,
        updated_at = NOW()
    WHERE id = p_file_id;
    
    -- If it's a folder, also mark all children as deleted
    IF v_is_folder THEN
        WITH RECURSIVE subfolder AS (
            SELECT id FROM public.files WHERE parent_id = p_file_id
            UNION ALL
            SELECT f.id FROM public.files f
            JOIN subfolder s ON f.parent_id = s.id
        )
        UPDATE public.files
        SET 
            is_deleted = TRUE,
            updated_at = NOW()
        WHERE id IN (SELECT id FROM subfolder);
    END IF;
    
    RETURN TRUE;
END;
$$;

-- Updated restore_file function 
CREATE OR REPLACE FUNCTION public.restore_file(
    p_file_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_user_id UUID;
    v_is_folder BOOLEAN;
    v_parent_id UUID;
    v_parent_deleted BOOLEAN;
BEGIN
    -- Get file info and check ownership
    SELECT user_id, is_folder, parent_id INTO v_user_id, v_is_folder, v_parent_id
    FROM public.files
    WHERE id = p_file_id;
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    IF v_user_id != auth.uid() THEN
        RETURN FALSE;
    END IF;
    
    -- Check if parent folder is deleted
    IF v_parent_id IS NOT NULL THEN
        SELECT is_deleted INTO v_parent_deleted
        FROM public.files
        WHERE id = v_parent_id;
        
        -- Can't restore if parent is still in trash
        IF v_parent_deleted THEN
            RETURN FALSE;
        END IF;
    END IF;
    
    -- Mark the file as not deleted
    UPDATE public.files
    SET 
        is_deleted = FALSE,
        updated_at = NOW()
    WHERE id = p_file_id;
    
    -- If it's a folder, also restore all children
    IF v_is_folder THEN
        WITH RECURSIVE subfolder AS (
            SELECT id FROM public.files WHERE parent_id = p_file_id
            UNION ALL
            SELECT f.id FROM public.files f
            JOIN subfolder s ON f.parent_id = s.id
        )
        UPDATE public.files
        SET 
            is_deleted = FALSE,
            updated_at = NOW()
        WHERE id IN (SELECT id FROM subfolder);
    END IF;
    
    RETURN TRUE;
END;
$$;


-- Function to permanently delete a file (both from files table and storage)
CREATE OR REPLACE FUNCTION public.hard_delete_file(
    p_file_id UUID,
    p_user_id UUID DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_user_id UUID;
    v_is_folder BOOLEAN;
    v_storage_object_id UUID;
    v_bucket_id TEXT;
    v_path TEXT;
    v_supabase_url TEXT;
    v_service_role_key TEXT;
BEGIN
    -- Get file info and check ownership
    SELECT 
        user_id, 
        is_folder, 
        storage_object_id,
        path
    INTO 
        v_user_id, 
        v_is_folder, 
        v_storage_object_id,
        v_path
    FROM public.files
    WHERE id = p_file_id;
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    IF v_user_id != COALESCE(auth.uid(), p_user_id) THEN
        RETURN FALSE;
    END IF;
    
    -- If it's a folder, delete all children first
    IF v_is_folder THEN
        WITH RECURSIVE subfolder AS (
            SELECT id, storage_object_id, is_folder FROM public.files WHERE parent_id = p_file_id
            UNION ALL
            SELECT f.id, f.storage_object_id, f.is_folder FROM public.files f
            JOIN subfolder s ON f.parent_id = s.id
        )
        DELETE FROM public.files
        WHERE id IN (SELECT id FROM subfolder);
        
        -- Delete the folder itself
        DELETE FROM public.files
        WHERE id = p_file_id;
        
        RETURN TRUE;
    ELSE
        -- For regular files, delete from storage if storage_object_id exists
        IF v_storage_object_id IS NOT NULL THEN
            -- The storage object will be deleted by the application
            -- The trigger we created will handle removing the file record
            
            -- Just delete the file record directly
            DELETE FROM public.files
            WHERE id = p_file_id;
        ELSE
            -- If no storage object, just delete the file record
            DELETE FROM public.files
            WHERE id = p_file_id;
        END IF;
        
        RETURN TRUE;
    END IF;
END;
$$;

