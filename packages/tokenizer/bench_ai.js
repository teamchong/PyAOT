import { Tokenizer, models } from 'ai-tokenizer';

try {
    const tokenizer = new Tokenizer(models['openai/gpt-4o']);

    window.benchAITokenizer = function(text, iterations) {
        // Warmup
        for (let i = 0; i < 100; i++) tokenizer.encode(text);

        // Benchmark
        const start = performance.now();
        for (let i = 0; i < iterations; i++) {
            tokenizer.encode(text);
        }
        return performance.now() - start;
    };

    window.testAITokenizer = function(text) {
        return tokenizer.encode(text).length;
    };

    console.log('ai-tokenizer loaded successfully');
} catch (e) {
    console.error('ai-tokenizer error:', e);
    window.aiTokenizerError = e.message;
}
