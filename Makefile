### Dev Makefile for landing + ingress-nginx on Docker Desktop

KUBECTL ?= kubectl
HELM    ?= helm
NS      ?= default

# Ingress NGINX
INGRESS_RELEASE      ?= ingress-nginx
INGRESS_CHART        ?= ingress-nginx/ingress-nginx
INGRESS_VALUES_FILE  ?= ingress-nginx-values.yaml
INGRESS_SVC          ?= ingress-nginx-controller
INGRESS_LOCAL_PORT   ?= 8080   # puerto en tu laptop
INGRESS_REMOTE_PORT  ?= 80     # puerto del servicio en el cluster

# Landing chart
LANDING_RELEASE ?= landing
LANDING_CHART   ?= helm/landing
IMAGE_NAME      ?= landing-static
IMAGE_TAG       ?= dev

.PHONY: init up ingress landing tunnel stop-tunnel status destroy clean

## init: agrega el repo de ingress-nginx (lo corres solo una vez)
init:
	$(HELM) repo add ingress-nginx https://kubernetes.github.io/ingress-nginx || true
	$(HELM) repo update

## up: build de la imagen, deploy de ingress-nginx + landing
up: ingress landing

## ingress: instala/actualiza ingress-nginx con el values.yaml
ingress:
	$(HELM) upgrade --install $(INGRESS_RELEASE) $(INGRESS_CHART) -f $(INGRESS_VALUES_FILE) --namespace $(NS) --create-namespace

## landing: build de la imagen y deploy del chart
landing:
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .
	$(HELM) upgrade --install $(LANDING_RELEASE) $(LANDING_CHART) --namespace $(NS)

## tunnel: abre el port-forward del Ingress Controller (deja esto corriendo en una terminal)
tunnel:
	$(KUBECTL) port-forward svc/$(INGRESS_SVC) $(INGRESS_LOCAL_PORT):$(INGRESS_REMOTE_PORT) --namespace $(NS)

## stop-tunnel: intenta matar el port-forward (best effort)
stop-tunnel:
	pkill -f "port-forward svc/$(INGRESS_SVC) $(INGRESS_LOCAL_PORT):$(INGRESS_REMOTE_PORT)" || true

## status: muestra estado rápido de pods, svc e ingress
status:
	$(KUBECTL) get pods -n $(NS)
	$(KUBECTL) get svc -n $(NS)
	$(KUBECTL) get ingress -n $(NS) || true

## destroy: borra releases de Helm (landing + ingress-nginx)
destroy:
	-$(HELM) uninstall $(LANDING_RELEASE) --namespace $(NS)
	-$(HELM) uninstall $(INGRESS_RELEASE) --namespace $(NS)

## clean: alias sencillo
clean: destroy

