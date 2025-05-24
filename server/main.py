from fastapi import FastAPI
from models.base import Base
from routes import auth
from database import engine

# fastapi dev main.py
# Run the FastAPI server with the following command: uvicorn main:app --host 0.0.0.0 --port 8000
# db pass bd123


app = FastAPI()

app.include_router(auth.router, prefix='/auth')

Base.metadata.create_all(engine)