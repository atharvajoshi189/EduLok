from sqlalchemy import Column, Integer, String, Boolean, Enum, ForeignKey, Float
from .database import Base 
import enum

# 1. Role Enum (Yeh same rahega)
class UserRole(str, enum.Enum):
    STUDENT = "student"
    TEACHER = "teacher"
    ADMIN = "admin"

# 2. User Table Model (Yeh update hoga)
class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String)
    mobile_number = Column(String, unique=True, index=True, nullable=True)
    email = Column(String, unique=True, index=True, nullable=True) 
    role = Column(Enum(UserRole), nullable=False, default=UserRole.STUDENT)
    is_verified = Column(Boolean, default=False)
    is_active = Column(Boolean, default=True)
    
    # --- NAYA COLUMN YAHAN ADD KIYA ---
    # Yeh 'False' hoga jab user sign up karega
    # Aur 'True' ho jaayega jab woh onboarding poora karega
    has_onboarded = Column(Boolean, default=False)

    # --- TEACHER SPECIFIC FIELDS ---
    subject = Column(String, nullable=True)
    experience = Column(String, nullable=True)
    rating = Column(Float, default=5.0)

# 3. Mentorship Request Table Model (Yeh same rahega)
class MentorshipRequest(Base):
    __tablename__ = "mentorship_requests"
    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    teacher_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    status = Column(String, default="pending") 

# 4. Student Progress Table Model (Yeh same rahega)
class StudentProgress(Base):
    __tablename__ = "student_progress"
    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    content_id = Column(String, nullable=False, index=True) 
    progress_percentage = Column(Float, default=0.0) 
    is_completed = Column(Boolean, default=False)