// Skip tiktoken - use tiktoken.js CDN instead
const script = document.createElement('script');
script.src = 'https://cdn.jsdelivr.net/npm/tiktoken@1.0.17/dist/tiktoken.umd.js';
script.onload = () => {
    const encoder = tiktoken.get_encoding('cl100k_base');
    
    window.benchTiktoken = function(text, iterations) {
        for (let i = 0; i < 100; i++) encoder.encode(text);
        const start = performance.now();
        for (let i = 0; i < iterations; i++) {
            encoder.encode(text);
        }
        return performance.now() - start;
    };
    
    window.testTiktoken = function(text) {
        return encoder.encode(text).length;
    };
};
document.head.appendChild(script);
