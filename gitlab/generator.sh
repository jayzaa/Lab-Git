#!/bin/bash

# Create directory structure
mkdir -p gitlab

# Namespace YAML
cat <<EOF > gitlab/00-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: gitlab
EOF

# ConfigMap YAML
cat <<EOF > gitlab/01-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: gitlab-config
  namespace: gitlab
data:
  GITLAB_OMNIBUS_CONFIG: |
    external_url 'http://git.lab.clubzap.org'
EOF

# Secrets YAML
cat <<EOF > gitlab/02-secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: gitlab-secrets
  namespace: gitlab
type: Opaque
stringData:
  gitlab-root-password: "G0Pomelo2024!"
EOF

# PostgreSQL YAML
cat <<EOF > gitlab/03-postgresql.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: gitlab-postgresql
  namespace: gitlab
spec:
  serviceName: "postgresql"
  replicas: 1
  selector:
    matchLabels:
      app: postgresql
  template:
    metadata:
      labels:
        app: postgresql
    spec:
      containers:
      - name: postgresql
        image: postgres:11
        ports:
        - containerPort: 5432
EOF

# Redis YAML
cat <<EOF > gitlab/04-redis.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: gitlab-redis
  namespace: gitlab
spec:
  serviceName: "redis"
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:5.0
        ports:
        - containerPort: 6379
EOF

# MinIO YAML
cat <<EOF > gitlab/05-minio.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: gitlab-minio
  namespace: gitlab
spec:
  serviceName: "minio"
  replicas: 1
  selector:
    matchLabels:
      app: minio
  template:
    metadata:
      labels:
        app: minio
    spec:
      containers:
      - name: minio
        image: minio/minio
        args:
        - server
        - /data
        ports:
        - containerPort: 9000
EOF

# GitLab YAML
cat <<EOF > gitlab/06-gitlab.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gitlab
  namespace: gitlab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: gitlab
  template:
    metadata:
      labels:
        app: gitlab
    spec:
      containers:
      - name: gitlab
        image: gitlab/gitlab-ee:latest
        env:
        - name: GITLAB_OMNIBUS_CONFIG
          valueFrom:
            configMapKeyRef:
              name: gitlab-config
              key: GITLAB_OMNIBUS_CONFIG
        ports:
        - containerPort: 80
EOF

# Ingress YAML
cat <<EOF > gitlab/07-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: gitlab-ingress
  namespace: gitlab
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
  - host: git.lab.clubzap.org
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: gitlab
            port:
              number: 80
  tls:
  - hosts:
    - git.lab.clubzap.org
    secretName: gitlab-tls
EOF

# ArgoCD Application YAML
cat <<EOF > gitlab-argocd-application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: gitlab
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://your.git.repo.url'
    targetRevision: HEAD
    path: gitlab
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: gitlab
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

echo "YAML files generated successfully in the 'gitlab' directory."
