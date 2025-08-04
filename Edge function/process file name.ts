// import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
// import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.42.0' 
import { parse as parseYaml } from 'https://deno.land/std@0.224.0/yaml/parse.ts'; // Import YAML parser
import { createClient } from 'jsr:@supabase/supabase-js@^2';

Deno.serve(async (req)=>{
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', {
      status: 405
    });
  }
  const { record } = await req.json();
  const bucketId = record.bucket_id;
  const objectName = record.name // This is the full path within the bucket
  ;
  const storageObjectId = record.id // Get the ID from storage.objects to link to your files table
  ;
  if (!bucketId || !objectName || !storageObjectId) {
    return new Response('Missing required fields in payload', {
      status: 400
    });
  }
  const supabase = createClient(Deno.env.get('SUPABASE_URL'), Deno.env.get('SUPABASE_SERVICE_ROLE_KEY'));
  try {
    const { data: fileData, error: downloadError } = await supabase.storage.from(bucketId).download(objectName);
    if (downloadError) {
      console.error('Error downloading file:', downloadError.message);
      return new Response(`Error downloading file: ${downloadError.message}`, {
        status: 500
      });
    }
    let extractedName = null;
    let extractedText = null;
    let wordCount = null;
    let firstLine = null;
    let fileType = null;
    if (fileData) {
      const textContent = await fileData.text();
      extractedText = textContent; // Store the full content if desired
      // Determine if it's a Markdown file based on extension (or MIME type if reliable)
      if (objectName.toLowerCase().endsWith('.md') || objectName.toLowerCase().endsWith('.markdown')) {
        fileType = 'text/markdown';
        // Extract YAML Frontmatter
        const frontmatterRegex = /^---\s*\n([\s\S]*?)\n---\s*\n([\s\S]*)$/;
        const match = textContent.match(frontmatterRegex);
        if (match) {
          const yamlBlock = match[1];
          const markdownContent = match[2]; // Content after frontmatter
          try {
            const metadata = parseYaml(yamlBlock);
            if (metadata && typeof metadata === 'object' && 'Name' in metadata) {
              extractedName = metadata.Name;
            }
            // You can extract other metadata fields here if needed
            // console.log('Extracted YAML Metadata:', metadata);
            // For word count and first line, use the actual markdown content
            wordCount = markdownContent.split(/\s+/).filter((word)=>word.length > 0).length;
            firstLine = markdownContent.split('\n')[0];
          } catch (yamlError) {
            console.error('Error parsing YAML frontmatter:', yamlError.message);
          }
        } else {
          // No YAML frontmatter, treat as plain markdown or fall back
          console.warn('No YAML frontmatter found for:', objectName);
          wordCount = textContent.split(/\s+/).filter((word)=>word.length > 0).length;
          firstLine = textContent.split('\n')[0];
        }
      } else {
        // Handle other text file types (e.g., plain text, CSV, JSON)
        if (objectName.toLowerCase().endsWith('.txt')) fileType = 'text/plain';
        else if (objectName.toLowerCase().endsWith('.csv')) fileType = 'text/csv';
        else if (objectName.toLowerCase().endsWith('.json')) fileType = 'application/json';
        wordCount = textContent.split(/\s+/).filter((word)=>word.length > 0).length;
        firstLine = textContent.split('\n')[0];
      }
    // Add other file type handling as before for non-text files
    }
    // 3. Update your custom 'files' table
    // We link using storage_object_id which is unique for each uploaded file in storage.objects
    const { error: updateError } = await supabase.from('files').update({
      name: extractedName || objectName.split('/').pop(),
      mime_type: fileType || record.metadata?.mimetype
    }).eq('storage_object_id', storageObjectId); // Use the storage_object_id to target the correct row
    if (updateError) {
      console.error('Error updating files table:', updateError.message);
      return new Response(`Error updating files table: ${updateError.message}`, {
        status: 500
      });
    }
    return new Response('File processed and database updated successfully!', {
      status: 200
    });
  } catch (error) {
    console.error('Unhandled error:', error.message);
    return new Response(`Unhandled error: ${error.message}`, {
      status: 500
    });
  }
});
