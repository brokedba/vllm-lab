# 🦙 Running vLLM Locally with OpenAI-Compatible API

>[!TIP]
>This guide shows how to run a small LLM like [TinyLlama](https://huggingface.co/TinyLlama/TinyLlama-1.1B-Chat-v1.0) using [vLLM](https://github.com/vllm-project/vllm) on CPU and interact with it using OpenAI-style Python clients.
>
---

## 1. Start the vLLM Server (CPU mode)

Make sure you’re using a lightweight model and the server will auto-fallback to CPU-safe "V0 engine":

```bash
## Serve Using CLI
vllm server TinyLlama/TinyLlama-1.1B-Chat-v1.0 --device cpu --dtype bfloat16
### Using python 
python -m vllm.entrypoints.openai.api_server \
  --model=TinyLlama/TinyLlama-1.1B-Chat-v1.0 \
  --dtype bfloat16
```
- Default port: http://localhost:8000
- Default endpoint: /v1
- No token needed for public models like TinyLlama.

## 2. Offline inference : Check Backend (Direct vLLM Python API)
- See file [check_backend.py](./check_backend.py)
```python
python check_backend.py
--- Answer
<class 'vllm.model_executor.models.llama.LlamaForCausalLM'>
```

## 3. Completion Endpoint (OpenAI-style)
- See file [open_ai_vllm_completion.py](./open_ai_vllm_completion.py)
```nginx
python open_ai_vllm_completion.py
```
Answer
```nginx
Completion(id='cmpl-99f2688873b643d9a9c7a170778d82bc', 
choices=[CompletionChoice(finish_reason='length', index=0, logprobs=None, 
text=' big city with a metropolitan population of over a million people. Our drinking', 
stop_reason=None, prompt_logprobs=None)], created=1748768446, model='TinyLlama/TinyLlama-1.1B-Chat-v1.0', 
object='text_completion', system_fingerprint=None, usage=CompletionUsage(completion_tokens=16, 
prompt_tokens=4, total_tokens=20, completion_tokens_details=None, prompt_tokens_details=None))
```
## 4. Chat Completion (OpenAI-style)
- See file [open_ai_vllm_completion.py](./open_ai_vllm_chat.py)
```nginx
python open_ai_vllm_chat.py
```
Answer
```nginx
Chat response: ChatCompletion(id='chatcmpl-ff3e2358b4014b7ca4e45b901803c032', choices=[Choice(finish_reason='stop', index=0, logprobs=None, 
message=ChatCompletionMessage(content="Sure thing! Here's a funny joke:\n\nQ: What do you call a bird stuck in a tree?\n\nA: A hen with a thousand eggs.", 
refusal=None, role='assistant', annotations=None, audio=None, function_call=None, tool_calls=[], reasoning_content=None), stop_reason=None)], 
created=1748769021, model='TinyLlama/TinyLlama-1.1B-Chat-v1.0', object='chat.completion', service_tier=None, system_fingerprint=None, 
usage=CompletionUsage(completion_tokens=40, pr
```
---
## Codespace
1. click on Code button select "Create codespace on main"
2. clone vllm repository
```nginx
cd vllm-lab
# clone vllm repo
git clone --branch v0.8.5 https://github.com/vllm-project/vllm.git vllm_source
cd vllm_source
3. build the docker image from cpu dockerfile
```
docker build -f docker/Dockerfile.cpu -t vllm-cpu-env --target vllm-openai .
```
4. Download the llama3 model locally after accepting terms of use from Hugging face's meta registry

```
 pip install huggingface-hub
huggingface-cli login
huggingface-cli download meta-llama/Llama-3.2-1B-Instruct --local-dir ./llama3
```   
5.Run Docker and mount it:
```nginx
docker run -d \
  --privileged=true \
  --shm-size=4g \
  -p 8000:8000 \
  -v "$(pwd)/llama3:/models/llama3" \
  -e VLLM_CPU_KVCACHE_SPACE=2 \
  -e VLLM_CPU_OMP_THREADS_BIND=0,1 \
  vllm-cpu-env \
  --model=/models/llama3 \
  --dtype=bfloat16 \
  --max-model-len=2048
```

