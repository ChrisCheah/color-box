param vmName string = 'dev-ubuntu-001'
param vmSize string = 'Standard_D2s_v3'
param location string = resourceGroup().location
param vnetName string = 'vnet-westus2-1'
param subnetName string = 'default'
param sshPublicKey string
param adminUsername string = 'azureuser'
param nsgName string = '${vmName}-nsg'
param nicName string = '${vmName}-nic'

// Get reference to existing vnet
resource existingVnet 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: vnetName
}

// Get reference to existing subnet
resource existingSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' existing = {
  parent: existingVnet
  name: subnetName
}

// Create Network Security Group
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowSSHInbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          // Laptop uses DHCP within the corporate 10.247.0.0/16 range; allow the whole range
          sourceAddressPrefix: '10.247.0.0/16'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowHTTPSOutbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
    ]
  }
}

// Create Network Interface
resource nic 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: existingSubnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}

// Cloud-init script for development environment setup
var cloudInit = base64('''#!/bin/bash
set -e
apt-get update
apt-get upgrade -y
apt-get install -y build-essential curl wget git openssh-client openssh-server python3 python3-pip python3-venv python3-dev nodejs npm vim nano htop net-tools jq unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release
usermod -aG docker azureuser || true
mkdir -p /home/azureuser/projects
chown -R azureuser:azureuser /home/azureuser/projects
cd /home/azureuser/projects
sudo -u azureuser git config --global core.editor "nano"
sudo -u azureuser git config --global pull.rebase false
cat > /home/azureuser/projects/README-SETUP.md << 'EOF'
# Ubuntu Development VM - Setup Guide

## Project Directory
All projects are cloned to: `/home/azureuser/projects/`

## Setup Instructions for Private Repos

Before cloning private Git repositories, configure SSH authentication:

### Step 1: Copy your SSH key to the VM
From your Windows laptop, copy your GitHub SSH private key:

```bash
scp -i dev-vm-access -r C:\\Users\\<YourUser>\\.ssh\\id_ed25519* azureuser@<VM_PRIVATE_IP>:/home/azureuser/.ssh/
```

### Step 2: Set correct permissions
On the VM:
```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

### Step 3: Configure SSH for Git
```bash
ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts
```

### Step 4: Test Git SSH connection
```bash
ssh -T git@github.com
```

### Step 5: Clone the private repositories
```bash
cd ~/projects
git clone git@github.com:your-org/py-lab.git
git clone git@github.com:your-org/tars.git
git clone git@github.com:your-org/jira-automation.git
```

## Python Virtual Environments

For each project directory:

```bash
cd ~/projects/py-lab
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

## Connect from Windows Laptop

### Prerequisites
- SSH client (built-in on Windows 10+)
- VS Code with Remote - SSH extension
- Private key: `dev-vm-access` (in vsc-remote folder)

### Connect via SSH
```bash
ssh -i dev-vm-access azureuser@<VM_PRIVATE_IP>
```

### Connect via VS Code Remote SSH
1. Install "Remote - SSH" extension in VS Code
2. Add to `~/.ssh/config`:

```
Host dev-ubuntu-001
  HostName <VM_PRIVATE_IP>
  User azureuser
  IdentityFile "C:\\Users\\<YourUser>\\git\\py-lab\\azure_network\\vsc-remote\\dev-vm-access"
  StrictHostKeyChecking no
```

3. In VS Code, press Ctrl+Shift+P → "Remote-SSH: Connect to Host" → select `dev-ubuntu-001`

## Useful Commands

### Check Docker
```bash
docker run hello-world
```

### Check Python
```bash
python3 --version
pip list
```

### Check Node.js
```bash
node --version
npm --version
```

### Monitor system
```bash
htop
df -h
```
EOF
chown azureuser:azureuser /home/azureuser/projects/README-SETUP.md
systemctl enable ssh
systemctl start ssh
echo "Setup completed successfully!"
''')


// Create Virtual Machine
resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
        provisionVMAgent: true
      }
      customData: cloudInit
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        diskSizeGB: 32
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: {
            primary: true
          }
        }
      ]
    }
  }
}

// Outputs
output vmId string = vm.id
output nicPrivateIP string = nic.properties.ipConfigurations[0].properties.privateIPAddress
output vmName string = vmName
output adminUsername string = adminUsername
output sshCommand string = 'ssh -i dev-vm-access ${adminUsername}@${nic.properties.ipConfigurations[0].properties.privateIPAddress}'
output vscodeRemoteSSHConfig string = '''Host ${vmName}
  HostName ${nic.properties.ipConfigurations[0].properties.privateIPAddress}
  User ${adminUsername}
  IdentityFile dev-vm-access
  StrictHostKeyChecking no'''
