# M365 Copilot Integration Guide — ISV Maintenance Pipeline

**Repository:** `applied-ai-software-delivery`
**Last Updated:** 2026-07-24

---

## Contents

1. [Overview](#1-overview)
2. [How it Works](#2-how-it-works)
3. [Two Technical Paths](#3-two-technical-paths)
4. [AWX REST API Endpoints](#4-awx-rest-api-endpoints)
5. [Authentication Chain](#5-authentication-chain)
6. [What You Need to Set Up](#6-what-you-need-to-set-up)
7. [Repository Structure for M365 Agent](#7-repository-structure-for-m365-agent)
8. [Capability Comparison](#8-capability-comparison)
9. [Quickest Proof-of-Concept](#9-quickest-proof-of-concept)
10. [Next Steps](#10-next-steps)

---

## 1. Overview

The `sdt-maintenance-refresh-agent` GitHub Copilot agent cannot be invoked directly from Microsoft 365 Copilot — the two runtimes are completely separate platforms. However, the pipeline it orchestrates **can be fully replicated** in M365 Copilot by pointing a Declarative Agent at the AWX REST API.

The AWX Workflow Template built in [awx-pipeline-guide.md](awx-pipeline-guide.md) becomes the execution engine. M365 Copilot (Teams, Outlook, M365 Chat) becomes the conversational front-end that collects inputs, launches the workflow, monitors progress, and presents approval gates as Teams Adaptive Cards.

**Key principle:** The z/OS automation logic (Ansible playbooks, JCL templates, SMP/E processing) stays entirely inside AWX and never moves. Only the conversation layer changes.

---

## 2. How it Works

```
M365 Copilot (Teams / Outlook / M365 Chat)
    │
    │  User: "Run maintenance for TDMF ZOSMFB"
    ▼
Declarative Agent (declarativeAgent.json)
    │  Instructions ported from sdt-maintenance-refresh-agent.agent.md
    │  Collects 14 pipeline inputs via Adaptive Card survey
    │
    │  Action: launch_pipeline(survey_vars)
    ▼
Azure Function App  ────────────────────────────────────────────┐
    │  Authenticated via Entra App Registration (OAuth2)        │
    │  AWX API token retrieved from Azure Key Vault at runtime  │
    │                                                           │
    │  POST /api/v2/workflow_job_templates/{id}/launch/         │
    ▼                                                           │
AWX Automation Controller                                       │
    │  Executes: COPYRENA → DDEFUPDT → Internet Maintenance     │
    │                                                           │
    │  Pipeline pauses at APPLY CHECK Approval Node             │
    │                                                           │
    │  Action: get_pipeline_status(workflow_job_id)             │
    │  GET /api/v2/workflow_jobs/{id}/                          │
    │  GET /api/v2/jobs/{id}/stdout/?format=txt                 │
    ▼                                                           │
Azure Function returns APPLY CHECK summary JSON                 │
    │                                                           │
    ▼                                                           │
M365 Copilot presents Teams Adaptive Card:                      │
    "APPLY CHECK complete — 6 SYSMODs ready.                    │
     Approve to proceed with APPLY, or Deny to abort."         │
    │                                                           │
    │  User clicks Approve                                      │
    │  Action: approve_gate(approval_id)                        │
    │  POST /api/v2/workflow_approvals/{id}/approve/            │
    ▼                                                           │
AWX continues: APPLY → ACCEPT CHECK → [Approval] →             │
               ACCEPT → Shrinkwrap                              │
    │                                                           │
    ▼                                                           │
Azure Function returns final result JSON ───────────────────────┘
    │
    ▼
M365 Copilot:
    "Pipeline complete.
     New shrinkwrap: ACSNS.TDMF.V5R11M0.ZOSMFB.ZS31D.SHRNKWRP
     RC=0 — 42 datasets backed up."
```

---

## 3. Two Technical Paths

### Path A — Copilot Studio Connector (Low-Code)

Best when your organisation already uses Power Platform and does not require custom polling logic.

**How to build:**
1. Open **Copilot Studio** → Create a Custom Copilot
2. Add a **Topic** for maintenance pipeline launch
3. Add an **HTTP connector action** (or Power Automate cloud flow) that calls the AWX REST API
4. Use **Adaptive Card** nodes to collect the 14 survey inputs
5. For approval gates: Power Automate sends a Teams Adaptive Card with Approve/Deny buttons; the response calls `POST /api/v2/workflow_approvals/{id}/approve/`

**Limitation — polling timeout:** Power Automate HTTP actions time out after 120 seconds. Long-running AWX jobs (RECEIVE ORDER can take 30+ minutes) require a **Do-Until loop** with a Recurrence trigger, or use the AWX webhook notification feature to push job completion back to Power Automate rather than polling.

---

### Path B — Declarative Agent + Azure Function (Recommended)

More control over polling, error handling, and job output formatting. Suitable for production use.

**Components:**

| Component | Technology | Responsibility |
|---|---|---|
| Declarative Agent | `declarativeAgent.json` + `openapi.yaml` | Conversation, input collection, output formatting |
| Azure Function App | Node.js or Python | Auth proxy; long-poll AWX jobs; format output for M365 |
| OpenAPI spec | `openapi.yaml` | Defines 5 operations M365 Copilot can call (see §4) |
| Azure Key Vault | Azure Portal | Stores AWX API token securely |
| Entra App Registration | Azure AD | OAuth2 — M365 Copilot → Azure Function auth |

**How the polling works in Azure Function:**
The Azure Function uses a **Durable Function** (orchestrator pattern) so it can wait hours for long-running AWX jobs without holding an HTTP connection open:

```
HTTP trigger: launch_pipeline
  → Start AWX workflow job
  → Start Durable orchestrator (job_id)
     → Poll GET /api/v2/workflow_jobs/{id}/ every 30s
     → On status == "waiting" (approval node): return approval_id to M365
     → On status == "successful": return final summary to M365
     → On status == "failed": return error detail to M365
```

---

## 4. AWX REST API Endpoints

These are the five operations the Azure Function (or Power Automate flow) must implement:

| Operation | Method | AWX Endpoint | Purpose |
|---|---|---|---|
| `launch_pipeline` | POST | `/api/v2/workflow_job_templates/{wfjt_id}/launch/` | Start the pipeline; returns `workflow_job_id` |
| `get_pipeline_status` | GET | `/api/v2/workflow_jobs/{wfj_id}/` | Poll overall workflow status and node states |
| `get_job_output` | GET | `/api/v2/jobs/{job_id}/stdout/?format=txt` | Retrieve SYSPRINT/SMPOUT text for a specific job step |
| `approve_gate` | POST | `/api/v2/workflow_approvals/{approval_id}/approve/` | Unblock APPLY CHECK or ACCEPT CHECK approval node |
| `deny_gate` | POST | `/api/v2/workflow_approvals/{approval_id}/deny/` | Abort the pipeline at an approval node |

### Finding the workflow job template ID

```bash
curl -s https://awx.example.com/api/v2/workflow_job_templates/ \
  -H "Authorization: Bearer $AWX_TOKEN" | \
  python3 -m json.tool | grep -A2 '"ISV Maintenance Pipeline"'
```

### Example: Launch pipeline

```bash
curl -s -X POST \
  https://awx.example.com/api/v2/workflow_job_templates/42/launch/ \
  -H "Authorization: Bearer $AWX_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "extra_vars": {
      "shrinkwrap_dsn":    "ACSNS.TDMF.V5R11M0.ZOSMFA.ZS31D.SHRNKWRP",
      "new_qual":          "ACS%S.TDMF.V5R11M0.ZOSMFB",
      "vendor":            "ibm",
      "global_csi":        "ACSVS.TDMF.V5R11M0.ZOSMFB.GLOBAL.CSI",
      "target_csi":        "ACSVS.TDMF.V5R11M0.ZOSMFB.TARGET.CSI",
      "dlib_csi":          "ACSVS.TDMF.V5R11M0.ZOSMFB.DLIB.CSI",
      "target_zone":       "TZONE",
      "dlib_zone":         "DZONE",
      "existing_qual_rest":"TDMF.V5R11M0.ZOSMFA",
      "new_qual_rest":     "TDMF.V5R11M0.ZOSMFB",
      "userid_node":       "ZS31D",
      "typrun_norun":      "false"
    }
  }'
# Response: {"workflow_job": 1234, "url": "/api/v2/workflow_jobs/1234/", ...}
```

### Example: Check for pending approval nodes

```bash
WFJOB_ID=1234
curl -s https://awx.example.com/api/v2/workflow_jobs/${WFJOB_ID}/workflow_nodes/ \
  -H "Authorization: Bearer $AWX_TOKEN" | \
  python3 -c "
import sys, json
data = json.load(sys.stdin)
for node in data.get('results', []):
    if node.get('do_not_run') is False and node.get('job') is None:
        print('Approval pending — node:', node['id'])
"
```

### Example: Approve a gate

```bash
APPROVAL_ID=99
curl -s -X POST \
  https://awx.example.com/api/v2/workflow_approvals/${APPROVAL_ID}/approve/ \
  -H "Authorization: Bearer $AWX_TOKEN"
# Response: HTTP 204 No Content
```

---

## 5. Authentication Chain

```
M365 Copilot
  │
  │  OAuth2 — client_credentials flow
  │  Scope: api://{azure-function-app-id}/pipeline.execute
  ▼
Azure Function App
  │  (registered in Entra — validates M365 Copilot's access token)
  │
  │  Fetches AWX API token from Azure Key Vault
  │  Key Vault secret name: awx-api-token
  │  Uses Managed Identity (no secret stored in Function code)
  ▼
AWX Automation Controller
  │  Authorization: Bearer {awx_token}
  │  (Application token with workflow_job_template:execute scope)
  │
  │  Runs Ansible playbooks using:
  ▼
DCUF z/OS LPAR
  SSH private key stored in AWX Machine Credential
  (never exposed outside AWX — M365 only sees job IDs and text output)
```

### Setting up the Entra App Registration

1. Azure Portal → **Entra ID** → App Registrations → New Registration
2. Name: `ISV-Maintenance-Pipeline-M365`
3. Supported account types: single tenant
4. Add an **Application ID URI**: `api://{client-id}`
5. Add a **scope**: `pipeline.execute` (admin-consent required)
6. Note the **Client ID** and **Tenant ID** — needed in `declarativeAgent.json`

### Setting up the AWX API token

```
AWX UI → top-right menu → My profile → Tokens → Add
  Description : M365 Copilot Integration
  Application : (leave blank for personal token, or create an Application)
  Scope       : Write
→ Copy token value → store in Azure Key Vault as secret "awx-api-token"
```

---

## 6. What You Need to Set Up

| # | Item | Where | Estimated effort |
|---|---|---|---|
| 1 | AWX Workflow Template + Survey | Already done ([awx/configure-pipeline.yml](../awx/configure-pipeline.yml)) | Done |
| 2 | Azure Subscription | Azure Portal | 1 hour (if not existing) |
| 3 | Entra App Registration | Azure AD | 30 min |
| 4 | Azure Key Vault + secret | Azure Portal | 30 min |
| 5 | Azure Function App (Python/Node.js) | Azure Portal + VS Code | 4–8 hours |
| 6 | OpenAPI spec (`openapi.yaml`) | `m365-agent/` in repo | 2 hours |
| 7 | Declarative Agent (`declarativeAgent.json`) | `m365-agent/` in repo | 2 hours |
| 8 | Teams App manifest + package | `m365-agent/` in repo | 1 hour |
| 9 | Teams Admin Center deployment | M365 Admin Portal | 30 min |
| 10 | AWX notification → Teams webhook (optional) | AWX + Teams | 1 hour |

**Total estimated effort (Path B): 2–3 days**

---

## 7. Repository Structure for M365 Agent

Once built, the M365 agent source lives alongside the existing agent and Ansible files:

```
applied-ai-software-delivery/
├── .github/agents/
│   └── sdt-maintenance-refresh-agent.agent.md   ← GitHub Copilot (existing)
│
├── m365-agent/                                  ← NEW (to be created)
│   ├── declarativeAgent.json                    ← Instructions + action references
│   ├── manifest.json                            ← Teams App manifest (v1.18+)
│   ├── openapi.yaml                             ← 5-operation API plugin spec
│   ├── azure-function/
│   │   ├── launch_pipeline/
│   │   │   └── __init__.py                      ← POST /launch_pipeline
│   │   ├── get_pipeline_status/
│   │   │   └── __init__.py                      ← GET /get_pipeline_status
│   │   ├── get_job_output/
│   │   │   └── __init__.py                      ← GET /get_job_output
│   │   ├── approve_gate/
│   │   │   └── __init__.py                      ← POST /approve_gate
│   │   ├── deny_gate/
│   │   │   └── __init__.py                      ← POST /deny_gate
│   │   ├── host.json
│   │   └── requirements.txt
│   └── README.md
│
├── ansible/                                     ← Existing (unchanged)
└── awx/                                         ← Existing (unchanged)
```

### `declarativeAgent.json` skeleton

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/copilot/declarative-agent/v1.2/schema.json",
  "version": "v1.2",
  "name": "ISV Maintenance Pipeline",
  "description": "End-to-end maintenance agent for IBM, Broadcom, and BMC ISV products on z/OS via AWX.",
  "instructions": "<paste content from sdt-maintenance-refresh-agent.agent.md — Steps 1-16 — with tool calls replaced by action references>",
  "actions": [
    {
      "id": "launch_pipeline",
      "file": "openapi.yaml"
    }
  ]
}
```

### `openapi.yaml` skeleton

```yaml
openapi: 3.0.0
info:
  title: ISV Maintenance Pipeline API
  version: "1.0"
  description: Launches and monitors the ISV Maintenance Pipeline on AWX

servers:
  - url: https://{functionapp}.azurewebsites.net/api

paths:
  /launch_pipeline:
    post:
      operationId: launchPipeline
      summary: Launch the ISV Maintenance Pipeline workflow in AWX
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/PipelineInputs'
      responses:
        '200':
          description: Workflow launched
          content:
            application/json:
              schema:
                properties:
                  workflow_job_id: { type: integer }
                  status:          { type: string }

  /get_pipeline_status:
    get:
      operationId: getPipelineStatus
      summary: Get current status of a running pipeline workflow job
      parameters:
        - name: workflow_job_id
          in: query
          required: true
          schema: { type: integer }
      responses:
        '200':
          description: Workflow status

  /get_job_output:
    get:
      operationId: getJobOutput
      summary: Retrieve stdout/SMPOUT text for a specific AWX job step
      parameters:
        - name: job_id
          in: query
          required: true
          schema: { type: integer }
      responses:
        '200':
          description: Job stdout text

  /approve_gate:
    post:
      operationId: approveGate
      summary: Approve an APPLY CHECK or ACCEPT CHECK gate in AWX
      requestBody:
        required: true
        content:
          application/json:
            schema:
              properties:
                approval_id: { type: integer, description: "AWX workflow approval node ID" }
      responses:
        '204':
          description: Gate approved

  /deny_gate:
    post:
      operationId: denyGate
      summary: Deny (abort) an APPLY CHECK or ACCEPT CHECK gate in AWX
      requestBody:
        required: true
        content:
          application/json:
            schema:
              properties:
                approval_id: { type: integer }
      responses:
        '204':
          description: Gate denied

components:
  schemas:
    PipelineInputs:
      type: object
      required:
        - shrinkwrap_dsn
        - new_qual
        - vendor
        - global_csi
        - target_zone
        - dlib_zone
        - existing_qual_rest
        - new_qual_rest
        - userid_node
      properties:
        shrinkwrap_dsn:      { type: string }
        new_qual:            { type: string }
        vendor:              { type: string, enum: [ibm, broadcom, bmc] }
        global_csi:          { type: string }
        target_csi:          { type: string }
        dlib_csi:            { type: string }
        target_zone:         { type: string }
        dlib_zone:           { type: string }
        existing_qual_rest:  { type: string }
        new_qual_rest:       { type: string }
        userid_node:         { type: string }
        typrun_norun:        { type: boolean, default: false }
        shrnkwrp_space_primary:   { type: integer, default: 200 }
        shrnkwrp_space_secondary: { type: integer, default: 50 }
```

---

## 8. Capability Comparison

| Capability | GitHub Copilot agent | M365 Copilot (Path B) |
|---|---|---|
| Entry point | VS Code chat (`@sdt-maintenance-refresh-agent`) | Teams / Outlook / M365 Chat |
| Input collection | `vscode/askQuestions` | Adaptive Card / conversation |
| JCL generation | AI renders Jinja2 locally | Ansible `template` task inside AWX |
| JCL review before submit | Yes — shown in chat | Possible via `getJobOutput` action before approval |
| Job submission | MCP `submit_zos_job` | AWX Job Template → `ibm.ibm_zos_core.zos_job_submit` |
| Job monitoring | MCP `wait_for_zos_job(max_lines=30)` | Azure Durable Function polls `GET /api/v2/jobs/{id}/` |
| Approval gates | File markers + chat `yes`/`no` | Teams Adaptive Card Approve/Deny → `approve_gate` action |
| Multi-approver | Not supported | Supported — configure AWX team approval |
| Documentation update (Step 16) | Edits local markdown file | Requires additional GitHub API or SharePoint action |
| Audit trail | JSON logs in `ansible/logs/` | AWX job history + Azure Function logs + ServiceNow (optional) |
| z/OS SSH key exposure | On control node only | On AWX only — never reaches M365 |
| Requires VS Code | Yes | No — any M365 client |

---

## 9. Quickest Proof-of-Concept

Test the AWX API connection before building the full Azure Function:

### Step 1 — Get an AWX API token

```
AWX UI → User menu → My Profile → Tokens → Add
  Scope: Write
→ Copy token
```

### Step 2 — Find the Workflow Job Template ID

```bash
export AWX_TOKEN=<your-token>
export AWX_HOST=https://awx.example.com

curl -s "${AWX_HOST}/api/v2/workflow_job_templates/" \
  -H "Authorization: Bearer ${AWX_TOKEN}" | \
  python3 -c "
import sys, json
for t in json.load(sys.stdin)['results']:
    print(t['id'], t['name'])
"
```

### Step 3 — Launch the pipeline

```bash
curl -s -X POST "${AWX_HOST}/api/v2/workflow_job_templates/42/launch/" \
  -H "Authorization: Bearer ${AWX_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "extra_vars": {
      "shrinkwrap_dsn":    "ACSNS.TDMF.V5R11M0.ZOSMFA.ZS31D.SHRNKWRP",
      "new_qual":          "ACS%S.TDMF.V5R11M0.ZOSMFB",
      "vendor":            "ibm",
      "global_csi":        "ACSVS.TDMF.V5R11M0.ZOSMFB.GLOBAL.CSI",
      "target_zone":       "TZONE",
      "dlib_zone":         "DZONE",
      "existing_qual_rest":"TDMF.V5R11M0.ZOSMFA",
      "new_qual_rest":     "TDMF.V5R11M0.ZOSMFB",
      "userid_node":       "ZS31D",
      "typrun_norun":      "true"
    }
  }'
```

If this returns a `workflow_job` ID — the API works and you have everything needed to build the Azure Function.

### Step 4 — Poll until an approval node appears

```bash
WFJOB_ID=1234

curl -s "${AWX_HOST}/api/v2/workflow_jobs/${WFJOB_ID}/" \
  -H "Authorization: Bearer ${AWX_TOKEN}" | \
  python3 -c "
import sys, json
d = json.load(sys.stdin)
print('Status:', d['status'])
print('Failed:', d.get('failed', False))
"
```

### Step 5 — Approve the APPLY CHECK gate

```bash
# Find pending approval nodes
curl -s "${AWX_HOST}/api/v2/workflow_approvals/?workflow_job=${WFJOB_ID}" \
  -H "Authorization: Bearer ${AWX_TOKEN}" | \
  python3 -c "
import sys, json
for a in json.load(sys.stdin)['results']:
    print('Approval ID:', a['id'], '| Status:', a['status'])
"

# Approve
APPROVAL_ID=99
curl -s -X POST "${AWX_HOST}/api/v2/workflow_approvals/${APPROVAL_ID}/approve/" \
  -H "Authorization: Bearer ${AWX_TOKEN}"
```

If all five steps work from the command line, the Azure Function is a straightforward wrapper around these same `curl` calls.

---

## 10. Next Steps

| Priority | Task |
|---|---|
| 1 | Verify AWX API is reachable from the Azure Function App subnet (network / firewall) |
| 2 | Create Entra App Registration + Azure Key Vault secret |
| 3 | Build Azure Function App with the 5 operations (scaffold in `m365-agent/azure-function/`) |
| 4 | Create `openapi.yaml` pointing at the deployed Function App URL |
| 5 | Create `declarativeAgent.json` with instructions ported from the agent file |
| 6 | Package as Teams App (`manifest.json`) and sideload for testing |
| 7 | Submit to Teams Admin Center for organisation-wide deployment |
| 8 | Configure AWX notifications → Teams webhook so approvers get pinged automatically |
