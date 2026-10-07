#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Automated deployment script for Ubuntu development VM in vnet-westus2-1
    
.DESCRIPTION
    Deploys the dev-ubuntu-001 VM with all necessary configurations for Python development
    including Git support, Docker, VS Code Server, and three project repositories.
    
.PARAMETER ResourceGroup
    Azure resource group name (default: DefaultResourceGroup-westus2)
    
.PARAMETER TemplateFile
    Path to Bicep template file (default: vsc-remote/main.bicep)
    
.PARAMETER ParametersFile
    Path to parameters file (default: vsc-remote/parameters.json)
    
.EXAMPLE
    .\deploy.ps1
    
.EXAMPLE
    .\deploy.ps1 -ResourceGroup "MyResourceGroup"
#>

param(
    [string]$ResourceGroup = "DefaultResourceGroup-westus2",
    [string]$Location = "westus2",
    [string]$TemplateFile = "vsc-remote/main.bicep",
    [string]$ParametersFile = "vsc-remote/parameters.json"
)

$ErrorActionPreference = "Stop"

# Colors for output
$InfoColor = "Cyan"
$SuccessColor = "Green"
$ErrorColor = "Red"
$WarningColor = "Yellow"

function Write-Info {
    param([string]$Message)
    Write-Host $Message -ForegroundColor $InfoColor
}

function Write-Success {
    param([string]$Message)
    Write-Host $Message -ForegroundColor $SuccessColor
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "ERROR: $Message" -ForegroundColor $ErrorColor
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "WARNING: $Message" -ForegroundColor $WarningColor
}

# Banner
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗"
Write-Host "║     Ubuntu Development VM Deployment - vnet-westus2-1      ║"
Write-Host "╚════════════════════════════════════════════════════════════╝"
Write-Host ""

# Step 1: Validate prerequisites
Write-Info "Step 1: Validating prerequisites..."

try {
    $account = az account show --query "{subscriptionId:id, name:name}" -o json | ConvertFrom-Json
    Write-Success "✓ Azure CLI authenticated"
    Write-Info "  Subscription: $($account.name) ($($account.subscriptionId))"
}
catch {
    Write-Error-Custom "Azure CLI not authenticated. Run 'az login' first."
    exit 1
}

# Verify resource group exists
try {
    $rg = az group show --name $ResourceGroup --query "name" -o tsv
    Write-Success "✓ Resource group exists: $rg"
}
catch {
    Write-Error-Custom "Resource group '$ResourceGroup' not found."
    exit 1
}

# Verify template files exist
if (-not (Test-Path $TemplateFile)) {
    Write-Error-Custom "Template file not found: $TemplateFile"
    exit 1
}
Write-Success "✓ Bicep template found: $TemplateFile"

if (-not (Test-Path $ParametersFile)) {
    Write-Error-Custom "Parameters file not found: $ParametersFile"
    exit 1
}
Write-Success "✓ Parameters file found: $ParametersFile"

# Verify vnet exists
Write-Info ""
Write-Info "Step 2: Verifying virtual network..."

try {
    $vnet = az network vnet show --resource-group $ResourceGroup --name "vnet-westus2-1" --query "name" -o tsv
    Write-Success "✓ vnet-westus2-1 exists"
}
catch {
    Write-Error-Custom "Virtual network 'vnet-westus2-1' not found in resource group."
    exit 1
}

# Check quotas
Write-Info ""
Write-Info "Step 3: Checking vCPU quotas..."

try {
    $quota = az vm list-usage --location $Location --query "[?name.value=='standardDSv3Family'].limit" -o tsv
    if ($quota -gt 0) {
        Write-Success "✓ vCPU quota available: $quota vCPUs"
    }
    else {
        Write-Error-Custom "No vCPU quota available for Standard_D series."
        exit 1
    }
}
catch {
    Write-Warning-Custom "Could not verify quota. Proceeding with deployment anyway."
}

# Step 4: Deploy infrastructure
Write-Info ""
Write-Info "Step 4: Deploying VM infrastructure..."
Write-Host "  Template: $TemplateFile"
Write-Host "  Parameters: $ParametersFile"
Write-Host ""

try {
    $deploymentName = "dev-ubuntu-$(Get-Random -Minimum 1000 -Maximum 9999)"
    
    Write-Info "Deployment started (name: $deploymentName)..."
    Write-Info "This may take 10-15 minutes. Please wait..."
    Write-Host ""
    
    $deployment = az deployment group create `
        --resource-group $ResourceGroup `
        --template-file $TemplateFile `
        --parameters $ParametersFile `
        --query "properties.outputs" -o json | ConvertFrom-Json
    
    Write-Success "✓ Deployment completed successfully!"
}
catch {
    Write-Error-Custom "Deployment failed: $_"
    exit 1
}

# Extract outputs
Write-Info ""
Write-Info "Step 5: Retrieving deployment outputs..."

try {
    $vmId = $deployment.vmId.value
    $vmName = $deployment.vmName.value
    $adminUser = $deployment.adminUsername.value
    $privateIP = $deployment.nicPrivateIP.value
    $sshCommand = $deployment.sshCommand.value
    $vsCodeConfig = $deployment.vscodeRemoteSSHConfig.value
    
    Write-Success "✓ VM deployed successfully!"
    Write-Host ""
    Write-Host "VM Details:"
    Write-Host "  VM Name:        $vmName"
    Write-Host "  VM ID:          $vmId"
    Write-Host "  Admin User:     $adminUser"
    Write-Host "  Private IP:     $privateIP"
}
catch {
    Write-Error-Custom "Failed to extract deployment outputs: $_"
    exit 1
}

# Step 6: Display next steps
Write-Host ""
Write-Success "════════════════════════════════════════════════════════════"
Write-Success "                    DEPLOYMENT COMPLETE!"
Write-Success "════════════════════════════════════════════════════════════"
Write-Host ""

Write-Host "SSH Access:" -ForegroundColor Yellow
Write-Host "  Command: $sshCommand"
Write-Host ""

Write-Host "VS Code Remote SSH Configuration:" -ForegroundColor Yellow
Write-Host "Add to ~/.ssh/config on Windows:"
Write-Host ""
Write-Host $vsCodeConfig
Write-Host ""

Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Test SSH connectivity:"
Write-Host "     $sshCommand 'echo SSH Connected'"
Write-Host ""
Write-Host "  2. Configure Git SSH authentication (see DEPLOYMENT_GUIDE.md)"
Write-Host ""
Write-Host "  3. Clone private repositories"
Write-Host ""
Write-Host "  4. Set up Python virtual environments"
Write-Host ""
Write-Host "  5. Connect with VS Code Remote SSH"
Write-Host ""

Write-Host "Documentation:" -ForegroundColor Yellow
Write-Host "  - DEPLOYMENT_GUIDE.md   : Detailed step-by-step guide"
Write-Host "  - main.bicep            : Infrastructure template"
Write-Host "  - parameters.json       : Deployment parameters"
Write-Host ""

# Save outputs to file
Write-Info "Saving deployment outputs to vsc-remote/deployment-outputs.txt..."

$outputContent = @"
Ubuntu Development VM - Deployment Outputs
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

VM DETAILS:
-----------
VM Name:        $vmName
VM ID:          $vmId
Admin User:     $adminUser
Private IP:     $privateIP
Resource Group: $ResourceGroup
Location:       $Location

SSH CONNECTION:
---------------
$sshCommand

SSH CONFIG (add to ~/.ssh/config):
-----------------------------------
$vsCodeConfig

NEXT STEPS:
-----------
1. Verify SSH connectivity
2. Configure Git SSH authentication
3. Clone repositories (py-lab, tars, jira-automation)
4. Set up Python virtual environments
5. Connect with VS Code Remote SSH

For detailed instructions, see: DEPLOYMENT_GUIDE.md
"@

$outputContent | Out-File -FilePath "vsc-remote/deployment-outputs.txt" -Encoding UTF8
Write-Success "✓ Outputs saved to vsc-remote/deployment-outputs.txt"

Write-Host ""
Write-Success "Deployment script completed successfully!"
Write-Host ""
