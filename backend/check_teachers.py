import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from backend.database import SessionLocal
from backend import models

def check_teachers():
    db = SessionLocal()
    try:
        teachers = db.query(models.User).filter(models.User.role == "teacher").all()
        print(f"Found {len(teachers)} teachers:")
        for t in teachers:
            print(f"ID: {t.id}, Name: {t.full_name}, Verified: {t.is_verified}, Mobile: {t.mobile_number}")
    finally:
        db.close()

if __name__ == "__main__":
    check_teachers()
