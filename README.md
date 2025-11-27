# Landing Home Lab on Kubernetes

This repository is a small **home lab** to practice:

- Building a Docker image for a static landing page (`index.html`)
- Deploying it to **Kubernetes** using **Helm**
- Exposing it through **NGINX Ingress** (on Docker Desktop)
- Accessing it locally via `kubectl port-forward`

It is **not** intended to be production-grade; it is a compact, repeatable learning environment.

---

## Repository structure

```text
.
├── Dockerfile
├── index.html
├── img/
│   └── fotoejecutiva.png       # logo used by the landing page
├── ingress-nginx-values.yaml   # config for NGINX Ingress Controller
├── helm/
│   └── landing/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── deployment.yaml
│           ├── service.yaml
│           └── ingress.yaml
└── Makefile
```

**Files overview:**

- **Dockerfile** – Builds an NGINX-based image that serves `index.html` and the `img/` directory.
- **ingress-nginx-values.yaml** – Values file used to configure the NGINX Ingress Controller via Helm.
- **helm/landing** – Helm chart that deploys the landing page (Deployment, Service, Ingress).
- **Makefile** – Convenience targets to install/upgrade the lab without typing long commands.

All resources are created in the **`default`** namespace of the local Docker Desktop Kubernetes cluster.

---

## Requirements

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) with **Kubernetes enabled**
- `kubectl` installed and configured to use the Docker Desktop context
- `helm` installed
- `make` installed (for using the Makefile targets)

Quick checks:

```bash
kubectl config current-context   # should show: docker-desktop
kubectl get nodes                # at least one node in Ready state
helm version
```

---

## NGINX Ingress via Helm

This lab uses the official `ingress-nginx` Helm chart.

The file `ingress-nginx-values.yaml` contains minimal configuration for the controller service:

```yaml
controller:
  service:
    type: NodePort
    nodePorts:
      http: 30080
      https: 30443
```

This keeps the controller configuration explicit and versioned in the repository.

---

## Makefile targets

The `Makefile` provides a few helpful targets:

- `make init` – Add/update the `ingress-nginx` Helm repo (optional, first time).
- `make up` – Deploy or upgrade:
  - NGINX Ingress Controller
  - Landing page (Helm chart)
- `make status` – Show pods, services, and ingresses in the `default` namespace.
- `make destroy` – Uninstall the Helm releases (`landing` and `ingress-nginx`).

### 1. (Optional) Initialize Helm repositories

You only need this once (or when you want to refresh chart repositories):

```bash
make init
```

If `helm repo update` fails due to lack of internet or DNS issues, it does **not** affect previously downloaded charts. You can still use `make up` as long as the chart was installed before.

### 2. Deploy NGINX Ingress + landing

From the root of the repository:

```bash
make up
```

This will:

1. Install or upgrade the **NGINX Ingress Controller** using `ingress-nginx-values.yaml`.
2. Build the Docker image for the landing page:
   - `landing-static:dev`
3. Install or upgrade the **`landing`** Helm release (Deployment, Service, Ingress).

You can check the status with:

```bash
make status
# or manually:
kubectl get pods
kubectl get svc
kubectl get ingress
```

You should see:

- A Deployment/Pod for the landing page.
- A Service for the landing page.
- An Ingress named `landing`.
- The `ingress-nginx-controller` service.

---

## Accessing the landing page (via port-forward)

In this home lab, the landing page is accessed through a **port-forward from your machine to the Ingress Controller service**.

In a separate terminal:

```bash
kubectl port-forward svc/ingress-nginx-controller 8080:80 --namespace default
```

Leave that command running.

Then open your browser and visit:

> **http://localhost:8080**

The traffic flow is:

```text
Browser (localhost:8080)
    → kubectl port-forward
    → Service "ingress-nginx-controller" (port 80)
    → Ingress "landing"
    → Service "landing"
    → Pod (NGINX serving index.html)
```

---

## Tearing down the lab

To remove the Kubernetes resources created by Helm (landing + ingress-nginx):

```bash
make destroy
```

This is equivalent to:

```bash
helm uninstall landing --namespace default
helm uninstall ingress-nginx --namespace default
```

This **does not** delete local Docker images; it only removes the Kubernetes resources.

---

## Customization

### Changing replica count

In `helm/landing/values.yaml`:

```yaml
replicaCount: 1
```

You can change this to run multiple replicas of the landing page:

```yaml
replicaCount: 3
```

Then redeploy:

```bash
make up
```

Kubernetes will run 3 pods for the landing, and the `Service` will load-balance requests between them.

### Changing image name or tag

By default, `helm/landing/values.yaml` contains:

```yaml
image:
  repository: landing-static
  tag: dev
  pullPolicy: IfNotPresent
```

If you want to push the image to a registry or version it:

```yaml
image:
  repository: your-registry/landing-static
  tag: v1.0.0
```

Build and redeploy:

```bash
docker build -t your-registry/landing-static:v1.0.0 .
make up
```

---

## Notes

- This repository is a **home lab**, intended for local experimentation with Docker Desktop, Kubernetes, Helm, and NGINX Ingress.
- All resources are created in the `default` namespace of the Docker Desktop Kubernetes cluster.
- Access is done via `kubectl port-forward` to keep networking simple and fully local.
- The manifests and values are intentionally small and opinionated to keep the lab easy to understand, tweak, and extend.
