# Manual TLS/SSL Setup for Kubernetes Gateway (CaaS)

## Context
You are configuring TLS/SSL for a Kubernetes Gateway in Intel CaaS using a **manual certificate workflow**.

⚠️ This method is **not recommended for production**.

---

## Objective
Enable HTTPS termination on a Kubernetes Gateway using a manually obtained certificate and Kubernetes TLS secret.

---

## Inputs Required
- DNS alias for the gateway (must match certificate)
- Access to https://certs.intel.com/
- Kubernetes namespace
- OpenSSL CLI installed
- Certificate password (set during download)

---

## Step-by-Step Instructions

### 1. Request Certificate
- Go to https://certs.intel.com/
- Request a certificate with:
  - DNS alias included
- During download:
  - Use **PEM (OpenSSL) format**
  - Enable:
    - Root Chain
    - Private Key
    - Chain Order = End Entity First
    - Extract PEM into separate files (.crt, .key)
  - Set a password

---

### 2. Extract Certificate Files
After download and unzip, verify:
- `.crt` → certificate
- `*chain.pem` → CA intermediaries + root CA
- `.key` → encrypted private key

If `chain.pem` not present:
- Manually combine:
  - Intermediates (e.g., Intel Internal Issuing CA)
  - Root CA
- Use a text editor to merge into one file

---

### 3. Decrypt Private Key
Run:

```bash
openssl rsa -in [ENCRYPTED-KEY] -out [UNENCRYPTED-KEY]
```

- Provide password when prompted

---

### 4. Combine Certificate and Chain
- Merge files into one `.crt` file:
  - Certificate (.crt) **first**
  - Then certificate chain (*chain.pem)

---

### 5. Create Kubernetes TLS Secret
Run:

```bash
kubectl create secret -n <NAMESPACE> tls <SECRET_NAME>   --cert=path/to/cert-and-chain.crt   --key=path/to/unencrypted-key.key
```

---

### 6. Update Gateway Configuration

Modify `gateway.yaml`:

```yaml
- name: https
  port: 9443
  protocol: HTTPS
  tls:
    mode: Terminate
    certificateRefs:
      - name: <SECRET_NAME>
```

---

### 7. Apply Updated Configuration

```bash
kubectl -n <NAMESPACE> apply -f gateway.yaml
```

---

### 8. Validate HTTPS Access

```bash
curl https://<DNS_ALIAS>.intel.com
```

---

## Expected Outcome
- Kubernetes Gateway serves traffic over HTTPS
- TLS is terminated using provided secret
- HTTP requests are redirected to HTTPS

---

## Constraints / Notes
- Certificate DNS must match gateway hostname
- Chain order must be: End entity → intermediates → root
- Private key must be unencrypted before use
- Not suitable for production use

---

## Output Artifacts
- Kubernetes TLS Secret
- Updated `gateway.yaml`
- HTTPS-enabled Gateway endpoint
