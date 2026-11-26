# Deployment Procedures

This directory contains standard operating procedures (SOPs) for z/OS software deployments.

## Available Procedures

### 1. Standard PTF Deployment
**File:** [standard-ptf-deployment.md](standard-ptf-deployment.md)  
**Purpose:** Step-by-step procedure for deploying PTFs using SMP/E  
**Use When:** Regular maintenance deployment during scheduled windows

### 2. Emergency Deployment
**File:** [emergency-deployment.md](emergency-deployment.md)  
**Purpose:** Expedited procedure for critical fixes  
**Use When:** Production issues requiring immediate PTF application

### 3. Rollback Procedures
**File:** [rollback-procedures.md](rollback-procedures.md)  
**Purpose:** How to rollback failed deployments  
**Use When:** Deployment fails or causes system issues

### 4. Pre-Deployment Checklist
**File:** [pre-deployment-checklist.md](pre-deployment-checklist.md)  
**Purpose:** Validation steps before starting deployment  
**Use When:** Before every deployment (mandatory)

### 5. Post-Deployment Validation
**File:** [post-deployment-validation.md](post-deployment-validation.md)  
**Purpose:** Verification steps after deployment  
**Use When:** After every deployment (mandatory)

## Using the Procedures

All procedures follow this standard format:

1. **Purpose** - What this procedure accomplishes
2. **Prerequisites** - What must be in place before starting
3. **Risk Assessment** - Impact and risk level
4. **Procedure Steps** - Detailed step-by-step instructions
5. **Validation** - How to verify success
6. **Troubleshooting** - Common issues and solutions
7. **Rollback** - How to reverse if needed

## AI Agent Assistance

For help with any procedure, use these agents:

- `@deployment-planner` - Create deployment plans
- `@smpe-validator` - Validate SMP/E zones
- `@rollback-planner` - Generate rollback procedures
- `@change-reviewer` - Review documentation

## Contributing

When creating new procedures:

1. Use the template in `procedure-template.md`
2. Include all required sections
3. Test the procedure in lower environments
4. Have a peer review before adding to production use
5. Update this README with the new procedure

---

**Questions?** Contact the Mainframe Systems Programming Team
