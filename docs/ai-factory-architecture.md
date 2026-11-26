# AI-Assisted z/OS Software Delivery Factory — Architecture & Configuration Reference

**Scope:** All AI agents, skills, MCP servers, APIs, and infrastructure requirements across the applied-ai workspace  
**Last Updated:** 26th June 2026

---

## Table of Contents

1. [Overview](#1-overview)
2. [AI Model & Orchestration Layer](#2-ai-model--orchestration-layer)
3. [Agent Catalogue](#3-agent-catalogue)
   - 3.1 [Software Delivery Agents](#31-software-delivery-agents)
   - 3.2 [z/OS Systems Programming Agents](#32-zos-systems-programming-agents)
   - 3.3 [Interview & Assessment Agents](#33-interview--assessment-agents)
   - 3.4 [Migration Assistant Agents](#34-migration-assistant-agents)
4. [Skills (Reusable Instruction Modules)](#4-skills-reusable-instruction-modules)
5. [MCP Servers](#5-mcp-servers)
   - 5.1 [zos-toolkit (Node.js — Custom)](#51-zos-toolkit-nodejs--custom)
   - 5.2 [Zowe MCP Server](#52-zowe-mcp-server)
6. [Control Node Requirements](#6-control-node-requirements)
   - 6.1 [VS Code & Extensions](#61-vs-code--extensions)
   - 6.2 [Zowe CLI & Profiles](#62-zowe-cli--profiles)
   - 6.3 [Ansible & Python](#63-ansible--python)
   - 6.4 [SSH (zowex / Zowe Remote SSH)](#64-ssh-zowex--zowe-remote-ssh)
7. [z/OS LPAR Requirements](#7-zos-lpar-requirements)
   - 7.1 [Core z/OS Components](#71-core-zos-components)
   - 7.2 [APIs Active on the LPAR](#72-apis-active-on-the-lpar)
   - 7.3 [RACF & Security Requirements](#73-racf--security-requirements)
8. [API Reference](#8-api-reference)
   - 8.1 [z/OSMF REST API](#81-zosmf-rest-api)
   - 8.2 [RSE API (IBM Remote System Explorer)](#82-rse-api-ibm-remote-system-explorer)
   - 8.3 [Zowe SSH (zowex)](#83-zowe-ssh-zowex)
9. [Network Topology](#9-network-topology)
10. [Repository Structure](#10-repository-structure)

---

## 1. Overview

This factory system uses **GitHub Copilot Chat** (powered by **Claude Sonnet 4.6**) running inside VS Code as the AI orchestration layer. Custom agent files (`.agent.md`) define specialised personas and workflows that automate z/OS mainframe operations — including SMP/E maintenance delivery, environment cleanup and restore, audit reporting, migration analysis, health checking, and documentation generation.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                   DEVELOPER WORKSTATION (Control Node)                      │
│                                                                             │
│  ┌────────────────────┐    ┌──────────────────────────────────────────────┐ │
│  │  VS Code 1.119.0   │◄──►│  GitHub Copilot Chat                         │ │
│  │                    │    │  Model: Claude Sonnet 4.6                    │ │
│  │  Extensions:       │    │  Mode: Agent (.agent.md) / Skill (.SKILL.md) │ │
│  │  • Copilot Chat    │    └──────────────────┬───────────────────────────┘ │
│  │  • Z Open Editor   │                       │                             │
│  │  • Zowe Explorer   │    ┌──────────────────▼───────────────────────────┐ │
│  │  • Ansible         │    │  MCP Servers (Model Context Protocol)        │ │
│  └────────────────────┘    │  • zos-toolkit (Node.js v18+ — custom)       │ │
│                            │  • Zowe MCP Server (@zowe/cics-for-zowe-cli) │ │
│  ┌─────────────────────────┴────────────────────────────────────────────┐  │ │
│  │  Zowe CLI v3.4.1  ──► z/OSMF :443  /  SSH :22  /  RSE API :6800      │  │ │
│  │  Ansible Core 2.14  ──► SSH :22 (ibm.ibm_zos_core modules)           │  │ │
│  └──────────────────────────────────────────────────────────────────────┘  │ │
└──────────────────────────────────────────────────────────────────────────── ┘
                    │ HTTPS :443 / SSH :22 / RSE :6800
┌───────────────────▼─────────────────────────────────────────────────────────┐
│                 z/OS LPAR — DCUF (138.69.218.201)                           │
│                                                                             │
│  z/OSMF :443  │  z/OS OpenSSH :22  │  RSE API :6800  │  JES2 / SMP/E      │
│  Python 3.13  │  ZOAU v1r3         │  Java J21.0_64  │  RACF / AT-TLS     │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. AI Model & Orchestration Layer

| Item | Detail |
|------|--------|
| **AI Model** | Claude Sonnet 4.6 (via GitHub Copilot) |
| **Surface** | GitHub Copilot Chat extension in VS Code |
| **Agent System** | VS Code `.agent.md` files — each defines a named mode with a specific persona, workflow, tools, and constraints |
| **Skill System** | `SKILL.md` files — reusable instruction modules read at agent invocation time |
| **Configuration** | `.github/copilot-instructions.md` per repository — sets the default persona and guardrails for all non-agent conversations |
| **Tool Access** | MCP servers expose callable tools; VS Code built-in tools (`vscode/askQuestions`, `edit/editFiles`, etc.) are available to all agents |
| **Credentials** | `ZOWE_USER` / `ZOWE_PASSWORD` environment variables passed to MCP server via `mcp.json`; never stored in agent files |

### How Agents Are Invoked

Agents are selected from the **mode selector** in the Copilot Chat panel (or by typing `@agent-name` inline). When activated, the agent's `.agent.md` file is injected into the model context, overriding the default persona. The agent may call MCP tools, run terminal commands, read/write files, and ask the technician questions — all within its defined workflow.

---

## 3. Agent Catalogue

### 3.1 Software Delivery Agents

**Repository:** `applied-ai-software-delivery`

#### `maintenance-receive-apply`

| Property | Value |
|----------|-------|
| **File** | `.github/agents/maintenance-receive-apply.agent.md` |
| **Purpose** | End-to-end SMP/E internet maintenance delivery for IBM, Broadcom, and BMC. Covers the full lifecycle: vendor selection → RECEIVE ORDER (GIMZIP) → APPLY CHECK with technician review gate → APPLY → ACCEPT CHECK with technician review gate → ACCEPT. |
| **Workflow** | Vendor Selection → Input Collection → RECEIVE ORDER → APPLY CHECK Gate → APPLY → ACCEPT CHECK Gate → ACCEPT → Final Report |
| **Key Tools** | `run_ansible_playbook`, `wait_for_zos_job`, `get_job_output`, `list_maintenance_logs` |
| **Ansible Playbook** | `ansible/playbooks/internet-maintenance.yml` |
| **JCL Templates** | `smpe_receive_ibm.j2`, `smpe_receive_bmc.j2`, `smpe_receive_broadcom.j2`, `smpe_apply_check.j2`, `smpe_apply.j2`, `smpe_accept.j2` |
| **MCP Dependency** | `zos-toolkit` — for `wait_for_zos_job` (MCP-first polling, replaces shell while-loops) |
| **Vendors Supported** | IBM (esw.ibm.com), Broadcom (delivery.broadcom.com), BMC (ftp.bmc.com) |
| **Gate Mechanism** | File-based marker system: `logs/gate_apply_pending.marker` / `logs/gate_accept_pending.marker`; agent reads markers and presents gate in chat |
| **Report Output** | `ansible/logs/maintenance_report_{vendor}_{timestamp}.md` |

---

#### `sdt-maintenance-refresh-agent`

| Property | Value |
|----------|-------|
| **File** | `.github/agents/sdt-maintenance-refresh-agent.agent.md` |
| **Purpose** | Cleans up an existing ISV product environment and restores it from the last shrinkwrap backup under a new maintenance-level qualifier. Generates ADRDSSU COPYRENA and GIMSMP DDEFUPDT JCL. Includes Shrinkwrap creation and Documentation Update steps. |
| **Workflow** | Input Collection (2 values) → Value Derivation → COPYRENA JCL Gen → Review Gate → Submit → Monitor → DDDEF Input Collection → DDEFUPDT JCL Gen → Review Gate → Submit → Monitor → Shrinkwrap Gate → SHRNKWRP JCL Gen → Review Gate → Submit → Monitor → Final Pipeline Report → Documentation Update |
| **Steps** | 16 steps: Steps 1–5 (ADRDSSU), Steps 6–10 (DDDEF), Steps 11–14 (Shrinkwrap), Step 15 (Final Report), Step 16 (Documentation Update) |
| **JCL Generated** | `COPYRENA` (ADRDSSU CLEANUP + RESTDSN), `DDEFUPDT` (GIMSMP UCLIN + ZONEEDIT), `SHRNKWRP` (ADRDSSU DUMP) |
| **Vendors Supported** | IBM, Broadcom, BMC (vendor-agnostic JCL templates) |
| **Key Inputs** | Existing Shrinkwrap DSN, New Package Qualifier |
| **Derived Values** | EXISTING_QUAL, NEW_QUAL_REST, CLEANUP_EXCLUDE, RENAME_ACSNS/ACSVS old/new, SMPPTS_DSN, DDDEF_CHANGE_OLD/NEW, NEW_SHRNKWRP_DSN |
| **Safety** | TYPRUN=NORUN dry run by default; explicit "approve live" + "CONFIRM LIVE" required for destructive operations |
| **Doc Update** | Step 16 reads the existing Impact & Installation Guide, updates Shrinkwrap DSN, Appendix B dataset lists, and adds/replaces the `Maintenance/Fix Apply Process - Last/Latest` section |

---

#### `smpe-validator`

| Property | Value |
|----------|-------|
| **File** | `.github/agents/smpe-validator.agent.md` |
| **Purpose** | Validates SMP/E zones, identifies configuration issues, and provides remediation guidance. |
| **Use Case** | Pre-deployment zone health check; error SYSMOD analysis; HOLDDATA review; cross-zone discrepancy detection |

---

#### `deployment-planner`

| Property | Value |
|----------|-------|
| **File** | `.github/agents/deployment-planner.agent.md` |
| **Purpose** | Analyses PTF packages, creates deployment plans, and assesses risks for z/OS software deployments. |
| **Output** | Structured deployment plan with risk classification (Low / Medium / High / Critical), dependency resolution, validation steps |

---

#### `rollback-planner`

| Property | Value |
|----------|-------|
| **File** | `.github/agents/rollback-planner.agent.md` |
| **Purpose** | Creates comprehensive rollback procedures for software deployments and provides emergency recovery guidance. |
| **Trigger Conditions** | Critical subsystem failures, IPL instability, data integrity issues, security vulnerabilities |

---

#### `operational-audit-compliance-assistant`

| Property | Value |
|----------|-------|
| **File** | `.github/agents/operational-audit-compliance-assistant.agent.md` |
| **Purpose** | Agentic AI-based operational audit and compliance platform for DCUF. Collects and parses IBM Health Checker outputs; categorises findings as SUCCESS / WARNING / EXCEPTION; correlates with IBM best practices; generates audit reports (Markdown, PDF, HTML, Excel); supports historical tracking and trend analysis. |
| **Integrations** | IBM Health Checker, ServiceNow, z/OSMF REST API |

---

#### `zos-migration-healthcheck-assistant`

| Property | Value |
|----------|-------|
| **File** | `.github/agents/zos-migration-healthcheck-assistant.agent.md` |
| **Purpose** | Executes and analyses IBM Health Checker `ZOSMIG*` checks on a z/OS LPAR via Zowe CLI, then produces a structured Migration Health Report covering passed checks, exceptions, and remediation actions. |

---

#### `zosmf-install-guide-generator`

| Property | Value |
|----------|-------|
| **File** | `.github/agents/zosmf-install-guide-generator.agent.md` |
| **Purpose** | Generates a fully formatted Shrinkwrap Installation Guide and Impact Statement for any IBM product or product bundle installed on DCUF via z/OSMF. Supports new installs and maintenance refreshes (ZOSMFA, ZOSMFB, …). |
| **Output** | `.md` file (and optionally `.docx` via pandoc + Word COM post-processing on Windows) |
| **Templates** | `shrinkwrap-guide-generator/zosmf_maintenance_template.md`, `zosmf_install_template.md` |
| **Products** | Single products and multi-product bundles/suites |

---

### 3.2 z/OS Systems Programming Agents

**Repository:** `Skills-zOS`

| Agent Name | File | Purpose |
|------------|------|---------|
| `batch-triaging` | `batch-triaging.agent.md` | Diagnoses and triages batch job failures |
| `CICS availability` | `CICS availability.agent.md` | CICS availability checks and incident response |
| `Command-Center` | `Command-Center.agent.md` | MVS operator command centre and console automation |
| `Jes` | `Jes.agent.md` | JES2 spool management and job monitoring |
| `mainframe-reviewer` | `mainframe-reviewer.agent.md` | Reviews mainframe JCL, configuration, and change requests |
| `Mainframe Software Agent` | `mainframe_software.agent.md` | Queries mainframe software versions, descriptions, and compatibility |
| `storage-triaging` | `storage-triaging.agent.md` | Storage problem diagnosis and DASD/VSAM triage |
| `Batch-Inc-email` | `Batch-Inc-email.agent.md` | Automated batch incident email generation |
| `Stone branch-ESP batch request` | `Stone branch-ESP batch request.agent.md` | Stonebranch/ESP batch scheduling request automation |

All `Skills-zOS` agents operate under the **Senior z/OS Systems Programmer** persona defined in `.github/copilot-instructions.md`, with guardrails against modifying `SYS1.LINKLIB`, `SYS1.SVCLIB`, and APF list changes without explicit instruction.

---

### 3.3 Interview & Assessment Agents

**Repository:** `applied-ai-interview-assessment`

| Agent Name | File | Purpose |
|------------|------|---------|
| `zos-sysprog-interview-assesment` | `zos-sysprog-assessement.agent.md` | Structured technical interview for z/OS Systems Programmer candidates across all core mainframe domains |
| `zos-comm-assesment` | `zos-comm-assesment.agent.md` | Technical interview for z/OS Communications specialist (VTAM, TCPIP, Enterprise Extender) |
| `zos-storage-assessment` | `zos-storage-assessment.agent.md` | Technical interview for z/OS Storage specialist |

These agents conduct adaptive structured interviews, ask follow-up questions, and score candidates on a 1–5 proficiency scale per domain.

---

### 3.4 Migration Assistant Agents

**Repository:** `applied-ai-zos-migration-assistant`

#### `zos-upgrade-assistant`

| Property | Value |
|----------|-------|
| **File** | `.github/agents/zos-upgrade-assistant.agent.md` |
| **Purpose** | Interactive z/OS upgrade assistant. Presents a 9-phase step tracker covering the full migration pipeline. Technician selects connectivity mode (SSH via Zowe MCP / z/OSMF REST / offline file upload), then runs, marks complete, marks pending, or skips phases via slash commands. Delegates each phase to the corresponding `zos-migrate-0*` skill file. |
| **Phases** | 01 Inventory → 02 Compatibility → 03 Parmlib → 04 Proclib → 05 Exits → 06 IPL → 07 Comparison → 08 Checklist → 09 Project Plan |

---

#### General Agent (`problem-solver`)

**Repository:** `applied-ai-general-toolbox`

| Property | Value |
|----------|-------|
| **File** | `.github/agents/problem-solver.agent.md` |
| **Purpose** | Guides mainframe systems programmers through a structured problem-solving methodology to produce a clear, precise problem statement and actionable solution path. |

---

## 4. Skills (Reusable Instruction Modules)

Skills are `SKILL.md` files read at runtime by the AI using the `read/readFile` tool. They provide domain-specific instructions on demand without inflating the base context.

### Software Delivery Skills (`applied-ai-software-delivery`)

| Skill | File | Purpose |
|-------|------|---------|
| `package-transfer` | `skills/package-transfer/SKILL.md` | Automates secure transfer of Shopz packages from SDT factory to target LPARs via SFTP/FTP |
| `smpe-deployment` | `skills/smpe-deployment/SKILL.md` | Step-by-step guidance for SMP/E RECEIVE, APPLY, and ACCEPT with HOLDDATA analysis and error recovery |
| `shrinkwrap-guide-generator` | `skills/shrinkwrap-guide-generator/SKILL.md` | Template-based generation of Shrinkwrap Installation Guides (see `zosmf-install-guide-generator` agent) |

### z/OS Systems Skills (`Skills-zOS`)

| Skill | File | Purpose |
|-------|------|---------|
| `dcuf-system-info-doc` | `skills/dcuf-system-info-doc/SKILL.md` | Declarative system information for the DCUF LPAR (system variables, software versions, catalog structures, parmlib members, JES2 settings, SMP/E environment) |
| `holddata-action-review` | `skills/holddata-action-review/SKILL.md` | Transforms raw BYPASS(HOLDSYS) Action Plan reports into structured Maintenance Peer Review Reports |
| `holddata-bypass` | `skills/holddata-bypass/SKILL.md` | Generates SMP/E control statements for HOLD condition bypass (BYPASS operand syntax) |
| `sdt-package-transfer` | `skills/sdt-package-transfer/SKILL.md` | Use cases for moving packages from Atos SDT factory to client LPAR |
| `zos-dynamic-linklist` | `skills/zos-dynamic-linklist/SKILL.md` | Generates safe MVS operator commands for dynamic LNKLST additions/updates |
| `zos-zfs-migration` | `skills/zos-zfs-migration/SKILL.md` | Migrating z/OS file systems (HFS/zFS) to zFS Version 5 |

### General Toolbox Skills (`applied-ai-general-toolbox`)

| Skill | File | Purpose |
|-------|------|---------|
| `iodf-chpdetail` | `skills/iodf-chpdetail/SKILL.md` | Parses IBM HCD Channel Path Detail Reports; maps logical CHPIDs to physical PCHIDs |
| `knowledge-doc-creator` | `skills/knowledge-doc-creator/SKILL.md` | Interviews z/OS, CICS, and DB2 System Programmers to capture tacit knowledge as explicit documentation |

### Migration Assistant Skills (`applied-ai-zos-migration-assistant`)

| Skill | Phase | Purpose |
|-------|-------|---------|
| `zos-migrate-01-inventory` | Phase 01 | Software and hardware inventory |
| `zos-migrate-02-compatibility` | Phase 02 | z/OS compatibility checks |
| `zos-migrate-03-parmlib` | Phase 03 | Member-by-member PARMLIB analysis (syntax changes, new/deprecated parameters) |
| `zos-migrate-04-proclib` | Phase 04 | PROCLIB member comparison |
| `zos-migrate-05-exits` | Phase 05 | System exit inventory and compatibility |
| `zos-migrate-06-ipl` | Phase 06 | IPL sequence and LOADxx analysis |
| `zos-migrate-07-comparison` | Phase 07 | Structured comparison of PARMLIB, PROCLIB, LNKLST, APF between source and target |
| `zos-migrate-08-checklist` | Phase 08 | Synthesises all prior phases into a single ordered migration checklist + ServiceNow CHG body |
| `zos-migrate-09-plan` | Phase 09 | Timeline-driven project plan with milestones, resource assignments, critical path, and risk register |

---

## 5. MCP Servers

MCP (Model Context Protocol) servers expose callable tools that the AI model can invoke directly — analogous to function calling. They bridge the AI layer to live z/OS systems without requiring the user to copy/paste command output.

### 5.1 zos-toolkit (Node.js — Custom)

| Property | Value |
|----------|-------|
| **Location** | `applied-ai-general-toolbox/mcp-servers/zos-toolkit/server.js` |
| **Runtime** | Node.js ≥ 18.0.0 |
| **Transport** | `stdio` (VS Code spawns the process; JSON-RPC over stdin/stdout) |
| **SDK** | `@modelcontextprotocol/sdk` v1.29.0 |
| **Config File** | `applied-ai-general-toolbox/.vscode/mcp.json` |
| **Credentials** | `ZOWE_USER` / `ZOWE_PASSWORD` passed via environment variables (never stored in config or agent files) |
| **Scope** | Shared across all agents in the workspace — single server instance |

**VS Code `mcp.json` configuration:**
```json
{
  "servers": {
    "zos-toolkit": {
      "type": "stdio",
      "command": "node",
      "args": ["/home/a463476/repos/applied-ai-general-toolbox/mcp-servers/zos-toolkit/server.js"],
      "env": {
        "ZOWE_USER":     "${env:ZOWE_USER}",
        "ZOWE_PASSWORD": "${env:ZOWE_PASSWORD}"
      }
    }
  }
}
```

**VS Code `settings.json`** (enables MCP for Copilot):
```json
{
  "github.copilot.chat.mcp.enabled": true
}
```

#### Tool Catalogue

| Category | Tool Name | Description |
|----------|-----------|-------------|
| **Connectivity** | `check_zowe_connection` | Verify z/OSMF endpoint connectivity and server details |
| **z/OS Datasets** | `list_zos_datasets` | List datasets matching a pattern (Zowe `files list ds`) |
| | `read_zos_dataset` | Read a sequential dataset or PDS directory |
| | `read_pds_member` | Read a specific PDS/PDSE member |
| | `list_pds_members` | List members of a PDS/PDSE |
| **SMP/E** | `extract_sysmods_from_smpmcs` | Parse SMPMCS dataset to extract SYSMOD list |
| | `parse_shopz_packlist` | Parse IBM Shopz packing list to extract PTF list |
| | `parse_fixcat_report` | Parse IBM FixCat report to identify missing fixes |
| | `compare_sysmod_lists` | Diff two SYSMOD lists (received vs applied vs accepted) |
| | `parse_smprpt_status` | Extract SYSMOD status from SMPRPT output |
| **z/OS Jobs** | `submit_zos_job` | Submit JCL and return job ID |
| | `query_zos_job` | Get current job status |
| | `wait_for_zos_job` | Poll job to completion with timeout; optionally retrieve spool DD |
| | `get_job_output` | Retrieve specific spool DD (e.g. SMPOUT, SMPRPT, JESMSGLG) |
| | `list_zos_jobs` | List jobs by name pattern |
| **SSH** | `ssh_execute_command` | Execute a USS shell command on the LPAR via Zowe SSH |
| | `ssh_list_uss_files` | List files in a USS directory via Zowe SSH |
| **RSE API** | `rse_check_connection` | Verify RSE API endpoint health (`/info/serverdetails`) |
| | `rse_list_datasets` | List datasets via RSE API (alternative to z/OSMF) |
| | `rse_read_uss_file` | Read a USS file via RSE API |
| **Ansible** | `run_ansible_playbook` | Execute an Ansible playbook and return stdout/stderr |
| | `list_ansible_tasks` | List tasks in a playbook without executing |
| **Local Files** | `read_local_file` | Read a local file on the control node |
| | `list_maintenance_logs` | List and browse `ansible/logs/` directory |

**Internal architecture:** The server uses `zowe` CLI under the hood for dataset, job, and SSH operations (async `spawn` — never `spawnSync` to avoid blocking the StdioServerTransport event loop). RSE API calls are made directly via Node.js `https.request`. The Zowe config is read from `applied-ai-general-toolbox/zowe.config.json`.

---

### 5.2 Zowe MCP Server

The **Zowe MCP Server** is the official IBM/Zowe-project MCP server that exposes Zowe CLI functionality as MCP tools. It is used primarily by the migration assistant and health check agents when they need richer z/OS operations than the custom `zos-toolkit` provides.

| Property | Value |
|----------|-------|
| **Package** | `@zowe/zowe-mcp-server` (official Zowe project) |
| **Runtime** | Node.js |
| **Transport** | `stdio` |
| **Profile Source** | `zowe.config.json` at `applied-ai-general-toolbox/zowe.config.json` |
| **Typical Tools Exposed** | Dataset read/write, job submit/monitor, USS file operations, z/OSMF REST calls, TSO command execution |
| **Usage Context** | `zos-upgrade-assistant` and `zos-migration-healthcheck-assistant` agents reference it for live LPAR data collection during migration phases |

---

## 6. Control Node Requirements

### 6.1 VS Code & Extensions

| Component | Version in Use | Minimum | Notes |
|-----------|---------------|---------|-------|
| **VS Code** | 1.119.0 | 1.90 | Agent mode (`.agent.md`) requires VS Code 1.90+ |
| **GitHub Copilot** | Latest | — | Copilot subscription required |
| **GitHub Copilot Chat** | 0.48.1 | — | Includes agent mode and MCP support |
| **IBM Z Open Editor** | Latest | 3.0 | JCL/REXX/COBOL syntax, Zowe Explorer integration |
| **Zowe Explorer** | Latest | 3.0 | Dataset/USS/Jobs browsing via z/OSMF or RSE API |
| **Ansible Extension** | Latest | — | Playbook syntax, inventory support |
| **YAML Extension** | Latest | — | Ansible and Zowe config validation |

**Key VS Code configuration:**
- `github.copilot.chat.mcp.enabled: true` — enables MCP tool invocation from agents
- Agent files are registered automatically from `.github/agents/*.agent.md` within any open workspace folder
- Skills are registered from `.github/skills/**/SKILL.md` and referenced in `copilot-instructions.md`

### 6.2 Zowe CLI & Profiles

**Zowe CLI version:** v3.4.1 (z/OSMF plugin v8.31.1)

**Config file:** `applied-ai-general-toolbox/zowe.config.json`

Three connection profiles are active:

| Profile | Type | Host | Port | Purpose |
|---------|------|------|------|---------|
| `dcuf.zosmf` | z/OSMF | 138.69.218.201 | 443 (HTTPS) | Dataset ops, job submit/monitor, TSO |
| `dcuf.ssh` | SSH | 138.69.218.201 | 22 | USS command execution, file transfer |
| `dcuf.rse` | RSE API | 138.69.218.201 | 6800 (HTTPS) | IBM Remote System Explorer API |
| `dcub.zosmf` | z/OSMF | 10.75.10.85 | 443 (HTTPS) | Secondary LPAR (DCUB) |
| `dcub.ssh` | SSH | 10.75.10.85 | 22 | SSH to DCUB |

**Credentials:** Stored in the OS keyring (`autoStore: true`). For non-interactive use (MCP server, CI/CD), credentials are passed as environment variables `ZOWE_USER` / `ZOWE_PASSWORD` — keytar is bypassed entirely.

**`rejectUnauthorized: false`** is set for both LPARs — self-signed certificates are in use. In production, this should be replaced with a trusted CA certificate chain.

### 6.3 Ansible & Python

| Component | Version in Use | Minimum | Package |
|-----------|---------------|---------|---------|
| **Python** | 3.9.25 | 3.9 | System |
| **Ansible Core** | 2.14.18 | 2.12 | `pip install ansible-core` |
| **ibm.ibm_zos_core** | 1.16.0 | 1.9.0 | `ansible-galaxy collection install ibm.ibm_zos_core` |
| **ibm.ibm_zosmf** | 1.6.0 | 1.6.0 | `ansible-galaxy collection install ibm.ibm_zosmf` |
| **community.general** | 6.6.2 | 6.0.0 | Included with Ansible |
| **paramiko** | 3.0+ | 3.0 | `pip install paramiko` — SSH/SFTP for Python |
| **pyyaml** | 6.0+ | 6.0 | `pip install pyyaml` |
| **requests** | 2.28+ | 2.28 | `pip install requests` |

Ansible uses SSH (port 22) with `OpenSSH 8.7p1 / OpenSSL 3.5.1` as the transport. The `ibm.ibm_zos_core` modules execute on the z/OS managed node using Python 3.13 + ZOAU. SSH multiplexing is configured for performance (`ControlMaster=auto`, `ControlPersist=60s`).

### 6.4 SSH (zowex / Zowe Remote SSH)

**Zowe Remote SSH** (`zowex`) is the mechanism by which VS Code's Z Open Editor and the Zowe CLI SSH profile connect to z/OS USS. It provides:

- **Interactive USS sessions** from VS Code terminal
- **Remote file editing** of z/OS USS files directly in VS Code
- **Zowe CLI SSH commands** (`zowe uss issue ssh <command>`) — used by the `zos-toolkit` MCP server's `ssh_execute_command` and `ssh_list_uss_files` tools

**Authentication:** Ed25519 keypair (`~/.ssh/id_zos`) with SSH agent forwarding. Fallback to password-based auth via Zowe credential store.

**SSH profile in `zowe.config.json`:**
```json
"ssh": {
  "type": "ssh",
  "properties": { "port": 22 }
}
```

Zowe `uss issue ssh` wraps the z/OS OpenSSH subsystem and presents output as plain text (not JSON), unlike z/OSMF calls which return `--rfj` JSON.

---

## 7. z/OS LPAR Requirements

### 7.1 Core z/OS Components

| Component | Product ID | Version | Minimum | Notes |
|-----------|-----------|---------|---------|-------|
| **z/OS** | 5650-ZOS | 3.2 (ZS32D) | 2.3 | Primary target LPAR: DCUF |
| **SMP/E** | — | 37.35 | 37.00 | Required for all maintenance delivery agents |
| **JES2** | — | Active | Active | Job submission and spool management |
| **z/OS OpenSSH** | — | System-level | Any | Required for all SSH-based operations (Ansible, Zowe SSH) |
| **IBM Open Enterprise SDK for Python** | 5655-PYT | 3.13 | 3.9 | Required by `ibm.ibm_zos_core` Ansible modules on managed node |
| **IBM Z Open Automation Utilities (ZOAU)** | 5698-PA1 | v1r3 | v1.2.2 | Required by `ibm.ibm_zos_core` (provides `dmod`, `mvscmd`, ZOAU Python API) |
| **Java (IBM maintenance)** | IBM J21.0_64 | J21.0_64 | J8.0_64 | Required for SMP/E RECEIVE ORDER (IBM GIMZIP HTTPS delivery) |
| **Java (Broadcom/BMC maintenance)** | IBM J8.0 | J8.0 | J8.0 | Required for SMP/E RECEIVE ORDER (Broadcom/BMC GIMZIP) |

### 7.2 APIs Active on the LPAR

| API / Service | Port | Protocol | Purpose |
|---------------|------|----------|---------|
| **z/OSMF** | 443 | HTTPS | REST API for dataset operations, job submit/monitor, TSO, z/OSMF workflows; used by Zowe CLI z/OSMF profile |
| **RSE API** | 6800 | HTTPS | IBM Remote System Explorer API — alternative dataset/USS access path used by Zowe Explorer and the `rse_*` MCP tools; base path `/rseapi/api/v1` |
| **z/OS OpenSSH** | 22 | SSH | USS shell access; Ansible module execution; Zowe SSH profile |
| **AT-TLS** | (internal) | TLS | Policy-based TLS wrapping for SMP/E outbound HTTPS to IBM/Broadcom/BMC endpoints |

**z/OSMF services required:**
- `DataSets and Members` — `GET /zosmf/restfiles/ds/{dsn}`
- `Jobs` — `POST /zosmf/restjobs/jobs`, `GET /zosmf/restjobs/jobs/{jobid}`, spool retrieval
- `TSO/E address spaces` — `POST /zosmf/tsoApp/tso`
- `z/OSMF Information` — `GET /zosmf/info` (connectivity check)

**RSE API services required:**
- `/info/serverdetails` — health check
- `/datasets` — dataset listing
- `/unixfiles` — USS file read

### 7.3 RACF & Security Requirements

| Requirement | Detail |
|-------------|--------|
| **TSO user ID** | Required for all Zowe CLI z/OSMF operations; must have READ access to target datasets and submit authority for JES2 |
| **SMP/E job userid** | The SMP/E RECEIVE ORDER job userid requires READ access to the SMPNTS USS directory and outbound HTTPS via AT-TLS |
| **AT-TLS policy** | Outbound HTTPS on port 443 from the SMP/E job userid to `esw.ibm.com`, `delivery.broadcom.com`, `ftp.bmc.com` |
| **RACF keyrings** | `FTPACS/DCUFSMPE_SECINTKEYRING` (IBM SECINT certificate), `FTPACS/DCUFSMPE_KEYRING` (IBM client), `FTPACS/BCOMSMPE_KEYRING` (Broadcom), `FTPACS/BMCSMPE_KEYRING` (BMC) |
| **APF authorisation** | No changes to APF list are required for the maintenance delivery pipeline |
| **SMPNTS directory** | `/maint_zfs/ibm/smpnts`, `/maint_zfs/broadcom/smpnts`, `/maint_zfs/bmc/smpnts` — must exist on USS, `chmod 600`, RACF READ-only for SMP/E job userid |
| **Dataset profiles** | RACF READ access to all `ACSNS.*` and `ACSVS.*` product datasets for the technician's TSO userid; UPDATE access for the SMP/E job |

---

## 8. API Reference

### 8.1 z/OSMF REST API

z/OSMF (z/OS Management Facility) provides the primary REST API surface used by Zowe CLI and the `zos-toolkit` MCP server.

| Aspect | Detail |
|--------|--------|
| **Endpoint** | `https://138.69.218.201:443` |
| **Authentication** | Basic authentication (userid/password) over HTTPS |
| **Certificate** | Self-signed (`rejectUnauthorized: false`); production should use trusted CA |
| **Zowe Profile** | `dcuf.zosmf` |
| **How Used** | Zowe CLI wraps all z/OSMF calls; the MCP server uses `zowe` binary via async `spawn` |
| **Key Operations** | Dataset list/read, PDS member read, job submit, job status poll, job output retrieval, z/OSMF health check |
| **Alternative** | RSE API (port 6800) provides equivalent dataset/USS operations via a different REST interface |

### 8.2 RSE API (IBM Remote System Explorer)

The RSE API is IBM's Remote System Explorer service running on z/OS, providing an alternative REST interface to datasets and USS files.

| Aspect | Detail |
|--------|--------|
| **Endpoint** | `https://138.69.218.201:6800/rseapi/api/v1` |
| **Authentication** | HTTP Basic auth (`Authorization: Basic <base64>`) |
| **Zowe Profile** | `dcuf.rse` (type: `rseapi`) |
| **How Used** | Directly via Node.js `https.request` in the MCP server (no Zowe CLI wrapper for RSE calls) |
| **Key Operations** | Health check (`/info/serverdetails`), dataset listing (`/datasets`), USS file read (`/unixfiles`) |
| **Use Case** | Provides an alternative read path when z/OSMF is unavailable; used by Zowe Explorer for dataset browsing |

### 8.3 Zowe SSH (zowex)

Zowe's SSH integration provides shell access to USS from the control node.

| Aspect | Detail |
|--------|--------|
| **Protocol** | SSH (port 22) to z/OS OpenSSH |
| **Zowe Profile** | `dcuf.ssh` (type: `ssh`) |
| **Zowe CLI Command** | `zowe uss issue ssh "<command>" --ssh-profile dcuf.ssh` |
| **MCP Tools** | `ssh_execute_command` and `ssh_list_uss_files` in `zos-toolkit` |
| **Authentication** | Zowe credential store (keytar) for interactive use; `ZOWE_USER` / `ZOWE_PASSWORD` env vars for MCP server |
| **Output Format** | Plain text (stdout/stderr/exitCode) — not JSON |
| **Use Cases** | Read SMPNTS files, check USS directory contents, run USS utilities (`df`, `ls`, `bpxwmigf`), verify ZFS mount status |
| **VS Code Integration** | IBM Z Open Editor uses the SSH profile for remote file editing and terminal sessions on USS |

---

## 9. Network Topology

```
Control Node (Linux)                           z/OS LPAR — DCUF (138.69.218.201)
────────────────────                           ──────────────────────────────────
VS Code / Copilot                              
  └─► MCP: zos-toolkit ─── HTTPS :443 ──────► z/OSMF REST API
  └─► MCP: zos-toolkit ─── SSH   :22  ──────► z/OS OpenSSH (Zowe SSH / Ansible)
  └─► MCP: zos-toolkit ─── HTTPS :6800 ─────► RSE API
  └─► Ansible playbook ─── SSH   :22  ──────► ibm.ibm_zos_core modules
  └─► Zowe CLI         ─── HTTPS :443 ──────► z/OSMF (dataset / job / TSO)
  └─► Zowe CLI         ─── SSH   :22  ──────► USS shell commands

z/OS LPAR outbound (during SMP/E RECEIVE ORDER):
  z/OS LPAR ──────────── HTTPS :443 ──────────► esw.ibm.com (IBM Shopz)
  z/OS LPAR ──────────── HTTPS :443 ──────────► delivery.software.ibm.com
  z/OS LPAR ──────────── HTTPS :443 ──────────► delivery.broadcom.com
  z/OS LPAR ──────────── HTTPS :443 ──────────► ftp.bmc.com / support.bmc.com
  (All outbound HTTPS via AT-TLS / RACF keyrings)
```

---

## 10. Repository Structure

| Repository | Description | Key Contents |
|------------|-------------|--------------|
| `applied-ai-general-toolbox` | Shared tools and Zowe config | `zowe.config.json`, `mcp-servers/zos-toolkit/`, `.vscode/mcp.json` |
| `applied-ai-software-delivery` | SMP/E maintenance delivery automation | All software delivery agents, Ansible playbooks, JCL templates, docs |
| `Skills-zOS` | z/OS systems programming agents and skills | z/OS operational agents, DCUF system info skill, holddata skills |
| `applied-ai-zos-migration-assistant` | z/OS version migration assistant | 9-phase migration skills, `zos-upgrade-assistant` agent |
| `applied-ai-interview-assessment` | Technical interview agents | z/OS systems programmer, communications, and storage assessment agents |

**Agent file convention:** `.github/agents/<agent-name>.agent.md`  
**Skill file convention:** `.github/skills/<skill-name>/SKILL.md`  
**Persona config:** `.github/copilot-instructions.md` (one per repository)

---

*Document maintained by the SDT Applied AI Team*  
*Updated: 26th June 2026*
