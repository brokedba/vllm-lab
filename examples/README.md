# 🦙 Running vLLM Locally with OpenAI-Compatible API

>[!TIP]
>This guide shows how to run a small LLM like [TinyLlama](https://huggingface.co/TinyLlama/TinyLlama-1.1B-Chat-v1.0) using [vLLM](https://github.com/vllm-project/vllm) on CPU and interact with it using OpenAI-style Python clients.
>
---

## 1. Start the vLLM Server (CPU mode)

Make sure you’re using a lightweight model and the server will auto-fallback to CPU-safe "V0 engine":

```bash
python -m vllm.entrypoints.openai.api_server \
  --model=TinyLlama/TinyLlama-1.1B-Chat-v1.0 \
  --dtype bfloat16
```
- Default port: http://localhost:8000
- Default endpoint: /v1
- No token needed for public models like TinyLlama.

## 2. Check Backend (Direct vLLM Python API)
- See file [check_backend.py](./examples/check_backend.py)
```python
python check_backend.py
--- Answer
<class 'vllm.model_executor.models.llama.LlamaForCausalLM'>
```

## 3. Completion Endpoint (OpenAI-style)
- See file [open_ai_vllm_completion.py](./examples/open_ai_vllm_completion.py)
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
- See file [open_ai_vllm_completion.py](./examples/open_ai_vllm_chat.py)
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
