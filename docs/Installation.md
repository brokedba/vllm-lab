

## VLLM INSTALLATION
> This section is related to Ubuntu 22.4 LTS only (WSL optionally).
<p align="justified"> <img src= "https://github.com/user-attachments/assets/c127c962-bd81-4de8-aff8-f46869639f7d" width="720" height="400" /> </p> 

## Table of Contents

* [VLLM INSTALLATION](#vllm-installation)
    * [Requirements](#requirements)
* [I. PREPARATION](#i-preparation)
    * [1. Install Nvidia Drivers](#1-install-nvidia-drivers)
    * [2. Download NVIDIA CUDA toolkit](#2-download-nvidia-cuda-toolkit)
    * [3. Create the Environment](#3-create-the-environment)
* [II. INSTALL VLLM](#ii-install-vllm)
    * [1. Install On GPU (NVIDIA)](#1-install-on-gpu-nvidia)
        * [A. Using python](#A-using-python-vLLM-package)  
        * [B. Build wheel from source](#B-build-wheel-from-source)
    * [2. Install On CPU](#3-install-on-cpu)
        * [A. Build CPU wheel from source](#A-build-cpu-wheel-from-source)
        * [B. Set up using Docker](#B-set-up-using-docker)
        * [C. Set up using k8s](#C-Set-up-using-k8s)
* [III INTERACTING WITH THE LLM](#iii-interacting-with-the-llm)
### Requirements

- WSL version 2
- Python: 3.8–3.12
- GPU ABOVE GTX1080
---
## I. PREPARATION
### 1. Install Nvidia Drivers
First, install the appropriate NVIDIA drivers for your GPU:
```nginx
# Check if NVIDIA drivers are already installed  nvidia-smi If not, install NVIDIA drivers (Ubuntu/Debian)  
sudo apt update  sudo apt install nvidia-driver-535  

# Reboot after driver installation  
sudo reboot
```
### 2. Download NVIDIA CUDA toolkit
<details>
  <summary>TIP</summary>

> [!TIP]
> 
> The CUDA Toolkit can be installed using either of two different installation types:
> 1. Distribution-specific packages (RPM, Deb pkgs)
> 2. Runfile packages
>
> The NVIDIA CUDA Toolkit is available at https://developer.nvidia.com/cuda-downloads.

</details>

**Visit  [Nvidia's official Cuda toolkit](https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&Distribution=WSL-Ubuntu&target_version=2.0&target_type=deb_network) website** 
to download and install the Nvidia drivers for WSL. 

⏹️Choose Linux > x86_64 > WSL-Ubuntu > 2.0 > deb (network). 

A. Using Distribution-specific packages:
```nginx
wget https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt-get update
sudo apt-get -y install cuda-toolkit-12-9
````
- Unininstall cuda in case of conflicts
```bash
# Remove CUDA packages
sudo apt-get remove --purge 'cuda*' 'nvidia*'

# Remove the keyring
sudo apt-get remove --purge cuda-keyring

# Clean up residual files
sudo apt-get autoremove -y
sudo apt-get autoclean

# Check for leftovers (optional)
dpkg -l | grep cuda

```
<details>
<summary>B. Using Runfile:</summary>

```nginx
wget https://developer.download.nvidia.com/compute/cuda/12.9.0/local_installers/cuda_12.9.0_575.51.03_linux.run
sudo sh cuda_12.9.0_575.51.03_linux.run
```
</details>

Add cuda environment variables
```nginx
# Set environment variables. Add the following lines to your .bashrc:
vi ~/.bashrc
export CUDA_HOME=/usr/local/cuda-12-9  
export PATH="/usr/local/cuda-12.9/bin:$PATH"
export LD_LIBRARY_PATH="/usr/local/cuda-12.9/lib64:$LD_LIBRARY_PATH" 
```
**Verify the installation**

Reload your configuration and check that all is working as expected

```nginx
source ~/.bashrc
$ nvcc --version
nvcc: NVIDIA (R) Cuda compiler driver
Copyright (c) 2005-2025 NVIDIA Corporation
Built on Wed_Apr__9_19:24:57_PDT_2025
Cuda compilation tools, release 12.9, V12.9.4$1
Build cuda_12.9.r12.9/compiler.35813241_0
```
Check nvidia-smi
```nginx
$ nvidia-smi.exe
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 576.02                 Driver Version: 576.02         CUDA Version: 12.9     |
|-----------------------------------------+------------------------+----------------------+
| GPU  Name                  Driver-Model | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA GeForce GTX 1650      WDDM  |   00000000:01:00.0 Off |                  N/A |
| N/A   56C    P8              2W /   50W |       0MiB /   4096MiB |      0%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+
+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI              PID   Type   Process name                        GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|  No running processes found                                                             |
+-----------------------------------------------------------------------------------------+
```

### 3. Create the Environment
Using UV
```bash
# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

####
mkdir -p ~/ai/vllm
cd ~/ai/vllm
uv venv --python 3.12 --seed

# Activate with:
 source .venv/bin/activate
```
<details>
<summary>Using Conda</summary>

  ```bash
mkdir -p ~/miniconda3
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
rm ~/miniconda3/miniconda.sh

# Activate with:
source ~/miniconda3/bin/activate

# Update the python version with your own
conda create -n myenv python=3.12 -y
```
</details>

---

## II. INSTALL VLLM
There are different ways and parameters to install vLLM . We will explore few of them that might fit your use case.
### 1. Install On GPU (NVIDIA)
#### A. Using Python vLLM package
Install vLLM along with its necessary dependencies:
1. Using pip.
```nginx
# Install vLLM with CUDA 12.8.
pip install vllm --extra-index-url https://download.pytorch.org/whl/cu128
# OR
pip install torch==X.Y.Z+cu128 -f https://download.pytorch.org/whl/torch_stable.html
# latest pre-released version
pip install vllm --pre --extra-index-url https://wheels.vllm.ai/nightly
# stable version , -U means upgrade if exists
pip install -U vllm==0.8.5 
```
> `--pre` is required for pip to consider pre-released versions.
2. Using uv which automatically chooses the right cuda version based on the current driver
```nginx
uv pip install vllm --torch-backend=auto
# last version with specific cuda
uv pip install vllm --torch-backend=cu126 --extra-index-url https://wheels.vllm.ai/nightly
# stable version
uv pip install vllm==0.8.5 
```
  > `--torch-backend=auto` ensures automatic GPU support
3. Use full commit hash from the main branch for dev versions
```nginx
export VLLM_COMMIT=72d9c316d3f6ede485146fe5aabd4e61dbc59069
uv pip install vllm --extra-index-url https://wheels.vllm.ai/${VLLM_COMMIT}
```
<details>
<summary>pip difference</summary>

   In uv, packages in `--extra-index-url` have higher priority than the default index, to install dev pre-release versions.
In contrast, pip combines packages from `--extra-index-url` and the default index, choosing only the latest version.

Therefore, for pip users, it requires specifying a placeholder wheel name to install a specific commit:

```bash
# use full commit hash from the main branch
export VLLM_COMMIT=33f460b17a54acb3b6cc0b03f4a17876cff5eafd
pip install https://wheels.vllm.ai/${VLLM_COMMIT}/vllm-1.0.0.dev-cp38-abi3-manylinux1_x86_64.whl
```
>  example url:
> https://wheels.vllm.ai/33f460b17a54acb3b6cc0b03f4a17876cff5eafd/vllm-1.0.0.dev-cp38-abi3-manylinux1_x86_64.whl
</details>

> [!TIP]
> **vLLM** uses **PyTorch** as an Interface directly speaking to your GPU (chip) va optimized kernels, leveraging powerful features like torch.compile, to enable LLM computations.

  #### B. Build wheel from source
A. Set up using Python-only build (without compilation)
```nginx
git clone --branch v0.8.5 https://github.com/vllm-project/vllm.git
cd vllm
VLLM_USE_PRECOMPILED=1 pip install --editable .
```
> this downloads the pre-built wheel of the base commit + Use its compiled libraries in the installation.
>  Using pip's `--editable` flag, changes you make to the code will be reflected when you run vLLM

B. Set up using Full build (with compilation)
```nginx
git clone --branch v0.8.5 https://github.com/vllm-project/vllm.git
cd vllm
export MAX_JOBS=6
pip install -e .
```
> When you want to modify C++ or CUDA code. This can take several minutes. 
## 3. Install On CPU
 
**vLLM CPU backend supports the following vLLM features**:
- Tensor Parallel
- Model Quantization (INT8 W8A8, AWQ, GPTQ)
- Chunked-prefill
- Prefix-caching
- FP8-E5M2 KV cache
### A. Build CPU wheel from source
>[!tip]
>    **Install vs Build:**
>    - To generate a wheel for reuse or distribution, use `python -m build` then `pip install dist/*.whl`.
>    - For in-place installs (no-wheel) and dev testing, use `uv pip install . --no-build-isolation`.

**Prerequisite**
  - OS: Linux
  - Compiler: gcc/g++ >= 12.3.0 (optional, recommended)
  - Instruction Set Architecture (ISA): AVX512 (optional, recommended)
    > AMD: You need 4th gen processors (Zen 4, 9000x series) or higher to support full AVX512 insutruction set to run vLLM inference (otherwise exit 132).
    > 3rd Generation AMD EPYC processors (Milan) "do not support AVX-512 instructions."  

>[!note]
> Here are a few tips to avoid common issues:
>    - **NumPy ≥2.0 error**: Downgrade using `pip install "numpy<2.0"`.
>    - **CMake picks up CUDA**: Add `CMAKE_DISABLE_FIND_PACKAGE_CUDA=ON` to prevent CUDA detection.
>    - **Torch CPU wheel not resolving**: Use `--index-url` during the `requirements/cpu.txt` install.
>    - **`torch==X.Y.Z+cpu` not found**: Set `"torch==X.Y.Z+cpu"` in [`pyproject.toml`](https://github.com/vllm-project/vllm/blob/main/pyproject.toml).
>    - **Deprecated `setup.py install`**: Use the [PEP 517-compliant](https://peps.python.org/pep-0517/) `python -m build` instead.


To install vLLM on CPU, you must build it from source as there are no pre-built CPU wheels ([set-up-using-python](https://docs.vllm.ai/en/latest/getting_started/installation/cpu.html#set-up-using-python), [build.inc](https://github.com/vllm-project/vllm/blob/main/docs/getting_started/installation/cpu/build.inc.md)).

**Steps:**
1. Install dependencies
```bash
sudo apt-get update  -y
sudo apt-get install -y gcc-12 g++-12 libnuma-dev python3-dev
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 10 --slave /usr/bin/g++ g++ /usr/bin/g++-12
```
2. Clone the vLLM repo
```nginx
git clone --branch v0.8.5 https://github.com/vllm-project/vllm.git vllm_source
cd vllm_source
```
3. Install required Python packages
```
pip install --upgrade pip
pip install "cmake>=3.26" wheel packaging ninja "setuptools-scm>=8" numpy
pip install -v -r requirements/cpu.txt --extra-index-url https://download.pytorch.org/whl/cpu
```
4. Build and install vLLM:

    **Option A:** Build a wheel
   
You can do this using one of the following methods: 

- Using python `build` package (recommended)   
```console
# Specify kv cache in GiB
export VLLM_CPU_KVCACHE_SPACE=2
# Example: to bind to the first 4 CPU cores, use '0-3'. Check available cores using: lscpu -e
export VLLM_CPU_OMP_THREADS_BIND=0-4 
# Build the wheel
VLLM_TARGET_DEVICE=cpu CMAKE_DISABLE_FIND_PACKAGE_CUDA=ON python -m build --wheel --no-isolation
```
- Using `uv` (fastest option)
```
VLLM_TARGET_DEVICE=cpu CMAKE_DISABLE_FIND_PACKAGE_CUDA=ON  uv build --wheel

```
Install the wheel (non-editable)
```
uv pip install dist/*.whl
```
**Option B:** Install directly from source

- Standard install:
```console
VLLM_TARGET_DEVICE=cpu CMAKE_DISABLE_FIND_PACKAGE_CUDA=ON uv pip install . --no-build-isolation
```
- Editable install (with `-e` flag): 
```console
VLLM_TARGET_DEVICE=cpu CMAKE_DISABLE_FIND_PACKAGE_CUDA=ON uv pip install -e . --no-build-isolation
```


5. **Serve the model**
```bash
vllm serve TinyLlama/TinyLlama-1.1B-Chat-v1.0 --device cpu --dtype bfloat16
vllm serve Qwen/Qwen2.5-Coder-1.5B-Instruct --device cpu
# optional  
vllm serve NousResearch/Meta-Llama-3-8B-Instruct --dtype auto --device cpu --api-key token-abc123
```
<details> 
<summary>If you want to develop vllm, install it in editable mode instead.</summary>  
 
 ```bash
 VLLM_TARGET_DEVICE=cpu python setup.py develop
```
</details>

### B. Set up using Docker
1. Pre-built images for CPU can be found here
   https://gallery.ecr.aws/q9t5s3a7/vllm-cpu-release-repo
```nginx
 docker pull public.ecr.aws/q9t5s3a7/vllm-cpu-release-repo:v0.8.5.post1
# Run the container
docker run --rm \
--privileged=true \
--shm-size=2g \
-p 8000:8000 \
-e VLLM_CPU_KVCACHE_SPACE=1 \
-e VLLM_CPU_OMP_THREADS_BIND=0-1 \
public.ecr.aws/q9t5s3a7/vllm-cpu-release-repo:v0.8.5.post1 \
--model TinyLlama/TinyLlama-1.1B-Chat-v1.0 \
--dtype bfloat16

Index:
VLLM_CPU_KVCACHE_SPACE=2   ==> allocates 2GB for KV cache on CPU
VLLM_CPU_OMP_THREADS_BIND=0-1 ==> binds to 2 CPU cores for inference
```

2. Build image from source
```nginx
git clone --branch v0.8.5 https://github.com/vllm-project/vllm.git vllm_source
cd vllm_source
$ docker build -f docker/Dockerfile.cpu -t vllm-cpu-env --target vllm-openai  .
# download the model 
huggingface-cli login
huggingface-cli  download meta-llama/Llama-3.2-1B-Instruct --local-dir ./llama3

# Launching OpenAI server 
$ docker run --rm \
             --privileged=true \
             --shm-size=4g \
             -p 8000:8000 \
             -v "$(pwd)/llama3:/models/llama3" \
             -e VLLM_CPU_KVCACHE_SPACE=<KV cache space> \
             -e VLLM_CPU_OMP_THREADS_BIND=<CPU cores for inference> \
             vllm-cpu-env \
             --model=/models/llama3  \
             --dtype=bfloat16 \

# You can either use the ipc=host flag or --shm-size flag to allow the container to access the host's shared memory.        
```
> This can take a long time. We recommend the pre-built-images from [Amazone public registry (ECR) ](https://gallery.ecr.aws/q9t5s3a7/vllm-cpu-release-repo)

 Example with Hugging Face token
```nginx
docker run --rm \
  --privileged=true \
  --shm-size=4g \
  -p 8000:8000 \
  -e HUGGING_FACE_HUB_TOKEN=your_actual_token \
  -e VLLM_CPU_KVCACHE_SPACE=1Gi \
  -e VLLM_CPU_OMP_THREADS_BIND=2 \
  vllm-cpu-env \
  --model=meta-llama/Llama-3.2-1B-Instruct \
  --dtype=bfloat16
  --shm-size=2g
 ## --api-key supersecretkey  (require a key from clients to access the model) 
 
```
> To avoid needing [HF credentials ](https://huggingface.co/settings/tokens.) use the following models: TinyLlama/TinyLlama-1.1B-Chat-v1.0 , mistralai/Mistral-7B-Instruct-v0.1, TheBloke/OpenHermes-2.5-Mistral-GGUF

### C. Set up using k8s
- [Oracle Cloud](https://github.com/brokedba/vllm-lab/tree/main/examples/k8s/civo)
- [Civo Cloud](https://github.com/brokedba/vllm-lab/tree/main/examples/k8s/oci)

---

## III Interacting With The LLM
### A. Docker
After running the vllm cpu image on docker we can Interact with the endpoint on port 8000 
```python
from openai import OpenAI
openai_api_key = "EMPTY"
openai_api_base = "http://localhost:8000/v1"
client = OpenAI(
    api_key=openai_api_key,   <--- key is empty if not specified in the docker launch
    base_url=openai_api_base,
)
models = client.models.list()
model = models.data[0].id
completion = client.chat.completions.create(
    model="TinyLlama/TinyLlama-1.1B-Chat-v1.0",
    messages=[
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": Who won the wolrd cup in 2022 ?"},
    ]
)
print(completion.choices[0].message.content)
```
## Python
- Start the Open AI compatible API server 
```bash
vllm serve  TinyLlama/TinyLlama-1.1B-Chat-v1.0 --dtype float16
```
- **1. Test the endpoint**
```nginx
  curl http://localhost:8000/v1/models | jq .data[].id
 "TinyLlama/TinyLlama-1.1B-Chat-v1.0"
```
- **2. Test the completion**
```
 curl http://localhost:8000/v1/completions \
    -H "Content-Type: application/json" \
    -d '{
        "model": "TinyLlama/TinyLlama-1.1B-Chat-v1.0",
        "prompt": "San Francisco is a",
        "max_tokens": 10,
        "temperature": 0
    }' | jq .choices[].text
``` 
- **Response**
```
" great place to start. The city is home to"
```
- **3. Test the chat completion**
```
curl http://localhost:8000/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d '{
        "model": "TinyLlama/TinyLlama-1.1B-Chat-v1.0",
        "messages": [
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": "Who won the world cup in 2022 ?"}
        ]
    }' | jq .choices[].content 
``` 
- **Response**
```
"The correct answer is: Argentina won the 2022 world cup."
```

## 🛠️ Troubleshooting
1. When creating a CPU build and receive an error such as: `Could not find a version that satisfies the requirement torch==X.Y.Z+cpu+cpu`, consider updating [pyproject.toml](https://github.com/vllm-project/vllm/blob/main/pyproject.toml) to help pip resolve the dependency.

    ```toml title="pyproject.toml"
    [build-system]
    requires = [
      "cmake>=3.26.1",
      ...
      "torch==X.Y.Z+cpu"   # <-------
    ]
    ```


2. When runing a python module OpenAI endpoint and you're on CPU. 
```nginx
python -m vllm.entrypoints.openai.api_server --model=TinyLlama/TinyLlama-1.1B-Chat-v1.0  --dtype bfloat16
```
You might see errors like:
```nginx
AttributeError: '_OpNamespace' '_C_utils' object has no attribute 'init_cpu_threads_env'
```
**Solution:**
You may need to patch/remove/comment this line in [`vllm/worker/cpu_worker.py`](https://github.com/vllm-project/vllm/blob/main/vllm/worker/cpu_worker.py):
```
# ... snip
## comment torch.ops._C_utils.init_cpu_threads_env(...)
# ... snip
```
<details>
 <summary>Explanation</summary>

> [!NOTE]
> 
> **Root cause**:
> 
> **vllm.serve()** and **LLM(model, task=...)** use different execution paths than **python -m vllm.entrypoints.openai.api_server**. 
>- The later uses the multiprocessing-based VLLM engine and tries to optimize CPU threading.
>   - That engine explicitly calls torch.ops._C_utils.init_cpu_threads_env, which:
>     - Exists only in some CPU builds of PyTorch (like nightly or compiled with MKL).
>     - Does not exist in the basic +cpu wheels from PyPI.
>
V0 fallback still crashes if your PyTorch doesn’t have `torch.ops._C_utils.init_cpu_threads_env`, which is the actual root problem.
><p align="justified"> <img src= "https://github.com/user-attachments/assets/e7143928-4de4-4e7f-8ec9-a0499ea11a0f" width="620" height="100" /> </p>  
</details>
