# Ubuntu Development VM — Deployment & Connection Guide

Verified working setup for the `dev-ubuntu-001` development VM in `vnet-westus2-1`.

| Property | Value |
|----------|-------|
| VM Name | `dev-ubuntu-001` |
| Private IP | `10.160.38.68` |
| User | `azureuser` |
| OS | Ubuntu 22.04.5 LTS |
| VM Size | Standard_D2s_v3 (2 vCPU, 8 GB) |
| Location | West US 2 |
| SSH Key | `vsc-remote/dev-vm-access` |

Installed: Python 3.10.12 · Git 2.34.1 · Node.js 12.22.9 · VS Code 1.127.0

---

## Step 1: Deploy the VM

From the workspace root in PowerShell:

```powershell
$resourceGroup = "DefaultResourceGroup-westus2"

az deployment group create `
  --resource-group $resourceGroup `
  --template-file vsc-remote/main.bicep `
  --parameters vsc-remote/parameters.json
```

Retrieve the private IP after deployment:

```powershell
az vm show -d --resource-group $resourceGroup --name dev-ubuntu-001 `
  --query privateIps -o tsv
```

---

## Step 2: Configure SSH Access (Windows laptop)

Add to `~/.ssh/config`:

```
Host dev-ubuntu-001
  HostName 10.160.38.68
  User azureuser
  IdentityFile C:\Users\cheahchr\git\py-lab\azure_network\vsc-remote\dev-vm-access
```

Test the connection:

```powershell
ssh dev-ubuntu-001 "uname -a"
```

> If the VM was redeployed and you get a host-key warning:
> `ssh-keygen -R 10.160.38.68`

---

## Step 3: Git Authentication via Intel Proxy

The `intel-sandbox` org enforces a **GitHub IP allow list**. The VM's egress IP is not
allow-listed, so Git traffic must be routed through the Intel proxy
(`proxy-dmz.intel.com:911`), whose IP is allowed. This is already configured on the VM:

- **Proxy (persistent for all tools):** `/etc/profile.d/intel-proxy.sh`
- **Git proxy:** `http.proxy` / `https.proxy` → `http://proxy-dmz.intel.com:911`
- **Credentials:** `credential.helper=store` with a GitHub OAuth token in `~/.git-credentials`
- **Identity:** `Chris Cheah <chris.cheah@intel.com>`

Verify Git connectivity:

```powershell
ssh dev-ubuntu-001 "cd ~/projects/py-lab && git fetch && echo OK"
```

> If the token expires, refresh `~/.git-credentials` on the VM with a current token
> (from the laptop: `printf 'protocol=https\nhost=github.com\n\n' | git credential-manager get`).

---

## Step 4: Repositories

Cloned under `/home/azureuser/projects/`:

| Path | Repo |
|------|------|
| `py-lab` | `intel-sandbox/py-lab` |


To re-clone if needed (proxy already configured):

```powershell
ssh dev-ubuntu-001 "cd ~/projects && git clone https://github.com/intel-sandbox/py-lab.git"
```

---

## Step 5: Python Virtual Environments

Each repo has its own `.venv` (Python 3.10):

- `py-lab/.venv`

Activate one:

```bash
source ~/projects/py-lab/.venv/bin/activate
```

Recreate / install dependencies for a repo:

```bash
cd ~/projects/<repo>
python3 -m venv .venv && source .venv/bin/activate
pip install --upgrade pip
[ -f requirements.txt ] && pip install -r requirements.txt
[ -f pyproject.toml ] && pip install -e .
```

---

## Step 6: Install Visual Studio Code (on the VM)

VS Code is installed on the VM from the official Microsoft apt repository:

```bash
sudo apt-get install -y wget gpg apt-transport-https
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg
sudo install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
echo 'deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main' \
  | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
rm -f /tmp/packages.microsoft.gpg
sudo apt-get update
sudo apt-get install -y code
code --version
```

> Installs the `code` binary (VS Code + CLI). Enables `code tunnel` and local-repo tooling on the VM.

---

## Step 7: Connect with VS Code Remote-SSH

1. Install the **Remote - SSH** extension in VS Code.
2. `Ctrl+Shift+P` → **Remote-SSH: Connect to Host** → `dev-ubuntu-001`.
3. Open folder `/home/azureuser/projects`.
4. Select the repo's `.venv` interpreter when prompted.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| SSH connection refused | Confirm your laptop IP is within `10.247.0.0/16` (NSG allow-list) and private IP is `10.160.38.68`. |
| Host-key mismatch after redeploy | `ssh-keygen -R 10.160.38.68` |
| Git `403 IP allow list` | Proxy not applied — check `git config --global --get http.proxy` returns `proxy-dmz.intel.com:911`. |
| Git auth failed | OAuth token expired — refresh `~/.git-credentials` (see Step 3). |
| pip/npm can't reach internet | Load proxy env: `source /etc/profile.d/intel-proxy.sh`. |

---

## Cleanup

```powershell
$resourceGroup = "DefaultResourceGroup-westus2"

# Capture the OS disk name before deleting the VM
$osDisk = az vm show -g $resourceGroup -n dev-ubuntu-001 --query "storageProfile.osDisk.name" -o tsv

az vm delete --resource-group $resourceGroup --name dev-ubuntu-001 --yes
az network nic delete --resource-group $resourceGroup --name dev-ubuntu-001-nic
az network nsg delete --resource-group $resourceGroup --name dev-ubuntu-001-nsg
az disk delete --resource-group $resourceGroup --name $osDisk --yes
```

> Deleting a VM does **not** remove its OS disk — delete it explicitly (above) to avoid orphaned disks.

> **Keep `vsc-remote/dev-vm-access` (private key) secure — never commit it.**
