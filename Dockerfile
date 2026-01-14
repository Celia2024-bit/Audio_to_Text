# 1. 使用轻量级 Python 环境
FROM python:3.11-slim

# 2. 安装必要工具 (FFmpeg 是核心, libsndfile1 是引擎依赖)
RUN apt-get update && apt-get install -y wget ffmpeg libsndfile1 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 3. 下载你在 Release 里上传的两个核心零件
# 请确保链接是你之前给我的那两个
RUN wget -O engine_linux "https://github.com/Celia2024-bit/Audio_to_Text/releases/download/v1.0/engine_linux"
RUN wget -O model.int8.onnx "https://github.com/Celia2024-bit/Audio_to_Text/releases/download/v1.0/model.int8.onnx"

# 4. 赋予执行权限
RUN chmod +x ./engine_linux

# 5. 安装 Python 依赖
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 6. 复制字典和你的主程序
COPY tokens.txt .
COPY app.py .

# 7. 暴露 Render 端口并启动 Python 程序
EXPOSE 10000
CMD ["python", "app.py"]