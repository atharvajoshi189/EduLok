from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
# We no longer need passlib (pwd_context, verify_password)
from jose import JWTError, jwt
from datetime import datetime, timedelta, timezone
from . import models, database

# --- JWT Token Settings (Same as before) ---
SECRET_KEY = "EDULOK_SECRET_KEY"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7 # 7 din

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/verify-otp") # Updated tokenUrl

# --- Helper Functions (Updated) ---

def get_user_by_mobile(db: Session, mobile_number: str):
    """Database se mobile number ke zariye user ko dhoondhta hai"""
    return db.query(models.User).filter(models.User.mobile_number == mobile_number).first()

def create_access_token(data: dict):
    """Naya JWT token banata hai"""
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(database.get_db)):
    """Token ko decode karke current user ki details nikalta hai"""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        # Hum ab 'sub' (subject) se mobile_number nikalenge
        mobile_number: str = payload.get("sub")
        if mobile_number is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    
    user = get_user_by_mobile(db, mobile_number=mobile_number)
    if user is None:
        raise credentials_exception
    return user

# NAYI Dependency: Admin user check karne ke liye (same as before)
def get_current_admin_user(current_user: models.User = Depends(get_current_user)):
    """Check karta hai ki current user login hai AUR ek Admin hai ya nahi."""
    if current_user.role != models.UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Operation not permitted. Requires Admin access."
        )
    return current_user