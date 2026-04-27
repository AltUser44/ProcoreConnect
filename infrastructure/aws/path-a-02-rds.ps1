<#
  Path A — PostgreSQL (db.t3.micro) in the default VPC for the Path A app EC2.

  Prerequisites: path-a-01-ec2.ps1 has run (procoreconnect-app-sg + instance exist).

  Creates (idempotent when resources already match):
  - DB subnet group using two subnets in different AZs in the default VPC
  - procoreconnect-rds-sg: allow TCP 5432 from the app security group only
  - Single-AZ RDS (Postgres), not publicly accessible

  Usage (from this folder):
    .\path-a-02-rds.ps1
    # Or pass a password (same user your Rails prod config expects by default):
    $sec = Read-Host "Master password" -AsSecureString
    .\path-a-02-rds.ps1 -MasterPassword $sec

  If -MasterPassword is omitted, a random password is written to
  .rds-creds.local (see .gitignore). Never commit that file.

  Env for Rails production (on EC2 / .env):
    DATABASE_HOST=(RDS endpoint, no port if 5432)
    DATABASE_PORT=5432
    DATABASE_USERNAME=procoreconnect
    PROCORECONNECT_DATABASE_PASSWORD=...
#>

[CmdletBinding()]
param(
  [string]   $ProfileName   = "procoreconnect",
  [string]   $Region        = "us-east-1",
  [string]   $AppSgName     = "procoreconnect-app-sg",
  [string]   $RdsSgName     = "procoreconnect-rds-sg",
  [string]   $SubnetGroupName = "procoreconnect-db",
  [string]   $DbInstanceId  = "procoreconnect-db",
  [string]   $MasterUsername = "procoreconnect",
  [string]   $InitialDbName = "procoreconnect_production",
  [SecureString] $MasterPassword = $null
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# --- default VPC
$vpcId = (& aws ec2 describe-vpcs --profile $ProfileName --region $Region `
  --filters "Name=isDefault,Values=true" `
  --query "Vpcs[0].VpcId" --output text)
if ([string]::IsNullOrWhiteSpace($vpcId) -or $vpcId -eq "None") { throw "No default VPC in $Region." }
Write-Host "Default VPC: $vpcId" -ForegroundColor Cyan

# --- app security group (must exist from path-a-01)
$appSg = (& aws ec2 describe-security-groups --profile $ProfileName --region $Region `
  --filters "Name=vpc-id,Values=$vpcId" "Name=group-name,Values=$AppSgName" `
  --query "SecurityGroups[0].GroupId" --output text)
if ([string]::IsNullOrWhiteSpace($appSg) -or $appSg -eq "None") { throw "Security group '$AppSgName' not found. Run path-a-01-ec2.ps1 first (or pass -AppSgName)."}
Write-Host "App security group: $appSg" -ForegroundColor Cyan

# --- two subnets, two different AZs (required for a DB subnet group)
$subJson = & aws ec2 describe-subnets --profile $ProfileName --region $Region `
  --filters "Name=vpc-id,Values=$vpcId" --output json
if ($LASTEXITCODE -ne 0) { throw "describe-subnets failed" }
$subDoc = $subJson | ConvertFrom-Json
$perAz = @{}
foreach ($s in $subDoc.Subnets) {
  $z = $s.AvailabilityZone
  if (-not $perAz.ContainsKey($z)) { $perAz[$z] = $s.SubnetId }
}
$azs = $perAz.Keys | Sort-Object
if ($azs.Count -lt 2) { throw "Need subnets in at least 2 availability zones in $vpcId; found: $($perAz.Count)." }
$subnetA = $perAz[$azs[0]]
$subnetB = $perAz[$azs[1]]
Write-Host "DB subnets ($($azs[0]), $($azs[1])): $subnetA, $subnetB" -ForegroundColor Cyan

# --- RDS security group: 5432 from app SG only
$rdsSg = (& aws ec2 describe-security-groups --profile $ProfileName --region $Region `
  --filters "Name=vpc-id,Values=$vpcId" "Name=group-name,Values=$RdsSgName" `
  --query "SecurityGroups[0].GroupId" --output text)
if ($rdsSg -and $rdsSg -ne "None" -and $rdsSg.Trim() -ne "") {
  Write-Host "Reusing RDS security group: $rdsSg" -ForegroundColor Cyan
} else {
  $rdsSg = (& aws ec2 create-security-group --profile $ProfileName --region $Region `
    --group-name $RdsSgName `
    --description "procoreconnect Path A (RDS) — from app SG only" `
    --vpc-id $vpcId `
    --query "GroupId" --output text)
  if ($LASTEXITCODE -ne 0 -or -not $rdsSg) { throw "create-security-group failed" }
  Write-Host "Created RDS security group: $rdsSg" -ForegroundColor Green
}

# Idempotent: allow 5432 from app SG
$errF = [IO.Path]::GetTempFileName()
$null = & aws ec2 authorize-security-group-ingress --profile $ProfileName --region $Region `
  --group-id $rdsSg --protocol tcp --port 5432 --source-group $appSg 2> $errF
$e = $LASTEXITCODE
$eMsg = if (Test-Path -LiteralPath $errF) { (Get-Content -LiteralPath $errF -Raw) } else { "" }
Remove-Item -LiteralPath $errF -ErrorAction SilentlyContinue
if ($e -ne 0) {
  if ($eMsg -notmatch '(?i)InvalidPermission|Duplicate|already') {
    throw "authorize-security-group-ingress 5432 from $appSg failed: $eMsg"
  }
}

# --- password
$plainPw = $null
if ($MasterPassword) {
  $BSTR = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($MasterPassword)
  try { $plainPw = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR) } finally { [void][Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR) }
} else {
  $credsFile = Join-Path $scriptDir ".rds-creds.local"
  if (Test-Path -LiteralPath $credsFile) {
    $rawC = Get-Content -LiteralPath $credsFile -Raw
    if ($rawC -match 'PROCORECONNECT_DATABASE_PASSWORD=([^\r\n]+)') { $plainPw = $Matches[1].Trim() }
  }
  if (-not $plainPw) {
    $bytes = [byte[]]::new(24)
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $rng.GetBytes($bytes)
    $plainPw = "Pc" + ([BitConverter]::ToString($bytes) -replace "-", "") + "1!"
    if ($plainPw.Length -lt 8) { throw "Generated password too short" }
    [IO.File]::WriteAllText($credsFile, "PROCORECONNECT_DATABASE_PASSWORD=$plainPw`nMASTER_USERNAME=$MasterUsername`n")
    Write-Warning ('Wrote generated master password to {0} (not committed; see .gitignore). Back it up securely.' -f $credsFile)
  } else {
    Write-Host "Reusing existing password from $credsFile" -ForegroundColor Yellow
  }
}

# --- DB subnet group
$oldE = $ErrorActionPreference
$ErrorActionPreference = "SilentlyContinue"
$null = & aws rds describe-db-subnet-groups --profile $ProfileName --region $Region --db-subnet-group-name $SubnetGroupName 2>$null
$eex = $LASTEXITCODE
$ErrorActionPreference = $oldE
if ($eex -eq 0) {
  Write-Host "Reusing DB subnet group: $SubnetGroupName" -ForegroundColor Cyan
} else {
  & aws rds create-db-subnet-group --profile $ProfileName --region $Region `
    --db-subnet-group-name $SubnetGroupName `
    --db-subnet-group-description "procoreconnect Path A" `
    --subnet-ids $subnetA $subnetB
  if ($LASTEXITCODE -ne 0) { throw "create-db-subnet-group failed" }
  Write-Host "Created DB subnet group: $SubnetGroupName" -ForegroundColor Green
}

# --- RDS instance
$oldE2 = $ErrorActionPreference
$ErrorActionPreference = "SilentlyContinue"
$st = & aws rds describe-db-instances --profile $ProfileName --region $Region --db-instance-identifier $DbInstanceId --query "DBInstances[0].DBInstanceStatus" --output text 2>$null
$ErrorActionPreference = $oldE2
if ($LASTEXITCODE -eq 0 -and $st -and $st -ne "None" -and $st.Trim() -ne "") {
  $ep = (& aws rds describe-db-instances --profile $ProfileName --region $Region --db-instance-identifier $DbInstanceId `
    --query "DBInstances[0].Endpoint.Address" --output text)
  Write-Warning "RDS $DbInstanceId already exists (status: $st). Not modifying. Endpoint: $ep"
} else {
  & aws rds create-db-instance --profile $ProfileName --region $Region `
    --db-instance-identifier $DbInstanceId `
    --db-instance-class db.t3.micro `
    --engine postgres `
    --master-username $MasterUsername `
    --master-user-password $plainPw `
    --allocated-storage 20 `
    --storage-type gp3 `
    --no-publicly-accessible `
    --no-multi-az `
    --db-name $InitialDbName `
    --vpc-security-group-ids $rdsSg `
    --db-subnet-group-name $SubnetGroupName `
    --backup-retention-period 1 `
    --tags "Key=Name,Value=procoreconnect-rds" "Key=app,Value=procoreconnect"
  if ($LASTEXITCODE -ne 0) { throw "create-db-instance failed" }
  Write-Host "create-db-instance submitted. Provisioning can take 5–15 minutes." -ForegroundColor Green
}

# --- show endpoint
$epAddr = $null
$st2 = "unknown"
for ($i = 0; $i -lt 60; $i++) {
  $st2 = (& aws rds describe-db-instances --profile $ProfileName --region $Region --db-instance-identifier $DbInstanceId --query "DBInstances[0].DBInstanceStatus" --output text 2>$null)
  if ($LASTEXITCODE -ne 0) { break }
  $epAddr = (& aws rds describe-db-instances --profile $ProfileName --region $Region --db-instance-identifier $DbInstanceId --query "DBInstances[0].Endpoint.Address" --output text)
  if ($st2 -eq "available" -and $epAddr -and $epAddr -ne "None") { break }
  Write-Host "  RDS status: $st2 (waiting for endpoint...)" -ForegroundColor DarkGray
  Start-Sleep -Seconds 15
}

Write-Host ""
Write-Host "==== RDS ====" -ForegroundColor Magenta
Write-Host "DB instance id:  $DbInstanceId" -ForegroundColor Magenta
Write-Host "Engine DB name:  $InitialDbName" -ForegroundColor Magenta
Write-Host "Instance status: $st2" -ForegroundColor Magenta
if ($epAddr -and $epAddr -ne "None") {
  Write-Host "Endpoint:        $epAddr" -ForegroundColor Magenta
} else {
  Write-Host ('Endpoint:        (not ready yet; check EC2 > RDS in console or re-run: aws rds describe-db-instances --db-instance-identifier {0})' -f $DbInstanceId) -ForegroundColor Yellow
}
Write-Host "Username:        $MasterUsername" -ForegroundColor Magenta
Write-Host ""
Write-Host "Set on the app host (EC2 .env or secrets):"
Write-Host "  DATABASE_HOST=$epAddr"
Write-Host "  DATABASE_PORT=5432"
Write-Host "  DATABASE_USERNAME=$MasterUsername"
Write-Host "  PROCORECONNECT_DATABASE_PASSWORD=<use .rds-creds.local or your -MasterPassword>"
Write-Host "==== then path-a-03-ecr.ps1 (or push images per runbook) ====" -ForegroundColor Magenta
