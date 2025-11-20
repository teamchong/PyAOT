import { encode } from 'gpt-tokenizer';

window.benchGPTTokenizer = function(text, iterations) {
    // Warmup
    for (let i = 0; i < 100; i++) encode(text);

    // Benchmark
    const start = performance.now();
    for (let i = 0; i < iterations; i++) {
        encode(text);
    }
    return performance.now() - start;
};

window.testGPTTokenizer = function(text) {
    return encode(text).length;
};
