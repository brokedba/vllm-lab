<!-- canvas.md -->
# Nebius + vLLM Production Stack – Architecture Canvas
```mermaid
%%{init: {'theme':'base', 'themeVariables':{ 'primaryColor':'#00ff00', 'primaryTextColor':'#0f0f0f', 'primaryBorderColor':'#00ff00','lineColor':'#007700', 'secondaryColor':'#007700', 'tertiaryColor':'#fff'}}}%%

flowchart TD
    subgraph "Terraform Provision"
        A[terraform plan] --> B[terraform apply]
    end

    subgraph "Nebius Cloud Infrastructure"
        C[VPC + Subnet] --> D[Managed K8s MK8S]
        D --> E[GPU Node-Group<br>L40S / H100<br>auto-scaling 1-8<br>GPU drivers pre-baked]
        D --> F[CPU Node-Group<br>generic workloads]
    end

    subgraph "Helm Releases"
        G[NGINX Ingress Controller<br>LoadBalancer svc] -->|external IP| H[Let's Encrypt ACME<br>HTTP-01 solver]
        I[kube-prometheus-stack<br>Grafana + Prometheus] --> J[GPU & vLLM dashboards]
        L[cert-manager] --> H
    end

    subgraph "vLLM Production Stack"
        M[vLLM Helm Chart] --> N[TinyLlama-1.1B GPU Pod]
        N -->|OpenAI-compatible API| O[https://vllm-api.ip.sslip.io]
        P[Horizontal Pod Autoscaler] --> N
        Q[ServiceMonitor<br>prometheus metrics] --> I
    end

    subgraph "Outputs Terraform"
        H --> R[nginx_ip_hex<br>nip/sslip subdomain]
        I --> S[grafana_admin_password]
        N --> T[vllm_api_key]
    end

    %% flow
    B --> C
    B --> E
    B --> F
    B --> G
    B --> I
    B --> L
    B --> M

    classDef terraform fill:#00ff00,stroke:#007700,color:#000
    classDef helm fill:#00ccff,stroke:#005577,color:#fff
    classDef user fill:#ff9900,stroke:#cc7700,color:#000
    classDef output fill:#ffcc00,stroke:#cc9900,color:#000

    class A,B terraform
    class G,I,L,M helm
    class O,P,Q user
    class R,S,T output
```

### Legend
| Colour | Meaning |
|--------|---------|
| 🟢 green | Terraform provisioned |
| 🔵 blue | Helm installed |
| 🟠 orange | End-user endpoints |
| 🟡 yellow | Terraform outputs |

### Quick Stats
- **Total deployment time**: **~20 min 41 s** (end-to-end)  
- **GPU node ready**: **~10 min** (drivers baked into image)  
- **HTTPS endpoints**: immediate (nip.io) or after rate-limit window (sslip.io)  
- **Region support**: eu-north1, eu-west1, us-central1
