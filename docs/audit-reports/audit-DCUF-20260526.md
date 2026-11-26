# DCUF Operational Audit & Compliance Report
**Audit ID:** DCUF-20260526-001
**Date:** 26 May 2026 | **Time:** 12:00 UTC
**Executed By:** SYSSA69
**System:** DCUF | **LPAR:** dcuf.atos-nao.net
**z/OS Version:** 3.1 (Internal: 05.29.00)
**Collection Source:** HZSPROC Console (Live)

---

## Compliance Dashboard

```
╔══════════════════════════════════════════════════════════════════════╗
║        DCUF OPERATIONAL AUDIT DASHBOARD — 26 MAY 2026 12:00 UTC     ║
║                   AUDIT-ID: DCUF-20260526-001                        ║
╠══════════════════════════════════════════════════════════════════════╣
║  OVERALL COMPLIANCE SCORE:  [██████████████░░░░░░] 70%               ║
╠══════════════════════════════════════════════════════════════════════╣
║  CHECK SUMMARY (150 evaluated / 35 not applicable / 185 total)       ║
║  ✅ PASS         ████████████████████████████ 105  (70.0%)           ║
║  ⚠️  WARNING      ████████ 17                  (11.3%)               ║
║  ❌ EXCEPTION    ████████████ 24               (16.0%)               ║
║  🔴 ERROR        █ 2                           (1.3%)                ║
║  ⬛ SKIPPED      35 (ENV N/A)                                        ║
╠══════════════════════════════════════════════════════════════════════╣
║  COMPLIANCE BY CATEGORY                                               ║
║  SECURITY        [█████████░░░░░░░░░░░]  67%  ❌  RACF+ICSF         ║
║  STORAGE         [████████████████████] 100%  ✅  HSM+CAT+DMO       ║
║  PERFORMANCE     [██████████████████░░]  92%  ✅  WLM+REAL+VIRT     ║
║  AVAILABILITY    [████████████████░░░░]  84%  ⚠️   XCF+RRS          ║
║  IO_SUBSYSTEM    [█████████████████░░░]  85%  ⚠️   IOS+ALLOC        ║
║  UNIX_SERVICES   [███████████████████░]  93%  ✅  USS+ZFS            ║
║  NETWORK         [███████████████████░]  94%  ✅  TCPIP+VTAM        ║
║  JES_SPOOL       [████████████████░░░░]  82%  ⚠️   JES2+PFA         ║
║  MIGRATION       [█████████████░░░░░░░]  67%  ❌  ZOSMIG*           ║
║  SYSTEM_BASE     [██████████████░░░░░░]  69%  ❌  CSV+GRS+CNZ       ║
║  SUBSYSTEMS      [████████░░░░░░░░░░░░]  44%  ❌  CICS              ║
╠══════════════════════════════════════════════════════════════════════╣
║  TOP 5 RISKS                                                          ║
║  🔴 #1  RACF_SENSITIVE_RESOURCES       (SECURITY)     Score: 10      ║
║  🔴 #2  XCF_CDS_SPOF                   (AVAILABILITY) Score: 10      ║
║  🔴 #3  JES2_CKPT_CONFIG_ADAJES0F      (JES_SPOOL)    Score: 10      ║
║  🔴 #4  USS_PARMLIB_MOUNTS             (UNIX_SERVICES) Score: 10     ║
║  🔴 #5  RACF_ENCRYPTION_ALGORITHM      (SECURITY)     Score:  9      ║
╚══════════════════════════════════════════════════════════════════════╝
```

---

## Executive Summary

| Metric | Count |
|---|---|
| Total Registered Checks | 185 |
| Not Applicable (ENV N/A) | 35 |
| **Actively Evaluated** | **150** |
| ✅ PASS | 105 (70%) |
| ⚠️ WARNING (EXCEPTION-MED) | 17 (11.3%) |
| ❌ EXCEPTION (HIGH+LOW) | 24 (16%) |
| 🔴 ERROR (UNEXP ERROR) | 2 (1.3%) |
| **Overall Compliance Score** | **70%** |

**Audit Verdict: ⚠️ ATTENTION REQUIRED**
Four critical findings require immediate action before the next change window. Seventeen warnings require resolution within 30 days. The overall compliance score of 70% reflects primarily RACF security configuration gaps and Sysplex CDS exposure. Storage, network, and performance categories are fully or near-fully compliant.

---

## Section A — EXCEPTION-HIGH: Critical Findings (Risk Score 10)

### 🔴 A1 — `RACF_SENSITIVE_RESOURCES` | IBMRACF | SECURITY | Score: 10

**Severity:** EXCEPTION-HIGH
**Issue:** One or more sensitive system resources (FACILITY, OPERCMDS, system datasets) are not adequately protected by RACF profiles or are accessible without proper authorization.
**Risk:** Unauthorized access to privileged system resources — potential for privilege escalation or data breach.

**Remediation Steps:**
1. `RLIST FACILITY * ALL` — identify unprotected or over-permissioned resources
2. Define discrete RACF profiles for all flagged sensitive resources
3. Apply `UACC(NONE)` and grant access only to required userids/groups
4. Verify `SETROPTS PROTECTALL(FAIL)` is active
5. **Reference:** *z/OS Security Server RACF Security Administrator's Guide — Sensitive Resources*

**Urgency:** 🔴 Immediate Action Required | **Parmlib:** RACF profiles | **Owner:** Security Administrator

---

### 🔴 A2 — `XCF_CDS_SPOF` | IBMXCF | AVAILABILITY | Score: 10

**Severity:** EXCEPTION-HIGH
**Issue:** A Sysplex Couple Data Set (CDS) is configured as a Single Point of Failure — no alternate CDS defined or the alternate resides on the same DASD volume as primary.
**Risk:** Loss of the CDS results in immediate Sysplex outage and potential IPL of all members.

**Remediation Steps:**
1. `D XCF,COUPLE` — identify current primary and alternate CDS locations
2. Define alternate CDS on a separate DASD volume and controller
3. Update `COUPLExx` parmlib: `PCOUPLE(primary-dsn,VOLSER) ACOUPLE(alternate-dsn,VOLSER)`
4. Perform `COUPLE PCOUPLE` switch to validate alternate
5. **Reference:** *z/OS MVS Setting Up a Sysplex — Couple Data Sets*

**Urgency:** 🔴 Immediate Action Required | **Parmlib:** COUPLExx | **UserMod:** ZOSXF45/ZOSXF46

---

### 🔴 A3 — `JES2_CKPT_CONFIG_ADAJES0F` | IBMJES2 | JES_SPOOL | Score: 10

**Severity:** EXCEPTION-HIGH
**Issue:** JES2 checkpoint configuration on ADAJES0F does not meet IBM best practice — checkpoint dataset may be on a single volume, inadequately sized, or improperly duplexed.
**Risk:** JES2 checkpoint failure causes spool outage — all batch and TSO work stops immediately.

**Remediation Steps:**
1. `$DCKPTSPACE` — display current checkpoint configuration and utilization
2. Ensure checkpoint is duplexed on separate volumes with `CKPT1` and `CKPT2`
3. Verify checkpoint dataset size against current spool activity volume
4. Review `JES2` parmlib `CKPTDEF` statement for NEWCKPT/BACKUP settings
5. **Reference:** *z/OS JES2 Initialization and Tuning Guide — Checkpoint*

**Urgency:** 🔴 Immediate Action Required | **Parmlib:** JES2 parmlib (CKPTDEF) | **Owner:** z/OS SysProg

---

### 🔴 A4 — `USS_PARMLIB_MOUNTS` | IBMUSS | UNIX_SERVICES | Score: 10

**Severity:** EXCEPTION-HIGH
**Issue:** One or more USS file system mount points defined in `BPXPRMxx` are not mounting correctly, have incorrect dataset names, or have configuration inconsistencies.
**Risk:** USS kernel startup failure at next IPL — potential loss of all UNIX services including CICS regions using USS, Java applications, and TCP/IP.

**Remediation Steps:**
1. `D OMVS,PFK(00)` — display current USS mount status and identify failed mounts
2. Review `BPXPRMxx` FILESYSTEM statements for all mount points
3. Validate all MOUNTPOINT paths and dataset names are correct and cataloged
4. Test: `F BPXOINIT,FILESYS ACTION=MOUNT,FILESYSTEM=<name>` before next IPL
5. **Reference:** *z/OS UNIX System Services Planning — BPXPRMxx FILESYSTEM*

**Urgency:** 🔴 Immediate Action Required | **Parmlib:** BPXPRMxx | **UserMod:** ZOSXF56

---

## Section B — WARNING (EXCEPTION-MED): 17 Findings

| # | Check | Owner | Category | Risk Score | Action Required |
|---|---|---|---|---|---|
| B1 | `RACF_ENCRYPTION_ALGORITHM` | IBMRACF | SECURITY | 9 | Update RACF to use KDFAES algorithm via `SETROPTS ALGORITHM(KDFAES)` |
| B2 | `RACF_AUDIT_CONTROLS` | IBMRACF | SECURITY | 9 | Enable RACF global audit: `SETROPTS AUDIT(*)` |
| B3 | `RACF_PASSWORD_CONTROLS` | IBMRACF | SECURITY | 9 | Enforce: min 8-char, mixed-case, 90-day expiry via `SETROPTS PASSWORD` |
| B4 | `RACF_CERTIFICATE_EXPIRATION` | IBMRACF | SECURITY | 9 | Renew expiring RACF digital certificates before expiry date |
| B5 | `XCF_CF_SYSPLEX_CONNECTIVITY` | IBMXCF | AVAILABILITY | 9 | Review CF-to-CF path configuration for full path redundancy |
| B6 | `RACF_SYSPLEX_COMMUNICATION` | IBMRACF | SECURITY | 8 | Enable RACF RRSF node communication in `RACF RRSF ACTIVE` |
| B7 | `RACF_ERASE_ON_SCRATCH` | IBMRACF | SECURITY | 8 | Enable: `SETROPTS ERASEONSTC ERASEONDELETE` |
| B8 | `RACF_JESSPOOL_ACTIVE` | IBMRACF | SECURITY | 8 | `SETROPTS CLASSACT(JESSPOOL)` — protect JES spool datasets |
| B9 | `RACF_TAPEVOL_ACTIVE` | IBMRACF | SECURITY | 8 | `SETROPTS CLASSACT(TAPEVOL)` — protect tape volumes |
| B10 | `RACF_TEMPDSN_ACTIVE` | IBMRACF | SECURITY | 8 | `SETROPTS CLASSACT(TEMPDSN)` — protect temporary datasets |
| B11 | `RACF_PTKTDATA_CLASS` | IBMRACF | SECURITY | 8 | Define `PTKTDATA` class profiles for PassTicket support |
| B12 | `XCF_CF_STR_AVAILABILITY` | IBMXCF | AVAILABILITY | 8 | Review CF structure availability thresholds in CFRM policy |
| B13 | `XCF_CDS_SEPARATION` | IBMXCF | AVAILABILITY | 8 | Verify primary/alternate CDS are on separate DASD controllers |
| B14 | `XCF_SFM_CFSTRHANGTIME` | IBMXCF | AVAILABILITY | 8 | Review `CFSTRHANGTIME` value in `COUPLExx` — align with IBM default |
| B15 | `SVA_AUTOIPL_DEFINED` | IBMSVA | SYSTEM_BASE | 7 | Define Automatic IPL recovery path in `LOADxx` |
| B16 | `SDUMP_AUTO_ALLOCATION` | IBMSDUMP | SYSTEM_BASE | 7 | Configure SDUMP auto-allocation in `DIAGxx` SDUMP statement |
| B17 | `ASM_PAGE_ADD` | IBMASM | PERFORMANCE | 7 | Add additional page space — current page dataset utilization above threshold |

---

## Section C — EXCEPTION-LOW (Advisory): 20 Findings

| # | Check | Owner | Category | Remediation Summary |
|---|---|---|---|---|
| C1 | `CICS_CAT3_CONFIGURATION` | IBMCICS | SUBSYSTEMS | Review CICS CAT3 region configuration — align with IBM CSD defaults |
| C2 | `CICS_RESOURCE_SECURITY` | IBMCICS | SUBSYSTEMS | Enable CICS resource-level security: `SEC=YES` in CICS SIT |
| C3 | `CICS_RESOURCE_CONFIGURATION` | IBMCICS | SUBSYSTEMS | Align CICS resource configuration with IBM published defaults |
| C4 | `CICS_REGION_CONFIGURATION` | IBMCICS | SUBSYSTEMS | Review CICS region SIT startup parameters for unsupported settings |
| C5 | `CICS_CEDA_ACCESS` | IBMCICS | SUBSYSTEMS | Restrict CEDA transid access via `RACF TCICSTRN` class profiles |
| C6 | `CSVTAM_T1BUF_T2BUF_EE` | IBMCS | NETWORK | Tune VTAM T1BUF/T2BUF buffer sizes for Enterprise Extender in `ATCSTRxx` |
| C7 | `ICSF_PKCS_PSS_SUPPORT` | IBMICSF | SECURITY | Enable PKCS PSS signature support in `CSFPRMxx` |
| C8 | `ZOSMIG32_NEXT_IOS_PLIB_DEFAULTS` | IBMIOS | MIGRATION | Explicitly code IOS parmlib defaults in `IECIOSxx` before z/OS 3.2 |
| C9 | `ZOSMIG32_WLM_OPT_CPENABLE` | IBMWLM | MIGRATION | Explicitly set `CPENABLE` parameter in `IWMPRMxx` before z/OS 3.2 |
| C10 | `SUP_ASVT_ABOVE_16M` | IBMSUP | SYSTEM_BASE | Move ASVT above 16M line — update `IEASYSxx` ASVT parameter |
| C11 | `CNZ_SYSCONS_ALLOWCMD` | IBMCNZ | SYSTEM_BASE | Review `ALLOWCMD` setting in `CONSOLxx` for system console security |
| C12 | `CNZ_CONSOLE_ROUTCODE_11` | IBMCNZ | SYSTEM_BASE | Define route code 11 receiver in `CONSOLxx` for emergency action msgs |
| C13 | `CNZ_AMRF_EVENTUAL_ACTION_MSGS` | IBMCNZ | SYSTEM_BASE | Configure AMRF eventual action message routing in `CONSOLxx` |
| C14 | `OCE_XTIOT_CHECK` | IBMOCE | IO_SUBSYSTEM | Review extended TIOT settings — update `IECIOSxx` XTIOT parameter |
| C15 | `PDSE_SMSPDSE1` | IBMPDSE | SYSTEM_BASE | Define `SMSPDSE1` module to LPA for PDSE performance improvement |
| C16 | `CSV_LPA_CHANGES` | IBMCSV | SYSTEM_BASE | Review and document LPA list contents — validate `LPALSTxx` currency |
| C17 | `CSV_LNKLST_SPACE` | IBMCSV | SYSTEM_BASE | Increase LNKLST space allocation — review `LNKLSTxx` for space pressure |
| C18 | `CSV_APF_EXISTS` | IBMCSV | SYSTEM_BASE | Verify all APF-authorized libraries in `PROGxx` exist and are cataloged |
| C19 | `GRS_AUTHQLVL_SETTING` | IBMGRS | SYSTEM_BASE | Set `AUTHQLVL=2` in `GRSCNFxx` — IBM best practice for GRS authority |
| C20 | `JES_NJE_SECURITY` | IBMJES | JES_SPOOL | Enable NJE security validation — review JES2 `NJEDEF` security parms |

---

## Section D — Errors Requiring Investigation

| # | Check | Owner | Error Type | Investigation Steps |
|---|---|---|---|---|
| D1 | `CIM_HTTPS_ENABLED` | IBMCIM | UNEXP ERROR | Verify CIM server is active (`D A,CFZCIM`); check CFZSEC exit routine; review CIM HTTPS configuration |
| D2 | `ICSFMIG7731_ICSF_RETAINED_RSAKEY` | IBMICSF | UNEXP ERROR | Verify ICSF fully initialized (`D ICSF,ST`); review `CSFPRMxx` RSA key settings; check for retained RSA keys in TKDS |

---

## Section E — Remediation Action Plan (Priority Order)

| Priority | Check | Owner | Parmlib Member | Urgency | ServiceNow |
|---|---|---|---|---|---|
| 🔴 P1 | `RACF_SENSITIVE_RESOURCES` | Security Admin | RACF profiles | Immediate | Open P1 Incident |
| 🔴 P1 | `XCF_CDS_SPOF` | z/OS SysProg | COUPLExx | Immediate | Open P1 Incident |
| 🔴 P1 | `JES2_CKPT_CONFIG_ADAJES0F` | z/OS SysProg | JES2 CKPTDEF | Immediate | Open P1 Incident |
| 🔴 P1 | `USS_PARMLIB_MOUNTS` | z/OS SysProg | BPXPRMxx | Immediate | Open P1 Incident |
| 🟠 P2 | `RACF_ENCRYPTION_ALGORITHM` | Security Admin | RACF SETROPTS | Before next change | Change Request |
| 🟠 P2 | `RACF_PASSWORD_CONTROLS` | Security Admin | RACF SETROPTS | Before next change | Change Request |
| 🟠 P2 | `RACF_AUDIT_CONTROLS` | Security Admin | RACF SETROPTS | Before next change | Change Request |
| 🟠 P2 | `RACF_CERTIFICATE_EXPIRATION` | Security Admin | RACF profiles | Before expiry | Change Request |
| 🟠 P2 | `XCF_CF_SYSPLEX_CONNECTIVITY` | z/OS SysProg | CFRMxx | Before next change | Change Request |
| 🟡 P3 | All RACF CLASS activation checks | Security Admin | RACF SETROPTS | Within 30 days | Change Request |
| 🟡 P3 | `CICS_*` checks (5) | CICS SysProg | CICS SIT/CSD | Within 30 days | Change Request |
| 🟡 P3 | `ZOSMIG32_*` (2) | z/OS SysProg | IECIOSxx/IWMPRMxx | Before z/OS 3.2 | Change Request |
| 🟡 P3 | `CSV_*` checks (3) | z/OS SysProg | LPALSTxx/PROGxx | Within 30 days | Change Request |
| 🟡 P3 | `CNZ_*` checks (3) | z/OS SysProg | CONSOLxx | Within 30 days | Change Request |

---

## Section F — Compliant Checks: 105 PASS

### Compliance Highlights by Domain

| Domain | Checks | Pass | Compliance | Status |
|---|---|---|---|---|
| Real/Virtual Storage (VSM/RSM) | 18 | 18 | 100% | ✅ Fully Compliant |
| Storage Management (HSM/CAT/DMO) | 7 | 7 | 100% | ✅ Fully Compliant |
| Predictive Failure Analysis (PFA) | 9 | 9 | 100% | ✅ Fully Compliant |
| CA Products (CCS/DTCM/VIEW) | 8 | 8 | 100% | ✅ Fully Compliant |
| zFS File System | 5 | 5 | 100% | ✅ Fully Compliant |
| Allocation (ALLOC) | 5 | 5 | 100% | ✅ Fully Compliant |
| TSO/E | 3 | 3 | 100% | ✅ Fully Compliant |
| IXGLOGR (Logger) | 4 | 4 | 100% | ✅ Fully Compliant |
| SDSF | 2 | 2 | 100% | ✅ Fully Compliant |
| Network TCP/IP | 17 | 16 | 94% | ✅ Compliant |
| UNIX Services (USS/ZFS) | 14 | 13 | 93% | ✅ Compliant |
| Performance (WLM/ASM/VSM/RSM) | 25 | 23 | 92% | ✅ Compliant |
| ICSF Cryptographic | 11 | 9 | 82% | ⚠️ 2 items |

### Notable Compliant Checks
- `ZOSMIG32_NEXT_IOS_DEPRECATIONS` — No deprecated IOS functions in use ✅
- `ZOSMIGREC_ROOT_FS_SIZE` — Root zFS filesystem adequately sized ✅
- `ZOSMIGREC_SUP_TIMER_INUSE` — STP timer properly configured ✅
- `ZOSMIGV2R4PREV_CS_IWQSC_TCPIP` — Previous migration CS check satisfied ✅
- `RACF_PROTECTALL_FAIL` — PROTECTALL(FAIL) is active ✅
- `RACF_IBMUSER_REVOKED` — IBMUSER is revoked ✅
- `HSM_CDSB_VALID_BACKUPS` — HSM control dataset backups are valid ✅
- All 9 PFA health checks passing — proactive failure analysis fully operational ✅

---

## Section G — Next Steps

### Immediate Actions (This Week)
1. **Raise 4 ServiceNow P1 Incidents** for all EXCEPTION-HIGH findings
2. **Schedule emergency RACF review** with Security Admin team for RACF_SENSITIVE_RESOURCES
3. **Validate CDS configuration** — `D XCF,COUPLE` to assess XCF_CDS_SPOF exposure
4. **JES2 checkpoint review** — `$DCKPTSPACE` during next maintenance window
5. **USS mount audit** — `D OMVS,PFK(00)` to identify failed BPXPRMxx mounts

### Short-Term Actions (30 Days)
6. **RACF Security Hardening** — Address all 14 RACF exceptions (PASSWORD, AUDIT, ENCRYPT, CLASSES)
7. **CICS Configuration Review** — Align 5 CICS configuration checks with IBM defaults
8. **System Base Cleanup** — Address CSV_APF_EXISTS, CSV_LNKLST_SPACE, CNZ_* checks

### Pre-z/OS 3.2 Migration (Before Upgrade)
9. **Resolve ZOSMIG32_NEXT_IOS_PLIB_DEFAULTS** — Code IECIOSxx defaults explicitly
10. **Resolve ZOSMIG32_WLM_OPT_CPENABLE** — Set CPENABLE in IWMPRMxx

### Operational Hygiene
11. **Re-audit** after P1/P2 remediation to track compliance improvement
12. **Schedule weekly automated audit** via cron/ESP to track trends
13. **Investigate D1/D2 UNEXP ERRORs** — CIM_HTTPS_ENABLED and ICSF_RETAINED_RSAKEY

---

## Appendix — Audit Metadata

| Field | Value |
|---|---|
| Audit ID | DCUF-20260526-001 |
| Audit Start | 2026-05-26T12:00:00Z |
| Audit End | 2026-05-26T12:25:59Z |
| Duration | ~26 minutes |
| Executed By | SYSSA69 |
| Zowe CLI Version | 8.31.1 (Zowe Release v3.4.1) |
| z/OSMF Host | 138.69.218.201:443 |
| HZSPROC STC | STC06036 |
| Commands Issued | ACTIVATE + RUN + DISPLAY(DETAIL) + DEACTIVATE |
| Post-Audit State | All checks deactivated (restored to pre-audit state) |
| Report Format | Markdown + PDF |
| Report Path | docs/audit-reports/audit-DCUF-20260526.md |
| History Path | docs/audit-history/dcuf-audit-history.json |

---

*Generated by DCUF Operational Audit & Compliance Assistant — operational-audit-compliance-assistant*
*Report is READ-ONLY. No system changes were made during this audit.*
