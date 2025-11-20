## Key Features

- Creates an Azure Container Registry (ACR) with admin account disabled
- Creates a user-assigned managed identity for the container instance
- Grants AcrPull role to the managed identity
- Deploys a container group that authenticates to ACR using the managed identity
- No username or password credentials required for ACR access
