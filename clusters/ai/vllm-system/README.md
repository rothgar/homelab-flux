# vLLM Deployment

vLLM is a high-throughput and memory-efficient inference engine for LLMs.

## Configuration

- **Image**: vllm/vllm-openai:latest
- **Default Model**: facebook/opt-125m (small test model)
- **GPU**: Requires 1 NVIDIA GPU
- **RuntimeClass**: nvidia
- **Memory**: 32-64Gi (optimized for 128GB node)
- **CPU**: 4-8 cores
- **Shared Memory**: 16Gi (for efficient tensor operations)
- **Storage**:
  - 50Gi PVC for cache (Longhorn)
  - 200Gi PVC for models (Longhorn) - models persist across restarts

## Changing the Model

To use a different model, edit `deployment.yaml` and change the `--model` argument:

```yaml
args:
- --model
- meta-llama/Llama-2-7b-chat-hf  # Example: Llama 2 7B
- --host
- "0.0.0.0"
- --port
- "8000"
```

### Popular Models

- **Llama 2 7B**: `meta-llama/Llama-2-7b-chat-hf`
- **Mistral 7B**: `mistralai/Mistral-7B-Instruct-v0.2`
- **Phi-3**: `microsoft/Phi-3-mini-4k-instruct`
- **Qwen**: `Qwen/Qwen2.5-7B-Instruct`

For private models, add your Hugging Face token to the `HUGGING_FACE_HUB_TOKEN` environment variable.

## Accessing vLLM

The service is exposed as a LoadBalancer. Get the IP with:

```bash
kubectl get svc -n vllm-system vllm
```

Access via NodePort (if LoadBalancer not working):
```bash
kubectl get svc -n vllm-system vllm -o jsonpath='{.spec.ports[0].nodePort}'
# Then access at http://10.1.1.14:<nodeport>
```

## OpenAI-Compatible API

vLLM provides an OpenAI-compatible API endpoint:

```bash
# List models
curl http://<service-ip>:8000/v1/models

# Generate completion
curl http://<service-ip>:8000/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "facebook/opt-125m",
    "prompt": "San Francisco is a",
    "max_tokens": 50
  }'

# Chat completion
curl http://<service-ip>:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "facebook/opt-125m",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

## Model Storage

Models are downloaded to `/models` on the persistent volume and cached between restarts. The first run will download the model, subsequent runs will use the cached version.

You can also pre-download models by exec'ing into the pod:

```bash
kubectl exec -n vllm-system -it deployment/vllm -- bash
# Inside the pod:
huggingface-cli download meta-llama/Llama-2-7b-chat-hf --local-dir /models/llama-2-7b
```

## Resource Requirements

Current configuration is optimized for the 128GB node:

- **Memory Request**: 32Gi
- **Memory Limit**: 64Gi
- **CPU Request**: 4 cores
- **CPU Limit**: 8 cores
- **Shared Memory**: 16Gi
- **GPU Memory Utilization**: 95%

Adjust based on your model size:

- **Small models (125M-1B)**: Current settings work well
- **Medium models (7B-13B)**: Current settings optimal
- **Large models (30B-70B)**: May need to increase memory limits or reduce `--gpu-memory-utilization`
- **Very large models (70B+)**: Consider tensor parallelism with multiple GPUs

## Monitoring

Check pod status:
```bash
kubectl get pods -n vllm-system
kubectl logs -n vllm-system -l app=vllm -f
```

## Troubleshooting

If the pod fails to start:
1. Check GPU is available: `kubectl describe node spark | grep nvidia.com/gpu`
2. Check NVIDIA device plugin is running: `kubectl get pods -n nvidia-system`
3. Check logs: `kubectl logs -n vllm-system -l app=vllm`
4. Verify RuntimeClass exists: `kubectl get runtimeclass nvidia`
