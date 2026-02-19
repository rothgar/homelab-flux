# Longhorn Configuration

## Storage Configuration

Longhorn is configured to use `/var/mnt/longhorn` for storage (1.7TB+ available).

### Node Disk Configuration

The default data path is configured in `longhorn-config.yaml`, but existing nodes may need manual reconfiguration if they were created before this setting was applied.

#### To reconfigure an existing node:

```bash
# Get the node name
NODE_NAME="spark"

# Remove the old disk
kubectl patch nodes.longhorn.io $NODE_NAME -n longhorn-system --type='json' \
  -p='[{"op": "replace", "path": "/spec/disks/OLD_DISK_NAME/allowScheduling", "value": false}]'
kubectl patch nodes.longhorn.io $NODE_NAME -n longhorn-system --type='json' \
  -p='[{"op": "replace", "path": "/spec/disks/OLD_DISK_NAME/evictionRequested", "value": true}]'
kubectl patch nodes.longhorn.io $NODE_NAME -n longhorn-system --type='json' \
  -p='[{"op": "remove", "path": "/spec/disks/OLD_DISK_NAME"}]'

# Add the new disk with correct path
kubectl patch nodes.longhorn.io $NODE_NAME -n longhorn-system --type='json' \
  -p='[{"op": "add", "path": "/spec/disks/data-disk", "value": {
    "allowScheduling": true,
    "diskType": "filesystem",
    "evictionRequested": false,
    "path": "/var/mnt/longhorn",
    "storageReserved": 107374182400,
    "tags": []
  }}]'

# Verify
kubectl get nodes.longhorn.io $NODE_NAME -n longhorn-system -o jsonpath='{.status.diskStatus.data-disk.storageMaximum}' | numfmt --to=iec
```

## LoadBalancer Service

The Longhorn frontend UI is exposed via MetalLB LoadBalancer. Get the IP with:

```bash
kubectl get svc -n longhorn-system longhorn-frontend
```

## Settings

- **default-data-path**: `/var/mnt/longhorn` - Uses the large storage mount
- **storage-over-provisioning-percentage**: 200% - Allows thin provisioning
- **storage-minimal-available-percentage**: 10% - Minimum free space threshold
- **guaranteed-instance-manager-cpu**: 10m - CPU guarantee for instance managers
