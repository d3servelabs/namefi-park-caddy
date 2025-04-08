# Namefi Caddy Server Deployment

This repository contains configuration to deploy a Caddy server on Google Cloud Compute Engine (GCE) for the namefi.ai domain.

## Prerequisites

- Google Cloud SDK installed locally
- A Google Cloud account with billing enabled
- Appropriate permissions to create and manage GCE instances
- Domain configured with proper A records pointing to your server's IP

## Deployment

### Option 1: Automated Deployment Script (Recommended)

Use the `deploy.sh` script for a complete deployment that:
- Reserves a static IP address
- Creates all necessary firewall rules
- Deploys the GCE instance with cloud-init configuration

1. Update the variables in `deploy.sh`:
   ```bash
   PROJECT_ID="your-project-id"
   ZONE="us-central1-a"  # Or your preferred zone
   REGION="us-central1"  # Should match the zone's region
   INSTANCE_NAME="namefi-caddy-server"
   MACHINE_TYPE="e2-small"  # Or your preferred machine type
   IP_NAME="namefi-caddy-ip"  # Name for the reserved IP
   ```

2. Run the deployment script:
   ```bash
   ./deploy.sh
   ```

3. Follow the output instructions to set up your DNS.

### Option 2: Manual GCE Deployment

Use the `cloud-init.yaml` file with gcloud to deploy Caddy:

```bash
gcloud compute instances create namefi-caddy-server \
  --project=your-project-id \
  --zone=us-central1-a \
  --machine-type=e2-small \
  --network-tier=PREMIUM \
  --tags=http-server,https-server,caddy-server \
  --metadata-from-file=user-data=cloud-init.yaml \
  --image-family=cos-stable \
  --image-project=cos-cloud \
  --boot-disk-size=20GB \
  --boot-disk-type=pd-balanced
```

For manual setup of static IP and firewall rules, see the commands in `deploy.sh`.

## Configuration Details

- The Caddy server is configured to:
  - Automatically obtain and renew SSL certificates for namefi.ai
  - Reverse proxy all requests to https://namefi.ai
  - Handle both HTTP and HTTPS traffic
  - Run as a Docker container for easy maintenance

## Maintenance

### Connecting to the Instance

To connect to your instance:

```bash
gcloud compute ssh namefi-caddy-server --zone=us-central1-a --project=your-project-id
```

### Viewing Logs

To access logs for the Caddy server:

```bash
# View all logs
docker logs namefi-caddy

# Follow logs in real-time
docker logs -f namefi-caddy

# Show only the last 100 lines
docker logs --tail=100 namefi-caddy

# Filter logs for specific content
docker logs namefi-caddy | grep error
```

You can also check system logs for the Container-Optimized OS:

```bash
# View system journal logs
journalctl -u docker

# View cloud-init logs
journalctl -u cloud-init
```

### Container Management

Common container management commands:
- Restart Caddy: `docker restart namefi-caddy`
- Stop Caddy: `docker stop namefi-caddy`
- Start Caddy: `docker start namefi-caddy`
- Update Caddy: `docker pull caddy:2-alpine && docker stop namefi-caddy && docker rm namefi-caddy && docker run -d --name namefi-caddy --restart=always -e APP_URL=https://namefi.ai -v /etc/caddy/Caddyfile:/etc/caddy/Caddyfile:ro -v /var/caddy/data:/data -p 80:80 -p 443:443 -p 8080:8080 -p 3443:3443 caddy:2-alpine`

## Troubleshooting

- **SSL Certificate Issues**: Make sure ports 80 and 443 are open in firewall rules
- **Proxy Not Working**: Verify the service is running correctly
- **Container Not Starting**: Check docker logs for more details
