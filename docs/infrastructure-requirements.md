# Infrastructure & Software Requirements
## maintenance-receive-apply Agent — Control Node & z/OS Managed Node

**Generated:** 2026-06-11  
**Ansible core:** 2.14.18 | **Python (control node):** 3.9.25  
**Playbook:** `ansible/playbooks/internet-maintenance.yml`

---

## 1. Control Node (Linux)

The control node is the Linux workstation or server from which Ansible playbooks are executed. It requires no z/OS software — all z/OS interaction happens remotely over SSH.

### 1.1 Core Software

| Component | Required Version | Installed Version | Notes |
|-----------|-----------------|-------------------|-------|
| **Python** | ≥ 3.9 | 3.9.25 | Ansible runtime dependency |
| **Ansible core** | ≥ 2.14 | 2.14.18 | Automation engine |
| **pip / pip3** | Any | — | Required to install Ansible |

Install Ansible:
```bash
pip3 install ansible==7.7.0
```

### 1.2 Ansible Collections

| Collection | Required Version | Installed Version | Purpose |
|------------|-----------------|-------------------|---------|
| **ibm.ibm_zos_core** | ≥ 1.9.0, < 2.0.0 | 1.16.0 | z/OS job submit, copy, query, output modules |
| **ibm.ibm_zosmf** | ≥ 1.6.0 | 1.6.0 | z/OSMF REST API integration (optional path) |
| **community.general** | ≥ 7.0.0, < 10.0.0 | 6.6.2 | Utility modules |

Install all collections:
```bash
ansible-galaxy collection install -r ansible/requirements.yml
```

### 1.3 SSH Key

| Item | Path | Notes |
|------|------|-------|
| Private key | `~/.ssh/id_zos` | Ed25519 or RSA; must be authorised on all z/OS target LPARs |
| Public key | `~/.ssh/id_zos.pub` | Added to `~/.ssh/authorized_keys` on z/OS for each userid |

Generate key:
```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_zos -C "ansible-zos"
```

### 1.4 Ansible Vault

Sensitive credentials (`zmf_user`, `zmf_password`, vendor portal tokens) are stored encrypted using Ansible Vault.

| Item | Path | Notes |
|------|------|-------|
| Vault password file | `ansible/.vault_pass` | chmod 600; listed in `.gitignore` |
| Encrypted vars | `inventory/group_vars/all/vault.yml` | Contains `vault_zmf_user`, `vault_zmf_password` |

Create vault file:
```bash
echo "your-vault-password" > ansible/.vault_pass
chmod 600 ansible/.vault_pass
ansible-vault create inventory/group_vars/all/vault.yml
```

### 1.5 Directory Layout

```
ansible/
├── ansible.cfg                    ← SSH settings, vault path, collections path
├── requirements.yml               ← Collection dependencies
├── .vault_pass                    ← Gitignored, chmod 600
├── inventory/
│   ├── hosts.yml                  ← LPAR inventory (dcuf, dev1, stage1, prod1…)
│   └── group_vars/all/main.yml    ← All environment variables, SMP/E config
├── playbooks/
│   └── internet-maintenance.yml   ← Main agent playbook
├── templates/                     ← Jinja2 JCL templates (one per vendor/phase)
└── logs/                          ← Generated reports and audit JSON files
```

---

## 2. z/OS Managed Node

The z/OS LPAR is the target system where SMP/E operations execute. Ansible connects over SSH and submits JCL jobs via JES2.

### 2.1 Operating System

| Requirement | Minimum | In Use (DCUF) |
|-------------|---------|--------------|
| **z/OS** | V2R3 | V2R4 (z/OS 2.4) |
| **SMP/E** | 37.35 | 37.35 |
| **JES2** | Any | Active spool — job submissions via JES2 internal reader |

### 2.2 USS Software Stack

All components must be installed in z/OS Unix System Services (USS).

| Component | Product ID | Path | Version | Purpose |
|-----------|-----------|------|---------|---------|
| **IBM Open Enterprise SDK for Python** | 5655-PYT | `/usr/lpp/IBM/cyp/v3r13/pyz/` | 3.13 | `ansible_python_interpreter` — executes Ansible modules on z/OS |
| **IBM Z Open Automation Utilities (ZOAU)** | 5698-PA1 | `/usr/lpp/IBM/zoau/v1r3/` | v1r3 | Python bindings used by `ibm_zos_core` modules; provides `zos_*` CLI tools |
| **Java J21.0_64** | — | `/usr/lpp/java/J21.0_64/` | 21.0 | SMP/E HTTPS client for **IBM** internet delivery (`RECEIVE ORDER`) |
| **Java J8.0** | — | `/usr/lpp/java/J8.0/` | 8.0 | SMP/E HTTPS client for **Broadcom** and **BMC** internet delivery |
| **z/OS OpenSSH** | — | `/usr/lpp/OS390/OPENSSH/` | Any | SSH daemon — Ansible connects exclusively via SSH |

### 2.3 z/OS Environment Variables

These must be active when Ansible modules run. They are injected by the `/tmp/zos_shell.sh` wrapper script (bootstrapped by the playbook's `raw:` pre-task) because z/OS SSH non-login sessions do **not** source `~/.profile`.

| Variable | Value | Why Required |
|----------|-------|-------------|
| `_BPXK_AUTOCVT` | `ON` | Enables automatic EBCDIC/ASCII conversion for USS files |
| `ZOAU_HOME` | `/usr/lpp/IBM/zoau/v1r3` | Root path for ZOAU binaries and libraries |
| `PATH` | `ZOAU/bin:Python/bin:/bin:/usr/bin` | Makes `zoau` and `python3` commands available |
| `LIBPATH` | `ZOAU/lib:Python/lib:/lib:/usr/lib:.` | Shared library resolution for ZOAU and Python |
| `PYTHONPATH` | `/usr/lpp/IBM/zoau/v1r3/lib/3.13` | ZOAU Python bindings for Python 3.13 |
| `_CEE_RUNOPTS` | `FILETAG(AUTOCVT,AUTOTAG) POSIX(ON)` | Language Environment: enables POSIX mode and auto file tagging |
| `_TAG_REDIR_ERR/IN/OUT` | `txt` | Tags redirected I/O as text to prevent binary corruption |
| `LANG` | `C` | Avoids EBCDIC collation issues in string operations |

### 2.4 RACF Requirements

| Item | Value | Purpose |
|------|-------|---------|
| **Ansible userid** | `syssa69` | Submits JCL jobs; must have RACF READ on SMP/E datasets |
| **SMP/E job userid** | — | Must have READ on all CSI and target zone datasets |
| **APF authorisation** | Not required | SMP/E runs as a standard batch job |

#### RACF Keyrings for Vendor SSL (SMP/E HTTPS client)

| Vendor | Keyring | Type | Purpose |
|--------|---------|------|---------|
| IBM (integrity check) | `FTPACS/DCUFSMPE_SECINTKEYRING` | Server CA trust | Verifies IBM ECC server certificate |
| IBM (client cert) | `FTPACS/DCUFSMPE_KEYRING` | Client certificate | Authenticates to IBM download service |
| Broadcom | `FTPACS/BCOMSMPE_KEYRING` | Client certificate | Authenticates to Broadcom delivery API |
| BMC | `FTPACS/BMCSMPE_KEYRING` | Client certificate | Authenticates to BMC support portal |

Vendor CA certificates must be imported into these keyrings before the first `RECEIVE ORDER`.

### 2.5 USS Filesystem

| Path | Purpose | Notes |
|------|---------|-------|
| `/maint_zfs/` | SMPNTS staging root — SMP/E downloads vendor packages here | Must exist and be writable before first run; cleaned by `DELETEPKG` after each RECEIVE |
| `/maint_zfs/ibm/smpnts` | IBM SMPNTS credential file | chmod 600; contains IBMID/CUSTOMER/ICRTOKEN |
| `/maint_zfs/broadcom/smpnts` | Broadcom SMPNTS credential file | chmod 600; contains BCSID/CUSTOMER/PASSWORD |
| `/maint_zfs/bmc/smpnts` | BMC SMPNTS credential file | chmod 600; contains BMCID/CUSTOMER/PASSWORD |
| `/tmp/imr_*.jcl` | Temporary rendered JCL files | Written by Ansible before job submission; cleaned up after |
| `/tmp/zos_shell.sh` | Ansible shell wrapper | Auto-created by playbook `raw:` pre-task on each run |

---

## 3. SSH Connection Architecture

```
┌─────────────────────────────────────────────────┐
│  Control Node (Linux)                           │
│                                                 │
│  ansible-playbook internet-maintenance.yml      │
│        │                                        │
│        │  SSH (port 22)                         │
│        │  Key: ~/.ssh/id_zos                    │
│        │  ControlMaster=auto                    │
│        │  ControlPersist=60s                    │
└────────┼────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────┐
│  z/OS LPAR (dcuf — 138.69.218.201)             │
│                                                 │
│  z/OS OpenSSH daemon                           │
│        │                                        │
│        ▼                                        │
│  /tmp/zos_shell.sh   ← shell wrapper            │
│  (sets BPXK_AUTOCVT, ZOAU, PATH, etc.)         │
│        │                                        │
│        ▼                                        │
│  /bin/sh + Python 3.13 (AnsiballZ modules)     │
│        │                                        │
│        ▼                                        │
│  ibm_zos_core modules:                         │
│    zos_copy   → uploads JCL to /tmp/*.jcl      │
│    zos_job_submit → submits to JES2 reader     │
│    zos_job_query  → polls until RC not None    │
│    zos_job_output → retrieves spool (SMPRPT)   │
└─────────────────────────────────────────────────┘
```

### Key SSH Settings (`ansible.cfg`)

| Setting | Value | Reason |
|---------|-------|--------|
| `pipelining` | `False` | **Must be off.** Pipelining pipes binary AnsiballZ modules via stdin; `_TAG_REDIR_IN=txt` would trigger EBCDIC auto-conversion and corrupt the module binary |
| `ssh_args` | `-o ControlMaster=auto -o ControlPersist=60s` | SSH connection multiplexing — one TCP connection reused for all tasks; avoids repeated handshakes and key exchanges |
| `private_key_file` | `~/.ssh/id_zos` | Dedicated key for z/OS targets |
| `host_key_checking` | `False` | Disabled for managed lab environments |
| `timeout` | `60` | SSH connect timeout in seconds |
| `remote_tmp` | `/tmp/.ansible` | Temp directory for localhost-delegated tasks |

---

## 4. Vendor API Endpoints

All three vendors expose HTTPS REST APIs consumed by SMP/E's `RECEIVE ORDER` command (GIMSMP) running as a batch job on z/OS. Outbound HTTPS port 443 must be open from the z/OS LPAR to all three endpoints.

| Vendor | Order Server URL | Java Home | Authentication |
|--------|-----------------|-----------|---------------|
| **IBM** | `https://eccgw01.boulder.ibm.com/services/projects/ecc/ws/` | J21.0_64 | IBMID + ICRTOKEN (Shopz API token) |
| **Broadcom** | `https://eapi.broadcom.com/receiveorder` | J8.0 | BCSID + Portal password |
| **BMC** | `https://ws-prod.bmc.com/smpe` | J8.0 | BMCID + Support portal password |

> **IBM token generation:** IBM Shopz → *Manage API tokens* → generate `ICRTOKEN`  
> **Broadcom/BMC:** Standard portal credentials — avoid special characters that conflict with SMPNTS parsing

---

## 5. z/OSMF

z/OSMF is configured in `group_vars/all/main.yml` and used by the `ibm.ibm_zosmf` collection. It is **not** in the critical path for `internet-maintenance.yml` — that playbook uses direct SSH + JES2 job submission only.

| Setting | Value |
|---------|-------|
| Port | 443 |
| User | `{{ vault_zmf_user }}` (Ansible Vault encrypted) |
| Password | `{{ vault_zmf_password }}` (Ansible Vault encrypted) |
| Used by | `ibm.ibm_zosmf` collection (other playbooks) |

---

## 6. SMP/E Configuration Reference

| Variable | Value (DCUF) | Description |
|----------|-------------|-------------|
| `smpe_global_csi` | `SMPE.ZS24M27.R2006.GLOBAL.CSI` | Global CSI dataset |
| `smpe_proc` | `SMPEZS24` | SMP/E started task procedure |
| `smpe_proclib` | `SYS2.PROCLIB.DCUF` | Procedure library |
| `smpe_classpath` | `/usr/lpp/smp/classes` | SMP/E Java classpath |
| `smpe_bypass_holds` | `HOLDERROR,HOLDCLASS(DOC,FIXCAT)` | Default BYPASS operands for APPLY/ACCEPT |

---

## 7. Quick Setup Checklist

### Control Node
- [ ] Python 3.9+ installed
- [ ] Ansible core 2.14+ installed (`pip3 install ansible==7.7.0`)
- [ ] Collections installed (`ansible-galaxy collection install -r ansible/requirements.yml`)
- [ ] SSH key generated (`~/.ssh/id_zos`)
- [ ] SSH public key authorised on all target z/OS LPARs
- [ ] Vault password file created (`ansible/.vault_pass`, chmod 600)
- [ ] `ansible/.vault_pass` listed in `.gitignore`

### z/OS Managed Node
- [ ] z/OS V2R3+
- [ ] IBM Open Enterprise SDK for Python 3.x (5655-PYT) installed
- [ ] ZOAU v1r3+ (5698-PA1) installed
- [ ] Java J21.0_64 installed (IBM vendor)
- [ ] Java J8.0 installed (Broadcom/BMC vendors)
- [ ] z/OS OpenSSH daemon active
- [ ] Ansible userid (`syssa69`) SSH-authorised and has RACF access to SMP/E datasets
- [ ] `/maint_zfs/` USS directory created and writable
- [ ] SMPNTS credential files created per vendor (`chmod 600`)
- [ ] RACF keyrings populated with vendor CA certificates
- [ ] Outbound HTTPS (port 443) open to IBM, Broadcom, and BMC endpoints

---

*Source: `ansible/ansible.cfg`, `ansible/inventory/group_vars/all/main.yml`, `ansible/requirements.yml`*  
*Ansible core 2.14.18 | ibm.ibm_zos_core 1.16.0 | ibm.ibm_zosmf 1.6.0 | Python 3.9.25*
