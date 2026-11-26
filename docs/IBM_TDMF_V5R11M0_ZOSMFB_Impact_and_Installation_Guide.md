# Impact Statement and Installation Guide
## IBM Transparent Data Migration Facility (TDMF) for z/OS V5.11.00 ZOSMFB
### Mainframe Software Delivery — 24th June 2026

---

## Table of Contents

- [Introduction](#introduction)
- [Product Overview](#product-overview)
- [Product Pre-requisites](#product-pre-requisites)
- [Release Information](#release-information)
- [Change Category](#change-category)
- [Document Location](#document-location)
- [Highlights / New Features](#highlights--new-features)
- [z/OS Compatibility](#zos-compatibility)
- [HOLDDATA / BYPACT Hold Reason Report](#holddata--bypact-hold-reason-report)
- [Installation Process (DCUF)](#installation-process-dcuf)
- [Maintenance/Fix Apply Process](#maintenancefix-apply-process)
- [Shrink-wrap Creation Process](#shrink-wrap-creation-process)
- [Installation Verification Process (IVP)](#installation-verification-process-ivp)
- [Installation Process for Target System](#installation-process-for-target-system)
- [Appendix 1 — Installation Datasets List & Space Requirements](#appendix-1--installation-datasets-list--space-requirements)
- [Appendix 2 — Sample Shrink Wrap Restore Job](#appendix-2--sample-shrink-wrap-restore-job)
- [Appendix 3 — Procedure to XMIT & Receive the Shrink-wrap](#appendix-3--procedure-to-xmit--receive-the-shrink-wrap)
- [Appendix 4 — Sample FTP Job to Download Shrink XMI from DCUF](#appendix-4--sample-ftp-job-to-download-shrink-xmi-from-dcuf)
- [Appendix 5 — Maintenance/Fixes Applied](#appendix-5--maintenancefixes-applied)

---

## Introduction

This document provides the Impact Statement and Installation Guide for the maintenance refresh of **IBM Transparent Data Migration Facility for z/OS V5R11M0** (Program Number: 5655-TZ5), from install level **ZOSMFA** to **ZOSMFB** on the DCUF LPAR.

---

## Product Overview

IBM Transparent Data Migration Facility (TDMF) for z/OS is a non-disruptive data movement product that enables online migration of data between DASD volumes on IBM Z mainframe systems without application outage. TDMF provides volume-level and dataset-level migration capabilities with full support for extended addressability, SMS-managed storage, and VSAM data sets.

TDMF is user-initiated and controlled and allows for full system sharing throughout the data centre. TDMF provides full access to the data at any point during a migration operation. TDMF supports dynamic takeover on the part of the target device, an important consideration in integrity and completeness of data migration. TDMF is completely model- and vendor-independent within the supported architecture.

**Benefits offered:**

- The ability to introduce new storage subsystem technologies without significant disruption of service.
- Protection of the value of existing storage equipment because all devices at the site can participate in a migration.
- Designation of any subsystem as either source or target.
- Lower continuing costs of operation by maintaining a multiple-vendor, non-model-specific environment.
- Conducting Parallel ESCON or FICON migrations, an important consideration when implementing RAID storage technologies.

---

## Product Pre-requisites

**Driving System Software Requirements:**

| Program Number | Product Name | Minimum VRM | Minimum Service Level | Included in the shipped product? |
|---|---|---|---|---|
| 5650-ZOS | z/OS | V2.5 or higher | N/A | No |

**Target systems:** TDMF installs in the z/OS (Z038) SREL.

**Machine Requirements:** The target system can run in any hardware environment that supports the required software.

**Installation Requisites:** TDMF has no mandatory installation requisites. TDMF has no conditional installation requisites.

**Operational Requisites:** TDMF has no mandatory operational requisites. TDMF has no conditional operational requisites.

---

## Release Information

| Field | Value |
|---|---|
| **Current Release** | V5R11M0 ZOSMFA |
| **Target Release** | V5R11M0 ZOSMFB |
| **Intermediate Releases** | N/A |
| **FMID** | HGTD5B0 |
| **Program Number** | 5655-TZ5 |
| **SMP/E Version** | 37.35 (GIMSMP) |
| **Target LPAR** | DCUF |
| **z/OS Level** | z/OS 3.2 (ZS32D) |

---

## Change Category

**Minor — Maintenance**

This maintenance refresh applies PTF-level fixes to FMID HGTD5B0. No IPL is required. No APF list changes. No system-level changes.

---

## Document Location

This information is gathered from the following vendor-supplied manuals on the IBM website:

- [IBM Transparent Data Migration Facility for z/OS 5.11.0 — IBM Documentation](https://www.ibm.com/docs/en/tdmf)
- Reference Guide
- Messages and Codes Manual

Above listed manuals are also available in the Team Documentation portal under:

> **TeamDocs > 02. Software Delivery Documentation > 01. Product Documents > 01. IBM > TDMF > V5R11M0**

The Impact and Installation Guide (this document) is available at:

> **TeamDocs > 02. Software Delivery Documentation > 01. Product Documents > 01. IBM > TDMF > V5R11M0 > ZOSMFB**

---

## Highlights / New Features

The following provides the current technical changes and enhancements to IBM Transparent Data Migration Facility (TDMF) for z/OS. This maintenance refresh delivers 14 accepted PTFs against FMID HGTD5B0, incorporating fixes for volume management, message handling, watchdog processing, and panel updates.

For more information, please refer to: [What's new — IBM Documentation](https://www.ibm.com/docs/en/tdmf)

**Key PTF highlights (ZOSMFB):**

- `UJ97580` — GTDMSGN, GTDMSGV, GTDRTNV, GTDTVOL: Message and volume routing updates
- `UJ99273` — GTDMVOL: Multi-volume migration enhancements
- `UJ99733` — GTDCVOL: Volume copy processing corrections
- `UJ96759` — GTDWTCH, GTDKEYS, GTDMON: Watchdog and monitoring fixes
- `UJ99123` — GTDRTNM: Route name handling correction
- `UJ98119` — GTDCSEL: Channel selection fix

---

## z/OS Compatibility

This version of TDMF (V5R11M0 ZOSMFB) supports the following operating systems:

- z/OS V2.5, V3.1, and V3.2

| z/OS Release | Status |
|---|---|
| z/OS 2.5 | Supported |
| z/OS 3.1 | Supported |
| z/OS 3.2 (ZS32D) | Supported — target LPAR level |

---

## HOLDDATA / BYPACT Hold Reason Report

Please review: `ACSNS.TDMF.V5R11M0.ZOSMFB.HOLDDATA(ZOSMFB)`

> **Note: No HOLD conditions found for this maintenance.**
> `BYPASS(HOLDSYS)` was used during APPLY and ACCEPT processing. No PE (Program Error), ERROR, or HIPER holds were active for any of the 14 accepted PTFs.

---

## Installation Process (DCUF)

The following steps were performed on DCUF for the ZOSMFB maintenance refresh:

| Step | Description | Job / Reference | Status |
|---|---|---|---|
| 1 | Restore product files from ZOSMFA Shrinkwrap `ACSNS.TDMF.V5R11M0.ZOSMFA.ZS31D.SHRNKWRP` using ADRDSSU COPYRENA | JOB04192 — CC 0004 | Done on DCUF |
| 2 | Update SMP/E DDDEF entries (GLOBAL, DZONE, TZONE) from ZOSMFA to ZOSMFB using GIMSMP DDEFUPDT | JOB04193 — CC 0000 | Done on DCUF |
| 3 | Verify DDDEF entries after update | SMPELIST | Done on DCUF |
| 4 | Download and RECEIVE 8 PTFs from IBM Order Server | IBMRCV (JOB04194) — 8 SYSMODs received | Done on DCUF |
| 5 | SMP/E APPLY CHECK — validate 9 SYSMODs, confirm no HOLDs | IBMAPK (JOB04197) — CC 0000 | Done on DCUF |
| 6 | SMP/E APPLY — apply 9 SYSMODs to TZONE; 17 elements updated | IBMAPL (JOB04200) — CC 0000 | Done on DCUF |
| 7 | SMP/E ACCEPT CHECK — validate 14 SYSMODs for promotion to DZONE | IBMACK (JOB04201) — CC 0000 | Done on DCUF |
| 8 | SMP/E ACCEPT — accept 14 SYSMODs to DZONE; 27 elements updated | IBMACC (JOB04225) — CC 0000 | Done on DCUF |
| 9 | All JCL and results saved | `ACSNS.TDMF.V5R11M0.ZOSMFB.RESULTS` | Done on DCUF |

---

## Maintenance/Fix Apply Process

**ZOSMFB — Maintenance Refresh from ZOSMFA**

| Step | Description | Status |
|---|---|---|
| 1 | Restore product files from previous Shrinkwrap: `ACSNS.TDMF.V5R11M0.ZOSMFA.ZS31D.SHRNKWRP` — COPYRENA (JOB04192) | Done on DCUF |
| 2 | Run DDEFUPDT to update DDDEF entries: `ACSNS.TDMF.V5R11M0.ZOSMFA.*` → `ACSNS.TDMF.V5R11M0.ZOSMFB.*` — JOB04193 | Done on DCUF |
| 3 | Run SMPELIST to verify DDDEF entries: `ACSNS.TDMF.V5R11M0.ZOSMFB.INSTLIB(SMPELIST)` | Done on DCUF |
| 4 | Download/RECEIVE PTFs from IBM Order Server: IBMRCV (JOB04194) — **SYSMODs Received: 8** | Done on DCUF |
| 5 | SMP/E APPLY CHECK + APPLY: IBMAPK (JOB04197), IBMAPL (JOB04200) — **SYSMODs APPLIED: 9 / SUPD: 3** | Done on DCUF |
| 6 | SMP/E ACCEPT CHECK + ACCEPT: IBMACK (JOB04201), IBMACC (JOB04225) — **SYSMODs ACCEPTED: 14 / SUPD: 7** | Done on DCUF |
| 7 | All results saved in `ACSNS.TDMF.V5R11M0.ZOSMFB.RESULTS` | Done on DCUF |

---

## Shrink-wrap Creation Process

| Step | Description | Status |
|---|---|---|
| 1 | Submit ADRDSSU SHRNKWRP job to create new shrinkwrap from `ACSNS.TDMF.V5R11M0.ZOSMFB.INSTLIB(SHRNKWRP)`. Output: `ACSNS.TDMF.V5R11M0.ZOSMFB.ZS31D.SHRNKWRP` — **43 datasets** (38 PDS + 4 VSAM + SGTNROOT) | JOB04249 — CC 0000 — Done on DCUF |
| 2 | Submit UNSHRINK job and save results to `ACSNS.TDMF.V5R11M0.ZOSMFB.RESULTS(UNSHRINK)` for verification | Done on DCUF |
| 3 | Refer Appendix 1 for list of datasets in shrinkwrap | See Appendix 1 |
| 4 | Refer Appendix 2 for sample RESTORE job | See Appendix 2 |

---

## Installation Verification Process (IVP)

| Check | Action | Expected Result |
|---|---|---|
| Verify TZONE SYSMODs | `LIST SYSMOD(UJ99733 UJ99273 UJ99123)` in SMP/E | STATUS=APPLIED |
| Verify DZONE SYSMODs | `LIST SYSMOD(UJ99733 UJ99273 UJ99123) ZONE(DZONE)` | STATUS=ACCEPTED |
| Verify AGTDLLIB intact | `LISTDS ACSNS.TDMF.V5R11M0.ZOSMFB.AGTDLLIB MEMBERS` | Members listed |
| Verify new shrinkwrap catalogued | `LISTCAT ENTRY(ACSNS.TDMF.V5R11M0.ZOSMFB.ZS31D.SHRNKWRP)` | Dataset catalogued |
| Verify TDMF procedures present | Check `ACSNS.TDMF.V5R11M0.ZOSMFB.PROCLIB` members | Procedures present |

---

## Installation Process for Target System

The following steps need to be performed on the Target LPAR:

| Step | Description | Where |
|---|---|---|
| 1 | Transfer shrinkwrap library to target system using XMIT or FTP. Shrinkwrap: `ACSNS.TDMF.V5R11M0.ZOSMFB.ZS31D.SHRNKWRP`. Refer Appendix 3 for XMIT process. | Target LPAR |
| 2 | Unshrink the shrinkwrap library. Refer Appendix 2 for sample unshrink job. Refer Appendix 1 for list of datasets. | Target LPAR |
| 3 | Review HOLDDATA: `ACSNS.TDMF.V5R11M0.ZOSMFB.HOLDDATA(ZOSMFB)`. **No Holddata found for this maintenance.** | Target LPAR |
| 4 | Perform further customisation following the user's guides and program directories. | Target LPAR |

---

## Appendix 1 — Installation Datasets List & Space Requirements

> **Note:** The datasets within the package occupied total **3,174 tracks** on DCUF (excluding the shrinkwrap). The ZOSMFB shrinkwrap `ACSNS.TDMF.V5R11M0.ZOSMFB.ZS31D.SHRNKWRP` is composed of **43 datasets** (38 PDS + 4 VSAM clusters + SGTNROOT).

### Product Libraries (ACSNS prefix):

```
ACSNS.TDMF.V5R11M0.ZOSMFB.AGTDELIB
ACSNS.TDMF.V5R11M0.ZOSMFB.AGTDLLIB
ACSNS.TDMF.V5R11M0.ZOSMFB.AGTDMLIB
ACSNS.TDMF.V5R11M0.ZOSMFB.AGTDPLIB
ACSNS.TDMF.V5R11M0.ZOSMFB.AGTDSAMP
ACSNS.TDMF.V5R11M0.ZOSMFB.AGTDTLIB
ACSNS.TDMF.V5R11M0.ZOSMFB.AGTDUSS
ACSNS.TDMF.V5R11M0.ZOSMFB.ARCHIVE.JCL.RES
ACSNS.TDMF.V5R11M0.ZOSMFB.CMDPROC
ACSNS.TDMF.V5R11M0.ZOSMFB.HOLDDATA
ACSNS.TDMF.V5R11M0.ZOSMFB.INSTLIB
ACSNS.TDMF.V5R11M0.ZOSMFB.ISPPLIB
ACSNS.TDMF.V5R11M0.ZOSMFB.PARMLIB
ACSNS.TDMF.V5R11M0.ZOSMFB.PDFPD
ACSNS.TDMF.V5R11M0.ZOSMFB.PROCLIB
ACSNS.TDMF.V5R11M0.ZOSMFB.PROD.PDF
ACSNS.TDMF.V5R11M0.ZOSMFB.PROPVAR
ACSNS.TDMF.V5R11M0.ZOSMFB.RESULTS
ACSNS.TDMF.V5R11M0.ZOSMFB.SAMPLIB
ACSNS.TDMF.V5R11M0.ZOSMFB.SCPPLOAD
ACSNS.TDMF.V5R11M0.ZOSMFB.SGTDELIB
ACSNS.TDMF.V5R11M0.ZOSMFB.SGTDLLIB
ACSNS.TDMF.V5R11M0.ZOSMFB.SGTDMLIB
ACSNS.TDMF.V5R11M0.ZOSMFB.SGTDPLIB
ACSNS.TDMF.V5R11M0.ZOSMFB.SGTDSAMP
ACSNS.TDMF.V5R11M0.ZOSMFB.SGTDTLIB
ACSNS.TDMF.V5R11M0.ZOSMFB.VTAMLST
ACSNS.TDMF.V5R11M0.ZOSMFB.WORKFLOW
```

### CSI Datasets (ACSVS prefix):

```
ACSVS.TDMF.V5R11M0.ZOSMFB.DLIB.CSI
ACSVS.TDMF.V5R11M0.ZOSMFB.GLOBAL.CSI
ACSVS.TDMF.V5R11M0.ZOSMFB.SGTNROOT
ACSVS.TDMF.V5R11M0.ZOSMFB.TARGET.CSI
```

### SMP/E Libraries (ACSNS prefix):

```
ACSNS.TDMF.V5R11M0.ZOSMFB.SMPDLOG
ACSNS.TDMF.V5R11M0.ZOSMFB.SMPDLOGA
ACSNS.TDMF.V5R11M0.ZOSMFB.SMPGLOG
ACSNS.TDMF.V5R11M0.ZOSMFB.SMPGLOGA
ACSNS.TDMF.V5R11M0.ZOSMFB.SMPMTS
ACSNS.TDMF.V5R11M0.ZOSMFB.SMPPTS
ACSNS.TDMF.V5R11M0.ZOSMFB.SMPSCDS
ACSNS.TDMF.V5R11M0.ZOSMFB.SMPSTS
ACSNS.TDMF.V5R11M0.ZOSMFB.SMPTLOG
ACSNS.TDMF.V5R11M0.ZOSMFB.SMPTLOGA
```

---

## Appendix 2 — Sample Shrink Wrap Restore Job

To restore the shrinkwrap on a target system, use the following sample job:

```jcl
//JOBCARD  JOB ...
//**********************************************************************
//*        SAMPLE UNSHRINK WRAP — ZOSMFB
//**********************************************************************
//STEP001  EXEC PGM=ADRDSSU
//SYSUT1   DD   DISP=SHR,
//         DSN=ACSNS.TDMF.V5R11M0.ZOSMFB.ZS31D.SHRNKWRP
//SYSPRINT DD   SYSOUT=*
//SYSIN    DD   *
  REST DS(INCL(**))                                       -
  OUTDYNAM(VVVVVV) INDD(SYSUT1)
/*
```

> **VVVVVV** = Target system VOLSER

---

## Appendix 3 — Procedure to XMIT & Receive the Shrink-wrap

Type the following command in ISPF TSO Option 6 on DCUF to transmit:

```
XMIT NODENAME.USERID DS('ACSNS.TDMF.V5R11M0.ZOSMFB.ZS31D.SHRNKWRP')
```

> `NODENAME` & `USERID` = those of the target LPAR

To receive the shrinkwrap on the target LPAR, issue from ISPF TSO Option 6:

```
RECEIVE INDSN('USERID.TDMF.V5R11M0.ZOSMFB.SHRNK.XMI')
```

When prompted, enter:

```
DSN('ACSNS.TDMF.V5R11M0.ZOSMFB.ZS31D.SHRNKWRP') VOL(VVVVVV)
```

> `VOL` statement is optional; `VVVVVV` = target system VOLSER.

---

## Appendix 4 — Sample FTP Job to Download Shrink XMI from DCUF

To download the shrinkwrap XMI, use the following sample FTP job:

```jcl
//JOBCARD  JOB ...
//*-------------------------------------------------------------------------*
//* SAMPLE FTP JCL to download SHRINK XMI from DCUF                        *
//*-------------------------------------------------------------------------*
//* Pre-allocate shrink XMI on target LPAR                                 *
//*-------------------------------------------------------------------------*
//ALLOCXMI EXEC PGM=IEFBR14
//OUTXMI   DD DSN=<target HLQ>.XMI,
//         DISP=(,CATLG,DELETE),
//         UNIT=3390,VOL=SER=xxxxxx,
//         SPACE=(CYL,(xx,yy),RLSE),
//         DCB=(LRECL=80,BLKSIZE=23440,RECFM=FB,DSORG=PS)
//*-------------------------------------------------------------------------*
//* FTP Shrink XMI from DCUF                                                *
//*-------------------------------------------------------------------------*
//FTPXMI   EXEC PGM=FTP,PARM='(TIMEOUT 720'
//SYSPRINT DD SYSOUT=*
//OUTPUT   DD SYSOUT=*,DCB=(RECFM=FB,LRECL=120,BLKSIZE=24000)
//INPUT    DD *
138.69.218.201
<DCUF TSO ID>
<DCUF TSO PASSWORD>
binary
get 'ACSNS.TDMF.V5R11M0.ZOSMFB.ZS31D.SHRNKWRP' '<target HLQ>.XMI' (repl
quit
/*
```

---

## Appendix 5 — Maintenance/Fixes Applied

**FMID:** HGTD5B0

**SYSMODs Received (8 PTFs — via IBM Order Server, IBMRCV JOB04194):**

| SYSMOD | Type | FMID |
|---|---|---|
| UJ97410 | PTF | HGTD5B0 |
| UJ97580 | PTF | HGTD5B0 |
| UJ97995 | PTF | HGTD5B0 |
| UJ98119 | PTF | HGTD5B0 |
| UJ98951 | PTF | HGTD5B0 |
| UJ99123 | PTF | HGTD5B0 |
| UJ99273 | PTF | HGTD5B0 |
| UJ99733 | PTF | HGTD5B0 |

**SYSMODs Applied to TZONE — IBMAPL (JOB04200):**

| Status | Count | SYSMODs |
|---|---|---|
| APPLIED | 9 | UJ96596, UJ96661, UJ96759, UJ97580, UJ97995, UJ98119, UJ99123, UJ99273, UJ99733 |
| SUPD | 3 | UJ96528 (superseded by UJ96759), UJ97410 (superseded by UJ99273), UJ98951 (superseded by UJ99733) |

**SYSMODs Accepted to DZONE — IBMACC (JOB04225):**

| Status | Count | SYSMODs |
|---|---|---|
| ACCEPTED | 14 | UJ95687, UJ95805, UJ96177, UJ96340, UJ96507, UJ96596, UJ96661, UJ96759, UJ97580, UJ97995, UJ98119, UJ99123, UJ99273, UJ99733 |
| SUPD | 7 | UJ95905 (superseded by UJ96759), UJ96120 (superseded by UJ97580), UJ96127 (superseded by UJ96507), UJ96303 (superseded by UJ97580), UJ96528 (superseded by UJ96759), UJ97410 (superseded by UJ99273), UJ98951 (superseded by UJ99733) |

> **DISCLAIMER:** SMP/E processing was performed using GIMSMP 37.35. The maintenance was applied with `BYPASS(HOLDSYS)` — no PE or ERROR holds were active. All SYSMODs with SOURCEIDs RSU*, SECINT, HIPER, and PRP were applied and accepted. Pre-requisite SYSMODs were confirmed satisfied at APPLY CHECK and ACCEPT CHECK (RC=0).

---

## Maintenance/Fix Apply Process - Last/Latest

### TDMF.V5R11M0.ZOSMFB — Applied 2026-07-22

| Field                     | Value                                                                 |
|---------------------------|-----------------------------------------------------------------------|
| New Qualifier             | ACS%S.TDMF.V5R11M0.ZOSMFB                                            |
| New Shrinkwrap DSN        | ACSNS.TDMF.V5R11M0.ZOSMFB.ZS31D.SHRNKWRP                            |
| Global CSI                | ACSVS.TDMF.V5R11M0.ZOSMFB.GLOBAL.CSI                                 |
| COPYRENA Job ID           | JOB00869 (RC=4)                                                       |
| DDEFUPDT Job ID           | JOB00871 (RC=0)                                                       |
| SMP/E RECEIVE Job ID      | JOB00880 (RC=0)                                                       |
| SMP/E APPLY CHECK Job ID  | JOB00882 (RC=0)                                                       |
| SMP/E APPLY Job ID        | JOB00886 (RC=0)                                                       |
| SMP/E ACCEPT CHECK Job ID | JOB00887 (RC=0)                                                       |
| SMP/E ACCEPT Job ID       | JOB00888 (RC=0)                                                       |
| Shrinkwrap Job ID         | JOB00898 (RC=0)                                                       |
| SYSMODs Applied           | 9 PTFs (UJ96596, UJ96661, UJ96759, UJ97580, UJ97995, UJ98119, UJ99123, UJ99273, UJ99733) |
| SYSMODs Accepted          | 14 PTFs (FMID HGTD5B0)                                                |
| Applied By                | SDT                                                                   |
| Date Applied              | 2026-07-22                                                            |

---

*© 2026 Eviden. All rights reserved.*
*Document generated by SDT ISV Maintenance Pipeline Agent — 24th June 2026*
*TeamDocs: 02. Software Delivery Documentation > 01. Product Documents > 01. IBM > TDMF > V5R11M0 > ZOSMFB*
