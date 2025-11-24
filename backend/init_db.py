from backend.database import SessionLocal, engine
from backend import models
from backend.models import User, UserRole

def init_db():
    # 1. Create Tables
    models.Base.metadata.create_all(bind=engine)
    
    db = SessionLocal()
    
    try:
        # 2. Check if Teacher exists
        teacher = db.query(User).filter(User.mobile_number == "9226581437").first()
        if not teacher:
            print("Creating Teacher...")
            teacher = User(
                full_name="Atharva Teacher",
                mobile_number="9226581437",
                email="teacher@edulok.com",
                role=UserRole.TEACHER,
                is_verified=True,
                is_active=True,
                has_onboarded=True
            )
            db.add(teacher)
        else:
            print("Teacher already exists.")

        # 3. Check if Student exists
        student = db.query(User).filter(User.mobile_number == "7020908728").first()
        if not student:
            print("Creating Student...")
            student = User(
                full_name="Atharva Student",
                mobile_number="7020908728",
                email="student@edulok.com",
                role=UserRole.STUDENT,
                is_verified=True, # Students don't strictly need this but good for consistency
                is_active=True,
                has_onboarded=True
            )
            db.add(student)
        else:
            print("Student already exists.")
            
        db.commit()
        print("Database initialized successfully!")
        
    except Exception as e:
        print(f"Error initializing database: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    init_db()
