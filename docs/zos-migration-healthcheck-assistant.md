# z/OS Migration Health Check Assistant

**Agent Name:** `zos-migration-healthcheck-assistant`
**Repository:** applied-ai-software-delivery
**Target System:** DCUF (`dcuf.atos-nao.net`)
**Connection:** Zowe CLI profile `myLPAR` (z/OSMF 138.69.218.201:443)
**Last Updated:** May 26, 2026

---

## Overview

The `zos-migration-healthcheck-assistant` is an AI agent that executes IBM Health Checker **ZOSMIG\*** checks live against a target LPAR via Zowe CLI, interprets the results, and produces a formal **Migration Health Report** suitable for inclusion in a ServiceNow Change Record.

It is scoped exclusively to z/OS release migration readiness — identifying parmlib defaults, deprecated functions, and system configuration items that must be resolved before migrating to the target z/OS release.

> **Read-Only Guarantee:** The agent never modifies parmlib members or system configuration. All remediation steps are generated for peer review only.

---

## Capabilities

| # | Capability | Detail |
|---|---|---|
| 1 | **Live ZOSMIG\* check execution** | Executes all ZOSMIG\* IBM Health Checker checks against a target LPAR via Zowe CLI |
| 2 | **Pre-audit state management** | Captures the `ACTIVE` / `INACTIVE` state of every ZOSMIG\* check before the audit; restores each check individually to its original state after collection — never issues bulk deactivation |
| 3 | **Result interpretation** | Parses IBM Health Checker status codes: `SUCCESSFUL`, `EXCEPTION-LOW`, `EXCEPTION-HIGH`, `CHECK-ERROR`, `INACTIVE` |
| 4 | **Exception remediation guidance** | For every exception, provides step-by-step parmlib changes, operator commands, or JCL with IBM Migration Guide references |
| 5 | **Successful check explanation** | For every passing check, documents what was verified, why it passed, and a compliance statement |
| 6 | **Migration readiness verdict** | Issues a `READY` / `NOT READY` verdict with a clear statement of what blocks migration |
| 7 | **Structured report generation** | Produces a Migration Health Report in Markdown with executive summary, passed checks, exceptions, remediation action plan, and next steps |
| 8 | **Report download** | Saves report as `.md` (Markdown) or `.pdf` (PDF via `md2pdf`) |
| 9 | **Raw output analysis** | Accepts pasted `F HZSPROC,DISPLAY,DETAIL` output directly — no live connection required |

---

## ZOSMIG\* Checks Coverage

The agent has a built-in knowledge base for all registered DCUF ZOSMIG\* checks:

| Check Name | Owner | Purpose |
|---|---|---|
| `ZOSMIGV2R4PREV_CS_IWQSC_TCPIP` | IBMCS | Verify sufficient fixed storage for IWQ IPSEC enablement |
| `ZOSMIG32_NEXT_IOS_PLIB_DEFAULTS` | IBMIOS | Identify IOS parmlib defaults that will silently change in z/OS 3.2 |
| `ZOSMIG32_NEXT_IOS_DEPRECATIONS` | IBMIOS | Detect use of IOS functions being deprecated in z/OS 3.2 |
| `ZOSMIG32_WLM_OPT_CPENABLE` | IBMWLM | Verify WLM `CPENABLE` is explicitly set before default changes in z/OS 3.2 |
| `ZOSMIGREC_ROOT_FS_SIZE` | IBMUSS | Verify z/OS root file system is large enough for the new release |
| `ZOSMIGREC_SUP_TIMER_INUSE` | IBMTIMER | Verify STP (Server Time Protocol) is active for Sysplex |

---

## How to Invoke

Open **VS Code Copilot Chat** and use the `@zos-migration-healthcheck-assistant` prefix.

---

### Run Migration Health Checks

```
@zos-migration-healthcheck-assistant run migration checks on myLPAR for z/OS 3.1 to 3.2
```

Provide any combination of:
- **Zowe profile name** (e.g., `myLPAR`)
- **Current z/OS level** (e.g., `z/OS 3.1`)
- **Target migration level** (e.g., `z/OS 3.2`)

**What happens:**

| Step | Action |
|---|---|
| **2a** | `F HZSPROC,DISPLAY,CHECK=(*,ZOSMIG*)` — capture pre-audit ACTIVE/INACTIVE state of every ZOSMIG\* check |
| **2b** | `F HZSPROC,ACTIVATE,CHECK=(<owner>,<name>)` — individually activate only the checks that were INACTIVE |
| **2c** | `F HZSPROC,RUN,CHECK=(*,ZOSMIG*)` — run all ZOSMIG\* checks |
| **2d** | `F HZSPROC,DISPLAY,CHECK=(*,ZOSMIG*),DETAIL` — retrieve detailed results |
| **2e** | Per-check restore — `F HZSPROC,DEACTIVATE,CHECK=(<owner>,<name>)` for each originally-INACTIVE check only |
| **2f** | Verification `F HZSPROC,DISPLAY,CHECK=(*,ZOSMIG*)` — confirm all checks match their pre-audit state |

---

### Analyze Raw Output (Offline Mode)

If Zowe CLI is not available, paste the raw `F HZSPROC,DISPLAY,DETAIL` output directly into the chat:

```
@zos-migration-healthcheck-assistant
<paste raw F HZSPROC,DISPLAY,CHECK=(*,ZOSMIG*),DETAIL output here>
```

The agent parses the output, maps each check to its knowledge base, and generates the full Migration Health Report without requiring a live connection.

---

### Download the Report

```
@zos-migration-healthcheck-assistant download report as md
@zos-migration-healthcheck-assistant download report as pdf
```

Saves the report to the current workspace:
```
docs/migration-health-report-DCUF-YYYYMMDD.md
docs/migration-health-report-DCUF-YYYYMMDD.pdf
```

---

## Report Structure

Every Migration Health Report contains the following sections:

| Section | Content |
|---|---|
| **Executive Summary** | Total checks, pass/exception counts, migration readiness verdict (`READY` / `NOT READY`) |
| **Section 1 — Successful Checks** | Summary table + per-check detail: what was checked, why it passed, compliance statement |
| **Section 2 — Exceptions Requiring Action** | Full exception detail: owner, severity, issue description, risk, remediation steps, urgency |
| **Section 3 — Remediation Action Plan** | Prioritized table: action, owner, parmlib member, priority, status |
| **Section 4 — Next Steps** | Resolve exceptions → re-run checks → attach to Change Record → peer review sign-off |
| **Section 5 — Download** | Instructions to save report as `.md` or convert to `.pdf` |

---

## Example Report Output

### Executive Summary Table

| Total Checks | Successful | Exception-Low | Exception-High | Migration Blocked |
|---|---|---|---|---|
| 6 | 4 | 2 | 0 | NO — advisory items only |

**Migration Readiness:** ⚠️ NOT READY — 2 advisory exceptions must be resolved before scheduling migration

---

### Successful Check — Example Detail

```
Check Detail: ZOSMIGREC_SUP_TIMER_INUSE
  Owner:      IBMTIMER  |  Exit Routine: IEATCADC
  Verified:   STP (Server Time Protocol) is active and in use for Sysplex
              time synchronisation — prerequisite for z/OS 3.2 Parallel Sysplex
  Why passed: STP is confirmed active on DCUF. Sysplex timing infrastructure
              is correctly configured and compatible with z/OS 3.2
  Statement:  DCUF Sysplex timer configuration (STP) meets z/OS 3.2 requirements
```

---

### Exception — Example Detail

```
Exception: ZOSMIG32_NEXT_IOS_PLIB_DEFAULTS
  Owner:     IBMIOS  |  Severity: EXCEPTION-LOW
  Issue:     IOS parmlib defaults will silently change at z/OS 3.2 migration
  Risk:      Unintended I/O behaviour change post-migration if not resolved
  Remediation:
    1. Review IECIOSxx parmlib member — explicitly code current default values
    2. Run F IOS,PARMLIB to display current active settings
    3. Compare against z/OS 3.2 Migration Guide — IOS chapter
    4. Add explicit values for any parameter where the default is changing
    5. Test in DEV/TEST before PROD migration
  Urgency:   ⚠️ Required Before Migration
```

---

## Live DCUF Results (May 26, 2026 — z/OS 3.1 → 3.2)

| Check | Owner | Status | Action |
|---|---|---|---|
| `ZOSMIGV2R4PREV_CS_IWQSC_TCPIP` | IBMCS | ✅ SUCCESSFUL | None |
| `ZOSMIG32_NEXT_IOS_PLIB_DEFAULTS` | IBMIOS | ❌ EXCEPTION-LOW | Explicitly code IECIOSxx defaults |
| `ZOSMIG32_NEXT_IOS_DEPRECATIONS` | IBMIOS | ✅ SUCCESSFUL | None |
| `ZOSMIG32_WLM_OPT_CPENABLE` | IBMWLM | ❌ EXCEPTION-LOW | Set CPENABLE in IWMPRMxx |
| `ZOSMIGREC_ROOT_FS_SIZE` | IBMUSS | ✅ SUCCESSFUL | None |
| `ZOSMIGREC_SUP_TIMER_INUSE` | IBMTIMER | ✅ SUCCESSFUL | None |

**Result:** 4 PASS · 2 EXCEPTION-LOW · Migration readiness: **67%**
**Saved:** `docs/migration-health-report-DCUF-20260526.md` / `.pdf`

---

## Pre-Audit State Management

The agent precisely tracks and restores the state of each ZOSMIG\* check:

```
Pre-audit snapshot (Step 2a):
  IBMCS,ZOSMIGV2R4PREV_CS_IWQSC_TCPIP    = INACTIVE  → will ACTIVATE → will DEACTIVATE after
  IBMIOS,ZOSMIG32_NEXT_IOS_PLIB_DEFAULTS  = INACTIVE  → will ACTIVATE → will DEACTIVATE after
  IBMIOS,ZOSMIG32_NEXT_IOS_DEPRECATIONS   = INACTIVE  → will ACTIVATE → will DEACTIVATE after
  IBMWLM,ZOSMIG32_WLM_OPT_CPENABLE       = INACTIVE  → will ACTIVATE → will DEACTIVATE after
  IBMUSS,ZOSMIGREC_ROOT_FS_SIZE           = ACTIVE    → left untouched → left untouched
  IBMTIMER,ZOSMIGREC_SUP_TIMER_INUSE      = INACTIVE  → will ACTIVATE → will DEACTIVATE after

Post-audit restore verification (Step 2f):
  All 6 checks confirmed matching their pre-audit state
```

---

## Safety Rules

- **NEVER** issues `F HZSPROC,DELETE` or `F HZSPROC,REMOVE`
- **NEVER** issues bulk `F HZSPROC,DEACTIVATE,CHECK=(*,ZOSMIG*)` — checks originally ACTIVE are never deactivated
- **ALWAYS** captures the pre-audit state snapshot before any ACTIVATE command
- **ALWAYS** restores each check individually to its original state after collection
- **ALWAYS** verifies the restore with a final `F HZSPROC,DISPLAY,CHECK=(*,ZOSMIG*)` and compares against the snapshot
- **NEVER** makes parmlib changes directly — all changes are generated for peer review
- **ALWAYS** recommends testing remediation in DEV/TEST before PROD

---

## Related Agents

| Agent | Purpose | When to Use |
|---|---|---|
| `operational-audit-compliance-assistant` | Full IBM Health Checker audit across all 11 categories | Full compliance baseline, pre/post-change audit, SQA/client report |
| `deployment-planner` | PTF deployment planning and risk assessment | Before applying maintenance |
| `rollback-planner` | Rollback procedures for deployments | Contingency planning |

---

*Maintained by: Mainframe Systems Programming Team*
*Agent definition: [.github/agents/zos-migration-healthcheck-assistant.agent.md](../.github/agents/zos-migration-healthcheck-assistant.agent.md)*
