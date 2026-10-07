// Temporary validation VM aligned with DEPLOYMENT_GUIDE.md (azureuser + dev-vm-access key).
// Adds NSG rules + HTTP/HTTPS listeners so the full test matrix can be validated live:
//   Inbound  (from 10.247.0.0/16): ICMP ping, SSH 22, HTTP 80, HTTPS 443
//   Outbound (Azure default AllowInternet/AllowVnet): HTTP/HTTPS to internal + external IPs
param vmName string = 'val-falcon-vm'
param vmSize string = 'Standard_D2s_v3'
param location string = resourceGroup().location
param vnetName string
param subnetName string
param sshPublicKey string
param adminUsername string = 'azureuser'
param laptopSourcePrefix string = '10.247.0.0/16'
param nsgName string = '${vmName}-nsg'
param nicName string = '${vmName}-nic'

resource existingVnet 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: vnetName
}

resource existingSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' existing = {
  parent: existingVnet
  name: subnetName
}

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
          sourceAddressPrefix: laptopSourcePrefix
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowHTTPInbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: laptopSourcePrefix
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowHTTPSInbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: laptopSourcePrefix
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowICMPInbound'
        properties: {
          protocol: 'Icmp'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: laptopSourcePrefix
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 130
          direction: 'Inbound'
        }
      }
    ]
  }
}

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

// Minimal cloud-init: persistent HTTP:80 and HTTPS:443 listeners (self-signed cert) for inbound tests.
var cloudInit = base64('''#!/bin/bash
set -e
mkdir -p /opt/val/https
openssl req -x509 -nodes -newkey rsa:2048 -keyout /opt/val/https/key.pem -out /opt/val/https/cert.pem -subj "/CN=val" -days 2
cat > /etc/systemd/system/pyhttp80.service << 'EOF'
[Unit]
Description=HTTP 80 validation listener
After=network.target
[Service]
ExecStart=/usr/bin/python3 -m http.server 80 --bind 0.0.0.0
Restart=always
[Install]
WantedBy=multi-user.target
EOF
cat > /etc/systemd/system/tls443.service << 'EOF'
[Unit]
Description=HTTPS 443 validation listener
After=network.target
[Service]
ExecStart=/usr/bin/openssl s_server -accept 443 -cert /opt/val/https/cert.pem -key /opt/val/https/key.pem -www
Restart=always
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now pyhttp80.service
systemctl enable --now tls443.service
echo "validation listeners started"
''')

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

output vmName string = vmName
output nicPrivateIP string = nic.properties.ipConfigurations[0].properties.privateIPAddress
output sshCommand string = 'ssh -i dev-vm-access ${adminUsername}@${nic.properties.ipConfigurations[0].properties.privateIPAddress}'
