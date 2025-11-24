from pydantic import BaseModel, EmailStr
from .models import UserRole
import enum
from typing import List, Optional

# --- Authentication Schemas (Naye) ---

class UserSignUp(BaseModel):
    full_name: str
    mobile_number: str
    role: UserRole = UserRole.STUDENT

class SendOTPRequest(BaseModel):
    mobile_number: str

class VerifyOTPRequest(BaseModel):
    mobile_number: str
    otp: str

class UserUpdateRole(BaseModel):
    role: UserRole


# --- Response Schemas ---

class User(BaseModel):
    id: int
    role: UserRole
    is_verified: bool
    has_onboarded: bool # Yeh bhi user info ka part hai
    
    full_name: Optional[str] = None
    mobile_number: Optional[str] = None
    email: Optional[EmailStr] = None
    
    # Teacher Fields
    subject: Optional[str] = None
    experience: Optional[str] = None
    rating: Optional[float] = None

    class Config:
        orm_mode = True

class TeacherProfileUpdate(BaseModel):
    subject: str
    experience: str
    full_name: str

# --- Token Schemas (Yeh update hoga) ---

class Token(BaseModel):
    access_token: str
    token_type: str
    # --- YEH NAYI LINE HAI ---
    # Yeh Flutter ko batayega ki user ko dashboard par bhejna hai ya onboarding par
    has_onboarded: bool 
    full_name: str
    role: str

class TokenData(BaseModel):
    mobile_number: Optional[str] = None


# --- Mentorship Schemas (Yeh same rahenge) ---

class MentorshipRequestCreate(BaseModel):
    teacher_id: int

class MentorshipRequest(BaseModel):
    id: int
    student_id: int
    teacher_id: int
    status: str

    class Config:
        orm_mode = True

class MentorshipRequestWithTeacher(MentorshipRequest):
    teacher: User

    class Config:
        orm_mode = True

# --- Delta Sync Schemas (Yeh same rahenge) ---

class ProgressUpdate(BaseModel):
    content_id: str
    progress_percentage: float
    is_completed: bool

class DeltaSyncData(BaseModel):
    progress_updates: List[ProgressUpdate] = []

class SyncResponse(BaseModel):
    status: str
    synced_items: int