# OM Web Viewer REST API – Access & Login Guide

**Product:** Broadcom OM Web Viewer 14.0.123
**API Version:** 1.0.0 (OAS 3.0)
**Base URL:** `http://138.69.218.201:8083/web-viewer`

---

## 1. Swagger UI

The interactive API documentation is available at:

```
http://138.69.218.201:8083/web-viewer/api/swagger-ui/index.html
```

The full OpenAPI specification (JSON) is available at:

```
http://138.69.218.201:8083/web-viewer/api/doc
```

---

## 2. Authentication Overview

The API uses a two-step authentication model:

| Step | Mechanism | Used For |
|------|-----------|----------|
| Login | HTTP Basic Auth (username + password) | `POST /api/v1/view/login` and `POST /api/v1/view/changePassword` only |
| All other calls | Session cookie (`brcmwvs...`) returned at login | Every protected endpoint |

The session cookie has a **12-hour maximum lifetime**. Always call `POST /api/v1/view/logout` when finished.

---

## 3. Logging In via Swagger UI

1. Open the Swagger UI URL in your browser.
2. Click the **Authorize** button (padlock icon, top-right of the page).
3. In the **basic (http, Basic)** section, enter your **Username** and **Password**.
4. Click **Authorize**, then **Close**.
5. Expand the **Authentication** section → select `POST /api/v1/view/login`.
6. Click **Try it out** → **Execute**.
7. Confirm the response **Code is 200** and the response body contains `"status": "SUCCESS"`.

You can now use **Try it out** for all protected operations in the Swagger UI. If the session expires, repeat from step 5.

---

## 4. Logging In via curl

### Login and save session cookie

```bash
curl -c cookies.txt \
     -u "USERNAME:PASSWORD" \
     -X POST "http://138.69.218.201:8083/web-viewer/api/v1/view/login" \
     -H "Accept: application/json"
```

Expected response:

```json
{
  "status": "SUCCESS",
  "result": {
    "groupName": "DEFAULT",
    "groupId": 1
  }
}
```

### Use session cookie for subsequent calls

```bash
# List repositories
curl -b cookies.txt \
     -H "Accept: application/json" \
     "http://138.69.218.201:8083/web-viewer/api/v1/view/repository"
```

### Logout

```bash
curl -b cookies.txt \
     -X POST "http://138.69.218.201:8083/web-viewer/api/v1/view/logout"
```

---

## 5. Logging In via Python

```python
import requests

BASE_URL = "http://138.69.218.201:8083/web-viewer"

# Create a persistent session (automatically manages cookies)
session = requests.Session()

# Step 1: Login with Basic Auth
response = session.post(
    f"{BASE_URL}/api/v1/view/login",
    auth=("USERNAME", "PASSWORD"),
    headers={"Accept": "application/json"}
)
response.raise_for_status()

login_result = response.json()
print(f"Login status : {login_result['status']}")
print(f"Group        : {login_result['result']['groupName']}")

# Step 2: Use session for all subsequent calls (cookie is automatic)
repos = session.get(
    f"{BASE_URL}/api/v1/view/repository",
    headers={"Accept": "application/json"}
)
repos.raise_for_status()
print(repos.json())

# Step 3: Logout when done
session.post(f"{BASE_URL}/api/v1/view/logout")
```

---

## 6. Selecting a Repository Group at Login

Optionally, specify a repository group at login time using query parameters:

| Parameter | Description |
|-----------|-------------|
| `groupName` | Repository group name (default: `%`) |
| `groupId` | Repository group ID (overrides `groupName` if both supplied) |

```bash
curl -c cookies.txt \
     -u "USERNAME:PASSWORD" \
     -X POST "http://138.69.218.201:8083/web-viewer/api/v1/view/login?groupName=FINANCE" \
     -H "Accept: application/json"
```

---

## 7. Common Error Responses

| HTTP Code | Meaning |
|-----------|---------|
| `200` | Success |
| `400` | Bad request – invalid or missing parameters |
| `401` | Unauthenticated – no valid session cookie or wrong credentials |
| `403` | Forbidden – authenticated but insufficient privileges |
| `404` | Resource not found (may also be returned to avoid disclosing existence) |
| `500` | Internal server error |

All error responses include a JSON body with a `messages` array containing `number`, `type`, and `content` fields for diagnostics.

---

## 8. Session Cookie Reference

The session cookie name follows the pattern:

```
brcmwv s d<deployment>
       │ └── deployment identifier (1–99999)
       └── session purpose identifier
```

**Security directives set on the cookie:**

- `HttpOnly` – not accessible via JavaScript
- `SameSite=Strict` – excluded from cross-site requests
- `Path=/<application-context>/api` – scoped to API calls only
- `Max-Age=43200` (12 hours)
- `Secure` + `__Secure-` prefix applied when served over HTTPS

---

*API Reference:* `http://138.69.218.201:8083/web-viewer/api/swagger-ui/index.html`
*User Documentation:* https://techdocs.broadcom.com/content/broadcom/techdocs/us/en/ca-mainframe-software/traditional-management/web-viewer/14-0.html
