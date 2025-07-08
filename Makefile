# Makefile for building, pushing to ECR, and deploying to EKS

SHELL             := /bin/bash
ACCOUNT_ID        := $(shell aws sts get-caller-identity --query Account --output text)
REGION            := $(shell aws configure get region)
REPO_NAME         := poc-py-odigos
IMAGE             := poc-py-odigos:latest
ECR_URI           := $(ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com/$(REPO_NAME)
IMAGE_URI         := $(ECR_URI):latest

.PHONY: all build create-repo login tag push deploy clean

all: build push deploy

## Build the Docker image locally
build:
	@echo "➡️  Building $(IMAGE)..."
	aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 512979937293.dkr.ecr.us-east-1.amazonaws.com
	docker build -t $(IMAGE) .

## Create the ECR repository if it doesn't exist
create-repo:
	@echo "➡️  Ensuring ECR repo $(REPO_NAME) exists..."
	aws ecr describe-repositories \
		--region $(REGION) \
		--repository-names $(REPO_NAME) \
	|| aws ecr create-repository \
		--region $(REGION) \
		--repository-name $(REPO_NAME)

## Log in to ECR
login: create-repo
	@echo "➡️  Logging in to ECR..."
	aws ecr get-login-password \
		--region $(REGION) \
	| docker login \
		--username AWS \
		--password-stdin $(ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com

## Tag the local image with the ECR URI
tag:
	@echo "➡️  Tagging image as $(IMAGE_URI)..."
	docker tag $(IMAGE) $(IMAGE_URI)

## Push the tagged image to ECR
push: login tag
	@echo "➡️  Pushing $(IMAGE_URI) to ECR..."
	docker push $(IMAGE_URI)

## Deploy to Kubernetes (EKS)
deploy:
	@echo "➡️  Applying Kubernetes manifests..."
	kubectl apply -f ./kube/deployment.yaml
	kubectl apply -f ./kube/service.yaml

## (Optional) Cleanup local images
clean:
	@echo "🗑️  Removing local images..."
	docker rmi $(IMAGE_URI) $(IMAGE) || true
