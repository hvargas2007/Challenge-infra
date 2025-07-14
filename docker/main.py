from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import json
import os
from typing import Dict, Any
import fcntl
from pathlib import Path

app = FastAPI(title="JSON Storage API - Docker Version")

# Configuración - usar variable de entorno o default
STORAGE_PATH = os.getenv("STORAGE_PATH", "/mnt/efs/json-storage")
Path(STORAGE_PATH).mkdir(parents=True, exist_ok=True)

class JSONData(BaseModel):
    id: str
    data: Dict[str, Any]

@app.get("/")
def home():
    return {
        "message": "JSON Storage API - Docker Version",
        "docs": "/docs",
        "storage_path": STORAGE_PATH
    }

@app.get("/health")
def health_check():
    return {"status": "healthy", "version": "docker"}

@app.post("/json")
def create_json(json_data: JSONData):
    file_path = f"{STORAGE_PATH}/{json_data.id}.json"
    
    if os.path.exists(file_path):
        raise HTTPException(status_code=409, detail="JSON with this ID already exists")
    
    # Guardar con file locking
    with open(file_path, 'w') as f:
        fcntl.flock(f.fileno(), fcntl.LOCK_EX)
        json.dump(json_data.data, f)
        fcntl.flock(f.fileno(), fcntl.LOCK_UN)
    
    return {"message": "JSON created", "id": json_data.id}

@app.get("/json/{json_id}")
def get_json(json_id: str):
    file_path = f"{STORAGE_PATH}/{json_id}.json"
    
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="JSON not found")
    
    with open(file_path, 'r') as f:
        data = json.load(f)
    
    return {"id": json_id, "data": data}

@app.put("/json/{json_id}")
def update_json(json_id: str, json_data: Dict[str, Any]):
    file_path = f"{STORAGE_PATH}/{json_id}.json"
    
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="JSON not found")
    
    with open(file_path, 'w') as f:
        fcntl.flock(f.fileno(), fcntl.LOCK_EX)
        json.dump(json_data, f)
        fcntl.flock(f.fileno(), fcntl.LOCK_UN)
    
    return {"message": "JSON updated", "id": json_id}

@app.delete("/json/{json_id}")
def delete_json(json_id: str):
    file_path = f"{STORAGE_PATH}/{json_id}.json"
    
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="JSON not found")
    
    os.remove(file_path)
    return {"message": "JSON deleted", "id": json_id}