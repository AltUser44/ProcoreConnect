<#
  Path A — ECR repositories + helper commands to tag/push the Rails and frontend images.

  Creates (if missing):
    - procoreconnect-web
    - procoreconnect-frontend

  The web image is re-used for Sidekiq (same image, different command) when you
  run compose on EC2.

  Usage (from this folder):
    .\path-a-03-ecr.ps1

  Then on a host with Docker (this PC, CI, or EC2 after "aws install"), run
  the printed "docker build / tag / push" block from the repo root.
#>

[CmdletBinding()]
param(
  [string] $ProfileName = "procoreconnect",
  [string] $Region     = "us-east-1",
  [string] $WebRepo    = "procoreconnect-web",
  [string] $FrontRepo  = "procoreconnect-frontend"
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "..\..")).Path

$account = (& aws sts get-caller-identity --profile $ProfileName --query Account --output text).Trim()
if ([string]::IsNullOrWhiteSpace($account) -or $account -eq "None") { throw "Could not get AWS account id" }
$registry = "${account}.dkr.ecr.${Region}.amazonaws.com"
Write-Host "ECR registry: $registry" -ForegroundColor Cyan

function Ensure-EcrRepo {
  param([string] $Name)
  $oldE = $ErrorActionPreference; $ErrorActionPreference = "SilentlyContinue"
  $null = & aws ecr describe-repositories --profile $ProfileName --region $Region --repository-names $Name 2>$null
  $ok = $LASTEXITCODE
  $ErrorActionPreference = $oldE
  if ($ok -eq 0) {
    Write-Host "Reusing ECR repository: $Name" -ForegroundColor Cyan
    return
  }
  & aws ecr create-repository --profile $ProfileName --region $Region --repository-name $Name `
    --image-scanning-configuration scanOnPush=true `
    --tags "Key=app,Value=procoreconnect"
  if ($LASTEXITCODE -ne 0) { throw "ecr create-repository $Name failed" }
  Write-Host "Created ECR repository: $Name" -ForegroundColor Green
}

Ensure-EcrRepo $WebRepo
Ensure-EcrRepo $FrontRepo

$webTag = "$registry/${WebRepo}:latest"
$frontTag = "$registry/${FrontRepo}:latest"

Write-Host ""
Write-Host "==== Docker: build, login, tag, push (run from repo root) ====" -ForegroundColor Magenta
Write-Host "# Repo root (adjust path if needed):" -ForegroundColor DarkGray
Write-Host ('  cd "{0}"' -f $root)
Write-Host ""
Write-Host "# Build" -ForegroundColor DarkGray
Write-Host "  docker build -t $WebRepo -f procoreconnect/Dockerfile procoreconnect"
Write-Host "  docker build -t $FrontRepo -f procoreconnect/client/Dockerfile procoreconnect/client"
Write-Host ""
Write-Host "# Login ECR" -ForegroundColor DarkGray
Write-Host "  aws ecr get-login-password --profile $ProfileName --region $Region | docker login --username AWS --password-stdin $registry"
Write-Host ""
Write-Host "# Tag + push" -ForegroundColor DarkGray
Write-Host "  docker tag ${WebRepo}:latest $webTag"
Write-Host "  docker tag ${FrontRepo}:latest $frontTag"
Write-Host "  docker push $webTag"
Write-Host "  docker push $frontTag"
Write-Host ""
Write-Host "==== On Path A EC2, pull and run (after IAM allows ECR pull) ====" -ForegroundColor Magenta
Write-Host "  aws ecr get-login-password --region $Region | docker login --username AWS --password-stdin $registry"
Write-Host "  docker pull $webTag"
Write-Host "  docker pull $frontTag"
Write-Host "----"
