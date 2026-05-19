# Hamro Awaz — API Documentation

**Document type:** Technical reference (Complaint Controller)  
**Audience:** Developers, integrators, and stakeholders  
**Style:** Structured reference suitable for export to Microsoft Word (consistent headings, tables, and section breaks).

---

## 1. Standard Response Wrapper

All complaint endpoints return responses using a common JSON envelope.

### 1.1 Response envelope fields

| Field | Type | Description |
|-------|------|-------------|
| `httpStatus` | string | HTTP status label (e.g. `"200 OK"`). |
| `message` | string | Human-readable status or error message. |
| `code` | number | Application or status code (e.g. `1073741824`). |
| `data` | object | Payload specific to the endpoint; shape depends on the operation. |
| `timestamp` | string | Response time in ISO 8601 format. |
| `asyncRequest` | boolean | Indicates whether the operation is processed asynchronously. |

### 1.2 Example (success pattern)

```json
{
  "httpStatus": "200 OK",
  "message": "string",
  "code": 1073741824,
  "data": {},
  "timestamp": "2026-03-28T12:00:00.000Z",
  "asyncRequest": true
}
```

---

## 2. Complaint Controller Endpoints

---

### 2.1 Create complaint

| Method | Endpoint | Auth | Request fields | Response |
|--------|----------|------|----------------|----------|
| POST | `/api/v1/user/complaint/create` | Required — logged-in **Citizen** | **Body (JSON):** `data.complaintTitle` (string, required), `data.complaintDescription` (string, required, min 20), `data.municipalityUniqueId` (string, required), `data.categoryId` (string, required), `data.complaintCoordinates.latitude` / `.longitude` (number, optional), `photos` (string: file or base64, optional). | **Standard Response Wrapper** (see Section 1). `data` contains create result / complaint payload from backend. |

**Request — media type:** `application/json` (multipart or extended payload if `photos` is sent as file per backend contract).

**Request fields**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `data.complaintTitle` | string | Yes | Title of the complaint. |
| `data.complaintDescription` | string | Yes | Detailed description; **minimum 20 characters**. Fewer characters should produce a validation error. |
| `data.municipalityUniqueId` | string | Yes | Municipality unique identifier. |
| `data.categoryId` | string | Yes | Complaint category identifier. |
| `data.complaintCoordinates.latitude` | number | No | Latitude of the complaint location. |
| `data.complaintCoordinates.longitude` | number | No | Longitude of the complaint location. |
| `photos` | string | No | Photo as file upload or **base64**-encoded string, per API integration. |

**Response**

| Item | Description |
|------|-------------|
| Format | **Standard Response Wrapper** (Section 1). |
| `data` | Created complaint or operation result as returned by the backend. |

---

### 2.2 Update complaint

| Method | Endpoint | Auth | Request fields | Response |
|--------|----------|------|----------------|----------|
| POST | `/api/v1/user/complaint/update` | Required — logged-in **Citizen**; **own complaint only** | **Query:** `photos` (binary file, optional). **Body (JSON):** `complaintUniqueId` (string, required); optional `complaintTitle`, `complaintDescription` (min 20 if sent), `municipality` (string), `photoUrl` (string), `categoryId` (string). | **Standard Response Wrapper** (see Section 1). `data` contains update result from backend. |

**Query — parameters**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `photos` | binary (file) | No | Optional new photo uploaded as binary file. |

**Request — body (JSON)**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `complaintUniqueId` | string | Yes | Unique id of the complaint to update. |
| `complaintTitle` | string | No | New title. |
| `complaintDescription` | string | No | New description; when provided, **minimum 20 characters**. |
| `municipality` | string | No | Municipality reference. |
| `photoUrl` | string | No | URL for an existing or referenced photo. |
| `categoryId` | string | No | Category identifier. |

**Response**

| Item | Description |
|------|-------------|
| Format | **Standard Response Wrapper** (Section 1). |
| `data` | Updated complaint or operation result as returned by the backend. |

**Authorization note:** Requests must authenticate as the citizen who owns the complaint; updates to other users’ complaints are not permitted.

---

### 2.3 List nearby complaints (dual authentication)

| Method | Endpoint | Auth | Request fields | Response |
|--------|----------|------|----------------|----------|
| POST | `/api/v1/user/complaint/list/nearBy` | **Dual mode** — optional; **no login required** for public use; **with login**, citizen personalization applies | **Query:** `searchParam` (object). **Body (JSON):** `latitude` (number, required), `longitude` (number, required), `radiusKm` (number, optional; default **0.1**, min **0.1**). | **Standard Response Wrapper** (see Section 1). **Guest:** nearby complaints only, no user-specific data. **Authenticated:** same listing **plus** highlights for the current user’s own submissions (see subsections 2.3.1 through 2.3.3). |

**Query — parameters**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `searchParam` | object | No | Optional search parameters object (structure as defined by backend; pass encoded per client conventions). |

**Request — body (JSON)**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `latitude` | number | Yes | Center latitude for the nearby search. |
| `longitude` | number | Yes | Center longitude for the nearby search. |
| `radiusKm` | number | No | Search radius in kilometers. **Default:** `0.1`. **Minimum:** `0.1`. |

**Response (both modes)**

| Item | Description |
|------|-------------|
| Format | **Standard Response Wrapper** (Section 1). |
| `data` | List (or paginated set) of nearby complaints; see dual-mode differences below. |

#### 2.3.1 Guest / public mode (no login)

| Aspect | Behavior |
|--------|----------|
| **When** | No valid authentication token is sent with the request. |
| **Data returned** | Nearby complaints suitable for a **public** map or listing. |
| **User-specific content** | **None** — no personalization, no “my complaints” highlighting, and no fields that identify or imply the current user. |

#### 2.3.2 Authenticated mode (logged-in citizen)

| Aspect | Behavior |
|--------|----------|
| **When** | A valid **Citizen** session / bearer token is included. |
| **Data returned** | **Personalized** nearby results: includes the same public complaint data **plus** user-relevant treatment of the listing. |
| **User-specific content** | Complaints submitted by the **current user** are **highlighted** (or otherwise distinguished) in the response so the client can emphasize “your” submissions on the map or list. |

#### 2.3.3 Side-by-side summary

| Aspect | Guest / public | Authenticated citizen |
|--------|----------------|------------------------|
| Login required | No | Yes (for personalization) |
| Nearby complaints | Yes | Yes |
| Highlights own submissions | No | Yes |
| User-specific fields in payload | No | Yes (per backend contract for “own” complaint markers) |

---

## 3. User Roles & Permissions

| Endpoint | Guest access | Citizen access | Notes |
|----------|--------------|----------------|-------|
| `POST /api/v1/user/complaint/create` | No | Yes | Requires authenticated citizen. |
| `POST /api/v1/user/complaint/update` | No | Yes | Authenticated citizen; **only** complaints owned by that user. |
| `POST /api/v1/user/complaint/list/nearBy` | **Yes** | Yes | **Publicly callable without login.** Citizens with a valid token receive **personalized** nearby results and **highlights** for their own complaints; guests receive the same geographic listing **without** user-specific data. |

---

*End of Complaint Controller API reference.*
