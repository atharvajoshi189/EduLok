import os

# Ensure ye path sahi hai!
textbooks_dir = './data_prep/raw_textbooks/' 
corpus_file = '../corpus.txt' # Output file location (Project Root)

with open(corpus_file, 'w', encoding='utf-8') as outfile:
    for filename in os.listdir(textbooks_dir):
        if filename.endswith(".txt"):
            file_path = os.path.join(textbooks_dir, filename)
            
            print(f"Processing: {filename}")
            
            with open(file_path, 'r', encoding='utf-8') as infile:
                content = infile.read()
                
                # Cleaning band! Sirf raw content likho:
                outfile.write(content)
                
                # Ek hi line ka separator do
                outfile.write('\n\n--- DOC SEP ---\n\n')

print(f"\n✅ Success! All textbooks compiled into {corpus_file}")