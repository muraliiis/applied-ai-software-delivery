# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

#### Operational Audit & Compliance Platform (May 26, 2026)
- **`operational-audit-compliance-assistant`** agent — full IBM Health Checker audit platform for DCUF
  - Executes all 185 registered health checks across 11 compliance domains via Zowe CLI
  - Captures pre-audit `ACTIVE`/`INACTIVE` state of every check; restores each check
    individually to its original state after collection (no bulk deactivation)
  - Normalizes findings into structured JSON datasets with risk scores (1–10)
  - Correlates exceptions with IBM best practice references and parmlib remediation steps
  - Generates compliance reports in Markdown and PDF with ASCII dashboard, executive
    summary, and prioritized remediation action plan
  - Supports historical trend tracking (`docs/audit-history/dcuf-audit-history.json`)
    and full audit trail logging (`docs/audit-history/audit-trail.log`)
  - Suitable for SQA review and client delivery — report identifies configuration change
    requirements mapped to IBM documentation
- **`zos-migration-healthcheck-assistant`** agent — ZOSMIG* migration readiness checks
  - Executes z/OS release migration health checks (ZOSMIG*) live against a target LPAR
  - Per-check pre-audit state snapshot with selective ACTIVATE/DEACTIVATE restore
  - Produces a Migration Health Report covering passed checks with compliance detail,
    exceptions with step-by-step remediation, and an action plan for the Change Record
  - Download as Markdown (`.md`) or PDF (`.pdf`)
- Audit report output directory: `docs/audit-reports/`
- Audit history and trail directory: `docs/audit-history/`
- First live audit of DCUF recorded: `docs/audit-reports/audit-DCUF-20260526.md/.pdf`
  - 185 checks | 150 evaluated | 70% compliance | 4 EXCEPTION-HIGH | 17 WARNING

#### Earlier Additions
- Initial repository structure
- README with comprehensive documentation
- AI agents for deployment planning and validation
  - deployment-planner agent
  - smpe-validator agent
  - rollback-planner agent
  - ptf-order-verification agent (copied from Skills-zOS)
- Skills for automated deployment tasks
  - package-transfer skill
  - smpe-deployment skill
- Sample Ansible playbooks for SMP/E operations
- Python utilities for package validation
- Bash scripts for package transfer
- GitHub workflows for CI/CD validation
- Custom Copilot instructions for software delivery

### Changed
- N/A

### Deprecated
- N/A

### Removed
- N/A

### Fixed
- N/A

### Security
- N/A

---

## [0.1.0] - 2026-05-06

### Added
- Initial repository setup
- Project documentation and structure
- AI-assisted deployment automation framework

---

[Unreleased]: https://github.gsissc.myatos.net/US-IRV-MAINFRAME-SERVICES/applied-ai-software-delivery/compare/v0.1.0...HEAD
[0.1.0]: https://github.gsissc.myatos.net/US-IRV-MAINFRAME-SERVICES/applied-ai-software-delivery/releases/tag/v0.1.0
