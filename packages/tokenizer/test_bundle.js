import './dist/gpt.bundle.js';

const TEXT = "Hello world";
const time = window.benchGPTTokenizer(TEXT, 100);
console.log('gpt-tokenizer: ' + time + 'ms');
console.log('tokens: ' + window.testGPTTokenizer(TEXT));
