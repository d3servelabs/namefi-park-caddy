#!/bin/bash
set -e

# Variables - update these
PROJECT_ID="d3serve-labs"
ZONE="us-central1-a"
REGION="us-central1"
INSTANCE_NAME="namefi-caddy-server"
MACHINE_TYPE="e2-small"
IP_NAME="namefi-caddy-ip"

# Color outputs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting deployment of Caddy Server for namefi.ai...${NC}"

# Check if static IP exists, if not create it
echo -e "${YELLOW}Checking if static IP exists...${NC}"
if ! gcloud compute addresses describe "$IP_NAME" --region="$REGION" --project="$PROJECT_ID" &>/dev/null; then
  echo -e "${YELLOW}Creating static IP address...${NC}"
  gcloud compute addresses create "$IP_NAME" \
    --project="$PROJECT_ID" \
    --region="$REGION" \
    --network-tier=PREMIUM
else
  echo -e "${GREEN}Static IP already exists.${NC}"
fi

# Get the IP address
IP_ADDRESS=$(gcloud compute addresses describe "$IP_NAME" \
  --project="$PROJECT_ID" \
  --region="$REGION" \
  --format="get(address)")
echo -e "${GREEN}Reserved IP address: $IP_ADDRESS${NC}"

# Create firewall rules if they don't exist
echo -e "${YELLOW}Checking and creating firewall rules...${NC}"

# HTTP rule
if ! gcloud compute firewall-rules describe allow-http --project="$PROJECT_ID" &>/dev/null; then
  echo -e "${YELLOW}Creating HTTP firewall rule...${NC}"
  gcloud compute firewall-rules create allow-http \
    --project="$PROJECT_ID" \
    --direction=INGRESS \
    --priority=1000 \
    --network=default \
    --action=ALLOW \
    --rules=tcp:80 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=http-server
else
  echo -e "${GREEN}HTTP firewall rule already exists.${NC}"
fi

# HTTPS rule
if ! gcloud compute firewall-rules describe allow-https --project="$PROJECT_ID" &>/dev/null; then
  echo -e "${YELLOW}Creating HTTPS firewall rule...${NC}"
  gcloud compute firewall-rules create allow-https \
    --project="$PROJECT_ID" \
    --direction=INGRESS \
    --priority=1000 \
    --network=default \
    --action=ALLOW \
    --rules=tcp:443 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=https-server
else
  echo -e "${GREEN}HTTPS firewall rule already exists.${NC}"
fi

# Custom ports rule for Caddy
if ! gcloud compute firewall-rules describe allow-caddy-custom --project="$PROJECT_ID" &>/dev/null; then
  echo -e "${YELLOW}Creating custom ports firewall rule...${NC}"
  gcloud compute firewall-rules create allow-caddy-custom \
    --project="$PROJECT_ID" \
    --direction=INGRESS \
    --priority=1000 \
    --network=default \
    --action=ALLOW \
    --rules=tcp:3443,tcp:8080 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=caddy-server
else
  echo -e "${GREEN}Custom ports firewall rule already exists.${NC}"
fi

# Check if instance exists, delete if it does
if gcloud compute instances describe "$INSTANCE_NAME" --zone="$ZONE" --project="$PROJECT_ID" &>/dev/null; then
  echo -e "${YELLOW}Instance already exists. Deleting...${NC}"
  gcloud compute instances delete "$INSTANCE_NAME" \
    --zone="$ZONE" \
    --project="$PROJECT_ID" \
    --quiet
fi

# Create instance with reserved IP and cloud-init
echo -e "${YELLOW}Creating GCE instance with Caddy...${NC}"
gcloud compute instances create "$INSTANCE_NAME" \
  --project="$PROJECT_ID" \
  --zone="$ZONE" \
  --machine-type="$MACHINE_TYPE" \
  --network-tier=PREMIUM \
  --tags=http-server,https-server,caddy-server \
  --metadata-from-file=user-data=cloud-init.yaml \
  --image-family=cos-stable \
  --image-project=cos-cloud \
  --boot-disk-size=20GB \
  --boot-disk-type=pd-balanced \
  --address="$IP_ADDRESS"

echo -e "${GREEN}Deployment complete!${NC}"
echo -e "${GREEN}Instance: $INSTANCE_NAME${NC}"
echo -e "${GREEN}External IP: $IP_ADDRESS${NC}"
echo -e "${YELLOW}Important:${NC} Add an A record for namefi.ai pointing to $IP_ADDRESS"
echo -e "${YELLOW}Verify deployment:${NC} gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --project=$PROJECT_ID" 