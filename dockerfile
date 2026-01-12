FROM kaldiasr/kaldi:latest

# =========================
# 1. 设置工作目录
# =========================
WORKDIR /opt/kaldi/egs/aishell/s5

# =========================
# 2. 安装系统依赖
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
# 3. 复制 Python 应用文件
# =========================
COPY app.py /app/app.py
COPY phonemes.py /app/phonemes.py
COPY requirements.txt /app/requirements.txt

# =========================
# 4. 安装 Python 依赖
# =========================
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir -r /app/requirements.txt
#RUN pip3 install --break-system-packages --no-cache-dir -r /app/requirements.txt

# =========================
# 5. 复制 Kaldi 相关脚本和配置
# =========================
# 如果你有自定义的 steps/ 或 utils/ 脚本，在这里复制
# COPY steps/ /opt/kaldi/egs/aishell/s5/steps/
# COPY utils/ /opt/kaldi/egs/aishell/s5/utils/
# COPY conf/ /opt/kaldi/egs/aishell/s5/conf/

# =========================
# 6. 复制或下载预训练模型
# =========================
# 方式1：如果你有预训练模型，直接复制
# COPY exp/ /opt/kaldi/egs/aishell/s5/exp/
# COPY data/ /opt/kaldi/egs/aishell/s5/data/

# 方式2：如果需要训练模型，运行训练脚本
# COPY run.sh /opt/kaldi/egs/aishell/s5/
# RUN bash run.sh

# =========================
# 7. 复制测试音频文件
# =========================
RUN mkdir -p data/test/wav
COPY demo/test.wav data/test/wav/test.wav

# =========================
# 8. Demo 自检（build 阶段验证）
# =========================
RUN echo "===== DEMO CHECK: Building feature pipeline =====" && \
    echo "demo /opt/kaldi/egs/aishell/s5/data/test/wav/test.wav" > data/test/wav.scp && \
    echo "demo demo" > data/test/utt2spk && \
    echo "demo demo" > data/test/spk2utt && \
    echo "===== Extracting MFCC features =====" && \
    steps/make_mfcc.sh --nj 1 data/test exp/make_mfcc/test mfcc && \
    echo "===== Computing CMVN stats =====" && \
    steps/compute_cmvn_stats.sh data/test exp/make_mfcc/test mfcc && \
    echo "===== Running alignment =====" && \
    steps/align_si.sh --nj 1 data/test exp/mono exp/mono_ali && \
    echo "===== Extracting phoneme alignment =====" && \
    ali-to-phones exp/mono_ali/final.mdl ark:"gunzip -c exp/mono_ali/ali.1.gz|" ark,t:- | head -n 20 && \
    echo "===== DEMO CHECK PASSED ====="

# =========================
# 9. 创建必要的目录
# =========================
RUN mkdir -p /app/uploads /app/temp

# =========================
# 10. 设置环境变量
# =========================
ENV FLASK_APP=/app/app.py
ENV PYTHONUNBUFFERED=1
ENV KALDI_ROOT=/opt/kaldi

# =========================
# 11. 切换到应用目录
# =========================
WORKDIR /app

# =========================
# 12. 健康检查
# =========================
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

# =========================
# 13. 暴露端口
# =========================
EXPOSE 5000

# =========================
# 14. 启动应用
# =========================
CMD ["python3", "app.py"]