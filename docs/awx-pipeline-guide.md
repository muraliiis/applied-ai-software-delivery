# ISV Maintenance Pipeline — AWX Migration & Architecture Guide

**Repository:** `applied-ai-software-delivery`
**Last Updated:** 2026-07-24

---

## Contents

1. [Overview](#1-overview)
2. [Architecture Comparison](#2-architecture-comparison)
3. [Pipeline Architecture for AWX](#3-pipeline-architecture-for-awx)
4. [Repository Structure](#4-repository-structure)
5. [New Playbooks Reference](#5-new-playbooks-reference)
6. [JCL Template Reference](#6-jcl-template-reference)
7. [AWX Setup — Step by Step](#7-awx-setup--step-by-step)
8. [Survey Variable Reference](#8-survey-variable-reference)
9. [Approval Node Behaviour](#9-approval-node-behaviour)
10. [Running Locally (Without AWX)](#10-running-locally-without-awx)
11. [Microsoft 365 Copilot Extension Path](#11-microsoft-365-copilot-extension-path)
12. [Troubleshooting](#12-troubleshooting)

---

## 1. Overview

The `sdt-maintenance-refresh-agent` GitHub Copilot agent orchestrates a 16-step pipeline for applying ISV maintenance on z/OS. This guide describes two migration paths:

- **AWX (no-AI):** The same pipeline, driven entirely by Ansible playbooks and an AWX Workflow Template with Approval Nodes replacing AI-driven gate prompts.
- **Microsoft 365 Copilot:** A conversational front-end that calls AWX via REST API instead of running Ansible locally.

The Ansible playbooks and Jinja2 JCL templates are the **single source of truth** for both paths — the AI agent and AWX both use the same automation layer.

---

## 2. Architecture Comparison

| Dimension | GitHub Copilot Agent | AWX Workflow (no AI) | M365 Copilot Agent |
|---|---|---|---|
| **Entry point** | VS Code chat (`@sdt-maintenance-refresh-agent`) | AWX UI / REST API / CLI | Teams chat / M365 app |
| **Input collection** | `vscode/askQuestions` interactive prompts | AWX Survey (web form) | Adaptive card / conversation |
| **JCL generation** | AI renders Jinja2 template, writes `/tmp/*.jcl` | `ansible.builtin.template` task | AWX job renders template |
| **Job submission** | MCP `submit_zos_job` → z/OSMF | `ibm.ibm_zos_core.zos_job_submit` | AWX job → z/OSMF REST API |
| **Job monitoring** | MCP `wait_for_zos_job(max_lines=30)` | `ibm.ibm_zos_core.zos_job_query` + poll | AWX job status webhook |
| **Gate mechanism** | File markers + `vscode/askQuestions` | AWX Approval Node | Power Automate approval / Teams card |
| **Authentication** | Zowe profile (`zowe.config.json`) | AWX Machine Credential (SSH) + Vault | Microsoft Entra + AWX API token |
| **Audit trail** | JSON files in `ansible/logs/` | AWX job history + `ansible/logs/` | AWX job history + ServiceNow |

### Which path to use

| Scenario | Recommended path |
|---|---|
| Engineer debugging a specific product | GitHub Copilot agent (interactive, IDE-native) |
| Scheduled monthly RSU refresh | AWX Workflow Template (automated, repeatable) |
| Service desk / management approval flow | M365 Copilot → AWX REST API |
| Unattended overnight maintenance | AWX Workflow with pre-approved survey launch |

---

## 3. Pipeline Architecture for AWX

```
AWX Workflow Template: "ISV Maintenance Pipeline"
│
│  Survey (14 questions — see §8)
│
├── [Job]      ISV - COPYRENA Restore
│               copyrena-restore.yml
│               ADRDSSU CLEANUP (delete old-qual datasets)
│               ADRDSSU RESTDSN (restore from shrinkwrap → new qual)
│
├── [Job]      ISV - DDDEF Update
│               ddefupdt.yml
│               GIMSMP UCLIN/ZONEEDIT across GLOBAL + DLIB + TARGET zones
│
├── [Job]      ISV - Internet Maintenance
│               internet-maintenance.yml
│               SMP/E RECEIVE ORDER (vendor-specific: IBM/Broadcom/BMC)
│               SMP/E APPLY CHECK  (dry-run gate — writes gate marker file)
│               SMP/E APPLY        (executes after gate confirmed)
│               SMP/E ACCEPT CHECK (dry-run gate — writes gate marker file)
│               SMP/E ACCEPT       (executes after gate confirmed)
│
├── [Approval] APPLY CHECK Review       ← replaces gate_apply_pending.marker
│               24-hour window
│               Technician reviews APPLY CHECK output in AWX job log
│               then clicks Approve / Deny in AWX UI or Teams notification
│
├── [Approval] ACCEPT CHECK Review      ← replaces gate_accept_pending.marker
│               24-hour window
│
└── [Job]      ISV - Shrinkwrap
                shrinkwrap.yml
                Scratch existing output DSN if present
                ADRDSSU DUMP → new shrinkwrap DSN
```

### Approval Node vs File Marker Gate

| Feature | File marker (AI agent) | AWX Approval Node |
|---|---|---|
| Technician UI | VS Code chat (`yes`/`no`) | AWX web UI / email link / Teams |
| Timeout | Unlimited (manual) | Configurable (default: 24 hours) |
| Audit trail | Log file on control node | AWX job history + activity stream |
| Notification | Chat message | AWX notification → email / Teams / Slack |
| Multi-approver | Not supported | Supported (any member of specified team) |

---

## 4. Repository Structure

```
applied-ai-software-delivery/
├── .github/
│   ├── agents/
│   │   └── sdt-maintenance-refresh-agent.agent.md   ← GitHub Copilot agent
│   └── AGENTS.md
│
├── ansible/
│   ├── playbooks/
│   │   ├── internet-maintenance.yml     RECEIVE → APPLY CHECK → APPLY → ACCEPT (existing)
│   │   ├── copyrena-restore.yml         ADRDSSU CLEANUP + RESTDSN         ← NEW
│   │   ├── ddefupdt.yml                 SMP/E DDDEF UCLIN/ZONEEDIT        ← NEW
│   │   └── shrinkwrap.yml               ADRDSSU DUMP shrinkwrap backup    ← NEW
│   │
│   ├── templates/
│   │   ├── smpe_receive_ibm.j2          existing
│   │   ├── smpe_receive_broadcom.j2     existing
│   │   ├── smpe_receive_bmc.j2          existing
│   │   ├── smpe_apply_check.j2          existing
│   │   ├── smpe_apply.j2                existing
│   │   ├── smpe_accept.j2               existing
│   │   ├── copyrena.j2                  ADRDSSU CLEANUP+RESTORE JCL       ← NEW
│   │   ├── ddefupdt.j2                  GIMSMP UCLIN/ZONEEDIT JCL         ← NEW
│   │   └── shrinkwrap.j2                ADRDSSU DUMP JCL                  ← NEW
│   │
│   ├── inventory/
│   │   └── group_vars/all/main.yml      environment_vars, SMP/E defaults
│   └── logs/                            JSON audit logs, phase reports
│
└── awx/
    ├── configure-pipeline.yml           ← NEW: AWX setup playbook
    └── pipeline-survey.json             ← NEW: AWX survey spec (14 questions)
```

---

## 5. New Playbooks Reference

### `copyrena-restore.yml`

**Purpose:** Restore the product environment from the last shrinkwrap backup under a new qualifier.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `shrinkwrap_dsn` | text | Yes | Full DSN of the existing shrinkwrap (e.g. `ACSNS.TDMF.V5R11M0.ZOSMFA.ZS31D.SHRNKWRP`) |
| `new_qual` | text | Yes | New package qualifier with `ACS%S.` prefix (e.g. `ACS%S.TDMF.V5R11M0.ZOSMFB`) |
| `typrun_norun` | bool | No | `true` = dry run (default); `false` = live run |

**Derived values:** `EXISTING_QUAL`, `CLEANUP_EXCLUDE`, `CLEANUP_INCLUDE_OLD/NEW`, `RESTORE_INCLUDE`, `RENAME_ACSNS_OLD/NEW`, `RENAME_ACSVS_OLD/NEW` — all calculated by `set_fact` tasks from the two inputs above.

**Key steps:** validate → derive → render `copyrena.j2` → copy to USS → submit COPYRENA → poll → assert RC ≤ 4 → display ADR messages → save audit log.

---

### `ddefupdt.yml`

**Purpose:** Update SMP/E DDDEF dataset entries across GLOBAL, DISTRIBUTION, and TARGET zones so GIMSMP can locate the renamed datasets after COPYRENA.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `global_csi` | text | Yes | Global CSI DSN (e.g. `ACSVS.TDMF.V5R11M0.ZOSMFB.GLOBAL.CSI`) |
| `target_csi` | text | No | Target CSI DSN; defaults to `global_csi` if blank |
| `dlib_csi` | text | No | Distribution CSI DSN; defaults to `global_csi` if blank |
| `target_zone` | text | Yes | TARGET zone name (e.g. `TZONE`) |
| `dlib_zone` | text | Yes | DISTRIBUTION zone name (e.g. `DZONE`) |
| `existing_qual_rest` | text | Yes | Old qualifier qualifiers 2-N (e.g. `TDMF.V5R11M0.ZOSMFA`) |
| `new_qual_rest` | text | Yes | New qualifier qualifiers 2-N (e.g. `TDMF.V5R11M0.ZOSMFB`) |

**Derived values:** `smppts_dsn` = `ACSNS.{new_qual_rest}.SMPPTS`, `dddef_change_old` = `ACSNS.{existing_qual_rest}.*`, `dddef_change_new` = `ACSNS.{new_qual_rest}.*`.

---

### `shrinkwrap.yml`

**Purpose:** Create a new shrinkwrap ADRDSSU DUMP backup of all datasets under the new package qualifier.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `new_qual` | text | Yes | New package qualifier (e.g. `ACS%S.TDMF.V5R11M0.ZOSMFB`) |
| `userid_node` | text | Yes | z/OS level node for output DSN (e.g. `ZS31D`, `ZS32D`) |
| `typrun_norun` | bool | No | `true` = dry run (default); `false` = creates output dataset |
| `shrnkwrp_space_primary` | int | No | Primary space in CYL (default: 200) |
| `shrnkwrp_space_secondary` | int | No | Secondary space in CYL (default: 50) |

**Derived values:** `new_shrnkwrp_dsn` = `ACSNS.{new_qual_rest}.{userid_node}.SHRNKWRP`, `shrnkwrp_include` = `ACS%S.{new_qual_rest}.**`, `shrnkwrp_exclude` = output DSN.

**Note:** On a live run, the playbook uses `ibm.ibm_zos_core.zos_data_set state: absent` to scratch any pre-existing output DSN before submitting the DUMP job. This prevents `ADR014E`.

---

## 6. JCL Template Reference

| Template | JCL Program | Variables |
|---|---|---|
| `copyrena.j2` | `ADRDSSU` (CLEANUP step + RESTDSN step) | `typrun_norun`, `cleanup_exclude`, `cleanup_include_old/new`, `tape2_dsn`, `restore_include`, `rename_acsns_old/new`, `rename_acsvs_old/new` |
| `ddefupdt.j2` | `GIMSMP` (UCLIN + ZONEEDIT × 3) | `global_csi`, `smppts_dsn`, `dlib_zone`, `dlib_csi`, `target_zone`, `target_csi`, `dddef_change_old/new` |
| `shrinkwrap.j2` | `ADRDSSU` (DUMP step) | `typrun_norun`, `shrnkwrp_include`, `shrnkwrp_exclude`, `new_shrnkwrp_dsn`, `shrnkwrp_space_primary/secondary` |

All templates use `smpe_job_acct`, `smpe_job_class`, `smpe_job_msgclass` from `group_vars/all/main.yml` as defaults.

---

## 7. AWX Setup — Step by Step

### Prerequisites

```bash
# Python packages
pip install awxkit

# Ansible collection
ansible-galaxy collection install ansible.controller

# Verify AWX version (requires 22.x or later for workflow approval nodes)
awx --version
```

### Step 1 — Create Credentials in AWX UI

Before running the configure playbook, manually create two credentials in AWX:

| Name | Type | Fields |
|---|---|---|
| `DCUF SSH` | Machine | `Username: ansible_user` value from inventory; SSH private key from vault |
| `DCUF Vault` | Vault | Vault password matching `.vault_pass` in `ansible/` |
| `github-pat` | Source Control | GitHub personal access token for repo access |

### Step 2 — Run the configure playbook

```bash
cd /home/a463476/repos/applied-ai-software-delivery

ansible-playbook awx/configure-pipeline.yml \
  -e "controller_host=https://awx.example.com" \
  -e "controller_username=admin" \
  -e "controller_password=$(cat .awx_pass)" \
  -e "scm_url=https://github.gsissc.myatos.net/US-IRV-MAINFRAME-SERVICES/applied-ai-software-delivery" \
  -e "scm_credential=github-pat"
```

This creates: organisation, project, inventory, 4 job templates, 1 workflow template with 5 nodes and 2 approval nodes, and attaches the survey.

### Step 3 — Add the DCUF host to the inventory

Either via AWX UI (Inventories → DCUF LPAR → Hosts → Add) or via the `awx` CLI:

```bash
awx hosts create \
  --inventory "DCUF LPAR" \
  --name "dcuf" \
  --variables '{"ansible_host": "138.69.218.201"}'
```

### Step 4 — Configure notifications (optional)

In AWX UI: Notification Templates → Create → choose email, Slack, or Teams webhook. Attach to the Workflow Template and to each Approval Node so approvers receive alerts when waiting for review.

### Step 5 — Launch the pipeline

```
AWX UI → Templates → ISV Maintenance Pipeline → Launch
→ Fill in survey (14 questions)
→ Pipeline runs COPYRENA → DDEFUPDT → Internet Maintenance
→ Job pauses at "APPLY CHECK Review" — review job output, click Approve
→ APPLY runs, then job pauses at "ACCEPT CHECK Review" — click Approve
→ Shrinkwrap runs
→ Pipeline complete
```

---

## 8. Survey Variable Reference

| Variable | Source | Example |
|---|---|---|
| `shrinkwrap_dsn` | Technician | `ACSNS.TDMF.V5R11M0.ZOSMFA.ZS31D.SHRNKWRP` |
| `new_qual` | Technician | `ACS%S.TDMF.V5R11M0.ZOSMFB` |
| `vendor` | Dropdown | `ibm` / `broadcom` / `bmc` |
| `global_csi` | Technician | `ACSVS.TDMF.V5R11M0.ZOSMFB.GLOBAL.CSI` |
| `target_csi` | Technician (optional) | `ACSVS.TDMF.V5R11M0.ZOSMFB.TARGET.CSI` |
| `dlib_csi` | Technician (optional) | `ACSVS.TDMF.V5R11M0.ZOSMFB.DLIB.CSI` |
| `target_zone` | Technician | `TZONE` |
| `dlib_zone` | Technician | `DZONE` |
| `existing_qual_rest` | Technician | `TDMF.V5R11M0.ZOSMFA` |
| `new_qual_rest` | Technician | `TDMF.V5R11M0.ZOSMFB` |
| `userid_node` | Technician | `ZS31D` (z/OS 3.1), `ZS32D` (z/OS 3.2) |
| `typrun_norun` | Dropdown | `true` (dry run) / `false` (live) |
| `shrnkwrp_space_primary` | Integer | `200` (CYL) |
| `shrnkwrp_space_secondary` | Integer | `50` (CYL) |

**Note:** `existing_qual_rest` and `new_qual_rest` are the same information as `shrinkwrap_dsn` and `new_qual` expressed differently. In a future iteration, the `ddefupdt.yml` playbook can derive these from `shrinkwrap_dsn`/`new_qual` using the same `set_fact` logic as `copyrena-restore.yml`, reducing the survey to 12 questions.

---

## 9. Approval Node Behaviour

AWX Approval Nodes replace the file marker gate mechanism from the AI agent:

| Agent mechanism | AWX equivalent |
|---|---|
| `cat logs/gate_apply_pending.marker` — polling every 15s | AWX job automatically pauses at approval node — no polling needed |
| Technician types `yes` in VS Code chat | Technician clicks **Approve** in AWX UI or email link |
| `echo 'yes' > logs/gate_apply_confirmed.marker` | AWX writes approval event to activity stream and unblocks next node |
| 24-hour timeout not enforced | Approval node `timeout: 86400` — auto-denies if not actioned within 24 hours |
| No multi-approver support | AWX supports team-based approvals — configure in Workflow settings |

### Reviewing job output before approving

When the pipeline pauses at an approval node:

1. Navigate to **Jobs** → click the active workflow job
2. Click the **Internet Maintenance** node to view its job output
3. Look for the APPLY CHECK SMPOUT summary:
   - `GIM61301I SYSMOD xxx SELECTED FOR PROCESSING` — SYSMODs queued
   - `GIM35007W SYSMOD xxx NOT SELECTED` — superseded, safe to ignore
   - `GIM61303E HOLD` — requires investigation before approving
4. Confirm RC ≤ 4, then click **Approve** on the approval node

---

## 10. Running Locally (Without AWX)

Each playbook can be run standalone from the `ansible/` directory. Run them in order for a full pipeline:

```bash
cd /home/a463476/repos/applied-ai-software-delivery/ansible

# Step 1: COPYRENA — dry run first
ansible-playbook playbooks/copyrena-restore.yml \
  -e "shrinkwrap_dsn=ACSNS.TDMF.V5R11M0.ZOSMFA.ZS31D.SHRNKWRP" \
  -e "new_qual=ACS%S.TDMF.V5R11M0.ZOSMFB" \
  -e "typrun_norun=true"

# Step 1: COPYRENA — live run (after reviewing dry-run output)
ansible-playbook playbooks/copyrena-restore.yml \
  -e "shrinkwrap_dsn=ACSNS.TDMF.V5R11M0.ZOSMFA.ZS31D.SHRNKWRP" \
  -e "new_qual=ACS%S.TDMF.V5R11M0.ZOSMFB" \
  -e "typrun_norun=false"

# Step 2: DDDEF Update
ansible-playbook playbooks/ddefupdt.yml \
  -e "global_csi=ACSVS.TDMF.V5R11M0.ZOSMFB.GLOBAL.CSI" \
  -e "target_csi=ACSVS.TDMF.V5R11M0.ZOSMFB.TARGET.CSI" \
  -e "dlib_csi=ACSVS.TDMF.V5R11M0.ZOSMFB.DLIB.CSI" \
  -e "target_zone=TZONE" \
  -e "dlib_zone=DZONE" \
  -e "existing_qual_rest=TDMF.V5R11M0.ZOSMFA" \
  -e "new_qual_rest=TDMF.V5R11M0.ZOSMFB"

# Step 3: Internet Maintenance (RECEIVE → APPLY → ACCEPT)
ansible-playbook playbooks/internet-maintenance.yml \
  -e "vendor=ibm" \
  -e "smpe_csi_dsn=ACSVS.TDMF.V5R11M0.ZOSMFB.GLOBAL.CSI" \
  -e "smpe_target_zone_input=TZONE" \
  -e "smpe_dlib_zone_input=DZONE"

# Step 4: Shrinkwrap — dry run first
ansible-playbook playbooks/shrinkwrap.yml \
  -e "new_qual=ACS%S.TDMF.V5R11M0.ZOSMFB" \
  -e "userid_node=ZS31D" \
  -e "typrun_norun=true"

# Step 4: Shrinkwrap — live run
ansible-playbook playbooks/shrinkwrap.yml \
  -e "new_qual=ACS%S.TDMF.V5R11M0.ZOSMFB" \
  -e "userid_node=ZS31D" \
  -e "typrun_norun=false"
```

---

## 11. Microsoft 365 Copilot Extension Path

### What is needed

To expose the pipeline in Microsoft Teams / M365 Copilot as a conversational agent:

| Component | Technology | Purpose |
|---|---|---|
| **Agent definition** | Declarative Agent JSON + instructions file | Ports the `.agent.md` instructions to M365 format |
| **Actions backend** | Azure Function App or Azure API Management | REST API layer that M365 Copilot calls |
| **AWX integration** | AWX REST API `POST /api/v2/workflow_job_templates/{id}/launch/` | Triggers the AWX workflow from M365 |
| **z/OSMF integration** | z/OSMF REST API (job monitoring) | Real-time job status in Teams adaptive cards |
| **Auth** | Microsoft Entra App Registration + AWX API token | OAuth2 for M365 → Azure → AWX |
| **Approval** | Teams Adaptive Card with Approve/Deny buttons | Replaces AWX Approval Node UI for M365 users |

### High-level flow

```
Teams user: "@Copilot run maintenance for TDMF ZOSMFB"
     ↓
M365 Declarative Agent (instructions from sdt-maintenance-refresh-agent)
     ↓  (Action: collect_inputs)
Adaptive Card survey in Teams chat
     ↓  (Action: launch_pipeline)
Azure Function → AWX REST API POST /api/v2/workflow_job_templates/N/launch/
     ↓
AWX executes: COPYRENA → DDEFUPDT → Internet Maintenance
     ↓  (Action: get_job_status)  polls AWX GET /api/v2/jobs/{id}/
Teams card: "APPLY CHECK complete — 6 SYSMODs ready. Approve or Deny?"
     ↓  (Teams card button)
Azure Function → AWX POST /api/v2/workflow_approvals/{id}/approve/
     ↓
AWX continues: APPLY → ACCEPT → Shrinkwrap
     ↓
Teams card: "Pipeline complete. Shrinkwrap: ACSNS.TDMF.V5R11M0.ZOSMFB.ZS31D.SHRNKWRP RC=0"
```

### Key files to create for M365 path

```
m365-agent/
├── declarativeAgent.json      ← ports sdt-maintenance-refresh-agent instructions
├── manifest.json              ← Teams App manifest
└── openapi.yaml               ← API plugin spec (collect_inputs, launch_pipeline,
                                  get_job_status, approve_gate)
```

The M365 path reuses the **same AWX workflow** — only the conversation layer changes.

---

## 12. Troubleshooting

### COPYRENA failures

| Error | Cause | Fix |
|---|---|---|
| `ADR220E` — tape/DSN not found | `TAPE2_DSN` (shrinkwrap) not catalogued | Verify DSN with `LISTCAT ENT(...)` |
| `ADR014E` — dataset already exists | RESTDSN found a conflicting DSN | New-qual datasets were not cleaned; re-check CLEANUP INCLUDE pattern |
| `RC=12` on CLEANUP | EXCLUDE pattern too narrow — shrinkwrap DSN matched INCLUDE | Confirm `CLEANUP_EXCLUDE` exactly matches `shrinkwrap_dsn` |
| `IGD17199I` — dataset not found in INCLUDE | Wrong `EXISTING_QUAL` pattern | Run `LISTCAT LEVEL(ACS%S.TDMF.V5R11M0.ZOSMFA)` to confirm pattern |

### DDEFUPDT failures

| Error | Cause | Fix |
|---|---|---|
| `GIM20501E` — DDDEF not found | DDDEF entry to change does not exist in zone | Verify DDDEF exists with `LIST DDDEF` in SMP/E interactive |
| `GIM35007E` — zone not found | Zone name typo | Confirm zone name with `LIST ZONES` against the CSI |
| `GIM24801W` — UCLIN warnings | Minor structural inconsistency on GLOBALZONE ZINDEX | Non-fatal if RC=4; review SMPOUT for detail |
| `RC=12` on GBLZONE | GLOBAL CSI DSN not found or zone uninitialised | Run `LISTCAT ENT(global_csi)` to confirm DSN exists |

### Shrinkwrap failures

| Error | Cause | Fix |
|---|---|---|
| `ADR006E` — space exhausted | Output dataset ran out of space | Increase `shrnkwrp_space_primary` via survey |
| `ADR014E` — dataset already exists | `zos_data_set state: absent` was skipped or failed | Manually scratch `new_shrnkwrp_dsn` with IDCAMS DELETE, then re-run |
| `ADR052E` — no datasets matched INCLUDE | Wrong `new_qual` or datasets not yet catalogued | Run `LISTCAT LEVEL(ACS%S.new_qual_rest)` to confirm datasets exist |
| `ADR744W` — empty PDS members skipped | Normal warning for empty partitioned datasets | RC=4 is acceptable |

### AWX-specific issues

| Symptom | Cause | Fix |
|---|---|---|
| Approval node never triggers | Internet Maintenance job failed before APPLY CHECK | Check Internet Maintenance job output for RC > 4 |
| Approval timed out (24h) | No-one actioned the approval | Re-launch workflow; consider increasing `timeout` or adding email notifications |
| `configure-pipeline.yml` fails: `ansible.controller not found` | Collection not installed | `ansible-galaxy collection install ansible.controller` |
| Survey variables not passed to job templates | Job template has `ask_variables_on_launch: false` but doesn't inherit from workflow | Set `allow_simultaneous: false` on the workflow and confirm survey variable names match playbook `vars_prompt` names exactly |
