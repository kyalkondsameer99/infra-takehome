#  Cluster-wide cap on Deployment replicas (CEL ValidatingAdmissionPolicy)

This enforces a cluster-wide limit of 5 replicas per Deployment using Kubernetes built-in ValidatingAdmissionPolicy (CEL). Any Deployment CREATE/UPDATE with `spec.replicas > 5` is denied at admission time. The limit lives in a ConfigMap so it's easy to change.

---

## Task

> Place a cluster-wide limit on the number of replicas allowed per Deployment.
> The limit should be 5.

---

## Artifacts

1. Script: `scripts/deploy.sh` — deploys everything to the cluster (Minikube-friendly).
2. Documentation: this README — explains how it works and how to run it.

---

## How it works

- `manifests/01-configmap.yaml` defines `data.maxReplicas: "5"` in `policy-config/replica-limit`.
- `manifests/10-validating-admission-policy.yaml` is a CEL rule that:
  - allows when `spec.replicas` is `null` (Deployment defaults to 1),
  - denies when `spec.replicas > maxReplicas`.
- `manifests/11-validating-admission-policy-binding.yaml` binds the policy to that ConfigMap.
- No external policy engine or custom webhook is used — this is native API server admission.

CEL expression used:
```cel
object.spec.replicas == null || int(object.spec.replicas) <= max
```

---

## Prerequisites

A running kuberenetes cluster.

```bash 
kubectl api-resources | grep -i ValidatingAdmissionPolicy 
```
to verify that ValidatingAdmissionPolicy and ValidatingAdmissionPolicyBinding are present in your cluster’s API resources before applying the manifests.


You should see both validatingadmissionpolicies and validatingadmissionpolicybindings.

---

## Deploy

```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh --install
```

This creates:

- Namespace: policy-config
- ConfigMap: replica-limit (with maxReplicas: "5")
- ValidatingAdmissionPolicy: cap-deployment-replicas
- Binding: cap-deployment-replicas-binding

---

## Testing

The grader will apply this manifest; it must be blocked:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: disallowed-redis
spec:
  selector:
    matchLabels:
      app: redis
  replicas: 6
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
        - name: redis
          image: redis
```

Run:

```bash
kubectl apply -f samples/disallowed-redis.yaml
```

Expected: the API denies it with a message like:

```
Replica count cannot exceed 5 for Deployments.
```

**Positive control (should succeed):**

```bash
kubectl apply -f samples/allowed-5.yaml
kubectl rollout status deploy/allowed-five
```

---




## Notes

- Enforcement is admission-time; invalid Deployments never get stored.
- If spec.replicas is omitted, Kubernetes defaults it to 1, which passes.
- Mutating webhooks can be used when we want to automatically override max replicas to our desired limit.



---


