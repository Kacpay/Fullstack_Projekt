from fastapi import FastAPI
from models.base import Base
from routes import auth
from routes import n_back_result
from database import engine

# fastapi dev main.py
# Run the FastAPI server with the following command: uvicorn main:app --host 0.0.0.0 --port 8000
# db pass bd123


app = FastAPI()

app.include_router(auth.router, prefix='/auth')
app.include_router(n_back_result.router, prefix='/nback')

Base.metadata.create_all(engine)