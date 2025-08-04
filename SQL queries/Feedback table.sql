-- Create the feedback table with email tracking
CREATE TABLE public.user_feedback (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    title TEXT NOT NULL,
    text TEXT NOT NULL,
    tag TEXT,
    status TEXT DEFAULT 'pending' 
        CHECK (status IN ('pending', 'in_progress', 'resolved', 'closed')),
    send_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    user_email TEXT NOT NULL,
    is_user_deleted BOOLEAN DEFAULT FALSE
);

-- Create indexes for performance
CREATE INDEX idx_user_feedback_user_id ON public.user_feedback(user_id);
CREATE INDEX idx_user_feedback_email ON public.user_feedback(user_email);
CREATE INDEX idx_user_feedback_status ON public.user_feedback(status);

-- Enable Row Level Security
ALTER TABLE public.user_feedback ENABLE ROW LEVEL SECURITY;

-- Function to preserve feedback details before user deletion
CREATE OR REPLACE FUNCTION public.preserve_feedback_on_user_delete()
RETURNS TRIGGER AS $$
BEGIN
    -- Update feedback entries for the user being deleted
    UPDATE public.user_feedback 
    SET 
        user_id = NULL,
        is_user_deleted = TRUE
    WHERE user_id = OLD.id;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to execute the preservation function
CREATE TRIGGER user_deletion_preserve_feedback
BEFORE DELETE ON auth.users
FOR EACH ROW 
EXECUTE FUNCTION public.preserve_feedback_on_user_delete();

-- Policy for users to insert their own feedback
CREATE POLICY "Users can insert their own feedback" 
ON public.user_feedback FOR INSERT 
WITH CHECK (
    user_id = (SELECT auth.uid()) AND 
    user_email = (SELECT email FROM auth.users WHERE id = auth.uid())
);

-- Policy for admins to read and update all feedback
CREATE POLICY "Admins can read and update all feedback"
ON public.user_feedback 
FOR ALL 
TO authenticated 
USING (public.is_admin());

-- Optional: Function to insert feedback with user details
CREATE OR REPLACE FUNCTION public.submit_user_feedback(
    p_title TEXT, 
    p_text TEXT, 
    p_tag TEXT DEFAULT NULL
)
RETURNS public.user_feedback
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_feedback public.user_feedback;
BEGIN
    INSERT INTO public.user_feedback (
        title, 
        text, 
        tag, 
        user_id, 
        user_email
    )
    VALUES (
        p_title, 
        p_text, 
        p_tag, 
        (SELECT auth.uid()),
        (SELECT email FROM auth.users WHERE id = auth.uid())
    )
    RETURNING * INTO v_feedback;
    
    RETURN v_feedback;
END;
$$;