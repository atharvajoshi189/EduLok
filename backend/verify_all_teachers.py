import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from backend.database import SessionLocal
from backend import models

def verify_all_teachers():
    db = SessionLocal()
    try:
        teachers = db.query(models.User).filter(models.User.role == "teacher").all()
        print(f"Found {len(teachers)} teachers. Verifying all...")
        for t in teachers:
            t.is_verified = True
            print(f"Verified: {t.full_name}")
        
        db.commit()
        print("✅ All teachers verified successfully!")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    verify_all_teachers()
