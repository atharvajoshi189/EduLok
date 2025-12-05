import pandas as pd
import os

base_dir = os.path.dirname(os.path.abspath(__file__))
excel_path = os.path.join(base_dir, 'data.xlsx')

try:
    df = pd.read_excel(excel_path)
    for col in df.columns:
        print(f"'{col}'")
except Exception as e:
    print(f"Error: {e}")
