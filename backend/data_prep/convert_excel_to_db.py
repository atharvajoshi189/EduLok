import pandas as pd
import sqlite3
import os
import re

def clean_text(text):
    """
    Removes special characters and converts text to lowercase for optimized search.
    """
    if not isinstance(text, str):
        return ""
    # Remove non-alphanumeric characters (keep spaces)
    text = re.sub(r'[^a-zA-Z0-9\s]', '', text)
    # Convert to lowercase
    text = text.lower()
    # Remove extra spaces
    text = re.sub(r'\s+', ' ', text).strip()
    return text

def convert_excel_to_db():
    # Define paths
    base_dir = os.path.dirname(os.path.abspath(__file__))
    excel_path = os.path.join(base_dir, 'data.xlsx')
    
    # Output directory (assets/databases) - relative to project root
    # Assuming script is in backend/data_prep/
    project_root = os.path.abspath(os.path.join(base_dir, '..', '..'))
    output_dir = os.path.join(project_root, 'assets', 'databases')
    db_path = os.path.join(output_dir, 'questions.db')

    # Create output directory if it doesn't exist
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        print(f"Created directory: {output_dir}")

    print(f"Reading Excel file from: {excel_path}")
    try:
        df = pd.read_excel(excel_path)
    except FileNotFoundError:
        print(f"Error: Excel file not found at {excel_path}")
        return
    except Exception as e:
        print(f"Error reading Excel file: {e}")
        return

    # Ensure required columns exist
    required_columns = ['Question', 'Solution (Step-by-step)', 'Class', 'Subject', 'Chapter']
    for col in required_columns:
        if col not in df.columns:
            print(f"Error: Missing column '{col}' in Excel file.")
            return

    # Create a clean_question column for FTS
    print("Processing data...")
    df['clean_question'] = df['Question'].apply(clean_text)

    # Connect to SQLite database
    print(f"Creating database at: {db_path}")
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Create FTS4 table
    # We use FTS4 for full-text search on the question
    cursor.execute("DROP TABLE IF EXISTS questions_fts")
    cursor.execute("""
        CREATE VIRTUAL TABLE questions_fts USING fts4(
            question, 
            solution, 
            class_name, 
            subject, 
            chapter, 
            clean_question
        )
    """)

    # Insert data
    print("Inserting data into database...")
    for index, row in df.iterrows():
        cursor.execute("""
            INSERT INTO questions_fts (question, solution, class_name, subject, chapter, clean_question)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (
            str(row['Question']), 
            str(row['Solution (Step-by-step)']), 
            str(row['Class']), 
            str(row['Subject']), 
            str(row['Chapter']), 
            str(row['clean_question'])
        ))

    conn.commit()
    conn.close()
    print("Database creation complete!")

if __name__ == "__main__":
    convert_excel_to_db()
