FROM kaldiasr/kaldi:latest

# =========================
# 1. 安装系统依赖
# =========================
RUN apt-get update && \
    apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3.11-venv \
    curl \
    && rm -rf /var/lib/apt/lists/*
    
# =========================
# 2. Kaldi + Aishell（一次性）
# =========================
WORKDIR /opt/kaldi/egs/thchs30/s5

# 下载 THCHS30 数据集
RUN mkdir -p /data/thchs30 && \
    cd /data/thchs30 && \
    wget -q http://www.openslr.org/resources/18/data_thchs30.tgz && \
    tar -xzf data_thchs30.tgz && \
    rm data_thchs30.tgz && \
    wget -q http://www.openslr.org/resources/18/resource.tgz && \
    tar -xzf resource.tgz && \
    rm resource.tgz

# 修改数据路径
RUN sed -i 's|thchs=/nfs/public/materials/data/thchs30-openslr|thchs=/data/thchs30|g' run.sh

# 只跑到 mono
RUN sed -i 's/^.*tri1/#&/' run.sh && \
    sed -i 's/^.*tri2/#&/' run.sh && \
    sed -i 's/^.*tri3/#&/' run.sh && \
    sed -i 's/^.*chain/#&/' run.sh && \
    chmod +x run.sh && \
    ./run.sh
# =========================
# 3. 复制 Python 应用文件
# =========================
WORKDIR /app
COPY app.py /app/app.py
COPY phonemes.py /app/phonemes.py
COPY requirements.txt /app/requirements.txt

# =========================
# 4. 安装 Python 依赖
# =========================
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir -r /app/requirements.txt

# =========================
# 5. 复制测试音频文件
# =========================
RUN mkdir -p data/test/wav
COPY demo/test.wav data/test/wav/test.wav

# =========================
# 6. 创建必要的目录
# =========================
RUN mkdir -p /app/uploads /app/temp

# =========================
# 7. 设置环境变量
# =========================
ENV FLASK_APP=/app/app.py
ENV PYTHONUNBUFFERED=1
ENV KALDI_ROOT=/opt/kaldi

# =========================
# 8. 切换到应用目录
# =========================
WORKDIR /app

# =========================
# 9. 健康检查
# =========================
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

# =========================
# 10. 暴露端口
# =========================
EXPOSE 5000

# =========================
# 11. 启动应用
# =========================
CMD ["python3", "app.py"]