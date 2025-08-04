CREATE OR REPLACE FUNCTION public.handle_storage_upload()
RETURNS TRIGGER AS $$
DECLARE
  user_storage_limit BIGINT;
  user_storage_used BIGINT;
BEGIN
  -- Set search_path to empty for security
  SET search_path = '';

  IF NEW.bucket_id = 'user-files' AND NEW.owner IS NOT NULL THEN
    SELECT storage_limit, storage_used
    INTO user_storage_limit, user_storage_used
    FROM public.profiles
    WHERE id = NEW.owner;

    user_storage_used := user_storage_used + COALESCE((NEW.metadata->>'size')::numeric, 0)::bigint;

    IF user_storage_used > user_storage_limit THEN
      -- Raise an exception to stop the upload
      RAISE EXCEPTION 'Storage limit exceeded. Cannot upload file.';
    ELSE
      UPDATE public.profiles
      SET
        storage_used = user_storage_used,
        file_count = file_count + 1
      WHERE id = NEW.owner;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_storage_upload
AFTER INSERT ON storage.objects
FOR EACH ROW EXECUTE FUNCTION public.handle_storage_upload();


CREATE OR REPLACE FUNCTION public.handle_storage_delete()
RETURNS TRIGGER AS $$
BEGIN
  -- Set search_path to empty for security
  SET search_path = '';
  
  IF OLD.bucket_id = 'user-files' AND OLD.owner IS NOT NULL THEN
    UPDATE public.profiles
    SET
      storage_used = GREATEST(0, storage_used - COALESCE((OLD.metadata->>'size')::numeric, 0)::bigint),
      file_count = GREATEST(0, file_count - 1)
    WHERE id = OLD.owner;
  END IF;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE or replace TRIGGER on_storage_delete
AFTER DELETE ON storage.objects
FOR EACH ROW EXECUTE FUNCTION public.handle_storage_delete();


CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER SET search_path = '' AS $$
DECLARE
  v_username TEXT;
  v_email TEXT;
BEGIN
  v_email := COALESCE(NEW.email, 'nomail');
  
  v_username := COALESCE(
    NULLIF(TRIM(NEW.raw_user_meta_data->>'username'), ''),
    NULLIF(SPLIT_PART(v_email, '@', 1), ''),
    'noname'
  );
  
  INSERT INTO public.profiles (id, username, mail)
  VALUES (NEW.id, v_username, v_email);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


CREATE OR REPLACE FUNCTION public.handle_profile_update()
RETURNS TRIGGER SET search_path = '' AS $$
BEGIN
  NEW.update_at = timezone('utc'::text, now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_profile_update
BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.handle_profile_update();


CREATE OR REPLACE FUNCTION public.handle_password_change()
RETURNS TRIGGER SET search_path = '' AS $$
BEGIN
  -- Check if the encrypted_password field was updated
  IF OLD.encrypted_password IS DISTINCT FROM NEW.encrypted_password THEN
    UPDATE public.profiles
    SET update_at = timezone('utc'::text, now())
    WHERE id = NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_password_change
AFTER UPDATE ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_password_change();


CREATE OR REPLACE FUNCTION public.handle_user_sign_in()
RETURNS TRIGGER SET search_path = '' AS $$
BEGIN
  UPDATE public.profiles
  SET last_sign_in_at = timezone('utc'::text, now())
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_sign_in
AFTER UPDATE OF last_sign_in_at ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_user_sign_in();


-- Function to delete profile when user is deleted
CREATE OR REPLACE FUNCTION public.handle_user_deletion()
RETURNS TRIGGER SET search_path = '' AS $$
BEGIN
  DELETE FROM public.profiles 
  WHERE id = OLD.id;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_deleted
AFTER DELETE ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_user_deletion();


CREATE OR REPLACE FUNCTION public.create_user_root_folder()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    -- Create root folder directly, ignoring the returned ID
    PERFORM public.create_folder(
        p_path := NEW.id::TEXT || '/',
        p_user_id := NEW.id,
        p_parent_id := NULL
    );
    
    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER create_root_folder_for_new_user
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.create_user_root_folder();
