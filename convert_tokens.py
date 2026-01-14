import pypinyin
import os

# 确保读取和写入都使用 utf-8 编码
input_file = "tokens.txt"
output_file = "tokens_pinyin.txt" # 先生成一个新文件对比看看

if not os.path.exists(input_file):
    print(f"错误：找不到 {input_file}，请确认你在模型文件夹内！")
else:
    with open(input_file, "r", encoding="utf-8") as f:
        lines = f.readlines()

    new_lines = []
    for line in lines:
        parts = line.strip().split()
        if len(parts) >= 1:
            token = parts[0]
            # 如果是中文字符，转成拼音
            if '\u4e00' <= token <= '\u9fff':
                # Style.TONE3 会生成 hao3 这种带数字调号的格式
                py = pypinyin.pinyin(token, style=pypinyin.Style.TONE3)[0][0]
                # 保持原来的索引号（如果有的话）
                idx = parts[1] if len(parts) > 1 else ""
                new_lines.append(f"{py} {idx}\n")
            else:
                new_lines.append(line)
        else:
            new_lines.append(line)

    with open("tokens.txt", "w", encoding="utf-8") as f:
        f.writelines(new_lines)
    print("成功：tokens.txt 已转换为拼音格式！")