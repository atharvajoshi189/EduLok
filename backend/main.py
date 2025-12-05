from fastapi import FastAPI, Depends, HTTPException, status
from sqlalchemy.orm import Session
from . import models, schemas, database, auth
from typing import List
from fastapi.middleware.cors import CORSMiddleware # CORS import
from . import models, schemas, database, auth, chat_service
from pydantic import BaseModel
from typing import Optional

class ChatRequest(BaseModel):
    query: str
    subject: Optional[str] = None

# 1. Database tables banana
models.Base.metadata.create_all(bind=database.engine)

# FastAPI app instance
app = FastAPI()

@app.on_event("startup")
async def startup_event():
    chat_service.initialize()

# --- CORS Middleware (To allow Flutter app to call API) ---
origins = ["*"]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
# --- End of CORS ---


# 2. Database Dependency
def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()

# --- API Endpoints ---

@app.get("/")
def read_root():
    return {"message": "EduLok Backend API v1.0"}

@app.post("/chat")
def chat_endpoint(request: ChatRequest):
    response = chat_service.get_response(request.query, request.subject)
    return {"answer": response}

# --- Stage 2 & 3: Mobile/OTP Authentication ---

@app.post("/auth/signup-send-otp", status_code=status.HTTP_200_OK)
def signup_send_otp(user_data: schemas.UserSignUp, db: Session = Depends(get_db)):
    db_user = auth.get_user_by_mobile(db, mobile_number=user_data.mobile_number)
    if db_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Mobile number already registered. Please login."
        )

    new_user = models.User(
        full_name=user_data.full_name,
        mobile_number=user_data.mobile_number,
        role=user_data.role,
        is_active=False,
        has_onboarded=False
    )
    db.add(new_user)
    db.commit()

    print(f"--- DUMMY OTP for {user_data.mobile_number}: 123456 ---")
    return {"message": "OTP sent successfully. Please verify."}

@app.post("/auth/login-send-otp", status_code=status.HTTP_200_OK)
def login_send_otp(request: schemas.SendOTPRequest, db: Session = Depends(get_db)):
    db_user = auth.get_user_by_mobile(db, mobile_number=request.mobile_number)
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Mobile number not registered. Please sign up."
        )

    print(f"--- DUMMY OTP for {request.mobile_number}: 123456 ---")
    return {"message": "OTP sent successfully. Please verify."}

@app.post("/auth/verify-otp", response_model=schemas.Token)
def verify_otp(request: schemas.VerifyOTPRequest, db: Session = Depends(get_db)):
    if request.otp != "123456":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid OTP"
        )

    db_user = auth.get_user_by_mobile(db, mobile_number=request.mobile_number)
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found. Please try signing up again."
        )

    db_user.is_active = True
    db.commit()

    access_token = auth.create_access_token(
        data={"sub": db_user.mobile_number}
    )

    return {
        "access_token": access_token,
        "token_type": "bearer",
        "has_onboarded": db_user.has_onboarded ,
        "full_name": db_user.full_name,
        "role": db_user.role
    }

# --- NAYA ENDPOINT: Onboarding Complete Karne Ke Liye (FIXED) ---
@app.post("/users/complete-onboarding", response_model=schemas.User)
def complete_onboarding(
    user_from_token: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    print("DEBUG: complete_onboarding called for user_from_token.id ->", getattr(user_from_token, "id", None))

    db_user = db.query(models.User).filter(models.User.id == user_from_token.id).first()
    if not db_user:
        print("DEBUG: no db_user found for id:", getattr(user_from_token, "id", None))
        raise HTTPException(status_code=404, detail="User not found in session")

    db_user.has_onboarded = True
    db.commit()
    db.refresh(db_user)

    print("DEBUG: after commit has_onboarded ->", db_user.has_onboarded, " (id:", db_user.id, ")")
    print("DEBUG: after commit has_onboarded ->", db_user.has_onboarded, " (id:", db_user.id, ")")
    return db_user

@app.put("/users/update-role", response_model=schemas.User)
def update_role(
    role_data: schemas.UserUpdateRole,
    user_from_token: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    db_user = db.query(models.User).filter(models.User.id == user_from_token.id).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")
    
    db_user.role = role_data.role
    db.commit()
    db.refresh(db_user)
    return db_user
# --- Baaki ke saare endpoints same rahenge ---

@app.get("/users/me", response_model=schemas.User)
def read_users_me(current_user: models.User = Depends(auth.get_current_user)):
    return current_user

# Stage 4: Mentorship System
@app.get("/teachers/", response_model=List[schemas.User])
def get_verified_teachers(db: Session = Depends(database.get_db), current_user: models.User = Depends(auth.get_current_user)):
    teachers = db.query(models.User).filter(
        models.User.role == models.UserRole.TEACHER,
        models.User.is_verified == True
    ).all()
    return teachers

@app.put("/teachers/update-profile", response_model=schemas.User)
def update_teacher_profile(
    profile_data: schemas.TeacherProfileUpdate,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(database.get_db)
):
    if current_user.role != models.UserRole.TEACHER:
        raise HTTPException(status_code=403, detail="Only teachers can update profile")
    
    db_user = db.query(models.User).filter(models.User.id == current_user.id).first()
    db_user.subject = profile_data.subject
    db_user.experience = profile_data.experience
    db_user.full_name = profile_data.full_name
    db_user.is_verified = True # Auto-verify for hackathon
    
    db.commit()
    db.refresh(db_user)
    return db_user

@app.post("/mentorship/request", response_model=schemas.MentorshipRequest)
def send_mentorship_request(request: schemas.MentorshipRequestCreate, db: Session = Depends(database.get_db), current_user: models.User = Depends(auth.get_current_user)):
    if current_user.role != models.UserRole.STUDENT:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only students can send mentorship requests")
    teacher = db.query(models.User).filter(models.User.id == request.teacher_id).first()
    if not teacher or teacher.role != models.UserRole.TEACHER:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Teacher not found")
    new_request = models.MentorshipRequest(student_id=current_user.id, teacher_id=request.teacher_id, status="pending")
    db.add(new_request)
    db.commit()
    db.refresh(new_request)
    return new_request

@app.get("/mentorship/requests/me", response_model=List[schemas.MentorshipRequest])
def get_my_mentorship_requests(db: Session = Depends(database.get_db), current_user: models.User = Depends(auth.get_current_user)):
    if current_user.role != models.UserRole.TEACHER:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only teachers can view requests")
    requests = db.query(models.MentorshipRequest).filter(models.MentorshipRequest.teacher_id == current_user.id, models.MentorshipRequest.status == "pending").all()
    return requests

@app.post("/mentorship/requests/approve/{request_id}", response_model=schemas.MentorshipRequest)
def approve_mentorship_request(request_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(auth.get_current_user)):
    if current_user.role != models.UserRole.TEACHER:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only teachers can approve requests")
    db_request = db.query(models.MentorshipRequest).filter(models.MentorshipRequest.id == request_id).first()
    if not db_request or db_request.teacher_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Request not found")
    db_request.status = "approved"
    db.commit()
    db.refresh(db_request)
    return db_request

@app.get("/mentorship/students", response_model=List[schemas.User])
def get_my_students(db: Session = Depends(database.get_db), current_user: models.User = Depends(auth.get_current_user)):
    if current_user.role != models.UserRole.TEACHER:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only teachers can view their students")
    
    # Join MentorshipRequest and User to get students where status is 'approved'
    students = db.query(models.User).join(models.MentorshipRequest, models.MentorshipRequest.student_id == models.User.id).filter(
        models.MentorshipRequest.teacher_id == current_user.id,
        models.MentorshipRequest.status == "approved"
    ).all()
    
    return students

@app.get("/mentorship/mentors", response_model=List[schemas.User])
def get_my_mentors(db: Session = Depends(database.get_db), current_user: models.User = Depends(auth.get_current_user)):
    if current_user.role != models.UserRole.STUDENT:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only students can view their mentors")
    
    # Join MentorshipRequest and User to get teachers where status is 'approved'
    mentors = db.query(models.User).join(models.MentorshipRequest, models.MentorshipRequest.teacher_id == models.User.id).filter(
        models.MentorshipRequest.student_id == current_user.id,
        models.MentorshipRequest.status == "approved"
    ).all()
    
    return mentors

@app.get("/mentorship/requests/sent", response_model=List[schemas.MentorshipRequestWithTeacher])
def get_sent_requests(db: Session = Depends(database.get_db), current_user: models.User = Depends(auth.get_current_user)):
    if current_user.role != models.UserRole.STUDENT:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only students can view sent requests")
    
    requests = db.query(models.MentorshipRequest).filter(
        models.MentorshipRequest.student_id == current_user.id,
        models.MentorshipRequest.status == "pending"
    ).all()
    return requests

@app.delete("/mentorship/requests/{request_id}", status_code=status.HTTP_204_NO_CONTENT)
def withdraw_request(request_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(auth.get_current_user)):
    if current_user.role != models.UserRole.STUDENT:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only students can withdraw requests")
    
    db_request = db.query(models.MentorshipRequest).filter(
        models.MentorshipRequest.id == request_id,
        models.MentorshipRequest.student_id == current_user.id
    ).first()
    
    if not db_request:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Request not found")
    
    db.delete(db_request)
    db.commit()
    return None

# Stage 5: Admin Panel API
@app.get("/admin/teachers/pending", response_model=List[schemas.User])
def get_pending_teachers(db: Session = Depends(database.get_db), current_admin: models.User = Depends(auth.get_current_admin_user)):
    pending_teachers = db.query(models.User).filter(
        models.User.role == models.UserRole.TEACHER,
        models.User.is_verified == False
    ).all()
    return pending_teachers

@app.post("/admin/teachers/verify/{teacher_id}", response_model=schemas.User)
def verify_teacher(teacher_id: int, db: Session = Depends(database.get_db), current_admin: models.User = Depends(auth.get_current_admin_user)):
    # --- YAHAN BHI EK TYPO FIX KIYA HAI ---
    db_teacher = db.query(models.User).filter(
        models.User.id == teacher_id,
        models.User.role == models.UserRole.TEACHER # Pehle 'TEACHNER' tha
    ).first()
    if not db_teacher:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Teacher not found")
    db_teacher.is_verified = True
    db.commit()
    db.refresh(db_teacher)
    return db_teacher

# Stage 6: Delta Sync API
@app.post("/sync/delta", response_model=schemas.SyncResponse)
def sync_delta_data(data: schemas.DeltaSyncData, db: Session = Depends(database.get_db), current_user: models.User = Depends(auth.get_current_user)):
    if current_user.role != models.UserRole.STUDENT:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only students can sync progress.")
    synced_count = 0
    for update in data.progress_updates:
        db_progress = db.query(models.StudentProgress).filter(models.StudentProgress.student_id == current_user.id, models.StudentProgress.content_id == update.content_id).first()
        if db_progress:
            db_progress.progress_percentage = update.progress_percentage
            db_progress.is_completed = update.is_completed
        else:
            db_progress = models.StudentProgress(student_id=current_user.id, content_id=update.content_id, progress_percentage=update.progress_percentage, is_completed=update.is_completed)
            db.add(db_progress)
        synced_count += 1
    db.commit()
    return {"status": "success", "synced_items": synced_count}