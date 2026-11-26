# IBM Champion Advocacy: Building an AI-Driven SMP/E Maintenance Agent with IBM Bob

**Author:** A463476  
**Date:** 26 November 2026  
**Category:** Mainframe Modernization · AI-Assisted Software Delivery · IBM Bob

---

## Advocacy Activity Description (250 words)

Mainframe software maintenance is one of the most risk-intensive, detail-dependent activities in enterprise IT. Applying PTFs and RSUs via SMP/E typically requires a skilled systems programmer to author JCL, monitor job output across multiple phases, manually interpret HOLDDATA and GIM return codes, and decide whether it is safe to proceed — a process that is slow, error-prone, and entirely undocumented in real time.

Using **IBM Bob**, I built the `@maintenance-receive-apply` agent — an AI-driven agent that orchestrates the complete SMP/E internet maintenance lifecycle across three ISV vendors (IBM, Broadcom, and BMC) through natural language. IBM Bob investigated a 1,974-line Ansible playbook, six JCL Jinja2 templates, inventory files, and sibling agents before writing a single line of agent code. It authored the full agent specification, detected and fixed three incorrect job name prefixes by cross-referencing the actual template files, identified eight correctness and reliability gaps through independent gap analysis, applied targeted fixes, registered the agent in the team registry, validated the target SMP/E environment live against z/OSMF, and then extended the agent into a native IBM Bob persona — all within a single conversation.

The result is a dual-format agent: a GitHub Copilot Chat agent for human-driven interactive maintenance, and an IBM Bob persona that Bob can spawn as a subagent for programmatic orchestration.

This demonstrates how IBM Bob accelerates mainframe modernization not by replacing mainframe expertise, but by encoding it into repeatable, governed, AI-driven workflows that any team member can execute safely.

---

## Agent Overview

| Property | Value |
|---|---|
| **Agent name** | `maintenance-receive-apply` |
| **GitHub Copilot agent** | `.github/agents/maintenance-receive-apply.agent.md` |
| **IBM Bob persona** | `.bob/agents/maintenance-receive-apply.md` |
| **Backed by** | `ansible/playbooks/internet-maintenance.yml` (1,974 lines) |
| **Supported vendors** | IBM (ESW/Shopz) · Broadcom (delivery.broadcom.com) · BMC (BMC Support portal) |
| **Target platform** | IBM z/OS (DCUF LPAR, z/OSMF-connected) |
| **Copilot invocation** | `@maintenance-receive-apply` in GitHub Copilot Chat |
| **Bob invocation** | `spawn_subagent` with persona `maintenance-receive-apply`, or "Use the maintenance-receive-apply persona" |

---

## Dual-Format Architecture

The agent exists in two complementary formats, each serving a different consumption model:

### GitHub Copilot Chat Agent — Human-Invokable
**File:** `.github/agents/maintenance-receive-apply.agent.md`  
**Location convention:** `.github/agents/*.agent.md`  
**Invoked by:** A human typing `@maintenance-receive-apply` in Copilot Chat  
**Tools:** Granular Copilot tool namespaces (`vscode/askQuestions`, `execute/runInTerminal`, `agent/runSubagent`, etc.)  
**Purpose:** Full 9-step interactive workflow — the technician drives each gate decision in conversation

### IBM Bob Persona — Bob-Spawnable Subagent
**File:** `.bob/agents/maintenance-receive-apply.md`  
**Location convention:** `.bob/agents/*.md` (project-level, committed to repo)  
**Invoked by:** Bob via `spawn_subagent` with persona name, or "Use the maintenance-receive-apply persona"  
**Tools:** Bob tool groups (`read`, `edit`, `execute`, `search`)  
**Purpose:** Focused subagent that Bob delegates maintenance work to programmatically — same pipeline logic, Bob-native format

Both files share the same underlying knowledge — job names, gate mechanism, MCP monitoring pattern, resume scenarios, and error handling — but are expressed in the format native to each platform.

---

## How IBM Bob Built This

IBM Bob was not used as a code generator — it was used as an engineering partner that read the codebase, identified the right design, found bugs before deployment, improved the agent iteratively, and then extended it into the Bob-native persona format.

### 1 — Codebase Investigation Before Writing Anything

Bob read and cross-referenced:
- `ansible/playbooks/internet-maintenance.yml` (1,974 lines, 5-phase SMP/E pipeline)
- `ansible/templates/smpe_receive_ibm.j2`, `smpe_receive_broadcom.j2`, `smpe_receive_bmc.j2`
- `ansible/templates/smpe_apply_check.j2`, `smpe_apply.j2`, `smpe_accept.j2`
- `ansible/maintenance-defaults.yml` (registered product catalogue)
- `ansible/inventory/group_vars/all/main.yml` (inventory variables including `smpe_global_zone`, `smpe_bypass_holds`)
- `scripts/bash/run-maintenance.sh` (wrapper script for registered products)
- `.github/agents/sdt-maintenance-refresh-agent.agent.md` (sibling agent for format consistency)

No assumptions were made. Every job name, file path, variable, gate marker filename, and GIM return code in both agent files was verified against the actual source.

### 2 — Full Copilot Agent Authoring (434 lines, single operation)

Bob created the complete GitHub Copilot Chat agent specification covering:
- YAML frontmatter with granular Copilot tool permissions
- Role & behaviour rules (MCP-first, gate mechanism, inventory variable sourcing)
- 9-step process flow with exact shell commands, MCP call patterns, and UI display templates
- Resume scenarios (4 paths)
- Error handling table (10 GIM conditions)
- Acceptable RC table
- SMPNTS credential file reference for all three vendors
- Outbound network prerequisite table

### 3 — Bug Detection (Before First Use)

By cross-checking against JCL templates, Bob found three bugs before the agent was ever run:

| Bug | Wrong value | Correct value | Source |
|---|---|---|---|
| Broadcom RECEIVE job prefix | `BCRCV` | `BCMRCV` | `smpe_receive_broadcom.j2` job card |
| APPLY vs APPLY CHECK job suffix | Ambiguous | `{pfx}APK` = check, `{pfx}APL` = live | Template step name analysis |
| APPLY template reference | `smpe_apply.j2` | `smpe_apply_check.j2` with `apply_check_mode: false` | Playbook line 1216 |

### 4 — Independent Gap Analysis (8 issues identified and fixed)

After creation, Bob independently analysed the agent against the codebase and surfaced eight gaps:

| Priority | Gap | Fix Applied |
|---|---|---|
| 🔴 Critical | APPLY template reference wrong | Corrected to `smpe_apply_check.j2` with mode flag |
| 🔴 Critical | Cycle marker reset too broad (all vendor) | Scoped to `{vendor}_{csi_key}` |
| 🔴 Critical | APPLY CHECK job polling step missing | Added explicit MCP step between RECEIVE and gate |
| 🟡 Reliability | `run-maintenance.sh` path not offered | Added Step 1a (registered) / 1b (unregistered) split |
| 🟡 Reliability | `smpe_global_zone` inventory variable undocumented | Added bullet with override guidance |
| 🟡 Reliability | `smpe_test_mode` flag not documented | Added Test/dry-run resume scenario |
| 🟡 Reliability | HOLD bypass log path bare/relative | Prefixed with `cd .../ansible &&` |
| 🟡 Discoverability | Agent not registered in `AGENTS.md` | Added full entry to registry |

### 5 — Live z/OSMF Validation

In the same session, Bob:
- Connected to z/OSMF (`localhost:443` → `138.69.218.201`) via REST API
- Authenticated as `SYSSA69` (HTTP 200 — `Basic realm="defaultRealm"`, Liberty server confirmed)
- Retrieved 200+ z/OS software instances via `/zosmf/swmgmt/swi`
- Located `TDMF_ZOSMFA_V5R11M0` (the agent's default product) with UUID `889587d9-...`
- Retrieved `MISFXCT JOB04938` SMPRPT spool output
- Confirmed **RC=0, `***NONE` — no missing critical fixes** for CSI `ACSVS.TDMF.V5R11M0.ZOSMFA.GLOBAL.CSI`
- Saved the report to `docs/tdmf_zosmfa_missing_critical_fixes.json`
- Submitted a fresh `MISFXCT JOB08281` for `ZOS25_RSU2606` and retrieved its full SMPRPT

### 6 — IBM Bob Persona Creation (Bob-native format)

After consulting IBM Bob documentation on the persona format, Bob:
- Created `.bob/agents/maintenance-receive-apply.md` using the correct Bob persona schema
- Used group-level tool declarations (`read`, `edit`, `execute`, `search`) — not Copilot namespaces
- Condensed the 9-step Copilot workflow into a focused Bob persona body with identity, input checklist, reference tables, execution steps, resume table, error table, output format rules, and constraints
- Updated `AGENTS.md` to list both files clearly — Copilot agent (human-invokable) and Bob persona (Bob-spawnable)

---

## Benefits: Bypassing Manual SMP/E Steps

Traditional SMP/E internet maintenance requires a systems programmer to execute every step manually. The agent eliminates or automates each of these:

### Manual Step 1 — Locate vendor credentials and order server details
**Manual:** Look up Shopz/Broadcom/BMC portal credentials, GIMZIP order server hostnames, SSL trust requirements, and SMPNTS credential file format for the specific vendor.  
**Agent:** Credentials are pre-staged at `/maint_zfs/{vendor}/smpnts`. The agent knows each vendor's order server, credential format, RACF keyring requirements, and outbound firewall ports. The technician provides only the vendor name.

### Manual Step 2 — Author the RECEIVE ORDER JCL
**Manual:** Copy a JCL template, fill in the CSI DSN, zone name, SMPNTS DD path, `SET BDY()` global zone name, timeout parameter, and job accounting information. One typo causes a GIM failure.  
**Agent:** `smpe_receive_{vendor}.j2` is rendered automatically from inventory variables. No JCL editing required.

### Manual Step 3 — Submit and monitor the RECEIVE job
**Manual:** Submit via TSO/SDSF or Zowe CLI. Repeatedly check JES spool. Watch for `GIM20502I` (completion). Manually interpret any `GIM53200E` (credentials), `GIM35401E` (network), or `GIM69145W` (zero SYSMODs) conditions.  
**Agent:** One MCP call — `wait_for_zos_job(job_id=..., ddname="SMPOUT", max_lines=30)` — waits up to 4 hours and returns key messages. All GIM codes are mapped to specific actions in the error table.

### Manual Step 4 — Run APPLY CHECK and read the report
**Manual:** Author and submit a separate APPLY CHECK job. Read SMPRPT output from spool. Manually count SYSMODs in PENDING-APPLY status. Identify HOLD classes, check if HOLDSYS bypasses are acceptable.  
**Agent:** APPLY CHECK runs automatically after RECEIVE. The agent reads the gate marker, parses SYSMOD counts, and surfaces a formatted HOLD Bypass Action Plan before asking for approval.

### Manual Step 5 — Decide whether to proceed with APPLY
**Manual:** Engineer judgement call. No formal gate. Easy to accidentally proceed when HOLDs are unreviewed.  
**Agent:** Explicit `yes/no` gate with SYSMOD counts, HOLD summary, and bypass plan presented in chat. The gate marker file (`gate_apply_confirmed.marker`) creates a durable audit record of the decision.

### Manual Step 6 — Submit and monitor APPLY
**Manual:** Author another JCL with the correct `BYPASS()` operands. Submit. Monitor. If RC=8, diagnose from raw SMPOUT.  
**Agent:** `smpe_apply_check.j2` renders with `apply_check_mode: false`. MCP monitors the job. On RC > 4, the agent halts (never re-runs) and escalates to `@rollback-planner`.

### Manual Step 7 — Run ACCEPT CHECK and ACCEPT
**Manual:** Two more JCL jobs. ACCEPT CHECK is often skipped under time pressure, risking incomplete DLIB promotion.  
**Agent:** ACCEPT CHECK is mandatory. A second gate presents the list of SYSMODs queued for ACCEPT. ACCEPT only runs after the technician approves.

### Manual Step 8 — Document the run
**Manual:** Relies on 7-day JES spool retention. No structured audit trail.  
**Agent:** Each cycle produces JSON audit logs, per-phase Markdown reports, and a structured `maintenance_report_{vendor}_{timestamp}.md` with all job IDs, RCs, and SYSMOD counts.

---

## Benefits for IBM Bob and Mainframe Modernization

| Capability | Traditional Approach | With IBM Bob |
|---|---|---|
| Agent specification quality | Manual authoring, often incomplete or outdated | Grounded in live codebase reading — no speculation |
| Bug detection | Found in production | Found before first use by cross-referencing source files |
| Gap analysis | Requires SME review cycles over days | Bob independently identifies reliability gaps from codebase analysis |
| Iteration speed | Days to write, review, and test | Full agent spec + bug fixes + gap resolution in one conversation |
| Knowledge encoding | Lives in individual engineers' heads | Encoded into versioned, reviewable files in source control |
| Platform reach | One format, one platform | Dual format: Copilot Chat (human) + Bob persona (programmatic) |
| Maintenance governance | Ad-hoc, relies on engineer discipline | Mandatory two-gate review model with durable audit trail |
| Multi-vendor complexity | Separate runbooks per vendor | Single agent, vendor resolved from one input |
| Recovery from failure | Manual diagnosis from JES spool | Four documented resume paths with exact syntax |

IBM Bob demonstrates that AI-assisted development for the mainframe is not about replacing z/OS expertise — it is about encoding that expertise into governed, repeatable, AI-driven workflows. The result is faster delivery, reduced human error, and a lower barrier to entry for the next generation of mainframe practitioners.

---

## Invocation Reference

### As a GitHub Copilot Chat agent (human-driven)
```
@maintenance-receive-apply Hi
@maintenance-receive-apply apply IBM TDMF maintenance
@maintenance-receive-apply apply Broadcom CA Auditor RSU maintenance
@maintenance-receive-apply apply BMC AMI Ops maintenance
@maintenance-receive-apply resume after RECEIVE failure job JOB01234
```

### As an IBM Bob persona (Bob-driven / programmatic)
```
Use the maintenance-receive-apply persona to apply IBM TDMF maintenance.

Spawn a subagent using the maintenance-receive-apply persona.
Run maintenance for the product registered as tdmf-zosmfa.
```

---

## Repository Layout

```
applied-ai-software-delivery/
├── .bob/
│   └── agents/
│       └── maintenance-receive-apply.md          ← IBM Bob persona (Bob-native)
├── .github/
│   ├── AGENTS.md                                 ← Registry (both files listed)
│   └── agents/
│       └── maintenance-receive-apply.agent.md    ← GitHub Copilot Chat agent
├── ansible/
│   ├── maintenance-defaults.yml                  ← Registered product catalogue
│   └── playbooks/
│       └── internet-maintenance.yml              ← Execution engine (1,974 lines)
├── docs/
│   ├── ibm-champion-advocacy-maintenance-receive-apply-agent.md  ← This file
│   └── tdmf_zosmfa_missing_critical_fixes.json   ← z/OSMF validated report
└── scripts/
    └── bash/
        └── run-maintenance.sh                    ← Registered-product wrapper
```

---

## Related Agents

| Agent | Format | Purpose |
|---|---|---|
| `maintenance-receive-apply` | Copilot + Bob | This agent — internet maintenance only (no restore/DDDEF) |
| `sdt-maintenance-refresh-agent` | Copilot | Full pipeline: ADRDSSU restore, DDDEF update, maintenance, shrinkwrap |
| `rollback-planner` | Copilot | SMP/E RESTORE procedure for failed APPLY or ACCEPT |
| `smpe-validator` | Copilot | HOLDSYS hold analysis and change approval support |

---

*Document generated with IBM Bob — Applied AI Software Delivery*
