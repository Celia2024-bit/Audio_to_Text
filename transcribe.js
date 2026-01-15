/**
 * 核心逻辑：获取音频识别结果并与文本拼音对比
 */
async function processAndCompare(audioFile, targetText) {
    // 确保使用远程服务器的地址
    const API_URL = "https://audio-to-text-29330024195.europe-west2.run.app/pinyin";
    // docker run -it -p 39999:10000 my_pinyin_service:v1 /bin/bash
     // const API_URL = "http://localhost:39999/pinyin";

    try {
        // --- 第一部分：处理文本转拼音 (前端逻辑) ---
        const expectedPinyins = pinyinPro.pinyin(targetText, { 
            toneType: 'num', 
            type: 'array' 
        });

        // --- 第二部分：请求远程服务器 (浏览器 fetch 方式) ---
        const formData = new FormData();
        // 浏览器中的 file 对象直接通过 append 即可，不需要 fs.createReadStream
        formData.append('file', audioFile);

        const response = await fetch(API_URL, {
            method: "POST",
            body: formData,
            // 注意：浏览器 fetch 上传 FormData 时不要手动设置 Content-Type 头部，
            // 浏览器会自动设置并加上必要的 boundary 分界符。
        });
        
        if (!response.ok) {
            throw new Error(`服务器响应错误: ${response.status}`);
        }

        const data = await response.json();
        // 根据你 Node.js 脚本的打印结果，通常返回的是 data.pinyin 或 data.tokens
        // 这里假设返回结果在 data.pinyin 中，请根据后端实际返回字段调整
        const actualPinyins = data.pinyin || data.tokens || []; 
        console.log("音频识别原始数据:", data);

        // --- 第三部分：执行比对 ---
        const comparisonResult = targetText.split('').map((char, index) => {
            const exp = expectedPinyins[index];
            const act = actualPinyins[index] || "";
            return {
                char: char,
                expected: exp,
                actual: act,
                isCorrect: exp === act
            };
        });

        return comparisonResult;

    } catch (error) {
        console.error("处理失败:", error);
        throw error;
    }
}