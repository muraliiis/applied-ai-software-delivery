# z/OS Migration Health Check Report

**System:** DCUF
**LPAR:** dcuf.atos-nao.net (`myLPAR`)
**Current z/OS:** 3.1 (05.29.00)
**Target z/OS:** 3.2
**Report Date:** 26 May 2026 — 04:24 UTC
**Executed By:** SYSSA69

---

## Executive Summary

| Total Checks | Successful | Exception-Low | Exception-High | Migration Blocked |
|---|---|---|---|---|
| 6 | 4 | 2 | 0 | NO |

**Migration Readiness: NOT READY** — 2 exceptions must be resolved before scheduling z/OS 3.2 migration.

---

## Section 1: Successful Checks — Compliance Confirmed

| Check | Owner | Last Run | Status |
|---|---|---|---|
| ZOSMIGV2R4PREV_CS_IWQSC_TCPIP | IBMCS | 26/05/2026 04:24 | SUCCESSFUL |
| ZOSMIG32_NEXT_IOS_DEPRECATIONS | IBMIOS | 26/05/2026 04:24 | SUCCESSFUL |
| ZOSMIGREC_ROOT_FS_SIZE | IBMUSS | 26/05/2026 04:24 | SUCCESSFUL |
| ZOSMIGREC_SUP_TIMER_INUSE | IBMTIMER | 26/05/2026 04:24 | SUCCESSFUL |

### Check Detail: ZOSMIGV2R4PREV_CS_IWQSC_TCPIP

- **Owner:** IBMCS | **Exit Routine:** EZBHCAC1
- **What was checked:** Verified that sufficient fixed storage (CSA/ECSA) is available to support IWQ IPSEC enablement required by z/OS Communications Server
- **Why it passed:** Current fixed storage allocation meets the minimum threshold for IWQ IPSEC. No changes to `IEASYSxx` CSA/REAL parameters are required before migration
- **Compliance Statement:** DCUF Communications Server storage configuration is compatible with z/OS 3.2

### Check Detail: ZOSMIG32_NEXT_IOS_DEPRECATIONS

- **Owner:** IBMIOS | **Exit Routine:** IOSHCADC
- **What was checked:** Scanned active IOS configuration for use of any I/O Supervisor functions that are being deprecated or removed in z/OS 3.2
- **Why it passed:** No deprecated IOS functions are actively in use on DCUF. All I/O processing paths use current supported interfaces
- **Compliance Statement:** DCUF IOS function usage is fully compatible with z/OS 3.2. No JCL, parmlib, or exit changes are required

### Check Detail: ZOSMIGREC_ROOT_FS_SIZE

- **Owner:** IBMUSS | **Exit Routine:** BPXHCADC | **Minimum Required:** 200 cylinders
- **What was checked:** Measured the allocated size of the z/OS UNIX root file system (`/`) to ensure it is large enough to accommodate the new z/OS 3.2 root content during ServerPac or SMP/E installation
- **Why it passed:** The root zFS on DCUF meets or exceeds the 200-cylinder minimum threshold. The installation will not halt due to insufficient root FS space
- **Compliance Statement:** DCUF root file system capacity is sufficient for z/OS 3.2 migration

### Check Detail: ZOSMIGREC_SUP_TIMER_INUSE

- **Owner:** IBMTIMER | **Exit Routine:** IEATCADC
- **What was checked:** Verified that Server Time Protocol (STP) is active and in use for Sysplex time synchronisation, which is a prerequisite for z/OS 3.2 in a Parallel Sysplex environment
- **Why it passed:** STP is confirmed active on DCUF. The Sysplex timing infrastructure is correctly configured and compatible with z/OS 3.2
- **Compliance Statement:** DCUF Sysplex timer configuration (STP) meets z/OS 3.2 requirements

---

## Section 2: Exceptions Requiring Action

### Exception 1 — ZOSMIG32_NEXT_IOS_PLIB_DEFAULTS

- **Owner:** IBMIOS | **Exit Routine:** IOSHCADC
- **Severity:** EXCEPTION-LOW
- **Issue:** One or more IOS parmlib parameters are currently relying on default values that will silently change at z/OS 3.2 migration time
- **Risk:** Unexpected I/O behaviour or subsystem startup failures post-migration if defaults are not explicitly locked in
- **Remediation:**
  1. Run `F IOS,PARMLIB` to display currently active IOS parmlib settings
  2. Review `IECIOSxx` in `SYS1.PARMLIB` (DCUF user mod: `ZOSXF18`)
  3. Compare each parameter against *z/OS 3.2 Migration Guide — IOS chapter*
  4. Explicitly code current values for any parameter whose default changes in 3.2
  5. Test updated `IECIOSxx` in DEV/TEST before applying to PROD
- **Urgency:** Required Before Migration

### Exception 2 — ZOSMIG32_WLM_OPT_CPENABLE

- **Owner:** IBMWLM | **Exit Routine:** IWMHCADD
- **Severity:** EXCEPTION-LOW
- **Issue:** WLM OPT parameter `CPENABLE` default value changes in z/OS 3.2 — not currently set explicitly in `IWMPRMxx`
- **Risk:** WLM workload behaviour will change silently post-migration — potential performance or dispatch priority impact
- **Remediation:**
  1. Check current CPENABLE value: `D WLM,PARMS`
  2. Locate active `IWMPRMxx` member in `SYS1.PARMLIB`
  3. Explicitly code the option to preserve current behaviour:
     `OPT CPENABLE(NO)   /* match current effective value */`
  4. Refresh WLM: `F WLM,REFRESH` and re-run health check to confirm
- **Urgency:** Required Before Migration

---

## Section 3: Remediation Action Plan

| # | Action | Owner | Parmlib Member | DCUF User Mod | Priority | Status |
|---|---|---|---|---|---|---|
| 1 | Explicitly code IOS parmlib defaults | z/OS SysProg | IECIOSxx | ZOSXF18 | High | Open |
| 2 | Explicitly set CPENABLE in IWMPRMxx | z/OS SysProg | IWMPRMxx | — | High | Open |

---

## Section 4: Next Steps

1. Resolve both exceptions above in DEV/TEST before production migration
2. Re-run health checks post-remediation to confirm all 6 checks SUCCESSFUL:
   `zowe zos-console issue command "F HZSPROC,RUN,CHECK=(*,ZOSMIG*)" --zosmf-profile myLPAR`
3. Deactivate ZOSMIG* checks after validation:
   `zowe zos-console issue command "F HZSPROC,DEACTIVATE,CHECK=(*,ZOSMIG*)" --zosmf-profile myLPAR`
4. Attach this report to the ServiceNow Change Record for the z/OS 3.2 migration
5. Obtain peer review sign-off on both parmlib changes before PROD

---

*Report generated by z/OS Migration Health Check Assistant — applied-ai-software-delivery*
