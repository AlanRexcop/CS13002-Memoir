-- A helper function to check if the currently logged-in user has the 'admin' role in their JWT
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN COALESCE(
    (auth.jwt()->>'app_metadata')::jsonb->>'role', 
    ''
  ) = 'admin';
END;
$$ LANGUAGE plpgsql STABLE SECURITY INVOKER;

-- Creates a secure function for an admin to fetch a single user's profile by their ID.
CREATE OR REPLACE FUNCTION admin_get_user_by_id(p_user_id UUID)
RETURNS TABLE (
  id UUID,
  username TEXT,
  mail TEXT,
  storage_used BIGINT,
  file_count INT,
  public_file_count INT,
  storage_limit BIGINT,
  created_at TIMESTAMPTZ,
  update_at TIMESTAMPTZ,
  last_sign_in_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER -- Ensures it runs with elevated privileges
AS $$
BEGIN
  -- Use our existing gatekeeper to ensure only admins can run this.
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Forbidden: You must be an admin to perform this action.';
  END IF;

  -- If the check passes, return the single requested profile.
  RETURN QUERY
    SELECT
      p.id,
      p.username,
      p.mail,
      p.storage_used,
      p.file_count,
      p.public_file_count,
      p.storage_limit,
      p.created_at,
      p.update_at,
      p.last_sign_in_at
    FROM public.profiles p
    WHERE p.id = p_user_id;
END;
$$;

-- Creates a function for admins to get all user profiles, bypassing RLS.
CREATE OR REPLACE FUNCTION public.admin_get_all_users()
RETURNS SETOF public.profiles
LANGUAGE plpgsql
SECURITY DEFINER -- Runs with function owner's permissions
SET search_path = ''  -- Security best practice: clear search path
AS $$
BEGIN
  -- First, check if the caller is an admin.
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Forbidden: You must be an admin to perform this action.'
    USING ERRCODE = 'insufficient_privilege';
  END IF;

  -- If the check passes, run the query to get all profiles.
  RETURN QUERY
    SELECT * FROM public.profiles ORDER BY created_at DESC;
END;
$$;

-- Creates a function for admins to delete users.
CREATE OR REPLACE FUNCTION public.admin_delete_users(user_ids UUID[]) 
RETURNS TABLE (deleted_count INT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  actual_deleted_count INT;
BEGIN
  -- Same security check as before.
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Forbidden: You must be an admin to perform this action.'
    USING ERRCODE = 'insufficient_privilege';
  END IF;

  -- Delete from auth.users and return the number of deleted users
  WITH deleted AS (
    DELETE FROM auth.users 
    WHERE id = ANY(user_ids)
    RETURNING id
  )
  SELECT COUNT(*) INTO actual_deleted_count FROM deleted;

  RETURN QUERY 
    SELECT actual_deleted_count;
END;
$$;

-- Function to set admin role using service role
CREATE OR REPLACE FUNCTION public.set_user_admin(target_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- Update app_metadata to set admin role
  -- IMPORTANT: This requires the service role key in your client-side code
  UPDATE auth.users 
  SET raw_app_meta_data = 
    jsonb_set(
      COALESCE(raw_app_meta_data, '{}'), 
      '{role}', 
      '"admin"'
    )
  WHERE id = target_user_id;
END;
$$;

-- Example usage
SELECT public.set_user_admin('a5778674-2b0e-4556-8b36-ce36f3e8fe95');

