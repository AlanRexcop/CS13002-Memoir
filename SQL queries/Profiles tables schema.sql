CREATE TABLE if not exists public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT NOT NULL,   -- new field
  mail TEXT NOT NULL,       -- new field
  storage_used BIGINT DEFAULT 0, -- Current storage used by the user in bytes
  file_count INT DEFAULT 0,    -- Number of files uploaded by the user
  public_file_count INT DEFAULT 0,
  storage_limit BIGINT DEFAULT 5242880, -- Default limit (e.g., 5MB in bytes)
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),  -- new field
  update_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),  -- new field
  last_sign_in_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())  -- new field
  user_image TEXT DEFAULT NULL 
    CHECK (
      user_image IS NULL OR 
      user_image ~ '^(https?://|/)[^\s]+$'
    )
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can delete their own profile" ON public.profiles;

-- Recreate policies with more permissive insert
CREATE POLICY "Users can view their own profile"
ON public.profiles
FOR SELECT TO authenticated
USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
ON public.profiles
FOR UPDATE TO authenticated
USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
ON public.profiles
FOR UPDATE TO authenticated
USING (auth.uid() = id)
WITH CHECK (
  auth.uid() = id AND 
  (
    user_image IS NULL OR 
    user_image ~ '^(https?://|/)[^\s]+$'
  )
);

CREATE POLICY "Users can delete their own profile" 
ON public.profiles 
FOR DELETE 
USING (auth.uid() = id);

-- Add a policy to allow insert from trigger function
drop POLICY "Allow insert from trigger"
ON public.profiles
FOR INSERT 
WITH CHECK (true);
