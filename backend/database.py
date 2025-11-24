from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from sqlalchemy.orm import Session

# 1. Database URL
# Hum abhi ke liye SQLite istemaal kar rahe hain.
# Yeh 'backend' folder mein hi ek 'edulok.db' naam ki file bana dega.
SQLALCHEMY_DATABASE_URL = "sqlite:///./edulok.db"

# 2. SQLAlchemy Engine
# Yeh engine database se connection manage karta hai.
engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    # Yeh setting SQLite ke liye zaroori hai
    connect_args={"check_same_thread": False} 
)

# 3. Database Session
# Har request ke liye ek naya database session banayega.
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# 4. Base Class
# Hamare saare database models (jaise User, Teacher) is class se inherit honge.
Base = declarative_base()
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()