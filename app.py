import os
import shutil
import subprocess
import uuid
from fastapi import FastAPI, UploadFile, File
from fastapi.responses import JSONResponse
from phonemes import kaldi_raw_to_pinyin

KALDI_ROOT = "/opt/kaldi/egs/thchs30"
DATA_DIR = f"{KALDI_ROOT}/data/test"
WAV_DIR = f"{DATA_DIR}/wav"
EXP_DIR = f"{KALDI_ROOT}/exp"
MFCC_DIR = f"{KALDI_ROOT}/mfcc"

app = FastAPI()


@app.get("/health")
def health():
    return {"status": "ok"}


# ======================
# Helper Functions
# ======================

def save_wav(file: UploadFile) -> str:
    """保存上传的音频并返回文件路径"""
    os.makedirs(WAV_DIR, exist_ok=True)
    uid = str(uuid.uuid4())
    wav_path = os.path.join(WAV_DIR, f"{uid}.wav")
    with open(wav_path, "wb") as f:
        shutil.copyfileobj(file.file, f)
    return uid, wav_path


def prepare_kaldi_files(uid: str, wav_path: str):
    """生成 wav.scp, utt2spk, spk2utt"""
    os.makedirs(DATA_DIR, exist_ok=True)
    with open(os.path.join(DATA_DIR, "wav.scp"), "w") as f:
        f.write(f"{uid} {wav_path}\n")
    with open(os.path.join(DATA_DIR, "utt2spk"), "w") as f:
        f.write(f"{uid} {uid}\n")
    with open(os.path.join(DATA_DIR, "spk2utt"), "w") as f:
        f.write(f"{uid} {uid}\n")


def run_kaldi_pipeline():
    """执行 Kaldi MFCC 特征提取和对齐"""
    cmds = [
        f"cd {KALDI_ROOT} && steps/make_mfcc.sh --nj 1 {DATA_DIR} {EXP_DIR}/make_mfcc/test {MFCC_DIR}",
        f"cd {KALDI_ROOT} && steps/compute_cmvn_stats.sh {DATA_DIR} {EXP_DIR}/make_mfcc/test {MFCC_DIR}",
        f"cd {KALDI_ROOT} && steps/align_si.sh --nj 1 {DATA_DIR} {EXP_DIR}/mono {EXP_DIR}/mono_ali",
    ]
    for cmd in cmds:
        subprocess.check_call(cmd, shell=True)


def extract_phonemes(max_pinyin: int = 5):
    cmd = (
        f"cd {KALDI_ROOT} && "
        f"ali-to-phones --per-frame {EXP_DIR}/mono_ali/final.mdl "
        f"ark:'gunzip -c {EXP_DIR}/mono_ali/ali.1.gz|' ark,t:-"
    )

    raw_result = subprocess.check_output(cmd, shell=True).decode("utf-8")

    phones_txt = f"{KALDI_ROOT}/data/lang/phones.txt"

    pinyin_list = kaldi_raw_to_pinyin(
        raw_text=raw_result,
        phones_txt_path=phones_txt,
        max_pinyin=max_pinyin
    )

    return pinyin_list, raw_result

# ======================
# Main Endpoint
# ======================

@app.post("/recognize")
async def recognize(file: UploadFile = File(...)):
    try:
        uid, wav_path = save_wav(file)
        prepare_kaldi_files(uid, wav_path)
        run_kaldi_pipeline()
        phonemes, raw_result = extract_phonemes(max_pinyin=5)
        return {
            "uid": uid,
            "phonemes": phonemes,
            "raw": raw_result[:1000]
        }

    except subprocess.CalledProcessError as e:
        return JSONResponse(status_code=500, content={"error": str(e)})
    except Exception as e:
        return JSONResponse(status_code=500, content={"error": str(e)})
