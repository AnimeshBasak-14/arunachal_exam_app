-- Create public storage bucket for question diagrams and cropped PDF illustrations
INSERT INTO storage.buckets (id, name, public) 
VALUES ('question_assets', 'question_assets', true)
ON CONFLICT (id) DO UPDATE SET public = true;

DO $$
BEGIN
    DROP POLICY IF EXISTS "Public Read Question Assets" ON storage.objects;
    DROP POLICY IF EXISTS "Allow All Question Assets" ON storage.objects;
END $$;

CREATE POLICY "Public Read Question Assets" ON storage.objects 
FOR SELECT USING (bucket_id = 'question_assets');

CREATE POLICY "Allow All Question Assets" ON storage.objects 
FOR ALL USING (bucket_id = 'question_assets') WITH CHECK (bucket_id = 'question_assets');
