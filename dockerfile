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
WORKDIR /opt/kaldi/egs

RUN wget -O thchs30_gmm.tgz https://kaldi-asr.org/models/3/0003_thchs30_gmm.tgz && \
    tar -xzf thchs30_gmm.tgz && \
    rm thchs30_gmm.tgz

# 解压后目录是：0003_thchs30_gmm
# 我们把它软链成 thchs30，方便路径统一
RUN ln -s /opt/kaldi/egs/0003_thchs30_gmm /opt/kaldi/egs/thchs30

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