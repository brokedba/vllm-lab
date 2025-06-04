 !!! note **Install vs Build:** - To generate a wheel for reuse or distribution, use `python -m build` then `pip install dist/*.whl`. - For in-place installs (no-wheel) and dev testing, use `uv pip install . --no-build-isolation`.<br>

## 🔧 Build from source (Intel/AMD x86)
If you're building from source on CPU, here are a few tips that may help avoid common issues:
- NumPy <2.0 conflict.**Fix:** Downgrade it to 1 `pip install "numpy<2.0"`.
- CMake picking up CUDA despite CPU target. **Fix:** add `CMAKE_DISABLE_FIND_PACKAGE_CUDA=ON` with the build command.
- `--extra-index-url` not resolving CPU torch. **Fix:** Use `--index-url` instead durring the requirements/cpu.txt intsall.
- `torch==2.6.0+cpu` not found .   Fix: set `"torch==2.6.0+cpu"` inside [pyproject.toml](https://github.com/vllm-project/vllm/blob/main/pyproject.toml).
- **Modern build method**: replace deprecated `setup.py install` by the [PEP 517-compliant](https://peps.python.org/pep-0517/) `python -m build`.

### 1. Install system dependencies:

```bash
sudo apt-get update -y
sudo apt-get install -y gcc-12 g++-12 libnuma-dev python3-dev
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 10 --slave /usr/bin/g++ g++ /usr/bin/g++-12
```
### 2. Clone vLLM and install Python build requirements:

```bash
git clone https://github.com/vllm-project/vllm.git vllm_source
cd vllm_source

pip install --upgrade pip
pip install "cmake>=3.26.1" wheel packaging ninja "setuptools-scm>=8" numpy
pip install -v -r requirements/cpu.txt --index-url https://download.pytorch.org/whl/cpu
```
### 3. Build and install vLLM:
**Option A:** Build a wheel and PEP-517 mcompliant install (setup.py install is deprecated).There are two options: 
- Using python build package (recommended)   

```bash
# Specify kv cache in GiB
export VLLM_CPU_KVCACHE_SPACE=2
# Check how many cores your machine have with lscpu -e (i.e values : 1,2/0-2/2)
export VLLM_CPU_OMP_THREADS_BIND=0-4 
# Build the wheel
VLLM_TARGET_DEVICE=cpu CMAKE_DISABLE_FIND_PACKAGE_CUDA=ON python -m build --wheel --no-isolation
```
- Using uv (fastest option)
```
VLLM_TARGET_DEVICE=cpu CMAKE_DISABLE_FIND_PACKAGE_CUDA=ON  uv build --wheel

```
Install the wheel (non-editable):
```
uv pip install dist/*.whl
```
 !!! tip "Disable CUDA detection"
`CMAKE_DISABLE_FIND_PACKAGE_CUDA=ON` prevents picking up CUDA during CPU builds, even if it's installed.

**Option B**: Install directly from source

```bash
VLLM_TARGET_DEVICE=cpu CMAKE_DISABLE_FIND_PACKAGE_CUDA=ON uv pip install . --no-build-isolation
```
IF you want an editable version add the `-e` flag 
```bash
VLLM_TARGET_DEVICE=cpu CMAKE_DISABLE_FIND_PACKAGE_CUDA=ON uv pip install -e . --no-build-isolation
```

!!! tip
If you hit an error like: Could not find a version that satisfies the requirement torch==2.6.0+cpu you may also edit [pyproject.toml](https://github.com/vllm-project/vllm/blob/main/pyproject.toml) to help pip resolve the build dependency.
```
[build-system]
requires = [
  "cmake>=3.26.1",
   ....
  "torch==2.6.0+cpu"   <-------
]
```
## 📝 2. PR Description
### Summary

This PR improves the CPU (x86) build documentation by updating [build.inc.md](https://github.com/vllm-project/vllm/blob/main/docs/getting_started/installation/cpu/build.inc.md) with tips and setup steps based on recent troubleshooting while building on Intel CPUs.

### 🛠️ Key Improvements for CPU Build Docs

1. ✅ **Added troubleshooting tips** with fixes for:
   - NumPy 2.0 compatibility
   - Incorrect CMake CUDA detection
   - PyTorch CPU wheel resolution
   - Deprecated setup.py install guidance, replaced with PE-517 methods
  
2. ✅ **Expanded install/build instructions**
   - Includes both `python -m build` and `uv build` options for generating a wheel
   - Avoid CUDA detection explicitly during CPU builds using `CMAKE_DISABLE_FIND_PACKAGE_CUDA=ON`

4. ✅ **Fixed a broken include path** in  [x86.inc.md](https://github.com/vllm-project/vllm/blob/main/docs/getting_started/installation/cpu/x86.inc.md):
   - Changed:
     ```markdown
     --8<-- "docs/getting_started/installation/cpu/cpu/build.inc.md"  <-- duplicate cpu
     ```
     To:
     ```markdown
     --8<-- "docs/getting_started/installation/cpu/build.inc.md:build-wheel-from-source"
     ```
  5. ✅ Fixed missing  `--8<-- [start:...]` marker in [build.inc.md](https://github.com/vllm-project/vllm/blob/main/docs/getting_started/installation/cpu/build.inc.md)  to support valid include block referencing from `x86.inc.md`.
     -  Added in build.inc.md:
        ```
        --8<-- [start:build-wheel-from-source]
        ## block content 
        --8<-- [end:build-wheel-from-source]
        ```
     - Removed `--8<-- [end:extra-information]` from build.inc.md
 

Thanks again @simon-mo for the nudge to contribute this upstream! 😊


## 🔁 3. Fork → Modify → PR Workflow
**1. Fork the repo:** 
Go to: https://github.com/vllm-project/vllm → click **Fork**

**2. Clone your fork:**
```bash
git config --global user.email "xxxx@gmail.com"
#check 
git config --global user.email  | or git log -1
# clone
git clone https://github.com/your-username/vllm.git
cd vllm
```
**3 Create a new branch:**
- **Add upstream and sync**
```bash
git remote add upstream https://github.com/vllm-project/vllm.git
git fetch upstream
git checkout main
git merge upstream/main
```
create a brench
```bash
git checkout -b improve-cpu-doc
```
**4. Make your edits:**
- Update docs/getting_started/installation/cpu/build.inc.md
- Fix the import in docs/getting_started/installation/cpu/x86.inc.md

**4.2. Preview MkDocs Locally** (optional but recommended)
- Install MkDocs + required plugins
  ```bash
  pip install mkdocs mkdocs-material mkdocs-include-markdown-plugin
  OR
  pipx install mkdocs mkdocs-material mkdocs-include-markdown-plugin
  ```
- Preview the site
  From the root of the repo:
  ```bash
  mkdocs serve
  ```
- Then open: http://127.0.0.1:8000
  - Navigate to: `Getting Started` → `Installation` → `CPU` → `Intel/AMD x86`
**5. Commit and push:**
```bash
git add docs/getting_started/installation/cpu/*
git commit -s -m "docs(cpu): improve CPU(x86) build instructions and fix include path" 
git push origin improve-cpu-doc
```
**6. Open PR:**
- Go to your GitHub fork and click "**Compare & pull request**"  
- Set title (e.g. docs(cpu): improve x86 build instructions)
-  → Paste the PR message above.
-  Submit!

Optional: preview the MkDocs render before submitting.
