# homelab-flux
flux configuration for my home lab

## Repository Structure

This repository contains Flux configurations for managing Kubernetes clusters using GitOps.

```
clusters/
└── ai/                    # AI cluster configuration
    ├── flux-system/       # Flux core components
    ├── namespaces/        # Namespace definitions
    └── README.md          # Cluster-specific documentation
```

## Clusters

### AI Cluster
- **Path**: `clusters/ai`
- **Namespaces**: monitoring, longhorn-system

See [clusters/ai/README.md](clusters/ai/README.md) for more details.

## Getting Started

To bootstrap a cluster with Flux:

```bash
flux bootstrap github \
  --owner=rothgar \
  --repository=homelab-flux \
  --path=clusters/<cluster-name> \
  --personal
```

## Prerequisites

- kubectl configured for your cluster
- flux CLI installed ([installation guide](https://fluxcd.io/flux/installation/))
