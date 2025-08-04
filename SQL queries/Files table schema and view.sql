-- Create the files table
CREATE TABLE IF NOT EXISTS public.files (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id),
    name TEXT NOT NULL,
    path TEXT NOT NULL,
    is_folder BOOLEAN DEFAULT FALSE,
    mime_type TEXT,
    size BIGINT,
    parent_id UUID REFERENCES public.files(id),
    storage_object_id UUID,
    created_at TIMESTAMPTZ DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ DEFAULT timezone('utc', now()),
    is_deleted BOOLEAN DEFAULT FALSE,
    is_public BOOLEAN DEFAULT FALSE
);
-- Enable Row Level Security
ALTER TABLE public.files ENABLE ROW LEVEL SECURITY;

-- Create index on parent_id for faster folder traversal
CREATE INDEX IF NOT EXISTS idx_files_parent_id ON public.files(parent_id);

-- Create index on user_id for faster user-specific queries
CREATE INDEX IF NOT EXISTS idx_files_user_id ON public.files(user_id);

-- Create index on storage_object_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_files_storage_object_id ON public.files(storage_object_id);

-- Create RLS policies
CREATE POLICY "Users can view their own files"
ON public.files
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

CREATE POLICY "Users can manage their own files" ON storage.objects
FOR ALL
TO authenticated
USING (owner = auth.uid())
WITH CHECK (
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Public files can be viewed by anyone
CREATE POLICY "Public files can be viewed by anyone"
ON public.files
FOR SELECT
TO anon, authenticated
USING (is_public = TRUE AND is_deleted = FALSE);

-- function to get file in a folder (non recursive)
CREATE OR REPLACE FUNCTION public.get_folder_contents(
    p_folder_id UUID DEFAULT NULL, -- NULL means root level
    p_include_deleted BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    path TEXT,
    is_folder BOOLEAN,
    mime_type TEXT,
    size BIGINT,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    is_deleted BOOLEAN,
    is_public BOOLEAN
)
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        f.id,
        f.name,
        f.path,
        f.is_folder,
        f.mime_type,
        f.size,
        f.created_at,
        f.updated_at,
        f.is_deleted,
        f.is_public
    FROM 
        files f
    WHERE 
        f.user_id = auth.uid()
        AND f.parent_id IS NOT DISTINCT FROM p_folder_id
        AND (p_include_deleted = TRUE OR f.is_deleted = FALSE)
    ORDER BY 
        f.is_folder DESC, -- Folders first
        f.name ASC;
END;
$$;


-- Function to get breadcrumb path to a folder
CREATE OR REPLACE FUNCTION public.get_folder_path(
    p_folder_id UUID
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    level INT
)
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
BEGIN
    RETURN QUERY
    WITH RECURSIVE folder_path AS (
        -- Base case: the target folder
        SELECT 
            f.id, 
            f.name, 
            f.parent_id,
            1 AS level
        FROM 
            files f
        WHERE 
            f.id = p_folder_id
            AND f.user_id = auth.uid()
            AND f.is_folder = TRUE
        
        UNION ALL
        
        -- Recursive case: parent folders
        SELECT 
            f.id, 
            f.name, 
            f.parent_id,
            fp.level + 1
        FROM 
            files f
        JOIN 
            folder_path fp ON f.id = fp.parent_id
        WHERE 
            f.user_id = auth.uid()
    )
    SELECT 
        fp.id, 
        fp.name, 
        fp.level
    FROM 
        folder_path fp
    ORDER BY 
        fp.level DESC; -- Root folder will be first
END;
$$;

-- Assuming a 'files' table with user_id referencing auth.users
CREATE OR REPLACE FUNCTION get_user_files()
RETURNS SETOF files
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY 
    SELECT * FROM files 
    WHERE user_id = (SELECT auth.uid());
END;
$$;
