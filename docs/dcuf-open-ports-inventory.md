# DCUF Open Port Inventory

**Host:** `138.69.218.201` (`DCUF.atos-nao.net`)
**Scan Date:** 2026-07-22
**Source:** z/OS netstat EZZ2587I output (authoritative) + HTTP/HTTPS fingerprinting

---

## Port Summary

| Port | STC / Daemon | Protocol | Application | Notes |
|------|-------------|----------|-------------|-------|
| **21** | `FTPD1` | FTP | IBM z/OS FTP Server | Plain-text FTP |
| **22** | `SSHD4` | SSH | OpenSSH 8.4 (z/OS USS) | Multiple active sessions |
| **443** | `IZUSVR1` | HTTPS | IBM z/OSMF | WebSphere Liberty |
| **514** | `SYSLOGD` | UDP | Syslog Daemon | System log collection |
| **990** | `FTPACSS1` | FTPS | IBM z/OS FTP with SSL (implicit TLS) | Secure FTP |
| **992** | `TN3270S` | TLS | TN3270S — Secure Telnet (3270) | Encrypted 3270 terminal |
| **1202** | `CCISSL` | TLS | CCI SSL | CA Common Communication Interface with SSL |
| **2021** | `FTPACSP1` | FTP | IBM z/OS FTP Active/Passive | Alternate FTP port |
| **3004** | `DBDFDIST` | TCP | Distribution Service | Internal distribution channel |
| **3005** | `DBDFDIST` | TCP | Distribution Service | Internal distribution channel |
| **4035** | `XPLRSED` | TCP | Remote System Explorer daemon | RSE component |
| **5989** | `CFZCIM` | HTTPS | z/OS CIM Server | Common Information Model (WBEM) |
| **6800** | `RSEAPI` | HTTPS | IBM RSE API | Remote System Explorer REST API |
| **7553** | `ZWE1AG` | HTTPS | Zowe API ML — Discovery Service | Eureka service registry |
| **7554** | `ZWE1AG` | HTTPS | Zowe API ML — Gateway | External API entry point + SSO |
| **7556** | `ZWESLSTC` | HTTPS | Zowe App Server — ZLUX Desktop | Web-based mainframe desktop UI |
| **7557** | `ZWE1SZ` | HTTPS | Zowe ZSS (z Secure Services) | Native z/OS backend for ZLUX |
| **7600** | `ZWE1AG` | HTTPS | Zowe — API Catalog (internal) | Bound to host IP |
| **7601** | `ZWE1AG` | HTTPS | Zowe — Caching Service (internal) | Bound to host IP |
| **8080** | `CA7API3` | HTTP | CA 7 Workload Automation REST API | HTTP connector |
| **8081** | `SYS17933` | HTTP | CICS CardDemo Web Application | Spring Boot WAR |
| **8083** | `TOMCATPR` | HTTP | Broadcom OM Web Viewer 14.0 | Tomcat WAR — `/web-viewer` |
| **8090** | `DBBDMONS` | HTTPS | DB / Buffer Pool Monitor | Bound to host IP |
| **8443** | `CA7API3` | HTTPS | CA 7 Workload Automation REST API | HTTPS connector (paired with 8080) |
| **9070** | `MVCAS` | HTTPS | MVS Common Application Services | Bound to host IP |
| **9092** | `H2DBSRVR` | TCP | H2 Embedded Database Server | Used by Java-based products |
| **28443** | `CA7SVR` | HTTPS | CA 7 Server (internal) | Bound to host IP |
| **28444** | `CA7ONL` | HTTPS | CA 7 Online (internal) | Bound to host IP |

---

## Zowe Component Port Map

| Port | STC | Component | Role |
|------|-----|-----------|------|
| **7553** | `ZWE1AG` | API ML Discovery Service | Internal Eureka registry — all services register here |
| **7554** | `ZWE1AG` | API ML Gateway | **External entry point** — routes + authenticates all API traffic |
| **7556** | `ZWESLSTC` | App Server (ZLUX) | **Zowe Desktop** web UI — TN3270, JES Explorer, File Manager |
| **7557** | `ZWE1SZ` | ZSS (z Secure Services) | Native z/OS C-based backend for the App Server |
| **7600** | `ZWE1AG` | API Catalog (internal) | API service catalog backend (host-bound) |
| **7601** | `ZWE1AG` | Caching Service (internal) | Zowe HA caching layer (host-bound) |
| **1251–1256** | `ZWE1AG` | Inter-component RPC | Internal ZWE1AG service mesh ports |

---

## CA 7 Workload Automation Port Map

| Port | STC | Role |
|------|-----|------|
| **8080** | `CA7API3` | REST API Web Services — HTTP |
| **8443** | `CA7API3` | REST API Web Services — HTTPS |
| **8005** | `CA7API3` | Tomcat shutdown port (127.0.0.1 — internal only) |
| **28443** | `CA7SVR` | CA 7 Server process (host-bound) |
| **28444** | `CA7ONL` | CA 7 Online process (host-bound) |

---

## Detailed Findings

### Port 21 — IBM z/OS FTP Server

```
220-FTPD1 IBM FTP CS 3.1 at DCUF.atos-nao.net, 02:26:52 on 2026-07-22.
220 Connection will close if idle for more than 5 minutes.
```

- **STC:** `FTPD1`
- **Product:** IBM FTP CS V3R1 (z/OS 3.1)
- **Risk:** Unencrypted — credentials transmitted in clear text. Use port 990 (FTPS) or port 22 (SFTP).

---

### Port 22 — OpenSSH (z/OS USS)

```
SSH-2.0-OpenSSH_8.4
```

- **STC:** `SSHD4` (multiple active sessions observed in netstat)
- **Version:** OpenSSH 8.4
- **Purpose:** z/OS UNIX System Services shell and SFTP access

---

### Port 443 — IBM z/OSMF (WebSphere Liberty)

- **STC:** `IZUSVR1`
- **Title:** `IBM z/OS Management Facility on DCUF.atos-nao.net`
- **Server:** IBM WebSphere Liberty (`X-Powered-By: Servlet/3.1`)
- **URLs:**
  - UI: `https://138.69.218.201/zosmf/`
  - Console: `https://138.69.218.201/ibm/console`

---

### Port 514 — Syslog Daemon

- **STC:** `SYSLOGD`
- **Protocol:** UDP (standard syslog)
- **Purpose:** Collects z/OS system log messages

---

### Port 990 — IBM z/OS FTPS (Implicit TLS)

```
220-FTPACSS1 IBM FTP CS 3.1 at DCUF.atos-nao.net
```

- **STC:** `FTPACSS1`
- **Purpose:** Encrypted FTP — preferred over port 21 for secure file transfers

---

### Port 992 — TN3270S (Secure Telnet)

- **STC:** `TN3270S`
- **Purpose:** TLS-encrypted 3270 terminal access to z/OS
- **Client:** Any TN3270 emulator with SSL support (IBM PCOMM, Micro Focus Rumba, Zowe Explorer)

---

### Port 1202 — CCI SSL

- **STC:** `CCISSL`
- **Product:** CA Common Communication Interface with SSL
- **Purpose:** Encrypted inter-product communication layer used by Broadcom (CA) products

---

### Port 2021 — IBM z/OS FTP (Active/Passive)

- **STC:** `FTPACSP1`
- **Purpose:** Alternate FTP listener supporting active and passive mode connections

---

### Port 3004 / 3005 — Distribution Service

- **STC:** `DBDFDIST`
- **Purpose:** Internal distribution channels, likely for Broadcom CA product data distribution

---

### Port 5989 — z/OS CIM Server

- **STC:** `CFZCIM`
- **Product:** IBM z/OS CIM Server (Common Information Model)
- **Standard:** DMTF WBEM (Web-Based Enterprise Management)
- **Purpose:** Hardware and system management information via CIM/WBEM protocol

---

### Port 6800 — IBM RSE API

- **STC:** `RSEAPI`
- **Product:** IBM Remote System Explorer (RSE) API
- **Purpose:** REST API for remote z/OS system access — used by IDz (IBM Developer for z/OS), VS Code extensions, and Zowe Explorer
- **Internal port:** `60800` bound to `127.0.0.1` (inter-process only)
- **URL:** `https://138.69.218.201:6800/`

---

### Ports 7553 / 7554 / 7556 / 7557 / 7600 / 7601 — Zowe

#### Port 7553 — API ML Discovery Service (`ZWE1AG`)

- **Purpose:** Internal Eureka registry — all Zowe and onboarded services register here so the Gateway can route requests
- **Authentication:** Basic Auth (401 on unauthenticated access)
- **Audience:** Internal Zowe infrastructure — not for direct end-user access

#### Port 7554 — API ML Gateway (`ZWE1AG`)

```
HTTP/1.1 200  —  Title: "API Mediation Layer"
Strict-Transport-Security: max-age=31536000; includeSubDomains
Eclipse Public License v2.0 — Copyright Contributors to the Zowe Project
```

- **Purpose:** Single external entry point for all API traffic. Authenticates users (SSO via SAF/RACF), routes to registered services, enforces security.
- **Key paths:** `/gateway/api/v1/services` (401), `/ui/v1/apicatalog`
- **URL:** `https://138.69.218.201:7554/`

#### Port 7556 — App Server / ZLUX Desktop (`ZWESLSTC`)

```
HTTP/1.1 302 → /ZLUX/plugins/org.zowe.zlux.bootstrap/web/
Last-Modified: Mon, 24 Nov 2025 17:46:39 GMT
```

- **Purpose:** Zowe Desktop — web-based graphical mainframe UI with pluggable apps (TN3270, JES Explorer, File Manager, Unix Shell)
- **URL:** `https://138.69.218.201:7556/`

#### Port 7557 — ZSS / z Secure Services (`ZWE1SZ`)

```
Server: jdmfws
```

- **Purpose:** Native z/OS C-based REST backend for the ZLUX App Server. Provides dataset browsing, UNIX services, and security to Desktop apps. Not for direct end-user access.

#### Ports 7600 / 7601 — Zowe Internal (`ZWE1AG`)

- Bound to `138.69.218.201` (host IP)
- **7600:** API Catalog backend service
- **7601:** Zowe HA Caching Service
- Both are consumed internally by ZWE1AG components

---

### Ports 8080 / 8443 / 8005 — CA 7 Workload Automation REST API

- **STC:** `CA7API3`
- **Product:** Broadcom CA 7 Workload Automation
- **Purpose:** REST API Web Services for job scheduling, monitoring, and automation

| Port | Role |
|------|------|
| **8080** | HTTP connector (external) |
| **8443** | HTTPS connector (external) |
| **8005** | Tomcat internal shutdown port (`127.0.0.1` — not externally accessible) |

- **HTTP URL:** `http://138.69.218.201:8080/`
- **HTTPS URL:** `https://138.69.218.201:8443/`

---

### Port 8081 — CICS CardDemo Web Application

```
HTTP/1.1 302 → /login    Title: "CardDemo - Sign On"
Set-Cookie: JSESSIONID=...; HttpOnly
```

- **STC:** `SYS17933`
- **Framework:** Spring Boot WAR (Spring Security)
- **Purpose:** CICS-based credit card demo application used for z/OS application testing
- **URL:** `http://138.69.218.201:8081/`

---

### Port 8083 — Broadcom OM Web Viewer 14.0

```
HTTP/1.1 308 → /web-viewer/ui/index.html
```

- **STC:** `TOMCATPR`
- **Product:** Broadcom OM Web Viewer 14.0.123
- **Context path:** `/web-viewer`
- **API version:** REST API 1.0.0 (OAS 3.0)

| Path | Description |
|------|-------------|
| `/web-viewer/ui/index.html` | Web Viewer UI |
| `/web-viewer/api/swagger-ui/index.html` | Swagger UI |
| `/web-viewer/api/doc` | OpenAPI JSON spec |
| `/web-viewer/api/v1/view/login` | REST API login |

- **Static asset layers:**

| Directory | Last-Modified | Origin |
|-----------|---------------|--------|
| `/api/swagger-ui/*` | 30 May 2025 | Original product WAR (initial install) |
| `/api/swagger-ui-custom/*` | 28 May 2026 | PTF maintenance patch (May 2026) |

- **URL:** `http://138.69.218.201:8083/web-viewer/`

---

### Port 8090 — Database / Buffer Pool Monitor (`DBBDMONS`)

- **STC:** `DBBDMONS`
- **Binding:** `138.69.218.201` (host IP — not 0.0.0.0)
- **Purpose:** Database monitoring service. STC name suggests a Broadcom or IBM DB2 monitoring component (e.g., Db2 Buffer pool Display Monitor or BMC MainView for Db2).
- **Protocol:** TLS — accepts connections but does not respond to plain HTTP

---

### Ports 28443 / 28444 — CA 7 Server and Online

- **STC:** `CA7SVR` (28443), `CA7ONL` (28444)
- **Binding:** `138.69.218.201` (host-bound — not publicly exposed via 0.0.0.0)
- **Purpose:** Internal CA 7 Workload Automation engine processes. `CA7SVR` is the main server; `CA7ONL` is the online/interactive component.

---

### Port 9070 — MVS Common Application Services (`MVCAS`)

- **STC:** `MVCAS`
- **Binding:** `138.69.218.201` (host-bound)
- **Purpose:** Internal application services layer used by Broadcom (CA) products for inter-component communication

---

### Port 9092 — H2 Embedded Database (`H2DBSRVR`)

- **STC:** `H2DBSRVR`
- **Product:** H2 embedded Java database
- **Purpose:** Persistence layer for a Java-based z/OS product (Zowe Caching Service, CA 7 API, or similar). Multiple active connections observed in netstat.

---

## Architecture Diagram

```
DCUF  138.69.218.201  (DCUF.atos-nao.net)
│
├──  :21    FTPD1      FTP (plain)
├──  :22    SSHD4      OpenSSH 8.4 (USS)
├──  :443   IZUSVR1    z/OSMF (WebSphere Liberty)
├──  :514   SYSLOGD    Syslog (UDP)
├──  :990   FTPACSS1   FTPS implicit TLS
├──  :992   TN3270S    TN3270S Secure Telnet
├──  :1202  CCISSL     CA CCI SSL
├──  :2021  FTPACSP1   FTP Active/Passive
│
├──  :5989  CFZCIM     z/OS CIM Server (WBEM)
├──  :6800  RSEAPI     IBM RSE API (IDz / Zowe Explorer)
│
├──  :7553  ZWE1AG     Zowe API ML — Discovery Service (Eureka)
├──  :7554  ZWE1AG     Zowe API ML — Gateway (external)
├──  :7556  ZWESLSTC   Zowe App Server — ZLUX Desktop
├──  :7557  ZWE1SZ     Zowe ZSS (z Secure Services)
├──  :7600  ZWE1AG     Zowe API Catalog (internal, host-bound)
├──  :7601  ZWE1AG     Zowe Caching Service (internal, host-bound)
│
├──  :8080  CA7API3    CA 7 REST API (HTTP)  ┐
├──  :8443  CA7API3    CA 7 REST API (HTTPS) ┘
├──  :28443 CA7SVR     CA 7 Server (internal, host-bound)
├──  :28444 CA7ONL     CA 7 Online (internal, host-bound)
│
├──  :8081  SYS17933   CICS CardDemo Web Application
├──  :8083  TOMCATPR   Broadcom OM Web Viewer 14.0
├──  :8090  DBBDMONS   DB / Buffer Pool Monitor (TLS, host-bound)
│
├──  :9070  MVCAS      MVS CAS (internal, host-bound)
├──  :9092  H2DBSRVR   H2 Embedded Database
│
├──  :3004  DBDFDIST   Distribution Service
├──  :3005  DBDFDIST   Distribution Service
└──  :4035  XPLRSED    Remote System Explorer daemon
```

---

## Security Observations

| Finding | Risk | Recommendation |
|---------|------|----------------|
| Port 21 — FTP plain text | **High** | Disable or restrict; use port 990 (FTPS) or port 22 (SFTP) |
| Port 2021 — FTP alternate | **High** | Restrict to authorised source IPs only |
| Port 514 — Syslog UDP | Medium | Restrict log traffic to authorised collectors only |
| Port 9092 — H2 Database | Medium | Verify H2 is not listening with default credentials |
| Port 8090 — DBBDMONS identity unconfirmed | Medium | Confirm application and restrict access |
| No `Server:` header exposed | Good | Version suppression hardening in place on Tomcat and Liberty |
| HSTS on 443, 7554, 7557 | Good | `Strict-Transport-Security` enforced |
| Internal ports host-bound (28443, 28444, 7600, 7601, 8090, 9070) | Good | Not externally accessible via `0.0.0.0` |

---

*Source:* z/OS netstat `EZZ2587I` output + TCP/HTTP fingerprinting from `Irvdevsecopsmf`
*Tools:* `nc`, `curl`, `openssl s_client`
