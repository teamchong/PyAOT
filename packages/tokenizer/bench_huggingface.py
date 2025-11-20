import time
from transformers import AutoTokenizer

TEXT = """The cat sat on the mat. The dog ran in the park. The bird flew in the sky. The fish swam in the sea. The snake slithered on the ground. The rabbit hopped in the field. The fox ran through the forest. The bear climbed the tree. The wolf howled at the moon. The deer grazed in the meadow."""

tokenizer = AutoTokenizer.from_pretrained("openai-community/gpt2")

# Warmup
for _ in range(100):
    tokenizer.encode(TEXT)

# Benchmark
iterations = 60000
start = time.time()
for _ in range(iterations):
    tokens = tokenizer.encode(TEXT)
elapsed = time.time() - start

print(f"{int(elapsed * 1000)}ms")
