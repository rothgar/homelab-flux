# AI Cluster Configuration

This directory contains the Flux configuration for the `ai` cluster.

## Directory Structure

```
ai/
├── flux-system/           # Flux core components and sync configuration
│   ├── gotk-components.yaml  # Flux GitOps Toolkit controllers
│   ├── gotk-sync.yaml        # GitRepository and Kustomization sync resources
│   └── kustomization.yaml    # Kustomize configuration for flux-system
├── namespaces/            # Namespace definitions
│   ├── monitoring.yaml       # Monitoring namespace
│   ├── kube-system.yaml      # kube-system namespace
│   ├── longhorn.yaml         # Longhorn storage namespace
│   └── kustomization.yaml    # Kustomize configuration for namespaces
└── kustomization.yaml     # Main kustomization file
```

## Namespaces

This cluster is configured with the following namespaces:
- **flux-system**: Flux controllers and sync resources
- **monitoring**: For monitoring tools (Prometheus, Grafana, etc.)
- **longhorn-system**: Longhorn distributed block storage

Note: The `kube-system` namespace is a built-in Kubernetes namespace and doesn't need to be explicitly created.

## Usage

To validate the configuration:
```bash
kustomize build .
```

To bootstrap this cluster with Flux:
```bash
flux bootstrap github \
  --owner=rothgar \
  --repository=homelab-flux \
  --path=clusters/ai \
  --personal
```
