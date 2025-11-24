import fitz # PyMuPDF library
import os

# --- Settings (Folder Paths) ---
# INPUT: User ka folder name 'raw_textbooks'
PDF_DIR = os.path.join("backend", "data_prep", "raw_textbooks")
# OUTPUT: Processed text files yahan save honge
TEXT_DIR = os.path.join("backend", "data_prep", "processed_text")

# Ensure the output directory exists
os.makedirs(TEXT_DIR, exist_ok=True)

print("Starting PDF Extraction...")

processed_count = 0

# Process files inside the user's directory
for filename in os.listdir(PDF_DIR):
    if filename.endswith((".pdf", ".PDF")):
        pdf_path = os.path.join(PDF_DIR, filename)
        
        # Output file ka naam: sirf extension badalna
        output_filename = filename.replace(".pdf", ".txt").replace(".PDF", ".txt")
        output_path = os.path.join(TEXT_DIR, output_filename)

        try:
            # Document ko open karna
            doc = fitz.open(pdf_path)
            full_text = ""
            
            # Har page se text nikalna
            for page in doc:
                full_text += page.get_text() + "\n\n"
            
            # Text file mein save karna
            with open(output_path, "w", encoding="utf-8") as out_file:
                out_file.write(full_text)
            
            doc.close()
            processed_count += 1
            print(f"SUCCESS: Extracted text from {filename} -> {output_filename}")

        except Exception as e:
            print(f"ERROR: Could not process {filename}. Details: {e}")

print(f"\nCompleted extraction of {processed_count} files.")
print(f"Check the '{TEXT_DIR}' folder for the .txt files.")