// demo.js
import fs from "fs";
import fetch from "node-fetch";
import FormData from "form-data";

// -------- 配置 --------
const API_URL = "http://localhost:5000/recognize";

// -------- 公共函数：上传音频并返回 JSON --------
export async function recognizeAudio(audioPath) {
  const form = new FormData();
  form.append("file", fs.createReadStream(audioPath));

  const response = await fetch(API_URL, {
    method: "POST",
    body: form
  });

  if (!response.ok) {
    throw new Error(`API 请求失败: ${response.status} ${response.statusText}`);
  }

  const data = await response.json();
  return data; // 返回 JSON: { uid, phonemes, raw }
}

// -------- Demo 函数 --------
export async function demo() {
  try {
    const audioPath = "./demo/test.wav"; // 测试音频
    const result = await recognizeAudio(audioPath);

    console.log("=== Demo 结果 ===");
    console.log("UID:", result.uid);
    console.log("Phonemes:", result.phonemes);
    console.log("Raw (前1000字符):", result.raw);
  } catch (err) {
    console.error("Demo 出错:", err);
  }
}

// -------- 如果直接用 node demo.js 执行 demo --------
if (require.main === module) {
  demo();
}
