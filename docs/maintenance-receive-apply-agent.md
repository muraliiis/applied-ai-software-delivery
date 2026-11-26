# maintenance-receive-apply Agent — Requirements & Ansible Collection Usage

**Agent file:** `.github/agents/maintenance-receive-apply.agent.md`  
**Playbook:** `ansible/playbooks/internet-maintenance.yml`  
**Generated:** 2026-06-10

---

## 1. What the Agent Does

The `maintenance-receive-apply` agent orchestrates end-to-end SMP/E internet maintenance delivery for three software vendors — **IBM**, **Broadcom**, and **BMC** — directly from their download portals to a z/OS LPAR via SMP/E's GIMZIP-based `RECEIVE ORDER` internet retrieval mechanism.

### Supported Lifecycle Phases

| Phase | Operation | Gate |
|-------|-----------|------|
| **Phase 1** | RECEIVE ORDER — download packages from vendor portal into SMPPTS | — |
| **Phase 2** | APPLY CHECK — dry-run to identify SYSMODs approved/blocked for APPLY | — |
| **Phase 3** | Technician Review Gate | ✋ Manual `yes/no` |
| **Phase 4** | APPLY — install SYSMODs into TARGET zone | — |
| **Phase 5a** | ACCEPT CHECK — dry-run to identify SYSMODs approved for ACCEPT | — |
| **Phase 5b** | Technician Review Gate | ✋ Manual `yes/no` |
| **Phase 5c** | ACCEPT — promote SYSMODs from TARGET to DLIB zone | — |

### Outputs Generated Per Run

| File | Contents |
|------|----------|
| `logs/phase1_receive_{vendor}_{ts}.md` | Job details + received SYSMOD list |
| `logs/phase2_applycheck_{vendor}_{ts}.md` | Approved/blocked SYSMOD analysis |
| `logs/phase4_apply_{vendor}_{ts}.md` | Job details + applied SYSMOD list |
| `logs/phase5_acceptcheck_{vendor}_{ts}.md` | Approved-for-ACCEPT SYSMOD list |
| `logs/phase5_accept_{vendor}_{ts}.md` | Job details + accepted SYSMOD list |
| `logs/maintenance_report_{vendor}_{ts}.md` | Full combined report with SYSMOD traceability |
| `logs/internet_receive_{vendor}_{ts}.json` | Raw RECEIVE job output (audit) |
| `logs/internet_applycheck_{vendor}_{ts}.json` | Raw APPLY CHECK job output (audit) |
| `logs/internet_apply_{vendor}_{ts}.json` | Raw APPLY job output (audit) |
| `logs/internet_accept_{vendor}_{ts}.json` | Raw ACCEPT job output (audit) |

---

## 2. Prerequisites

### 2.1 Control Node (Linux/Workstation)

| Requirement | Version | Notes |
|-------------|---------|-------|
| **Ansible** | ≥ 2.14 | Core automation engine |
| **Python** | ≥ 3.9 | Required by Ansible |
| **ibm.ibm_zos_core** collection | ≥ 1.9.0, < 2.0.0 | z/OS modules |
| **community.general** collection | ≥ 7.0.0, < 10.0.0 | Utility modules |
| SSH key | — | `~/.ssh/id_zos` — must be authorised on each target LPAR |
| Ansible Vault password | — | `ansible/.vault_pass` (chmod 600, gitignored) |

Install collections:
```bash
ansible-galaxy collection install -r ansible/requirements.yml
```

### 2.2 z/OS Managed Node (Target LPAR)

| Requirement | Version | Notes |
|-------------|---------|-------|
| **z/OS** | V2R3 or later | |
| **IBM Open Enterprise SDK for Python** | 3.13 (5655-PYT) | Path: `/usr/lpp/IBM/cyp/v3r13/pyz/bin/python3` |
| **IBM Z Open Automation Utilities (ZOAU)** | v1r3 (5698-PA1) | Path: `/usr/lpp/IBM/zoau/v1r3` |
| **z/OS OpenSSH** | — | Required for Ansible SSH connection |
| **Java** | J21.0_64 | Path: `/usr/lpp/java/J21.0_64/` — used by SMP/E HTTPS client |
| **SMP/E** | 37.35+ | Must have GIMSMP with internet delivery capability |
| **USS filesystem** | — | `/maint_zfs/` must exist and be writable (SMPNTS staging) |

### 2.3 Network Requirements (Outbound HTTPS from z/OS LPAR)

| Vendor | Target Host(s) | Port |
|--------|---------------|------|
| IBM | `eccgw01.boulder.ibm.com`, `esw.ibm.com`, `delivery.software.ibm.com` | 443 |
| Broadcom | `delivery.broadcom.com` | 443 |
| BMC | `ftp.bmc.com`, `support.bmc.com` | 443 |

SSL trust: vendor CA certificates must be in the LPAR's RACF keyring or GSK key database used by AT-TLS.

### 2.4 SMPNTS Credential Files (per vendor)

Files must exist on the control node before the first run. Protect with `chmod 600`.

**IBM** — `/maint_zfs/ibm/smpnts`
```
CREDENTIALS IBMID(your.ibmid@example.com)
            CUSTOMER(1234567)
            ICRTOKEN(your-shopz-api-token)
            COUNTRY(GB)
```

**Broadcom** — `/maint_zfs/broadcom/smpnts`
```
CREDENTIALS BCSID(your.bcid@example.com)
            CUSTOMER(1234567)
            PASSWORD(your-broadcom-portal-password)
            COUNTRY(GB)
```

**BMC** — `/maint_zfs/bmc/smpnts`
```
CREDENTIALS BMCID(your.bmcid@example.com)
            CUSTOMER(1234567)
            PASSWORD(your-bmc-support-password)
            COUNTRY(GB)
```

### 2.5 Ansible Inventory Variables

The following variables are resolved at runtime. Override at the host or group level in inventory:

| Variable | Source | Example |
|----------|--------|---------|
| `smpe_csi_dsn` | CLI `-e` | `ACSVS.TDMF.V5R11M0.ZOSMFA.GLOBAL.CSI` |
| `smpe_target_zone_input` | CLI `-e` | `TZONE` |
| `smpe_dlib_zone_input` | CLI `-e` | `DZONE` |
| `smpe_javahome` | `group_vars/all/main.yml` | `/usr/lpp/java/J21.0_64/` |
| `smpe_orderserver_url` | `group_vars/all/main.yml` | `https://eccgw01.boulder.ibm.com/...` |
| `smpe_job_class` | `group_vars/all/main.yml` | `A` |
| `smpe_job_msgclass` | `group_vars/all/main.yml` | `X` |
| `vendor` | CLI `-e` or interactive prompt | `ibm` / `broadcom` / `bmc` |
| `skip_receive` | CLI `-e` (optional) | `true` — skips Phase 1, loads SYSMODs from last audit log |

---

## 3. Ansible Collection Usage

### 3.1 `ibm.ibm_zos_core` (≥ 1.9.0)

This is the primary collection used across all five SMP/E job phases. Every module call requires `environment: "{{ environment_vars }}"` to set the ZOAU and Python environment on the managed node.

#### `ibm.ibm_zos_core.zos_copy`

**Purpose:** Upload rendered JCL from the control node (after Jinja2 template rendering) to a USS temporary file on the z/OS LPAR.

**Used in:** All 5 SMP/E job submission phases (RECEIVE, APPLY CHECK, APPLY, ACCEPT CHECK, ACCEPT)

**Key parameters:**
| Parameter | Value | Notes |
|-----------|-------|-------|
| `src` | `/tmp/imr_*.jcl` | Local rendered JCL file |
| `dest` | `/tmp/imr_*.jcl` | Remote USS path on z/OS |
| `force` | `true` | Overwrite if exists |
| `is_binary` | `false` | Text transfer |
| `encoding.from` | `UTF-8` | Control node encoding |
| `encoding.to` | `IBM-1047` | z/OS EBCDIC encoding |

**Example task (RECEIVE):**
```yaml
ibm.ibm_zos_core.zos_copy:
  src: "/tmp/imr_receive_{{ inventory_hostname }}.jcl"
  dest: "/tmp/imr_receive_{{ inventory_hostname }}.jcl"
  force: true
  is_binary: false
  encoding:
    from: UTF-8
    to: IBM-1047
environment: "{{ environment_vars }}"
```

---

#### `ibm.ibm_zos_core.zos_job_submit`

**Purpose:** Submit a JCL job from USS to the JES2 internal reader and return the job ID.

**Used in:** All 5 SMP/E job submission phases

**Key parameters:**
| Parameter | Value | Notes |
|-----------|-------|-------|
| `src` | `/tmp/imr_*.jcl` | USS path to JCL file |
| `location` | `uss` | JCL source is a USS file |
| `wait_time_s` | `30` | Initial wait before returning job ID |

**Returns:** `jobs[0].job_id`, `jobs[0].job_name` — used in subsequent polling and output tasks.

**Example task (APPLY CHECK):**
```yaml
ibm.ibm_zos_core.zos_job_submit:
  src: "/tmp/imr_applycheck_{{ inventory_hostname }}.jcl"
  location: uss
  wait_time_s: 30
environment: "{{ environment_vars }}"
register: _applycheck_submit
```

---

#### `ibm.ibm_zos_core.zos_job_query`

**Purpose:** Poll a running job by `job_id` until it reaches a terminal state (`ret_code` is not `None`). Used in `until/retries/delay` loops.

**Used in:** All 5 SMP/E job phases — polled every 30 seconds for up to 60 minutes.

**Key parameters:**
| Parameter | Value | Notes |
|-----------|-------|-------|
| `job_id` | `"{{ _submit.jobs[0].job_id }}"` | Job ID from `zos_job_submit` |

**Polling pattern:**
```yaml
ibm.ibm_zos_core.zos_job_query:
  job_id: "{{ _submit.jobs[0].job_id }}"
environment: "{{ environment_vars }}"
register: _poll
until: >
  _poll.jobs is defined
  and _poll.jobs | length > 0
  and _poll.jobs[0].ret_code is defined
  and _poll.jobs[0].ret_code.code is not none
retries: 120
delay: 30
```

---

#### `ibm.ibm_zos_core.zos_job_output`

**Purpose:** Retrieve the full spool output (all DD names and their content) for a completed job by `job_id`. This is where SYSMOD parsing happens — `SMPRPT` DD contains the APPLIED/ACCEPTED status records.

**Used in:** All 5 SMP/E job phases — called after polling confirms job completion.

**Key parameters:**
| Parameter | Value | Notes |
|-----------|-------|-------|
| `job_id` | `"{{ _submit.jobs[0].job_id }}"` | Job ID from `zos_job_submit` |

**DD names extracted per phase:**

| Phase | DD Name | Content Used For |
|-------|---------|-----------------|
| All phases | `SMPRPT` | Identify APPLIED/ACCEPTED SYSMODs via regex `^\s+(\S+)\s+(APPLIED\|ACCEPTED)\s+PTF` |
| All phases | `SMPOUT` | Extract GIM error messages (blocking reasons for APPLY/ACCEPT CHECK) |
| All phases | `SMPLOG` | Available in audit JSON; not parsed by default |

**SMPRPT parsing pattern:**
```yaml
set_fact:
  applied_sysmod_list: >-
    {{ accept_job.jobs[0].ddnames
       | selectattr('ddname', 'equalto', 'SMPRPT')
       | map(attribute='content')
       | list | first | default([])
       | join('\n')
       | regex_findall('^\s+(\S+)\s+APPLIED\s+PTF\s+\S+', multiline=True)
       | unique | sort }}
```

---

### 3.2 `ansible.builtin` (Ansible Core)

Used for control-node-side operations — no z/OS connection required.

| Module | Usage |
|--------|-------|
| `ansible.builtin.template` | Renders Jinja2 JCL templates (`.j2`) into `/tmp/imr_*.jcl` on the control node before upload; also renders `maintenance_report.j2` at end of run |
| `ansible.builtin.file` | Creates the `logs/` directory on the control node before first write |
| `ansible.builtin.copy` | Writes per-phase Markdown reports and audit JSON files to `logs/` on the control node |
| `ansible.builtin.find` | Locates the most recent audit JSON log when `skip_receive=true` (used to reload SYSMOD list from a previous run) |
| `ansible.builtin.pause` | Implements the two technician review gates (Phase 3 APPLY gate, Phase 5b ACCEPT gate) — waits for `yes`/`no` input before proceeding |
| `ansible.builtin.debug` | Displays phase summaries, comparison reports, and run parameters in the terminal |
| `ansible.builtin.assert` | Validates that `vendor`, `smpe_csi_dsn`, `smpe_target_zone_input`, and `smpe_dlib_zone_input` are all provided before any tasks run |
| `ansible.builtin.set_fact` | Sets runtime variables: `_vendor_key`, `receive_template`, `smpe_nts_path`, SYSMOD lists |
| `ansible.builtin.raw` | Bootstraps `/tmp/zos_shell.sh` wrapper on the z/OS LPAR (runs before Python is available) |
| `ansible.builtin.shell` | Runs Python inline scripts for report building (APPLY CHECK/ACCEPT CHECK detail reports) |
| `ansible.builtin.fail` | Aborts playbook if RC > 4 on any SMP/E job or if a required job fails to submit |

---

## 4. JCL Templates (Jinja2)

Located in `ansible/templates/`. Each template renders into a temporary JCL file uploaded to the z/OS USS path `/tmp/imr_*.jcl`.

| Template | Vendor | Phase | JCL Job Name |
|----------|--------|-------|-------------|
| `smpe_receive_ibm.j2` | IBM | Phase 1 | `SMPREORD` |
| `smpe_receive_broadcom.j2` | Broadcom | Phase 1 | `SMPREORD` |
| `smpe_receive_bmc.j2` | BMC | Phase 1 | `SMPREORD` |
| `smpe_apply_check.j2` | All | Phase 2 | `SMPAPYCK` |
| `smpe_apply.j2` | All | Phase 4 | `SMPAPLY1` |
| `smpe_accept.j2` | All | Phase 5a & 5c | `SMPACPCK` / `SMPACCPT` |
| `maintenance_report.j2` | All | Final | *(Markdown — not JCL)* |

> **Important:** All templates must use **inline Jinja2 expressions** (`{{ 'x' if cond else 'y' }}`), never `{% if %}` block tags. Ansible's `trim_blocks=True` default consumes the newline after `{% endif %}`, merging JCL continuation lines and causing JES2 to reject the job.

---

## 5. Invocation Reference

### Full run (interactive prompts)
```bash
cd ansible
ansible-playbook playbooks/internet-maintenance.yml
```

### Full run (non-interactive)
```bash
ansible-playbook playbooks/internet-maintenance.yml \
  -e "vendor=ibm" \
  -e "smpe_csi_dsn=ACSVS.TDMF.V5R11M0.ZOSMFA.GLOBAL.CSI" \
  -e "smpe_target_zone_input=TZONE" \
  -e "smpe_dlib_zone_input=DZONE"
```

### Skip RECEIVE (resume after a failed APPLY CHECK)
```bash
ansible-playbook playbooks/internet-maintenance.yml \
  -e "vendor=ibm" \
  -e "smpe_csi_dsn=ACSVS.TDMF.V5R11M0.ZOSMFA.GLOBAL.CSI" \
  -e "smpe_target_zone_input=TZONE" \
  -e "smpe_dlib_zone_input=DZONE" \
  -e "skip_receive=true"
```

### Start at a specific phase
```bash
# Start at ACCEPT CHECK (Phase 5a)
ansible-playbook playbooks/internet-maintenance.yml \
  -e "vendor=ibm" \
  -e "smpe_csi_dsn=ACSVS.IBMZWS.V9R5M0.ZOSMFA.CSI" \
  -e "smpe_target_zone_input=TZONE" \
  -e "smpe_dlib_zone_input=DZONE" \
  --start-at-task "[PHASE 5] Render ACCEPT CHECK JCL from template"
```

---

## 6. Acceptable Return Codes

| RC | Meaning | Action |
|----|---------|--------|
| 0 | Clean — no warnings | Proceed |
| 4 | Warning — informational holds or minor issues | Proceed (expected for ACCEPT with DOC/FIXCAT holds) |
| 8 | Error — missing requisites or HOLDSYS | Investigate GIM messages; do NOT proceed to APPLY/ACCEPT |
| 12+ | Severe error | Stop immediately; engage rollback-planner |

---

*Document generated from `ansible/playbooks/internet-maintenance.yml` and `ansible/inventory/group_vars/all/main.yml`*
