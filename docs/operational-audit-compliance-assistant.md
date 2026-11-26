# Operational Audit & Compliance Assistant

**Agent Name:** `operational-audit-compliance-assistant`
**Repository:** applied-ai-software-delivery
**Target System:** DCUF (`dcuf.atos-nao.net`)
**Connection:** Zowe CLI profile `myLPAR` (z/OSMF 138.69.218.201:443)
**Last Updated:** May 26, 2026

---

## Overview

The `operational-audit-compliance-assistant` is an AI-driven compliance audit agent for the DCUF mainframe LPAR. It executes all registered IBM Health Checker categories live via Zowe CLI, produces a risk-scored compliance report, and automatically restores every health check to its exact pre-audit state after collection.

The report is designed for use by **z/OS Systems Programmers**, **SQA teams**, and **client compliance reviewers** — mapping every exception to an IBM best practice reference, the affected parmlib member, and a prioritized remediation action plan.

> **Read-Only Guarantee:** The agent never modifies parmlib members, system datasets, or system configuration. All remediation steps are generated for peer review only.

---

## Capabilities

| # | Capability | Detail |
|---|---|---|
| 1 | **Live Health Check Execution** | Executes all registered IBM Health Checker checks via `F HZSPROC` console commands through Zowe CLI against DCUF |
| 2 | **Pre-Audit State Management** | Captures the `ACTIVE` / `INACTIVE` state of every check before the audit begins; restores each check individually to its original state after collection — never issues bulk deactivation |
| 3 | **Multi-Source Collection** | Supports HZSPROC console (primary), SDSF CK REXX batch, HZSPRINT batch, SMF Type 89, and z/OSMF REST API |
| 4 | **Data Normalization** | Produces a structured JSON record per check including `pre_audit_state`, `normalized_status`, `severity`, `category`, `parmlib_members`, `risk_score`, and `ibm_reference` |
| 5 | **11 Compliance Domains** | SECURITY · STORAGE · PERFORMANCE · AVAILABILITY · IO_SUBSYSTEM · UNIX_SERVICES · NETWORK · JES_SPOOL · MIGRATION · SYSTEM_BASE · SUBSYSTEMS |
| 6 | **Risk Scoring (1–10)** | Severity base score adjusted for security/RACF (+2), Sysplex availability (+2), parmlib change required (+1), IPL required (+1) |
| 7 | **IBM Best Practice Correlation** | Every EXCEPTION and WARNING mapped to IBM publication reference with parmlib member and remediation steps |
| 8 | **Compliance Report Generation** | ASCII dashboard + executive summary + exception detail + prioritized remediation action plan → saved as `.md` and `.pdf` |
| 9 | **Historical Audit Tracking** | Every audit result written to `docs/audit-history/dcuf-audit-history.json` for trend analysis over time |
| 10 | **Full Audit Trail Logging** | Every command issued during the audit session logged with timestamps to `docs/audit-history/audit-trail.log` |
| 11 | **Trend Analysis** | Conversational queries across audit history — identify improving or deteriorating categories |
| 12 | **Scheduled Audit Support** | JCL (ESP/CA7) and Linux cron templates for automated weekly or pre/post-change audits |
| 13 | **Conversational AI Queries** | Natural language Q&A for SysProg, SQA, and management audiences against the latest or historical audit data |
| 14 | **Export Formats** | Markdown (`.md`), PDF (`.pdf`), HTML (`.html`), Excel (`.xlsx`) |

---

## Compliance Domains

| Domain Code | IBM Owner(s) | Coverage |
|---|---|---|
| `SECURITY` | IBMRACF, IBMICSF | RACF profiles, password controls, encryption, certificates, AT-TLS, ICSF |
| `STORAGE` | IBMDMO, IBMHSM, IBMCAT | DFSMS, HSM, catalog integrity |
| `PERFORMANCE` | IBMWLM, IBMASM, IBMVSM, IBMRSM | WLM service classes, page space, real/virtual storage |
| `AVAILABILITY` | IBMXCF, IBMRRS | Sysplex, XCF, Coupling Facility, RRS |
| `IO_SUBSYSTEM` | IBMIOS, IBMALLOC, IBMOCE | I/O supervisor, allocation, extended TIOT |
| `UNIX_SERVICES` | IBMUSS, IBMZFS | OMVS kernel, zFS, USS mounts, root FS size |
| `NETWORK` | IBMCS | TCP/IP, VTAM, Enterprise Extender, AT-TLS |
| `JES_SPOOL` | IBMJES2, IBMJES, IBMPFA | JES2 checkpoint, NJE security, predictive failure analysis |
| `MIGRATION` | IBMIOS, IBMWLM, IBMUSS, IBMCS | ZOSMIG* z/OS release migration readiness checks |
| `SYSTEM_BASE` | IBMSUP, IBMCSV, IBMGRS, IBMCNZ, IBMPDSE | CSV LPA/LNKLST/APF, GRS, console, nucleus |
| `SUBSYSTEMS` | IBMCICS, IBMDB2, IBMIMS, IBMMQ | CICS, DB2, IMS, MQ subsystem checks |

---

## How to Invoke

Open **VS Code Copilot Chat** and use the `@operational-audit-compliance-assistant` prefix.

---

### Run a Full Audit

```
@operational-audit-compliance-assistant run full audit
```

Executes all registered IBM Health Checker categories against DCUF across all 11 compliance domains.

**What happens:**
1. Pre-audit state snapshot captured (ACTIVE/INACTIVE per check)
2. Only INACTIVE checks are individually activated
3. All checks run: `F HZSPROC,RUN,CHECK=(*,*)`
4. Detailed results collected: `F HZSPROC,DISPLAY,CHECK=(*,*),DETAIL`
5. Results normalized, risk-scored, and correlated with IBM best practices
6. Compliance report generated and saved to `docs/audit-reports/`
7. Each check restored to its original pre-audit state individually

**Output:**
```
docs/audit-reports/audit-DCUF-YYYYMMDD.md
docs/audit-reports/audit-DCUF-YYYYMMDD.pdf
docs/audit-history/dcuf-audit-history.json   ← updated
docs/audit-history/audit-trail.log           ← updated
docs/audit-history/preaudit-state-YYYYMMDD.json
docs/audit-history/restore-state-YYYYMMDD.json
```

---

### Run a Category-Focused Audit

```
@operational-audit-compliance-assistant run audit SECURITY
@operational-audit-compliance-assistant run audit STORAGE
@operational-audit-compliance-assistant run audit MIGRATION
@operational-audit-compliance-assistant run audit AVAILABILITY
@operational-audit-compliance-assistant run audit PERFORMANCE
@operational-audit-compliance-assistant run audit JES_SPOOL
@operational-audit-compliance-assistant run audit UNIX_SERVICES
@operational-audit-compliance-assistant run audit NETWORK
@operational-audit-compliance-assistant run audit SYSTEM_BASE
@operational-audit-compliance-assistant run audit SUBSYSTEMS
@operational-audit-compliance-assistant run audit IO_SUBSYSTEM
```

Runs only the checks belonging to the specified domain and generates a focused category report.

---

### Display Compliance Dashboard

```
@operational-audit-compliance-assistant show dashboard
```

Renders an ASCII compliance dashboard with per-category scores, overall compliance percentage, and top risks:

```
╔══════════════════════════════════════════════════════════════════════╗
║        DCUF OPERATIONAL AUDIT DASHBOARD — 26 MAY 2026 12:00 UTC     ║
╠══════════════════════════════════════════════════════════════════════╣
║  OVERALL COMPLIANCE SCORE:  [██████████████░░░░░░] 70%               ║
╠══════════════════════════════════════════════════════════════════════╣
║  ✅ PASS     105 (70%)  ⚠️  WARNING  17 (11.3%)  ❌ EXCEPTION  24    ║
╠══════════════════════════════════════════════════════════════════════╣
║  SECURITY        [█████████░░░░░░░░░░░]  67%  ❌                    ║
║  STORAGE         [████████████████████] 100%  ✅                    ║
║  PERFORMANCE     [██████████████████░░]  92%  ✅                    ║
║  AVAILABILITY    [████████████████░░░░]  84%  ⚠️                    ║
║  MIGRATION       [█████████████░░░░░░░]  67%  ❌                    ║
║  SUBSYSTEMS      [████████░░░░░░░░░░░░]  44%  ❌                    ║
╚══════════════════════════════════════════════════════════════════════╝
```

---

### Export Report

```
@operational-audit-compliance-assistant export report as pdf
@operational-audit-compliance-assistant export report as md
@operational-audit-compliance-assistant export report as html
@operational-audit-compliance-assistant export report as excel
```

Saves the latest audit report to `docs/audit-reports/audit-DCUF-<YYYYMMDD>.<ext>` and confirms the file path.

---

### Show Compliance Trends

```
@operational-audit-compliance-assistant show trends
```

Loads `docs/audit-history/dcuf-audit-history.json` and presents exception count trends across all previous audits, highlighting improving or deteriorating categories.

---

### Conversational Queries

The agent answers natural language questions against the latest and historical audit data.

#### System Programmer Queries
```
@operational-audit-compliance-assistant query: what are the top 5 risks from the last audit?
@operational-audit-compliance-assistant query: which parmlib members need updating to resolve all exceptions?
@operational-audit-compliance-assistant query: which checks have been failing for more than 3 consecutive audits?
@operational-audit-compliance-assistant query: show me all EXCEPTION checks for the RACF category
@operational-audit-compliance-assistant query: generate JCL to run only the SECURITY category checks
@operational-audit-compliance-assistant query: what is the risk score for the WLM exception?
```

#### SQA / Auditor Queries
```
@operational-audit-compliance-assistant query: what is the current overall compliance score for DCUF?
@operational-audit-compliance-assistant query: has DCUF been compliant for the last 30 days?
@operational-audit-compliance-assistant query: export all exceptions with remediation steps to Excel
@operational-audit-compliance-assistant query: generate an executive summary for the change management committee
```

#### Management Queries
```
@operational-audit-compliance-assistant query: is DCUF ready for z/OS 3.2 migration?
@operational-audit-compliance-assistant query: show me the compliance trend for the last quarter
@operational-audit-compliance-assistant query: what are the top 3 risks I need to present to the client?
```

---

## Report Structure

Every full audit report contains the following sections:

| Section | Content |
|---|---|
| **Compliance Dashboard** | ASCII visual with overall score and per-category bars |
| **Executive Summary** | Total/evaluated/pass/warning/exception/error counts and compliance % |
| **Section A — EXCEPTION-HIGH** | Critical findings with full remediation steps, parmlib members, and IBM references |
| **Section B — WARNING** | EXCEPTION-MED findings table with risk scores and required actions |
| **Section C — EXCEPTION-LOW** | Advisory findings with remediation summary |
| **Section D — Errors** | CHECK-ERROR / UNEXP ERROR findings requiring investigation |
| **Section E — Remediation Action Plan** | Prioritized P1/P2/P3 table with owner, parmlib member, and urgency |
| **Section F — Compliant Checks** | Passed checks by domain confirming operational health |
| **Section G — Next Steps** | Immediate, short-term, and pre-migration actions |
| **Appendix** | Audit metadata (duration, commands issued, Zowe profile, HZSPROC STC) |

---

## Output Files Reference

| File Path | Description |
|---|---|
| `docs/audit-reports/audit-DCUF-<YYYYMMDD>.md` | Full compliance report in Markdown |
| `docs/audit-reports/audit-DCUF-<YYYYMMDD>.pdf` | PDF version for distribution and Change Records |
| `docs/audit-history/dcuf-audit-history.json` | Structured history of all audit runs with counts and scores |
| `docs/audit-history/audit-trail.log` | Timestamped log of every command issued during each audit |
| `docs/audit-history/preaudit-state-<YYYYMMDD>.json` | Per-check ACTIVE/INACTIVE snapshot before the audit |
| `docs/audit-history/restore-state-<YYYYMMDD>.json` | Post-audit restore verification record |

---

## Pre/Post-Change Audit Workflow

Use this pattern to capture a compliance baseline before a change window and verify the outcome after:

```
Step 1 — Before the Change Window
  @operational-audit-compliance-assistant run full audit
  → Baseline compliance snapshot saved to docs/audit-reports/

Step 2 — Execute the Change
  (Deploy PTF, update parmlib, apply SMP/E maintenance, etc.)

Step 3 — After the Change Window
  @operational-audit-compliance-assistant run full audit
  → Delta automatically computed: new exceptions + resolved items highlighted

Step 4 — Distribute to SQA / Client
  @operational-audit-compliance-assistant export report as pdf
  → PDF attached to ServiceNow Change Record
```

---

## Scheduled Audit Examples

### Weekly Cron (Linux Control Node — every Sunday 02:00)
```bash
0 2 * * 0 cd /home/a463476/repos/applied-ai-software-delivery && \
  ./scripts/bash/run-hc-audit.sh --profile myLPAR --format pdf \
  >> logs/hc-audit-cron.log 2>&1
```

### JCL Scheduled via ESP / CA7
```jcl
//HCAUDSCD JOB (ACCT),'SCHEDULED HC AUDIT',CLASS=A,MSGCLASS=X
//STEP1    EXEC PGM=IKJEFT01
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
  EXEC 'SYS2.EXEC.DCUF(HCSCHAUD)'
/*
```

### Recommended Audit Schedule

| Audit Type | Frequency | Scope |
|---|---|---|
| Full Compliance Audit | Weekly | All 11 categories |
| Security Audit | Daily | SECURITY domain only |
| Migration Readiness | Before any z/OS upgrade | MIGRATION domain only |
| Pre-Change Audit | Before any production change | Affected category |
| Post-Change Audit | Within 2 hours of change close | Affected category |

---

## Safety Rules

- The agent operates in **read-only mode** — it will never modify parmlib, datasets, or system configuration
- **NEVER** issues bulk `F HZSPROC,DEACTIVATE,CHECK=(*,*)` — each check is restored individually based on its recorded pre-audit state
- Checks originally `ACTIVE` before the audit remain `ACTIVE` after — no unnecessary disruption to running monitors
- Checks originally `INACTIVE` are selectively deactivated one at a time after results are collected
- A verification `F HZSPROC,DISPLAY,CHECK=(*,*)` is issued after restore to confirm state matches the pre-audit snapshot
- All remediation steps are provided for **peer review only** — implementation requires a separate approved change

---

## Related Agents

| Agent | Purpose | Invocation |
|---|---|---|
| `zos-migration-healthcheck-assistant` | ZOSMIG* migration readiness checks only | `@zos-migration-healthcheck-assistant run migration checks on myLPAR for z/OS 3.1 to 3.2` |
| `deployment-planner` | PTF deployment planning and risk assessment | `@deployment-planner analyze package S1234567` |
| `smpe-validator` | SMP/E zone health and dependency validation | `@smpe-validator check zone MVST100` |

---

*Maintained by: Mainframe Systems Programming Team*
*Agent definition: [.github/agents/operational-audit-compliance-assistant.agent.md](../.github/agents/operational-audit-compliance-assistant.agent.md)*
