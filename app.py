import subprocess
import os
import json
from fastapi import FastAPI, UploadFile, File

app = FastAPI()

@app.post("/pinyin")
async def get_pinyin(file: UploadFile = File(...)):
    raw_path = f"raw_{file.filename}"
    processed_path = "input_16k.wav"
    
    with open(raw_path, "wb") as f:
        f.write(await file.read())
    
    try:
        # 1. FFmpeg 转换 (16k 单声道)
        subprocess.run([
            "ffmpeg", "-y", "-i", raw_path, 
            "-ar", "16000", "-ac", "1", processed_path
        ], capture_output=True, text=True)

        # 2. 调用识别引擎
        cmd = [
            "./engine_linux",
            "--sense-voice-model=./model.int8.onnx",
            "--tokens=./tokens.txt",
            "--num-threads=4",
            "--sense-voice-language=zh",
            processed_path
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        # --- 核心修正：合并 stdout 和 stderr 进行解析 ---
        full_output = result.stdout + "\n" + result.stderr
        lines = full_output.strip().split('\n')
        
        for line in reversed(lines):
            line = line.strip()
            # 只有当这一行看起来像 JSON 时才尝试解析
            if line.startswith('{') and line.endswith('}'):
                try:
                    return json.loads(line)
                except:
                    continue
        
        return {"error": "no_json_found", "raw_output": full_output}

    finally:
        for p in [raw_path, processed_path]:
            if os.path.exists(p): os.remove(p)

if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 10000))
    uvicorn.run(app, host="0.0.0.0", port=port)