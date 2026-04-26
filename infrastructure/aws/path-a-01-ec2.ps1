<#
  Path A — single EC2 (t3.micro) in the default VPC for docker compose.

  Run in YOUR PowerShell (where you ran: aws configure --profile procoreconnect)
  and never commit the generated .pem to git.

  What this does:
  - Discovers the default VPC + a public subnet in us-east-1
  - Creates a security group: 22 from YOUR current public IP only, 80+443+3000+8080 from anywhere
  - Creates an EC2 key pair and writes <KeyName>.pem in the current directory
  - Launches Amazon Linux 2023 with Docker (see user-data-amazonlinux2023-docker.sh)
  - Allocates and associates an Elastic IP (stable public address)

  Usage (from repo root):
    cd infrastructure\aws
    Set-ExecutionPolicy -Scope CurrentUser -RemoteSigned
    .\path-a-01-ec2.ps1

  Optional:
    .\path-a-01-ec2.ps1 -ProfileName procoreconnect -KeyName procoreconnect-us-east-1a
#>

[CmdletBinding()]
param(
  [string] $ProfileName   = "procoreconnect",
  [string] $Region        = "us-east-1",
  [string] $KeyName        = "procoreconnect-procore-key",
  [string] $InstanceType   = "t3.micro"
)

# "Stop" is kept for our own "throw" statements, but the AWS CLI writes expected
# failures (e.g. key not found) to stderr — so those calls are wrapped below.
$ErrorActionPreference = "Stop"

# Avoid accidental double-runs: one tagged app instance at a time
$existing = & aws ec2 describe-instances --profile $ProfileName --region $Region `
  --filters "Name=instance-state-name,Values=running,pending,stopping,stopped" "Name=tag:Name,Values=procoreconnect-app" `
  --query "Reservations[].Instances[].InstanceId" --output text
if ($existing -and $existing -ne "None" -and $existing.Trim() -ne "") {
  throw "An instance with tag Name=procoreconnect-app already exists: $existing. Terminate it in EC2 or change the tag before re-running."
}

$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$userDataPath = Join-Path $scriptDir "user-data-amazonlinux2023-docker.sh"
if (-not (Test-Path $userDataPath)) {
  throw "Missing $userDataPath"
}

# --- Public IP of THIS machine (for SSH lockdown) ---------------------------
$myIp = (Invoke-RestMethod -Uri "https://checkip.amazonaws.com" -TimeoutSec 20).Trim()
if ($myIp -notmatch "^\d{1,3}(\.\d{1,3}){3}$") {
  throw "Could not parse public IP from checkip.amazonaws.com (got: $myIp)"
}
$sshCidr = "$myIp/32"
Write-Host "Locking SSH (port 22) to this machine only: $sshCidr" -ForegroundColor Cyan

# --- Default VPC ------------------------------------------------------------
$vpcId = (& aws ec2 describe-vpcs `
    --profile $ProfileName --region $Region `
    --filters "Name=isDefault,Values=true" `
    --query "Vpcs[0].VpcId" --output text)
if ([string]::IsNullOrWhiteSpace($vpcId) -or $vpcId -eq "None") {
  throw "No default VPC found. Create a default VPC in $Region or set up a custom VPC and edit this script."
}
Write-Host "Default VPC: $vpcId" -ForegroundColor Cyan

# One subnet that maps a public IP on launch
$subnetId = (& aws ec2 describe-subnets `
    --profile $ProfileName --region $Region `
    --filters "Name=vpc-id,Values=$vpcId" "Name=map-public-ip-on-launch,Values=true" `
    --query "Subnets[0].SubnetId" --output text)
if ([string]::IsNullOrWhiteSpace($subnetId) -or $subnetId -eq "None") {
  throw "Could not find a public subnet in the default VPC."
}
Write-Host "Public subnet: $subnetId" -ForegroundColor Cyan

# --- Key pair (writes .pem next to this script) ---------------------------
$pemPath = Join-Path $scriptDir "$KeyName.pem"
# Must discard stderr: "not found" is normal when we need to create. (2>&1|Out-Null
# still records errors and can trip -ErrorAction Stop; 2>$null does not.)
$oldEap = $ErrorActionPreference
$ErrorActionPreference = "SilentlyContinue"
$null = & aws ec2 describe-key-pairs --profile $ProfileName --region $Region --key-names $KeyName 2>$null
$ErrorActionPreference = $oldEap
if ($LASTEXITCODE -eq 0) {
  Write-Warning "Key pair '$KeyName' already exists in this region. Skipping create. If you lost the .pem, delete the key pair in EC2 and re-run."
} else {
  $json = & aws ec2 create-key-pair --profile $ProfileName --region $Region --key-name $KeyName --output json
  if ($LASTEXITCODE -ne 0) { throw "create-key-pair failed: $json" }
  $kp = $json | ConvertFrom-Json
  [IO.File]::WriteAllText($pemPath, $kp.KeyMaterial)  # preserve PEM newlines
  Write-Host "Wrote private key: $pemPath" -ForegroundColor Green
  Write-Host "Tighten permissions: icacls on Windows (see runbook) or chmod 400 if copied to WSL" -ForegroundColor Yellow
}

# --- Security group ------------------------------------------------------
$sgName = "procoreconnect-app-sg"
$sgId = $null
$allSgs = & aws ec2 describe-security-groups --profile $ProfileName --region $Region --filters "Name=group-name,Values=$sgName" --query "SecurityGroups[0].GroupId" --output text
if ($allSgs -and $allSgs -ne "None") {
  $sgId = $allSgs
  Write-Host "Reusing security group: $sgId" -ForegroundColor Cyan
} else {
  $sgId = (& aws ec2 create-security-group --profile $ProfileName --region $Region `
      --group-name $sgName `
      --description "procoreconnect Path A" `
      --vpc-id $vpcId `
      --query "GroupId" --output text)
  Write-Host "Created security group: $sgId" -ForegroundColor Cyan
}

# Ingress. Re-run is OK: "InvalidPermission.Duplicate" is ignored.
function Add-SGRule {
  param([int] $port, [string] $cidr)
  $ipPerm = "IpProtocol=tcp,FromPort=$port,ToPort=$port,IpRanges=[{CidrIp=$cidr}]"
  $oldE = $ErrorActionPreference
  $ErrorActionPreference = "SilentlyContinue"
  $err = & aws ec2 authorize-security-group-ingress --profile $ProfileName --region $Region `
    --group-id $sgId --ip-permissions $ipPerm 2>&1
  $ErrorActionPreference = $oldE
  if ($LASTEXITCODE -ne 0 -and "$err" -notmatch "InvalidPermission\.Duplicate") {
    throw "authorize-security-group-ingress failed: $err"
  }
}
Add-SGRule 22  $sshCidr
Add-SGRule 80  "0.0.0.0/0"
Add-SGRule 443 "0.0.0.0/0"
Add-SGRule 3000 "0.0.0.0/0"
Add-SGRule 8080 "0.0.0.0/0"

# --- Amazon Linux 2023 AMI (x86_64) via SSM ----------------------------
$ssmParamNames = @(
  "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64",
  "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
)
$ami = $null
foreach ($n in $ssmParamNames) {
  $a = & aws ssm get-parameters --profile $ProfileName --region $Region --names $n --query "Parameters[0].Value" --output text
  if ($LASTEXITCODE -eq 0 -and $a -and $a -ne "None") { $ami = $a; break }
}
if ([string]::IsNullOrWhiteSpace($ami) -or $ami -eq "None") { throw "Failed to resolve AL2023 AMI from SSM Parameter Store (tried known parameter names)" }
Write-Host "AL2023 AMI: $ami" -ForegroundColor Cyan

# --user-data file URL for Windows: must use forward slashes after file:
$ab = (Resolve-Path $userDataPath).Path -replace "\\", "/"
# file:// + C:/Users/...  =>  file:///C:/Users/... (required by AWS CLI on Windows)
if ($ab -match "^[A-Z]:/") { $udUrl = "file:///" + $ab } else { $udUrl = "file://" + $ab }

# --- Launch instance -------------------------------------------------------
$instanceId = (& aws ec2 run-instances --profile $ProfileName --region $Region `
  --image-id $ami `
  --instance-type $InstanceType `
  --key-name $KeyName `
  --subnet-id $subnetId `
  --security-group-ids $sgId `
  --associate-public-ip-address `
  --user-data $udUrl `
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=procoreconnect-app}]" `
  --query "Instances[0].InstanceId" --output text)
if ($LASTEXITCODE -ne 0 -or -not $instanceId) { throw "run-instances failed" }
Write-Host "Instance: $instanceId" -ForegroundColor Green

# Wait for running
& aws ec2 wait instance-running --profile $ProfileName --region $Region --instance-ids $instanceId
Write-Host "Instance is running." -ForegroundColor Green

# --- Elastic IP ----------------------------------------------------------
$eipId = (& aws ec2 allocate-address --profile $ProfileName --region $Region --domain vpc --query "AllocationId" --output text)
& aws ec2 associate-address --profile $ProfileName --region $Region --instance-id $instanceId --allocation-id $eipId
$publicIp = (& aws ec2 describe-addresses --profile $ProfileName --region $Region --allocation-ids $eipId --query "Addresses[0].PublicIp" --output text)

Write-Host "" 
Write-Host "==== NEXT STEPS ====" -ForegroundColor Magenta
Write-Host "Public IP: $publicIp" -ForegroundColor Magenta
Write-Host "SSH (use your .pem, often via WSL is easier):`n  ssh -i `"$pemPath`" ec2-user@$publicIp" -ForegroundColor Magenta
Write-Host "When Docker user-data finishes (~2 min), on the host run: `n  docker --version" -ForegroundColor Magenta
Write-Host "==== RDS + ECR + deploy comes next (path-a-runbook.txt) ====" -ForegroundColor Magenta
