/**
 * Pinyin Parser for Numeric Tone Strings (e.g., "ni3")
 */
const PinyinParser = {
    initials: ['ch', 'sh', 'zh', 'b', 'p', 'm', 'f', 'd', 't', 'n', 'l', 'g', 'k', 'h', 'j', 'q', 'x', 'r', 's', 'z', 'y', 'w'],

    parse(input) {
        // Force conversion to string and handle nulls
        let str = String(input || "").toLowerCase().trim();
        if (!str) return { initial: '', final: '', tone: '' };
        
        // 1. Extract Tone (last digit)
        let tone = "";
        const toneMatch = str.match(/\d$/); 
        if (toneMatch) {
            tone = toneMatch[0]; // Keep as string "3"
            str = str.replace(/\d$/, ''); 
        }

        // 2. Extract Initial
        let initial = '';
        for (let i of this.initials) {
            if (str.startsWith(i)) {
                initial = i;
                break;
            }
        }

        // 3. Extract Final
        let final = str.slice(initial.length);

        return { initial, final, tone };
    }
};

async function processAndCompare(audioFile, targetText) {
       const API_URL = "https://audio-to-text-29330024195.europe-west2.run.app/pinyin";
    // docker run -it -p 39999:10000 my_pinyin_service:v1 /bin/bash
    //  const API_URL = "http://localhost:39999/pinyin";

    try {
        const expectedPinyins = pinyinPro.pinyin(targetText, { 
            toneType: 'num', 
            type: 'array' 
        });

        const formData = new FormData();
        formData.append('file', audioFile);

        const response = await fetch(API_URL, { method: "POST", body: formData });
        const data = await response.json();
        const actualPinyins = data.pinyin || data.tokens || []; 

        return targetText.split('').map((char, index) => {
            const exp = expectedPinyins[index] || "";
            const act = actualPinyins[index] || "";
            
            const res1 = PinyinParser.parse(exp);
            const res2 = PinyinParser.parse(act);

            // Log for debugging - check these in your browser console (F12)
            console.log(`Char: ${char} | Target: ${exp} vs User: ${act}`);
            console.log('Parser Results:', { target: res1, user: res2 });

            return {
                char,
                expected: exp,
                actual: act || "--",
                isCorrect: exp === act,
                diff: {
                    // Precise component matching
                    initialMatch: res1.initial === res2.initial,
                    finalMatch: res1.final === res2.final,
                    toneMatch: res1.tone === res2.tone
                }
            };
        });
    } catch (error) {
        console.error("Processing failed:", error);
        throw error;
    }
}