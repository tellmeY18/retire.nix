# werepair.fyi demo

Public demo: https://repair.tellmey.fyi via existing Traefik + Let's Encrypt.
No Tailscale ingress. App source and image CI: https://github.com/tellmeY18/werepair.fyi.

One non-root Phoenix release on an amd64 ZFS storage node. SQLite is on a 1 GiB
PVC; Recreate updates prevent concurrent writers. The initialization container
migrates and seeds only an explicitly enabled demo, and leaves existing data intact.

Isolation: no service-account token, no RBAC grants,
no host mounts, read-only root filesystem, dropped capabilities, seccomp, CPU/memory
limits and namespace quota. All pod egress is denied, including DNS, metadata and
the Kubernetes API. This cluster disables NetworkPolicy enforcement, so a pinned
firewall init image installs IPv4/IPv6 default-drop rules in this pod's network
namespace. Only this init container has root/NET_ADMIN, and it exits before seeding
or serving. Admission enforcement is privileged for this namespace to allow that
exception; audit/warn remain restricted. The app retains all restricted controls.
Inbound TCP/4000 is allowed for ingress and probes (CNI rewrites source IPs).
All other inbound ports and all new outbound connections are blocked. The
NetworkPolicy documents the desired narrower ingress boundary for when cluster
enforcement is enabled. Ingress limits requests to 2.5 MB and 10 requests/second
per source with a burst of 20. Demo admin credentials control only fictional data.
This limits blast radius; it is not a guarantee against kernel/runtime vulnerabilities.

## Apply only this demo

```sh
export KUBECONFIG="$HOME/.kube/glug-infra.yaml"
kubectl apply -f k8s/clusters/glug-infra/werepair/namespace.yaml
# Once only: generate the session secret without writing plaintext to disk.
kubectl -n werepair-demo create secret generic werepair-runtime \
  --from-literal=SECRET_KEY_BASE="$(openssl rand -base64 64 | tr -d '\n')"
kubectl apply -k k8s/clusters/glug-infra/werepair
kubectl -n werepair-demo rollout status deployment/werepair --timeout=180s
```

The session secret lives only in Kubernetes; it is never in source or the image.
Use the published immutable image digest in both init and application containers.
Reapplying manifests does not rotate the session secret or reset the database.
If MagicDNS is unavailable, add `--server=https://100.76.202.89:6443
--tls-server-name=k3s-cp.tail477f2f.ts.net` to kubectl (do not disable TLS verification).

## Inspect / remove

```sh
kubectl -n werepair-demo get pods,pvc
kubectl -n werepair-demo logs deployment/werepair -c initialize-demo
kubectl -n werepair-demo logs deployment/werepair -c app
# Disable the demo, preserving its data:
kubectl -n werepair-demo scale deployment/werepair --replicas=0
# Delete everything, including demo data, only when no longer needed:
kubectl delete namespace werepair-demo
```

No automatic deployment from GitHub: its workflow gets package-write permission,
not kubeconfig access. Cluster changes are applied from the admin workstation.
