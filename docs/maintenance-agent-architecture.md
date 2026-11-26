# SMP/E Internet Maintenance Agent — Architecture & Deployment Guide

**Playbook:** `ansible/playbooks/internet-maintenance.yml`  
**Scope:** IBM, Broadcom, and BMC internet maintenance delivery via SMP/E `RECEIVE ORDER`  
**Last Updated:** 2026-06-12

---

## 1. Architecture Overview

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│  DEVELOPER WORKSTATION — Control Node (Linux / macOS / WSL2)                    │
│                                                                                  │
│  ┌─────────────────────────┐    ┌─────────────────────────────────────────────┐ │
│  │  VS Code 1.119.0        │    │  GitHub Copilot Chat (Claude Sonnet 4.6)    │ │
│  │  ─────────────────────  │    │  ─────────────────────────────────────────  │ │
│  │  • Z Open Editor        │    │  • maintenance-receive-apply agent mode     │ │
│  │    (IBM Z extension)    │    │  • Orchestrates vendor selection, input     │ │
│  │  • Ansible extension    │    │    collection, playbook execution           │ │
│  │  • YAML extension       │    │  • Interprets job results, reports issues   │ │
│  └────────────┬────────────┘    └─────────────────────────────────────────────┘ │
│               │                                                                  │
│  ┌────────────▼────────────────────────────────────────────────────────────────┐ │
│  │  Ansible Core 2.14.18 (Python 3.9.25)                                       │ │
│  │  ansible-playbook internet-maintenance.yml                                   │ │
│  │                                                                              │ │
│  │  Collections:                                                                │ │
│  │   • ibm.ibm_zos_core  1.16.0   ← zos_job_submit / query / output / copy    │ │
│  │   • ibm.ibm_zosmf     1.6.0    ← z/OSMF REST API (optional path)           │ │
│  │   • community.general 6.6.2    ← utility modules                           │ │
│  └────────────┬────────────────────────────────────────────────────────────────┘ │
│               │                                                                  │
│  ┌────────────▼────────────┐    ┌─────────────────────────────────────────────┐ │
│  │  Zowe CLI v3.4.1        │    │  OpenSSH 8.7p1                              │ │
│  │  (zowe plugin v8.31.1)  │    │  ~/.ssh/id_zos  (Ed25519 keypair)           │ │
│  │  • TSO commands         │    │  ControlMaster=auto  ControlPersist=60s     │ │
│  │  • USS file ops         │    │  Port 22 → z/OS OpenSSH                     │ │
│  │  • z/OSMF port 443      │    │                                             │ │
│  └────────────┬────────────┘    └──────────────────────┬──────────────────────┘ │
└───────────────┼──────────────────────────────────────  │  ────────────────────┘
                │  HTTPS  (port 443)                     │  SSH (port 22)
                │  z/OSMF REST API                       │  Ansible modules
                │                                        │
┌───────────────▼────────────────────────────────────────▼──────────────────────┐
│  z/OS LPAR — Managed Node  (DCUF — 138.69.218.201)                            │
│                                                                                │
│  ┌─────────────────────┐   ┌──────────────────────────────────────────────┐   │
│  │  z/OS OpenSSH       │   │  JES2 Spool                                  │   │
│  │  (port 22)          │   │  • IBMRCV  — SMP/E RECEIVE ORDER             │   │
│  │  /bin/sh wrapper    │   │  • IBMAPK  — SMP/E APPLY CHECK               │   │
│  └──────────┬──────────┘   │  • IBMAPL  — SMP/E APPLY                     │   │
│             │              │  • IBMACK  — SMP/E ACCEPT CHECK              │   │
│             ▼              │  • IBMACC  — SMP/E ACCEPT                    │   │
│  Python 3.13 (5655-PYT)   └──────────────────────────────────────────────┘   │
│  ZOAU v1r3  (5698-PA1)                                                        │
│             │              ┌──────────────────────────────────────────────┐   │
│             ▼              │  SMP/E → Vendor Internet (HTTPS port 443)    │   │
│  ibm_zos_core modules:     │  RECEIVE ORDER with ORDERSERVER(ORDSRVR)     │   │
│   zos_copy  (JCL → USS)    │  • esw.ibm.com / delivery.software.ibm.com   │   │
│   zos_job_submit           │  • delivery.broadcom.com                     │   │
│   zos_job_query  (poll)    │  • ftp.bmc.com / support.bmc.com             │   │
│   zos_job_output           │                                              │   │
│             │              │  SSL trust via RACF keyrings (AT-TLS)        │   │
│             ▼              └──────────────────────────────────────────────┘   │
│  /maint_zfs/               ┌──────────────────────────────────────────────┐   │
│    ibm/smpnts              │  SMP/E CSI (Global zone)                     │   │
│    broadcom/smpnts         │  ACSVS.TDMF.V5R11M0.ZOSMFA.GLOBAL.CSI       │   │
│    bmc/smpnts              │  TZONE (TARGET) / DZONE (DLIB)              │   │
│                            └──────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────────────────┘

Logs / Audit (Control Node — ansible/logs/):
   cycle_{vendor}_{csi}_receive.marker   ← prevents RECEIVE re-run this cycle
   cycle_{vendor}_{csi}_apply.marker     ← prevents APPLY re-run this cycle
   cycle_{vendor}_{csi}_accept.marker    ← marks cycle complete
   internet_receive_{vendor}_{ts}.json   ← raw zos_job_output (SMPOUT/SMPRPT)
   internet_apply_{vendor}_{ts}.json     ← raw zos_job_output
   internet_accept_{vendor}_{ts}.json    ← raw zos_job_output
   phase1_receive_*.md / phase2_applycheck_*.md / phase4_apply_*.md / phase5_accept_*.md
```

---

## 2. Component Versions

### 2.1 Control Node

| Component | Role | Version in Use | Minimum Required |
|-----------|------|---------------|-----------------|
| **OS** | Control node platform | Linux (RHEL/Ubuntu) | Any Linux / macOS / WSL2 |
| **Python** | Ansible runtime | 3.9.25 | 3.9 |
| **Ansible Core** | Automation engine | 2.14.18 | 2.12 |
| **VS Code** | IDE + agent surface | 1.119.0 | 1.90 |
| **GitHub Copilot Chat** | Agent orchestration (LLM) | Claude Sonnet 4.6 | — |
| **IBM Z Open Editor** | JCL/REXX syntax support, Zowe integration | Latest | 3.0 |
| **Zowe CLI** | z/OS USS / TSO / z/OSMF operations | v3.4.1 (plugin 8.31.1) | v2 |
| **OpenSSH** | Transport for Ansible modules | 8.7p1 / OpenSSL 3.5.1 | 7.4 |

### 2.2 Ansible Collections

| Collection | Purpose | Installed | Requirement |
|------------|---------|-----------|-------------|
| **ibm.ibm_zos_core** | `zos_job_submit`, `zos_job_query`, `zos_job_output`, `zos_copy` | 1.16.0 | ≥ 1.9.0, < 2.0.0 |
| **ibm.ibm_zosmf** | z/OSMF REST API modules (optional ACCEPT path) | 1.6.0 | ≥ 1.6.0 |
| **community.general** | Utility modules | 6.6.2 | ≥ 6.0.0 |

### 2.3 z/OS Managed Node

| Component | Product ID | Version in Use | Minimum |
|-----------|-----------|---------------|---------|
| **z/OS** | — | 2.4 (V2R4) | 2.3 (V2R3) |
| **SMP/E** | — | 37.35 | 37.00 |
| **JES2** | — | Active | Active |
| **z/OS OpenSSH** | — | System-level | Any |
| **IBM Open Enterprise SDK for Python** | 5655-PYT | 3.13 | 3.9 |
| **IBM Z Open Automation Utilities (ZOAU)** | 5698-PA1 | v1r3 | v1.2.2 |
| **Java (IBM maintenance)** | — | J21.0_64 | J8.0_64 |
| **Java (Broadcom / BMC maintenance)** | — | J8.0 | J8.0 |

---

## 3. Network Ports

| Direction | Source | Destination | Port | Protocol | Purpose |
|-----------|--------|-------------|------|----------|---------|
| Outbound | Control node | z/OS LPAR | **22** | TCP/SSH | Ansible module execution; JCL upload; job polling |
| Outbound | Control node | z/OS LPAR | **443** | HTTPS | Zowe CLI z/OSMF REST API (optional) |
| Outbound | z/OS LPAR | `esw.ibm.com` | **443** | HTTPS/TLS | SMP/E RECEIVE ORDER — IBM Shopz |
| Outbound | z/OS LPAR | `delivery.software.ibm.com` | **443** | HTTPS/TLS | IBM package download |
| Outbound | z/OS LPAR | `delivery.broadcom.com` | **443** | HTTPS/TLS | SMP/E RECEIVE ORDER — Broadcom |
| Outbound | z/OS LPAR | `ftp.bmc.com` | **443** | HTTPS/TLS | SMP/E RECEIVE ORDER — BMC |
| Outbound | z/OS LPAR | `support.bmc.com` | **443** | HTTPS/TLS | BMC support portal authentication |

> **Note:** All z/OS outbound HTTPS uses AT-TLS with RACF keyrings for certificate trust. No plain-text HTTP is used.

---

## 4. Execution Flow

```
Copilot Chat (agent mode)
        │
        │ 1. Collects: vendor / CSI DSN / TARGET zone / DLIB zone
        │
        ▼
ansible-playbook internet-maintenance.yml
        │
        ├─ PRE: Check cycle_accept.marker → if FOUND → end_play (cycle done)
        │
        ├─ PHASE 1: RECEIVE ORDER
        │   ├─ Check cycle_receive.marker → if FOUND → skip_receive=true
        │   ├─ Render JCL (smpe_receive_{vendor}.j2)
        │   ├─ zos_copy → upload /tmp/imr_receive.jcl to z/OS USS
        │   ├─ zos_job_submit (wait_time=30s)  → IBMRCV submitted
        │   ├─ zos_job_query LOOP (every 10s, max 4h) → poll until status≠AC
        │   ├─ capture apply_rc from poll result  ← reliable RC source
        │   ├─ zos_job_output → fetch SMPOUT/SMPRPT
        │   ├─ Status guard → fail if job still AC after output fetch
        │   ├─ Save audit log: internet_receive_{vendor}_{ts}.json
        │   └─ Write cycle_receive.marker
        │
        ├─ PHASE 2: APPLY CHECK
        │   ├─ Render JCL (smpe_apply_check.j2, apply_check_mode=true)
        │   ├─ zos_copy → upload → zos_job_submit → IBMAPK
        │   ├─ zos_job_query LOOP → poll → capture apply_rc → zos_job_output
        │   ├─ Parse SMPRPT for APPLIED PTF list (applycheck_approved_list)
        │   ├─ Python cross-check vs internet_apply_*.json / internet_accept_*.json
        │   ├─ applycheck_new_to_apply_count == 0?
        │   │   └─ YES → write cycle_accept.marker → end_play (nothing to apply)
        │   └─ Save audit log + phase report
        │
        ├─ PHASE 3: TECHNICIAN REVIEW GATE (pause prompt)
        │   └─ Technician types 'yes' to proceed or Ctrl+C to abort
        │
        ├─ PHASE 4: APPLY
        │   ├─ Render JCL (smpe_apply_check.j2, apply_check_mode=false)
        │   ├─ zos_copy → upload → zos_job_submit → IBMAPL
        │   ├─ zos_job_query LOOP → poll → capture apply_rc → zos_job_output
        │   ├─ Status guard + fail if RC > 4
        │   ├─ Parse applied SYSMOD list from SMPRPT
        │   ├─ Save audit log: internet_apply_{vendor}_{ts}.json
        │   └─ Write cycle_apply.marker
        │
        ├─ PHASE 5a: ACCEPT CHECK
        │   ├─ Render JCL (smpe_accept.j2, accept_check_mode=true)
        │   ├─ zos_copy → upload → zos_job_submit → IBMACK
        │   ├─ zos_job_query LOOP → poll → zos_job_output
        │   └─ Save phase report
        │
        ├─ PHASE 5b: TECHNICIAN REVIEW GATE (pause prompt — ACCEPT)
        │   └─ Technician types 'yes' or 'skip'
        │
        └─ PHASE 5c: ACCEPT
            ├─ Render JCL (smpe_accept.j2, accept_check_mode=false)
            ├─ zos_copy → upload → zos_job_submit → IBMACC
            ├─ zos_job_query LOOP → poll → capture accept_rc → zos_job_output
            ├─ Status guard + fail if RC > 4
            ├─ Save audit log: internet_accept_{vendor}_{ts}.json
            └─ Write cycle_accept.marker  ← marks full cycle complete
```

---

## 5. JCL Job Names

| Phase | IBM | Broadcom | BMC | Defined in |
|-------|-----|----------|-----|-----------|
| RECEIVE ORDER | `IBMRCV` | `BCMRCV` | `BMCRCV` | `smpe_receive_{vendor}.j2` |
| APPLY CHECK | `IBMAPK` | `BCMAPK` | `BMCAPK` | `smpe_apply_check.j2` |
| APPLY | `IBMAPL` | `BCMAPL` | `BMCAPL` | `smpe_apply_check.j2` |
| ACCEPT CHECK | `IBMACK` | `BCMACK` | `BMCACK` | `smpe_accept.j2` |
| ACCEPT | `IBMACC` | `BCMACC` | `BMCACC` | `smpe_accept.j2` |

Job name is controlled by `_vendor_jobpfx` (`IBM`/`BCM`/`BMC`) resolved at runtime from the `vendor` parameter.

---

## 6. Cycle State — Marker Files

Marker files live in `ansible/logs/` on the control node. They are keyed by **vendor + CSI DSN** (not date), so multiple products on the same day do not block each other.

| Marker | Written after | Prevents |
|--------|--------------|---------|
| `cycle_{vendor}_{csi_key}_receive.marker` | RECEIVE completes | Re-running RECEIVE ORDER |
| `cycle_{vendor}_{csi_key}_apply.marker` | APPLY completes (RC ≤ 4) | Re-running APPLY |
| `cycle_{vendor}_{csi_key}_accept.marker` | ACCEPT completes **or** APPLY CHECK confirms 0 new SYSMODs | Entire play (end_play) |

**Reset for a new refresh cycle:**
```bash
rm ansible/logs/cycle_ibm_acsvs_tdmf_v5r11m0_zosmfa_global_csi_*.marker
```

---

## 7. Fresh Environment Deployment

### 7.1 Prerequisites Checklist

**Control Node:**
- [ ] Linux (RHEL 8+, Ubuntu 20.04+) or macOS 13+, or WSL2
- [ ] Python ≥ 3.9 (`python3 --version`)
- [ ] pip3 (`python3 -m pip --version`)
- [ ] Git (`git --version`)
- [ ] VS Code 1.90+ with GitHub Copilot Chat extension
- [ ] IBM Z Open Editor extension (VS Code Marketplace)
- [ ] Network access to z/OS LPAR on port 22
- [ ] Network access to z/OSMF on port 443 (optional)

**z/OS Managed Node:**
- [ ] z/OS V2R3 or later
- [ ] IBM Open Enterprise SDK for Python 5655-PYT (3.9 minimum, 3.13 recommended)
- [ ] IBM Z Open Automation Utilities 5698-PA1 (v1.2.2 minimum)
- [ ] z/OS OpenSSH running and accepting key authentication
- [ ] Java for SMP/E internet delivery (J21.0_64 for IBM; J8.0 for Broadcom/BMC)
- [ ] `/maint_zfs/` USS directory created and writable
- [ ] RACF keyrings configured for vendor SSL trust (see Section 2.4)
- [ ] Ansible userid (e.g., `syssa69`) with RACF access to SMP/E datasets

---

### 7.2 Step-by-Step: Control Node Setup

#### Step 1 — Clone the repository

```bash
git clone https://github.com/your-org/applied-ai-software-delivery.git
cd applied-ai-software-delivery
```

#### Step 2 — Install Python dependencies

```bash
pip3 install ansible-core>=2.14
# Or install the full package:
pip3 install -r requirements.txt
```

#### Step 3 — Install Ansible collections

```bash
cd ansible
ansible-galaxy collection install -r requirements.yml
# Verify:
ansible-galaxy collection list | grep -E "ibm\.|community\."
```

Expected output:
```
ibm.ibm_zos_core   1.16.0
ibm.ibm_zosmf      1.6.0
community.general  6.6.2
```

#### Step 4 — Generate SSH keypair for z/OS

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_zos -C "ansible-zos-$(hostname)"
chmod 600 ~/.ssh/id_zos
```

Then add `~/.ssh/id_zos.pub` content to `~/.ssh/authorized_keys` on the z/OS LPAR for each Ansible userid.

Test connectivity:
```bash
ssh -i ~/.ssh/id_zos syssa69@138.69.218.201 'echo "SSH OK"'
```

#### Step 5 — Configure inventory

Edit `ansible/inventory/hosts.yml` — update `ansible_host` and `ansible_user`:

```yaml
staging:
  hosts:
    dcuf:
      ansible_host: <your-lpar-ip>
      ansible_user: <your-userid>
      lpar_name: DCUF
```

#### Step 6 — Configure `group_vars`

Create `ansible/inventory/group_vars/all/main.yml` with z/OS environment variables:

```yaml
# z/OS environment injected into every Ansible shell session
environment_vars:
  _BPXK_AUTOCVT:     "ON"
  ZOAU_HOME:          "/usr/lpp/IBM/zoau/v1r3"
  PATH:               "/usr/lpp/IBM/zoau/v1r3/bin:/usr/lpp/IBM/cyp/v3r13/pyz/bin:/bin:/usr/bin"
  LIBPATH:            "/usr/lpp/IBM/zoau/v1r3/lib:/usr/lpp/IBM/cyp/v3r13/pyz/lib:/lib:/usr/lib:."
  PYTHONPATH:         "/usr/lpp/IBM/zoau/v1r3/lib/3.13"
  _CEE_RUNOPTS:       "FILETAG(AUTOCVT,AUTOTAG) POSIX(ON)"
  _TAG_REDIR_ERR:     "txt"
  _TAG_REDIR_IN:      "txt"
  _TAG_REDIR_OUT:     "txt"
  LANG:               "C"
  ansible_python_interpreter: "/usr/lpp/IBM/cyp/v3r13/pyz/bin/python3"
```

> Adjust paths to match your ZOAU and Python installation directories.

#### Step 7 — Create Ansible Vault for credentials (optional)

```bash
echo "your-vault-password" > ansible/.vault_pass
chmod 600 ansible/.vault_pass

ansible-vault create ansible/inventory/group_vars/all/vault.yml
# Add: zmf_user, zmf_password, other secrets
```

#### Step 8 — Provision SMPNTS credential files on z/OS

SSH to the LPAR and create:

```bash
# IBM
mkdir -p /maint_zfs/ibm
cat > /maint_zfs/ibm/smpnts << 'EOF'
CREDENTIALS IBMID(your.ibmid@example.com)
            CUSTOMER(1234567)
            ICRTOKEN(your-shopz-api-token)
            COUNTRY(GB)
EOF
chmod 600 /maint_zfs/ibm/smpnts

# Broadcom
mkdir -p /maint_zfs/broadcom
cat > /maint_zfs/broadcom/smpnts << 'EOF'
CREDENTIALS BCSID(your.bcid@example.com)
            CUSTOMER(1234567)
            PASSWORD(your-broadcom-password)
            COUNTRY(GB)
EOF
chmod 600 /maint_zfs/broadcom/smpnts

# BMC
mkdir -p /maint_zfs/bmc
cat > /maint_zfs/bmc/smpnts << 'EOF'
CREDENTIALS BMCID(your.bmcid@example.com)
            CUSTOMER(1234567)
            PASSWORD(your-bmc-password)
            COUNTRY(GB)
EOF
chmod 600 /maint_zfs/bmc/smpnts
```

> Generate your IBM `ICRTOKEN` at IBM Shopz → Manage API tokens.

#### Step 9 — Install Zowe CLI (optional — for USS / z/OSMF operations)

```bash
npm install -g @zowe/cli
zowe config init --global-config
zowe profiles create zosmf myLPAR \
  --host 138.69.218.201 --port 443 \
  --user syssa69 --password "xxx" \
  --reject-unauthorized false
zowe zosmf check status
```

#### Step 10 — Validate the environment

```bash
cd ansible
ansible -i inventory/hosts.yml dcuf -m ping
```

Expected: `dcuf | SUCCESS => {"ping": "pong"}`

Run syntax check:
```bash
ansible-playbook --syntax-check playbooks/internet-maintenance.yml
```

Expected: `playbook: playbooks/internet-maintenance.yml`

#### Step 11 — Run your first maintenance cycle

```bash
ansible-playbook playbooks/internet-maintenance.yml \
  -e "vendor=ibm" \
  -e "smpe_csi_dsn=YOUR.PRODUCT.GLOBAL.CSI" \
  -e "smpe_target_zone_input=TZONE" \
  -e "smpe_dlib_zone_input=DZONE"
```

Or invoke via GitHub Copilot Chat in `maintenance-receive-apply` mode:
```
Hi
```
The agent will prompt for vendor, CSI, and zone interactively.

---

### 7.3 VS Code + IBM Z Open Editor Setup

1. Open VS Code → Extensions (`Ctrl+Shift+X`)
2. Install **IBM Z Open Editor** (Publisher: IBM)  
3. Install **GitHub Copilot** and **GitHub Copilot Chat**  
4. Open the workspace folder: `File → Open Folder → applied-ai-software-delivery/`
5. The `.github/copilot-instructions.md` and `.github/skills/` are auto-loaded by Copilot Chat

---

### 7.4 Verifying z/OS Prerequisites

SSH to the LPAR and verify each requirement:

```sh
# Python
/usr/lpp/IBM/cyp/v3r13/pyz/bin/python3 --version
# Expected: Python 3.13.x

# ZOAU
/usr/lpp/IBM/zoau/v1r3/bin/zoaversion
# Expected: IBM Z Open Automation Utilities version 1.3.x

# Java (IBM maintenance)
/usr/lpp/java/J21.0_64/bin/java -version
# Expected: java version "21.0.x"

# OpenSSH daemon
netstat -b | grep SSHD
# Expected: OMVS listener on port 22

# MAINT_ZFS directory
ls -la /maint_zfs/ibm/smpnts
# Expected: file exists, mode 600

# SMP/E version (submit this JCL or check via ISPF)
# S GIMSMP — check SMPOUT for: GIM69177I SMP/E VERSION IS 37.xx
```

---

### 7.5 RACF Keyring Setup (SMP/E Vendor SSL)

The following keyrings must exist and contain the vendor CA certificate chain before the first `RECEIVE ORDER`. These are LPAR-specific; consult your RACF admin.

```rexx
/* Create keyrings */
RACDCERT ADDRING(DCUFSMPE_KEYRING)           ID(SYSSA69)
RACDCERT ADDRING(DCUFSMPE_SECINTKEYRING)     ID(SYSSA69)
RACDCERT ADDRING(BCOMSMPE_KEYRING)           ID(SYSSA69)
RACDCERT ADDRING(BMCSMPE_KEYRING)            ID(SYSSA69)

/* Connect vendor CA (example — IBM DigiCert root) */
RACDCERT ID(SYSSA69) CONNECT(CERTAUTH LABEL('DigiCert Global Root CA') +
  RING(DCUFSMPE_KEYRING) USAGE(CERTAUTH))

SETROPTS RACLIST(DIGTCERT) REFRESH
```

---

## 8. Troubleshooting Reference

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `UNREACHABLE: Failed to create temporary directory` | `delegate_to: localhost` task missing `ansible_connection: local` or `ansible_shell_executable: /bin/bash` | Ensure both vars are present on every delegated task |
| `RC=` empty in job result | `zos_job_output` in ibm_zos_core ≤ 1.9 does not populate `ret_code.code` for polled jobs | RC is now captured from `zos_job_query` poll result (`apply_rc` / `accept_rc` / `receive_rc`) |
| APPLY CHECK runs before RECEIVE completes | Job still `AC` when `zos_job_output` called | Status guard (`fail when status == AC`) now prevents this |
| RECEIVE re-runs every invocation | No cycle marker present | Marker `cycle_{vendor}_{csi}_receive.marker` is written after RECEIVE; delete to force re-run |
| `GIM35401E` network connection failed | Firewall blocking port 443 outbound from z/OS LPAR | Open TCP/443 to IBM/Broadcom/BMC endpoints |
| `GIM53200E` SMPNTS invalid | Credentials file missing or wrong path | Check `/maint_zfs/{vendor}/smpnts` exists and is readable by the job userid |
| `_TAG_REDIR_IN=txt` corrupting modules | Pipelining enabled | Set `pipelining = False` in `ansible.cfg` (already default in this project) |

---

*This document was generated from the live workspace. Re-generate after significant infrastructure changes.*
