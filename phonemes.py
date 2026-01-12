# phonemes.py
import os
import re

def load_phone_map(phones_txt_path):
    """
    读取 phones.txt: 23 t, 45 i, 78 an1
    返回 dict: { '23': 't', '45': 'i', '78': 'an1' }
    """
    phone_map = {}
    with open(phones_txt_path, "r", encoding="utf-8") as f:
        for line in f:
            parts = line.strip().split()
            if len(parts) == 2:
                phone, idx = parts
                phone_map[idx] = phone
    return phone_map


def ids_to_phones(id_list, phone_map):
    """把 ['23','23','45'] 转成 ['t','t','i']"""
    return [phone_map.get(pid, pid) for pid in id_list]


def deduplicate(seq):
    """去掉连续重复帧"""
    result = []
    last = None
    for x in seq:
        if x != last:
            result.append(x)
            last = x
    return result


def merge_phones_to_pinyin(phones):
    """
    ['t','i','an1','q','i4'] → ['tian1','qi4']
    """
    result = []
    buffer = ""

    for p in phones:
        buffer += p
        if re.search(r"\d$", p):   # 以声调结尾
            result.append(buffer)
            buffer = ""

    if buffer:
        result.append(buffer)

    return result


def kaldi_raw_to_pinyin(raw_text, phones_txt_path, max_pinyin=5):
    """
    主入口函数：Kaldi 输出 → 拼音列表
    """
    phone_map = load_phone_map(phones_txt_path)

    all_ids = []
    for line in raw_text.strip().split("\n"):
        parts = line.strip().split()
        if len(parts) > 1:
            all_ids.extend(parts[1:])  # 去掉 utt id

    phones = ids_to_phones(all_ids, phone_map)
    phones = deduplicate(phones)
    pinyin = merge_phones_to_pinyin(phones)

    return pinyin[:max_pinyin]
