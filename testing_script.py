#!/usr/bin/env python3

import tvm
import mlc_llm

from tvm.script import ir as I
from tvm.script import tir as T

# 1. Define a minimal working module
@I.ir_module
class MyModule:
    @T.prim_func
    def main():
        T.evaluate(0)

# 2. Build and Execute
try:
    executable = tvm.build(MyModule, target="llvm")
    executable["main"]()
    print("✓ TVM Runtime: Functional")

    # 3. Modern way to check the linked library path in 2025
    print(f"✓ TVM Library: {tvm.base._LIB}")

except Exception as e:
    print(f"✗ Test Failed: {e}")

print("\n")

from mlc_llm import MLCEngine

# Use a tiny model for rapid testing (approx 300MB download vs 5GB+)
# q4f16_1 is optimized for speed and low memory
MODEL = "HF://mlc-ai/SmolLM2-135M-Instruct-q4f16_1-MLC"

def quick_test():
    print(f"Loading {MODEL}...")
    engine = MLCEngine(model=MODEL)

    # Run a short prompt to verify completion
    response = engine.chat.completions.create(
        messages=[{"role": "user", "content": "Hi!"}],
        max_tokens=10
    )

    print("Response:", response.choices[0].message.content)
    print("✓ Quick Test Passed")

if __name__ == "__main__":
    quick_test()
