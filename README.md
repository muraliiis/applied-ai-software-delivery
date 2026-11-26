# Applied AI Software Delivery

**Intelligent Automation for z/OS Software Deployment & Maintenance**

## 🎯 Purpose

This repository provides AI-assisted automation tools and frameworks for z/OS software delivery, including:

- **SMP/E Package Deployment** - Automated PTF/APAR installation and verification
- **Configuration Management** - Ansible playbooks for z/OS system configuration
- **Change Management Integration** - ServiceNow workflow automation
- **Delivery Verification** - Pre/post-deployment validation scripts
- **Documentation Generation** - AI-assisted technical documentation

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│          VS Code + GitHub Copilot (AI Layer)            │
│  • Deployment Planning    • Change Analysis             │
│  • Risk Assessment        • Documentation Generation    │
└────────────────────┬────────────────────────────────────┘
                     │
         ┌───────────┴───────────┐
         │   Linux Control Node   │
         │   • Ansible Core       │
         │   • Python Scripts     │
         │   • SFTP/FTP Clients   │
         └───────────┬───────────┘
                     │
    ┌────────────────┼────────────────┐
    │                │                │
┌───┴───┐      ┌────┴────┐     ┌────┴─────┐
│ LPAR1 │      │  LPAR2  │     │  LPAR3   │
│ z/OS  │      │  z/OS   │     │  z/OS    │
└───────┘      └─────────┘     └──────────┘
```

## 📁 Repository Structure

```
applied-ai-software-delivery/
├── .github/
│   ├── copilot-instructions.md    # AI agent configuration
│   ├── AGENTS.md                   # Agent registration
│   ├── agents/                     # Custom AI agents
│   │   ├── deployment-planner.agent.md
│   │   ├── smpe-validator.agent.md
│   │   └── change-reviewer.agent.md
│   ├── skills/                     # Domain-specific skills
│   │   ├── package-transfer/
│   │   ├── smpe-deployment/
│   │   └── rollback-procedures/
│   └── workflows/                  # CI/CD pipelines
│       └── validate-playbooks.yml
│
├── ansible/
│   ├── playbooks/                  # Deployment playbooks
│   │   ├── smpe-receive.yml
│   │   ├── smpe-apply.yml
│   │   └── system-validation.yml
│   ├── roles/                      # Reusable roles
│   │   ├── smpe/
│   │   ├── dataset-management/
│   │   └── catalog-operations/
│   ├── inventory/                  # Environment configs
│   │   ├── production.yml
│   │   ├── staging.yml
│   │   └── development.yml
│   └── group_vars/                 # Variable definitions
│
├── scripts/
│   ├── python/                     # Automation scripts
│   │   ├── package_validator.py
│   │   ├── holddata_analyzer.py
│   │   └── deployment_reporter.py
│   ├── rexx/                       # z/OS REXX scripts
│   │   ├── SMPERECV.rexx
│   │   └── CATCHECK.rexx
│   └── bash/                       # Shell scripts
│       ├── transfer_package.sh
│       └── verify_transfer.sh
│
├── configs/
│   ├── deployment-templates/       # Deployment configurations
│   ├── snow-templates/             # ServiceNow templates
│   └── validation-rules/           # Deployment validation rules
│
├── docs/
│   ├── deployment-procedures/      # Standard procedures
│   ├── troubleshooting/            # Common issues & solutions
│   ├── architecture/               # Design documentation
│   ├── audit-reports/              # Compliance audit reports (MD + PDF)
│   └── audit-history/              # Audit history JSON + trail logs
│
└── README.md
```

## 🚀 Quick Start

### Prerequisites

- **Linux Control Node** with:
  - Ansible 2.9+
  - Python 3.8+
  - IBM Z Open Automation Utilities (ZOAU)
  - VS Code with GitHub Copilot

- **z/OS Target Systems** with:
  - SSH access configured
  - Python on z/OS (optional, for advanced automation)
  - SFTP/FTP access for package transfers

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.gsissc.myatos.net/US-IRV-MAINFRAME-SERVICES/applied-ai-software-delivery.git
   cd applied-ai-software-delivery
   ```

2. **Install Ansible dependencies:**
   ```bash
   pip install -r requirements.txt
   ansible-galaxy collection install ibm.ibm_zos_core
   ```

3. **Configure inventory:**
   ```bash
   cp ansible/inventory/sample.yml ansible/inventory/production.yml
   # Edit with your LPAR details
   ```

4. **Test connectivity:**
   ```bash
   ansible all -i ansible/inventory/production.yml -m ping
   ```

## 📋 Usage Examples

### 1. Package Transfer & Deployment

```bash
# Transfer PTF package from SDT factory to target LPAR
ansible-playbook ansible/playbooks/package-transfer.yml \
  -i ansible/inventory/production.yml \
  -e "package_name=S1234567.PACKLIST"

# Deploy using SMP/E
ansible-playbook ansible/playbooks/smpe-apply.yml \
  -i ansible/inventory/production.yml \
  -e "zone=MVST100" \
  -e "bypass_holds=true"
```

### 2. AI-Assisted Deployment Planning

Use the **deployment-planner** agent in VS Code:
1. Open a chat with `@deployment-planner`
2. Provide the PTF list or FIXCAT report
3. Agent analyzes dependencies, hold conditions, and risks
4. Generates deployment plan and rollback procedures

### 3. Validation & Verification

```bash
# Pre-deployment validation
ansible-playbook ansible/playbooks/pre-deployment-check.yml

# Post-deployment verification
ansible-playbook ansible/playbooks/post-deployment-verify.yml
```

## 🤖 AI Agents

### Available Agents

| Agent | Purpose | Usage |
|-------|---------|-------|
| **deployment-planner** | Analyzes PTF orders and creates deployment plans | `@deployment-planner analyze package S1234567` |
| **smpe-validator** | Validates SMP/E zones and identifies issues | `@smpe-validator check zone MVST100` |
| **rollback-planner** | Creates rollback procedures for deployments | `@rollback-planner create plan for PTF UJ12345` |
| **ptf-order-verification** | Verifies Shopz PTF orders and packing lists | `@ptf-order-verification verify packing list S1234567` |
| **Shrinkwrap_Guide_ZOSMF** | Generates Installation Guide & Impact Statement | `@Shrinkwrap_Guide_ZOSMF generate guide for product` |
| **zos-migration-healthcheck-assistant** | Executes ZOSMIG* health checks and produces Migration Health Report | `@zos-migration-healthcheck-assistant run migration checks on myLPAR for z/OS 3.1 to 3.2` |
| **operational-audit-compliance-assistant** | Full IBM Health Checker compliance audit platform for DCUF | `@operational-audit-compliance-assistant run full audit` |

### Using Agents

Open VS Code and start a chat:
```
@deployment-planner I need to deploy PTF package S9876543 to production.
Analyze the package and create a deployment plan with risk assessment.
```

---

## 🔍 Operational Audit & Compliance Platform

The **`operational-audit-compliance-assistant`** is an AI-driven compliance audit agent for the DCUF mainframe LPAR. It executes all registered IBM Health Checker categories live via Zowe CLI, produces a risk-scored compliance report, and restores every health check to its exact pre-audit state after collection.

This report is designed for consumption by **z/OS Systems Programmers**, **SQA teams**, and **client compliance reviewers** — mapping every exception to an IBM best practice reference, the affected parmlib member, and a prioritized remediation action plan.

### Capabilities

| # | Capability | Description |
|---|---|---|
| 1 | **Multi-source data collection** | Executes all checks via HZSPROC console (Zowe CLI); supports SDSF REXX batch, HZSPRINT, SMF Type 89, and z/OSMF REST API |
| 2 | **Pre-audit state management** | Captures ACTIVE/INACTIVE state of every check before the audit; restores each check individually to its original state after — never uses bulk deactivation |
| 3 | **Data normalization** | Produces structured JSON per check including `pre_audit_state`, `normalized_status`, `severity`, `category`, `parmlib_members`, `risk_score`, and `ibm_reference` |
| 4 | **11 compliance domains** | SECURITY, STORAGE, PERFORMANCE, AVAILABILITY, IO_SUBSYSTEM, UNIX_SERVICES, NETWORK, JES_SPOOL, MIGRATION, SYSTEM_BASE, SUBSYSTEMS |
| 5 | **Risk scoring (1–10)** | Severity base score adjusted for security/RACF (+2), Sysplex availability (+2), parmlib change required (+1), IPL required (+1) |
| 6 | **IBM best practice correlation** | Every exception mapped to IBM publication reference and remediation steps |
| 7 | **Compliance report generation** | ASCII dashboard + executive summary + per-finding detail + prioritized remediation action plan → saved as `.md` and `.pdf` |
| 8 | **Historical tracking** | `docs/audit-history/dcuf-audit-history.json` records every audit run; full command audit trail in `docs/audit-history/audit-trail.log` |
| 9 | **Trend analysis** | Conversational queries on exception trends across audit history |
| 10 | **Scheduled audits** | JCL (ESP/CA7) and Linux cron templates for automated weekly or pre/post-change audits |
| 11 | **Conversational queries** | Natural language Q&A for SysProg, SQA, and management audiences |

### How to Invoke

Open VS Code Copilot chat and use `@operational-audit-compliance-assistant`:

#### Run a Full Audit
```
@operational-audit-compliance-assistant run full audit
```
Executes all 185 IBM Health Checker categories against DCUF. Produces a compliance report saved to `docs/audit-reports/audit-DCUF-<YYYYMMDD>.md` and `.pdf`.

#### Run a Category-Focused Audit
```
@operational-audit-compliance-assistant run audit SECURITY
@operational-audit-compliance-assistant run audit MIGRATION
@operational-audit-compliance-assistant run audit AVAILABILITY
```
Runs only checks in the specified domain. Available categories: `SECURITY` `STORAGE` `PERFORMANCE` `AVAILABILITY` `IO_SUBSYSTEM` `UNIX_SERVICES` `NETWORK` `JES_SPOOL` `MIGRATION` `SYSTEM_BASE` `SUBSYSTEMS`

#### Display Compliance Dashboard
```
@operational-audit-compliance-assistant show dashboard
```
Renders an ASCII compliance dashboard with per-category scores, pass/warning/exception counts, and top risks:
```
╔══════════════════════════════════════════════════════════════════════╗
║        DCUF OPERATIONAL AUDIT DASHBOARD — 26 MAY 2026 12:00 UTC     ║
╠══════════════════════════════════════════════════════════════════════╣
║  OVERALL COMPLIANCE SCORE:  [██████████████░░░░░░] 70%               ║
╠══════════════════════════════════════════════════════════════════════╣
║  SECURITY   [█████████░░░░░░░░░░░]  67% ❌   AVAILABILITY [████████████████░░░░]  84% ⚠️  ║
║  STORAGE    [████████████████████] 100% ✅   NETWORK      [███████████████████░]  94% ✅  ║
║  MIGRATION  [█████████████░░░░░░░]  67% ❌   SUBSYSTEMS   [████████░░░░░░░░░░░░]  44% ❌  ║
╚══════════════════════════════════════════════════════════════════════╝
```

#### Export Report
```
@operational-audit-compliance-assistant export report as pdf
@operational-audit-compliance-assistant export report as md
@operational-audit-compliance-assistant export report as html
```
Saves the latest report to `docs/audit-reports/` in the requested format.

#### Show Compliance Trends
```
@operational-audit-compliance-assistant show trends
```
Loads `docs/audit-history/dcuf-audit-history.json` and presents exception count trends across all previous audits.

#### Conversational Queries
```
@operational-audit-compliance-assistant query: what are the top 3 risks from the last audit?
@operational-audit-compliance-assistant query: which parmlib members need updating to resolve all exceptions?
@operational-audit-compliance-assistant query: is DCUF ready for z/OS 3.2 migration?
@operational-audit-compliance-assistant query: which checks have been failing for more than 3 audits?
@operational-audit-compliance-assistant query: show me all EXCEPTION checks for the RACF category
```

### Audit Output Files

| File | Description |
|---|---|
| `docs/audit-reports/audit-DCUF-<YYYYMMDD>.md` | Full compliance report in Markdown |
| `docs/audit-reports/audit-DCUF-<YYYYMMDD>.pdf` | PDF version for distribution and Change Records |
| `docs/audit-history/dcuf-audit-history.json` | Structured history of all audit runs with counts and scores |
| `docs/audit-history/audit-trail.log` | Timestamped log of every command issued during the audit |
| `docs/audit-history/preaudit-state-<YYYYMMDD>.json` | Per-check ACTIVE/INACTIVE snapshot captured before each audit |
| `docs/audit-history/restore-state-<YYYYMMDD>.json` | Post-audit restore verification record |

### Report Structure

Every audit report contains the following sections:

| Section | Content |
|---|---|
| **Compliance Dashboard** | ASCII visual with per-category scores and overall compliance % |
| **Executive Summary** | Total checks, pass/warning/exception/error counts, compliance score |
| **Section A — EXCEPTION-HIGH** | Critical findings with full remediation steps and IBM references |
| **Section B — WARNING** | EXCEPTION-MED findings table with risk scores and action required |
| **Section C — EXCEPTION-LOW** | Advisory findings with remediation summary |
| **Section D — Errors** | CHECK-ERROR / UNEXP ERROR findings requiring investigation |
| **Section E — Remediation Action Plan** | Prioritized P1/P2/P3 table with owner, parmlib member, and urgency |
| **Section F — Compliant Checks** | Passed checks by domain confirming operational health |
| **Section G — Next Steps** | Immediate, short-term, and migration actions |
| **Appendix** | Audit metadata (duration, commands issued, Zowe profile, HZSPROC STC) |

### Pre/Post-Change Audit Workflow

```
Before Change Window:
  @operational-audit-compliance-assistant run full audit
  → Baseline compliance snapshot saved

After Change Window:
  @operational-audit-compliance-assistant run full audit
  → Delta report: new exceptions + resolved items highlighted automatically

For SQA / Client Review:
  @operational-audit-compliance-assistant export report as pdf
  → PDF attached to ServiceNow Change Record
```

> **Note:** The agent operates in read-only mode at all times. It never modifies parmlib members or system configuration. All remediation steps are generated for peer review only.

## 📚 Documentation

- [Deployment Procedures](docs/deployment-procedures/README.md)
- [Ansible Playbook Guide](docs/ansible-guide.md)
- [AI Agent Usage](docs/agents-guide.md)
- [Troubleshooting](docs/troubleshooting/README.md)
- [Architecture Overview](docs/architecture/README.md)

## 🔒 Security & Compliance

- **Credentials Management:** Use Ansible Vault for sensitive data
- **Audit Logging:** All deployments logged to ServiceNow
- **Change Control:** Mandatory peer review for production changes
- **Rollback Capability:** Every deployment includes rollback procedure

## 🛠️ Contributing

1. Create a feature branch: `git checkout -b feature/your-feature`
2. Make changes and test thoroughly
3. Submit pull request with detailed description
4. Ensure AI agents validate the changes

## 📝 Change Log

See [CHANGELOG.md](CHANGELOG.md) for version history.

## 📞 Support

- **Team:** US-IRV-MAINFRAME-SERVICES
- **Repository Issues:** [GitHub Issues](https://github.gsissc.myatos.net/US-IRV-MAINFRAME-SERVICES/applied-ai-software-delivery/issues)
- **Documentation:** [Wiki](https://github.gsissc.myatos.net/US-IRV-MAINFRAME-SERVICES/applied-ai-software-delivery/wiki)

## 📜 License

Copyright © 2026 Atos. All rights reserved.

---

**Last Updated:** May 26, 2026  
**Maintained by:** Mainframe Systems Programming Team
