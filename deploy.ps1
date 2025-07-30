# Production deployment script for Transaction Management API (PowerShell)
# This script is called by the webhook receiver

param(
    [string]$DockerImage = $(if ($env:DOCKER_IMAGE) { $env:DOCKER_IMAGE } else { "ghcr.io/sahilbharodiya/transaction-management-api:latest" }),
    [string]$ContainerName = $(if ($env:CONTAINER_NAME) { $env:CONTAINER_NAME } else { "transaction-api" }),
    [string]$HostPort = $(if ($env:HOST_PORT) { $env:HOST_PORT } else { "8080" }),
    [string]$ContainerPort = $(if ($env:CONTAINER_PORT) { $env:CONTAINER_PORT } else { "5000" }),
    [string]$DataDir = $(if ($env:DATA_DIR) { $env:DATA_DIR } else { "$(Get-Location)\data" }),
    [string]$CommitSha = $(if ($env:COMMIT_SHA) { $env:COMMIT_SHA } else { "unknown" })
)

$ErrorActionPreference = "Stop"

Write-Host "Starting deployment..." -ForegroundColor Green
Write-Host "======================="

Write-Host "Deployment Configuration:" -ForegroundColor Yellow
Write-Host "- Docker Image: $DockerImage"
Write-Host "- Container Name: $ContainerName"
Write-Host "- Port Mapping: ${HostPort}:${ContainerPort}"
Write-Host "- Data Directory: $DataDir"
Write-Host "- Commit SHA: $CommitSha"
Write-Host ""

# Create data directory if it doesn't exist
if (!(Test-Path $DataDir)) {
    New-Item -ItemType Directory -Path $DataDir -Force | Out-Null
    Write-Host "Created data directory: $DataDir"
}

try {
    # Pull the latest image
    Write-Host "Pulling Docker image..." -ForegroundColor Blue
    docker pull $DockerImage
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to pull Docker image: $DockerImage"
    }
    Write-Host "✅ Successfully pulled image" -ForegroundColor Green

    # Stop and remove existing container
    Write-Host "Stopping existing container..." -ForegroundColor Blue
    
    $runningContainer = docker ps -q --filter "name=$ContainerName" 2>$null
    if ($runningContainer) {
        docker stop $ContainerName
        Write-Host "   Stopped container: $ContainerName"
    } else {
        Write-Host "   No running container found"
    }

    $existingContainer = docker ps -aq --filter "name=$ContainerName" 2>$null
    if ($existingContainer) {
        docker rm $ContainerName
        Write-Host "   Removed container: $ContainerName"
    }

    # Start new container
    Write-Host "Starting new container..." -ForegroundColor Blue
    
    $dockerArgs = @(
        "run", "-d",
        "--name", $ContainerName,
        "-p", "${HostPort}:${ContainerPort}",
        "-v", "${DataDir}:/app/data",
        "--restart", "unless-stopped",
        "--health-cmd", "curl -f http://localhost:$ContainerPort/health || exit 1",
        "--health-interval", "30s",
        "--health-timeout", "10s",
        "--health-retries", "3",
        "-e", "COMMIT_SHA=$CommitSha",
        $DockerImage
    )
    
    $containerId = docker @dockerArgs
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to start container"
    }
    
    Write-Host "✅ Container started with ID: $containerId" -ForegroundColor Green

    # Wait for container to be healthy
    Write-Host "Waiting for container to be healthy..." -ForegroundColor Blue
    
    $maxAttempts = 30
    $attempt = 0
    
    do {
        Start-Sleep -Seconds 2
        $attempt++
        
        $health = docker inspect --format='{{.State.Health.Status}}' $ContainerName 2>$null
        
        if ($health -eq "healthy") {
            Write-Host "✅ Container is healthy!" -ForegroundColor Green
            break
        } elseif ($health -eq "unhealthy") {
            throw "Container became unhealthy"
        }
        
        Write-Host "   Attempt $attempt/$maxAttempts - Status: $health"
        
    } while ($attempt -lt $maxAttempts)
    
    if ($attempt -ge $maxAttempts) {
        Write-Warning "Health check timeout, but container is running"
    }

    # Test the API
    Write-Host "Testing API endpoint..." -ForegroundColor Blue
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:$HostPort/health" -TimeoutSec 10
        Write-Host "✅ API is responding: $($response.status)" -ForegroundColor Green
    } catch {
        Write-Warning "API health check failed, but deployment completed"
    }

    Write-Host ""
    Write-Host "🚀 Deployment completed successfully!" -ForegroundColor Green
    Write-Host "- API URL: http://localhost:$HostPort"
    Write-Host "- Container: $ContainerName"
    Write-Host "- Image: $DockerImage"
    Write-Host "- Commit: $CommitSha"

} catch {
    Write-Host ""
    Write-Host "❌ Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    
    # Show container logs if container exists
    $containerExists = docker ps -aq --filter "name=$ContainerName" 2>$null
    if ($containerExists) {
        Write-Host ""
        Write-Host "Container logs:" -ForegroundColor Yellow
        docker logs $ContainerName --tail 20
    }
    
    exit 1
}
