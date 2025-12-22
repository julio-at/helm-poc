IMAGE_REGISTRY ?= registry.digitalocean.com/guajiro
IMAGE_NAME     ?= landing-static
IMAGE_TAG      ?= v1.0.0

landing:
    docker build -t $(IMAGE_REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG) .
    docker push $(IMAGE_REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)
    $(HELM) upgrade --install $(LANDING_RELEASE) $(LANDING_CHART) \
      --set image.repository=$(IMAGE_REGISTRY)/$(IMAGE_NAME) \
      --set image.tag=$(IMAGE_TAG) \
      --namespace $(NS)

