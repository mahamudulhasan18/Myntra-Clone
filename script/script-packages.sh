#!/bin/bash

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo "=========================================="
echo " Ubuntu DevOps Toolchain Setup"
echo "=========================================="

# --------------------------------------------------
# 1. Basic system packages
# --------------------------------------------------

echo "[1/10] Installing required packages..."

sudo apt-get update -y

sudo apt-get install -y \
    ca-certificates \
    curl \
    wget \
    unzip \
    gnupg \
    gpg \
    apt-transport-https \
    lsb-release \
    software-properties-common

# --------------------------------------------------
# 2. Docker CE
# --------------------------------------------------

echo "[2/10] Installing Docker CE..."

sudo install -m 0755 -d /etc/apt/keyrings

# Remove old Docker repository/key if present
sudo rm -f /etc/apt/sources.list.d/docker.list
sudo rm -f /etc/apt/keyrings/docker.gpg

curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg

sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y

sudo apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

sudo systemctl enable --now docker

# Add current user to docker group
sudo usermod -aG docker "$USER"

echo "Docker version:"
sudo docker --version

echo "Docker Compose version:"
sudo docker compose version

# --------------------------------------------------
# 3. Docker Scout
# --------------------------------------------------

echo "[3/10] Installing Docker Scout..."

if ! command -v docker-scout >/dev/null 2>&1; then
    curl -sSfL https://raw.githubusercontent.com/docker/scout-cli/main/install.sh \
        | sudo sh -s -- -b /usr/local/bin
fi

echo "Docker Scout version:"
docker-scout version || sudo docker-scout version

# --------------------------------------------------
# 4. Java 17 - Eclipse Temurin
# --------------------------------------------------

echo "[4/10] Installing Java 17..."

sudo rm -f /etc/apt/sources.list.d/adoptium.list

sudo wget -q -O /etc/apt/keyrings/adoptium.asc \
    https://packages.adoptium.net/artifactory/api/gpg/key/public

echo \
"deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb \
$(lsb_release -cs) main" \
| sudo tee /etc/apt/sources.list.d/adoptium.list > /dev/null

sudo apt-get update -y

sudo apt-get install -y temurin-17-jdk

echo "Java version:"
java --version

# --------------------------------------------------
# 5. Terraform
# --------------------------------------------------

echo "[5/10] Installing Terraform..."

sudo wget -q -O- https://apt.releases.hashicorp.com/gpg \
    | sudo gpg --dearmor --yes \
    -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo \
"deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com \
$(lsb_release -cs) main" \
| sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null

sudo apt-get update -y

sudo apt-get install -y terraform

echo "Terraform version:"
terraform version

# --------------------------------------------------
# 6. kubectl
# --------------------------------------------------

echo "[6/10] Installing kubectl..."

KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)

curl -LO \
    "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"

sudo install \
    -o root \
    -g root \
    -m 0755 \
    kubectl \
    /usr/local/bin/kubectl

rm -f kubectl

echo "kubectl version:"
kubectl version --client

# --------------------------------------------------
# 7. AWS CLI v2
# --------------------------------------------------

echo "[7/10] Installing AWS CLI v2..."

curl -sSL \
    "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
    -o /tmp/awscliv2.zip

rm -rf /tmp/aws

unzip -q -o /tmp/awscliv2.zip -d /tmp

sudo /tmp/aws/install --update

rm -rf /tmp/aws /tmp/awscliv2.zip

echo "AWS CLI version:"
aws --version

# --------------------------------------------------
# 8. Node.js 20 LTS + npm
# --------------------------------------------------

echo "[8/10] Installing Node.js 20..."

sudo rm -f /etc/apt/sources.list.d/nodesource.list
sudo rm -f /usr/share/keyrings/nodesource.gpg

wget -q \
    -O /tmp/nodesource.gpg.key \
    https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key

sudo gpg \
    --dearmor \
    --yes \
    -o /usr/share/keyrings/nodesource.gpg \
    /tmp/nodesource.gpg.key

echo \
"deb [signed-by=/usr/share/keyrings/nodesource.gpg] \
https://deb.nodesource.com/node_20.x nodistro main" \
| sudo tee /etc/apt/sources.list.d/nodesource.list > /dev/null

sudo apt-get update -y

sudo apt-get install -y nodejs

rm -f /tmp/nodesource.gpg.key

echo "Node.js version:"
node -v

echo "npm version:"
npm -v

# --------------------------------------------------
# 9. Enable Docker for current user
# --------------------------------------------------

echo "[9/10] Configuring Docker permissions..."

sudo systemctl enable docker
sudo systemctl start docker

sudo usermod -aG docker "$USER"

# --------------------------------------------------
# 10. Final verification
# --------------------------------------------------

echo ""
echo "=========================================="
echo " Installation completed successfully"
echo "=========================================="

echo ""
echo "System:"
lsb_release -ds || true

echo ""
echo "Docker:"
sudo docker --version
sudo docker compose version

echo ""
echo "Docker Scout:"
docker-scout version || sudo docker-scout version

echo ""
echo "Java:"
java --version

echo ""
echo "Terraform:"
terraform version

echo ""
echo "kubectl:"
kubectl version --client

echo ""
echo "AWS CLI:"
aws --version

echo ""
echo "Node.js:"
node -v

echo ""
echo "npm:"
npm -v

echo ""
echo "=========================================="
echo " IMPORTANT"
echo "=========================================="
echo ""
echo "The user '$USER' was added to the docker group."
echo ""
echo "Log out and log back in for the Docker group"
echo "permission to take effect."
echo ""
echo "Or run:"
echo "    newgrp docker"
echo ""
echo "Then test:"
echo "    docker run hello-world"
echo ""
```
