from vllm import LLM
llm = LLM(model="TinyLlama/TinyLlama-1.1B-Chat-v1.0", task="generate")  # Name or path of your model
llm.apply_model(lambda model: print(model.__class__))
