import pytest
import tvm
from tvm.script import ir as I
from tvm.script import tir as T
from mlc_llm import MLCEngine

# --- TVM Tests ---

@I.ir_module
class MyModule:
    @T.prim_func
    def main():
        T.evaluate(0)

def test_tvm_compilation():
    """Verify that TVM can compile and run a minimal TIR module."""
    try:
        # Build for CPU
        executable = tvm.build(MyModule, target="llvm")
        # Execute the main function
        executable["main"]()
        assert True
    except Exception as e:
        pytest.fail(f"TVM Compilation/Runtime failed: {e}")

def test_tvm_library_path():
    """Verify the TVM library is correctly linked."""
    lib_path = tvm.base._LIB
    assert lib_path is not None
    assert "libtvm" in str(lib_path).lower()

# --- MLC LLM Tests ---

@pytest.fixture(scope="module")
def engine():
    """Fixture to initialize the MLCEngine once for all tests in this module."""
    model = "HF://mlc-ai/SmolLM2-135M-Instruct-q4f16_1-MLC"
    # Using a tiny model to keep test time low
    return MLCEngine(model=model)

def test_mlc_inference(engine):
    """Verify that MLC LLM can perform basic text completion."""
    response = engine.chat.completions.create(
        messages=[{"role": "user", "content": "Hi!"}],
        max_tokens=5
    )

    # Check that we got a valid response
    content = response.choices[0].message.content
    assert len(content) > 0
    assert isinstance(content, str)

#def test_mlc_backend_support():
#    """Verify at least one hardware backend is accessible via TVM."""
#    backends = ["llvm", "cuda", "metal", "vulkan"]
#    support = [tvm.device(b).exist for b in backends]
#    assert any(support), f"No hardware backend found. Support status: {dict(zip(backends, support))}"
