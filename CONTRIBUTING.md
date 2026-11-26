# Contributing to Applied AI Software Delivery

Thank you for your interest in contributing! This document provides guidelines for contributing to this repository.

## Getting Started

1. **Clone the repository:**
   ```bash
   git clone https://github.gsissc.myatos.net/US-IRV-MAINFRAME-SERVICES/applied-ai-software-delivery.git
   cd applied-ai-software-delivery
   ```

2. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes and commit:**
   ```bash
   git add .
   git commit -m "Description of changes"
   ```

4. **Push and create a pull request:**
   ```bash
   git push origin feature/your-feature-name
   ```

## Code Standards

### Ansible Playbooks
- Use YAML syntax with 2-space indentation
- Include descriptive task names
- Add error handling with `rescue` blocks
- Document variables at the top of playbooks
- Test playbooks with `--syntax-check` and `--check`

### Python Scripts
- Follow PEP 8 style guidelines
- Use type hints for function parameters
- Include docstrings for all functions and classes
- Write unit tests for new functionality
- Use `black` for code formatting

### Bash Scripts
- Use `#!/bin/bash` shebang
- Enable strict mode: `set -euo pipefail`
- Include usage documentation
- Quote all variables
- Add error handling

### Documentation
- Use Markdown format
- Include code examples
- Keep README files up to date
- Document all configuration options

## AI Agents and Skills

### Creating New Agents

1. Create file in `.github/agents/` with `.agent.md` extension
2. Include YAML frontmatter:
   ```yaml
   ---
   name: agent-name
   description: Brief description
   ---
   ```
3. Document role, capabilities, and usage
4. Register in `.github/AGENTS.md`
5. Test with sample scenarios

### Creating New Skills

1. Create directory in `.github/skills/skill-name/`
2. Add `SKILL.md` with:
   - Skill description
   - User persona
   - Input parameters
   - Step-by-step instructions
   - Examples and troubleshooting
3. Test thoroughly before deployment

## Pull Request Process

1. **Ensure all tests pass:**
   ```bash
   # Run syntax checks
   ansible-playbook --syntax-check ansible/playbooks/*.yml
   
   # Run linters
   ansible-lint ansible/playbooks/
   yamllint ansible/
   
   # Run Python tests
   pytest tests/
   ```

2. **Update documentation:**
   - Update README if adding new features
   - Update CHANGELOG with your changes
   - Add/update comments in code

3. **Request review:**
   - Assign to team member for review
   - Address all review comments
   - Ensure CI/CD pipeline passes

4. **Merge requirements:**
   - At least one approval required
   - All CI checks must pass
   - No merge conflicts
   - Branch up to date with main

## Commit Message Guidelines

Format: `<type>: <description>`

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Formatting changes
- `refactor`: Code restructuring
- `test`: Adding tests
- `chore`: Maintenance tasks

Examples:
```
feat: Add SMP/E ACCEPT playbook
fix: Correct package validation checksum logic
docs: Update deployment procedures README
```

## Testing

### Local Testing

Before submitting:
```bash
# Test Ansible playbooks
ansible-playbook --check ansible/playbooks/smpe-apply.yml

# Test Python scripts
python -m pytest tests/

# Test bash scripts
shellcheck scripts/bash/*.sh
```

### CI/CD Pipeline

All pull requests trigger automated checks:
- Ansible syntax validation
- YAML linting
- Python linting and tests
- Security scanning

Ensure all checks pass before requesting review.

## Questions or Issues?

- **For questions:** Contact the team via email or Teams
- **For bugs:** Create an issue in GitHub
- **For features:** Discuss with team lead before implementing

## Code of Conduct

- Be respectful and professional
- Follow security best practices
- Don't commit credentials or sensitive data
- Test thoroughly in lower environments first
- Document your work clearly

---

**Thank you for contributing!**
