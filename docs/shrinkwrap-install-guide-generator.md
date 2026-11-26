# zosmf-install-guide-generator

**Agent Name:** `zosmf-install-guide-generator`
**Previous Name:** `Shrinkwrap_Guide_ZOSMF`
**Repository:** applied-ai-software-delivery
**Agent File:** `.github/agents/zosmf-install-guide-generator.agent.md`
**Last Updated:** June 2, 2026

---

## Overview

`zosmf-install-guide-generator` is an AI documentation agent that generates a fully
formatted **Shrinkwrap Installation Guide and Impact Statement** Word document (`.docx`)
for any IBM product or product bundle installed on DCUF via z/OSMF.

It automates what was previously a manual documentation task — extracting product details
from Program Directory PDFs or IBM documentation URLs, populating a standardised Word
template, and producing a deployment-ready `.docx` guide suitable for SDT delivery and
client sign-off.

Supports:
- **New installations** (BASE, RSU levels)
- **Maintenance refreshes** (ZOSMFA, ZOSMFB)
- **Single products** and **multi-product bundles / suites**

---

## Capabilities

| # | Capability | Detail |
|---|---|---|
| 1 | **Template selection** | Automatically selects the correct template based on guide type (`NewInstall` / `Maintenance`) and install type (`ZOSMF` / `ZOSMFA` / `ZOSMFB`) |
| 2 | **PDF data extraction** | Extracts PID, FMIDs, dataset suffixes, ZFS suffixes, Non-SMP/E datasets, product overview, new features, migration notes, z/OS support statement, and IBM docs URL from Program Directory PDFs via Word COM automation |
| 3 | **IBM docs URL fetching** | Fetches IBM documentation URLs (`ibm.com/docs`) to extract the same fields when no PDF is available |
| 4 | **Bundle / multi-product mode** | Handles product suites with per-component extraction — each component processed individually, results aggregated at bundle level with the most-restrictive z/OS support statement |
| 5 | **Dataset list generation** | Auto-generates product datasets, SMP/E datasets (fixed 10-line set), ZFS datasets, Non-SMP/E datasets, CSI datasets, Holddata, Instlib, and Results blocks using correct HLQ patterns |
| 6 | **Auto-derived values** | Automatically sets installation date (today), HLQ_NS (`ACSNS`), HLQ_VS (`ACSVS`), ZOSPAC_LEVEL (from z/OS support statement), TARGET_RELEASE, and HOLDDATA_NOTE — never asks the user for these |
| 7 | **Placeholder substitution** | Fills every `{{PLACEHOLDER}}` token in the selected template with the collected or extracted value |
| 8 | **Markdown output** | Writes the fully populated guide as a `.md` file to `c:\Users\A462415\Priya\Shrinkwrap_guide\` |
| 9 | **Word DOCX generation** | Converts Markdown to `.docx` via pandoc + Word COM post-processing (styles, TOC, cover page, table borders) using `Generate-Guide.ps1` |
| 10 | **Output validation** | Verifies DOCX exists, counts tables (3 for new install, 4 for maintenance), and reports any unfilled `{{PLACEHOLDER}}` tokens |
| 11 | **User confirmation gates** | After PDF/URL extraction, presents a confirmation table of all extracted values and waits for user approval before proceeding |
| 12 | **Security** | Never stores, echoes, or logs credentials or sensitive dataset names beyond what is needed to fill the guide template |

---

## Guide Types Supported

| Guide Type | Install Type | Use Case |
|---|---|---|
| `NewInstall` | `ZOSMF` | First-time installation at BASE level |
| `NewInstall` | `ZOSMFA` | First-time installation at RSU level A |
| `NewInstall` | `ZOSMFB` | First-time installation at RSU level B |
| `Maintenance` | `ZOSMF` | Maintenance refresh from a previous ZOSMF installation |
| `Maintenance` | `ZOSMFA` | Maintenance refresh from a previous ZOSMFA installation |
| `Maintenance` | `ZOSMFB` | Maintenance refresh from a previous ZOSMFB installation |

---

## Input Parameters

Parameters marked **Auto** are never asked of the user — they are derived or fixed.

| Parameter | Required | Source |
|---|---|---|
| Vendor name | Yes | User |
| Product full name | Yes | User |
| Product short name (dataset node) | Yes | User |
| Product version label (e.g. `V16R1M0`) | Yes | User |
| Guide type (`NewInstall` / `Maintenance`) | Yes | User |
| Install type (`ZOSMF` / `ZOSMFA` / `ZOSMFB`) | Yes | User |
| IBM Program ID (PID) | Yes | Auto-extracted from PDF, or User |
| FMID list | Yes | Auto-extracted from PDF, or User |
| Dataset suffixes (Target + DLIB LLQs) | Yes | Auto-extracted from PDF, or User |
| ZFS dataset suffixes | If applicable | Auto-extracted from PDF |
| Non-SMP/E dataset suffixes | If applicable | Auto-extracted from PDF |
| z/OS compatibility statement | Yes | Auto-extracted from PDF, or User |
| Product overview | Yes | Auto-extracted from PDF, or User |
| New features bullet list | Yes | Auto-extracted from PDF, or User |
| Migration notes | Yes | Auto-extracted from PDF, or User |
| IBM documentation URL | Yes | Auto-extracted from PDF, or User |
| SDT Workflow number | Yes | User |
| Total tracks on DCUF | Yes | User |
| SMP/E version used | Yes | User |
| TeamDocs folder label and SharePoint URL | Yes | User |
| Current release *(Maintenance only)* | Maintenance | User |
| SYSMODs received / applied *(Maintenance only)* | Maintenance | User |
| Previous install type *(Maintenance only)* | Maintenance | User |
| Program Directory PDF path(s) | Optional | User |
| Installation date | **Auto** | Today's date |
| HLQ_NS | **Auto** | Always `ACSNS` |
| HLQ_VS | **Auto** | Always `ACSVS` |
| ZOSPAC_LEVEL | **Auto** | Derived from z/OS support statement |
| TARGET_RELEASE | **Auto** | Derived from product version + RSU level |
| HOLDDATA_NOTE | **Auto** | Fixed standard text |

---

## 7-Step Generation Process

The agent announces each step and does not proceed until the current step is complete.

| Step | Name | Action |
|---|---|---|
| **0** | Bundle Detection | Detects if the request is for a multi-product bundle or suite |
| **1** | Template Selection | Reads the correct template file from `c:\Users\A462415\Priya\Shrinkwrap_guide\` |
| **1b** | Data Extraction | Extracts product fields from PDFs (Word COM) or IBM docs URLs; presents confirmation table; waits for user approval |
| **2** | Dataset List Build | Generates all dataset name blocks: product, SMP/E, ZFS, Non-SMP/E, CSI, Holddata, Instlib, Results |
| **3** | Placeholder Fill | Substitutes every `{{PLACEHOLDER}}` in the template |
| **4** | Write Markdown | Saves the fully populated `.md` file to `c:\Users\A462415\Priya\Shrinkwrap_guide\` |
| **5** | Generate DOCX | Closes Word, runs `Generate-Guide.ps1` (pandoc + Word COM styling) |
| **6** | Validate Output | Confirms DOCX exists, table count correct, no unfilled placeholders |
| **7** | Report Completion | Displays output paths, table count, and fill status |

---

## How to Deploy in VS Code

### Prerequisites

| Requirement | Details |
|---|---|
| VS Code | Version 1.85 or later |
| GitHub Copilot Chat extension | Installed and signed in (`github.copilot-chat`) |
| Repository opened in VS Code | `applied-ai-software-delivery` folder open as a workspace |
| Microsoft Word | Installed on the Windows machine (required for DOCX post-processing) |
| Pandoc | Installed and on PATH |
| Template folder | `c:\Users\A462415\Priya\Shrinkwrap_guide\` with all four reference files |

### Required Template Files

| File | Purpose |
|---|---|
| `zosmf_install_template.md` | New install guide template with `{{PLACEHOLDER}}` tokens |
| `zosmf_maintenance_template.md` | Maintenance guide template |
| `Generate-Guide.ps1` | PowerShell converter: pandoc → Word COM styling |
| `zosmf_template.docx` | Word style reference (fonts, colours, table borders, page layout) |

### Verify Agent Registration

```bash
# Confirm the agent file exists
ls .github/agents/zosmf-install-guide-generator.agent.md

# Confirm it is registered in the agents registry
grep -n "zosmf-install-guide-generator" .github/AGENTS.md
```

### Open the Agent in VS Code Copilot Chat

1. Open VS Code with the `applied-ai-software-delivery` workspace loaded
2. Press `Ctrl+Alt+I` (Windows/Linux) or `Cmd+Alt+I` (Mac) to open Copilot Chat
3. In the chat panel, click the **agent/mode selector** at the top of the input area
4. Select **`zosmf-install-guide-generator`** from the list
5. Type your request and press Enter

> **Tip:** Type `@zosmf-install-guide-generator` directly in the chat input to invoke
> the agent inline without switching the mode selector.

---

## How to Invoke

### New Install — with Program Directory PDF

```
@zosmf-install-guide-generator generate installation guide for IBM Fault Analyzer for z/OS V16R1M0
Install type: ZOSMF
PDF: c:\path\to\faultanl_program_directory.pdf
SDT Workflow: 10006
Tracks: 20,016
SMP/E version: 37.35
TeamDocs: TeamDocs > 02.Software Delivery Documentation > DCUF > Products > Fault Analyzer
TeamDocs URL: https://atos365.sharepoint.com/sites/your-site/...
```

### New Install — with IBM Docs URL (no PDF)

```
@zosmf-install-guide-generator generate installation guide for IBM CICS TS V6R3M0 ZOSMF new install
IBM docs URL: https://www.ibm.com/docs/en/cics-ts/6.3?topic=program-directory
SDT Workflow: 10007
Tracks: 15,200
SMP/E version: 37.35
TeamDocs: TeamDocs > 02.Software Delivery Documentation > DCUF > Products > CICS
TeamDocs URL: https://atos365.sharepoint.com/sites/your-site/...
```

### Maintenance Refresh

```
@zosmf-install-guide-generator create maintenance guide for IBM Db2 for z/OS V13R1M0 ZOSMFA
Previous install type: ZOSMF
Current release: V13R1M0 RSU2412
SYSMODs received: 22
SYSMODs applied: 14
PDF: c:\path\to\db2_v13_program_directory.pdf
SDT Workflow: 10012
Tracks: 48,300
SMP/E version: 37.35
```

### Bundle / Suite (Multiple Products)

```
@zosmf-install-guide-generator generate bundle guide for IBM Application Delivery Foundation for z/OS V5R2M0
Bundle short name: ADFz
Install type: ZOSMF
Guide type: NewInstall
Components:
  1. IBM Fault Analyzer V16R1M0 — PDF: c:\path\to\faultanl_progdir.pdf
  2. IBM File Manager V16R1M0 — PDF: c:\path\to\filemgr_progdir.pdf
  3. IBM Debug Tool V16R1M0 — IBM docs: https://www.ibm.com/docs/en/debug-tool/16.1.0
SDT Workflow: 10015
Tracks: 62,400
SMP/E version: 37.35
```

### Natural Language Trigger Phrases

| Phrase | Example |
|---|---|
| `generate installation guide for` | `generate installation guide for IBM MQ V9R4M0` |
| `create shrinkwrap guide for` | `create shrinkwrap guide for IBM z/OS Connect V3` |
| `build install guide for` | `build install guide for CICS TS V6R3M0` |
| `generate maintenance guide for` | `generate maintenance guide for IBM Db2 V13 ZOSMFA` |
| `create ZOSMF guide for` | `create ZOSMF guide for IBM IMS V15` |
| `generate bundle guide for` | `generate bundle guide for ADFz V5R2M0` |
| `new product guide for` | `new product guide for IBM Fault Analyzer` |

---

## Output Files

**Single product** filename pattern:
```
c:\Users\A462415\Priya\Shrinkwrap_guide\<SHORT>_<VERSION>_<TYPE>_Guide.md
c:\Users\A462415\Priya\Shrinkwrap_guide\<SHORT>_<VERSION>_<TYPE>_Guide.docx
```

**Bundle** filename uses the bundle short name:
```
c:\Users\A462415\Priya\Shrinkwrap_guide\<BUNDLE_SHORT>_<BUNDLE_VERSION>_<TYPE>_Guide.md
c:\Users\A462415\Priya\Shrinkwrap_guide\<BUNDLE_SHORT>_<BUNDLE_VERSION>_<TYPE>_Guide.docx
```

| Request | Output Filename |
|---|---|
| Fault Analyzer V16R1M0 ZOSMF new install | `FAULTANL_V16R1M0_ZOSMF_Guide.docx` |
| Db2 V13R1M0 ZOSMFA maintenance | `DB2_V13R1M0_ZOSMFA_Guide.docx` |
| ADFz V5R2M0 ZOSMF bundle | `ADFz_V5R2M0_ZOSMF_Guide.docx` |

---

## Dataset Naming Convention

| Dataset Type | Pattern | Example |
|---|---|---|
| Product Target/DLIB datasets | `ACSNS.<SHORT>.<VERSION>.<TYPE>.<SUFFIX>` | `ACSNS.FAULTANL.V16R1M0.ZOSMF.SAIDILPA` |
| ZFS datasets | `ACSVS.<SHORT>.<VERSION>.<TYPE>.<SUFFIX>` | `ACSVS.FAULTANL.V16R1M0.ZOSMF.SFEKZFS` |
| Non-SMP/E datasets | `ACSNS.<SHORT>.<VERSION>.<TYPE>.<SUFFIX>` | `ACSNS.FAULTANL.V16R1M0.ZOSMF.CKRJOBS` |
| CSI datasets | `ACSVS.<SHORT>.<VERSION>.<TYPE>.[DLIB/GLOBAL/TARGET].CSI` | `ACSVS.FAULTANL.V16R1M0.ZOSMF.TARGET.CSI` |
| SMP/E datasets (always 10) | `ACSNS.<SHORT>.<VERSION>.<TYPE>.SMP*` | `ACSNS.FAULTANL.V16R1M0.ZOSMF.SMPPTS` |
| Holddata | `ACSNS.<SHORT>.<VERSION>.<TYPE>.DOCLIB` | `ACSNS.FAULTANL.V16R1M0.ZOSMF.DOCLIB` |
| Instlib / Results | `ACSNS.<SHORT>.<VERSION>.<TYPE>.INSTLIB` | `ACSNS.FAULTANL.V16R1M0.ZOSMF.INSTLIB` |

---

## Completion Report

After generation the agent displays:

```
=== GUIDE GENERATION COMPLETE ===
Product    : IBM Fault Analyzer for z/OS V16R1M0
Type       : NewInstall (ZOSMF)
Output MD  : c:\Users\A462415\Priya\Shrinkwrap_guide\FAULTANL_V16R1M0_ZOSMF_Guide.md
Output Doc : c:\Users\A462415\Priya\Shrinkwrap_guide\FAULTANL_V16R1M0_ZOSMF_Guide.docx
Tables     : 3
Status     : All placeholders filled
```

---

## Related Agents

| Agent | Purpose | When to Use |
|---|---|---|
| `deployment-planner` | PTF package analysis and deployment planning | Before installing the product |
| `smpe-validator` | SMP/E zone health check | Before and after SMP/E operations |
| `rollback-planner` | Rollback procedure generation | Contingency planning |
| `operational-audit-compliance-assistant` | Full IBM Health Checker compliance audit | Post-installation verification |

---

*Maintained by: Mainframe Systems Programming Team*
*Agent definition: `.github/agents/zosmf-install-guide-generator.agent.md`*
