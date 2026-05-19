# Requirements Document

## Introduction

This feature adds a structured API Documentation section to the Hamro Awaz civic complaint management system. It covers the three Complaint Controller endpoints sourced from the backend Swagger docs: creating a complaint, updating a complaint, and listing nearby complaints. The documentation must clearly capture request/response contracts, authentication requirements (including the dual-auth behavior of the nearby listing endpoint), and role-based access rules — all formatted consistently with the project's existing professional Word document style.

---

## Glossary

- **API_Documentation**: The structured reference section describing all backend REST endpoints for Hamro Awaz.
- **Complaint_Controller**: The backend controller exposing complaint-related REST endpoints under `/api/v1/user/complaint/`.
- **Citizen**: An authenticated user who has logged in to the Hamro Awaz application.
- **Guest**: An unauthenticated user accessing the system without a login session.
- **Standard_Response_Wrapper**: The common JSON envelope returned by all endpoints, containing `httpStatus`, `message`, `code`, `data`, `timestamp`, and `asyncRequest` fields.
- **Auth_Token**: A bearer token issued upon login, required for authenticated endpoints.
- **Dual_Auth_Endpoint**: An endpoint that accepts both authenticated and unauthenticated requests and adjusts its response accordingly.
- **Municipality_Unique_Id**: A unique string identifier for a municipality within the Hamro Awaz system.
- **Category_Id**: A unique string identifier for a complaint category.
- **Complaint_Unique_Id**: A unique string identifier for a specific complaint record.
- **Coordinates**: A pair of `latitude` and `longitude` numeric values representing a geographic location.
- **Radius_Km**: The search radius in kilometers used to filter nearby complaints.

---

## Requirements

### Requirement 1: Document the Create Complaint Endpoint

**User Story:** As a developer integrating with the Hamro Awaz backend, I want a complete reference for the `POST /api/v1/user/complaint/create` endpoint, so that I can implement complaint submission correctly.

#### Acceptance Criteria

1. THE API_Documentation SHALL include a dedicated section for `POST /api/v1/user/complaint/create` with method, full endpoint path, and authentication requirement clearly stated.
2. THE API_Documentation SHALL present all request body fields in a table with columns: Field, Type, Required, and Description.
3. THE API_Documentation SHALL document the following required fields: `data.complaintTitle` (string), `data.complaintDescription` (string, minimum 20 characters), `data.municipalityUniqueId` (string), `data.categoryId` (string).
4. THE API_Documentation SHALL document the following optional fields: `data.complaintCoordinates.latitude` (number), `data.complaintCoordinates.longitude` (number), `photos` (string, file or base64).
5. THE API_Documentation SHALL specify that this endpoint requires a valid Auth_Token (Citizen role only).
6. THE API_Documentation SHALL show the Standard_Response_Wrapper structure as the response format, with field-level descriptions for `httpStatus`, `message`, `code`, `data`, `timestamp`, and `asyncRequest`.
7. WHEN `data.complaintDescription` contains fewer than 20 characters, THE API_Documentation SHALL note that the backend returns a validation error response.

---

### Requirement 2: Document the Update Complaint Endpoint

**User Story:** As a developer integrating with the Hamro Awaz backend, I want a complete reference for the `POST /api/v1/user/complaint/update` endpoint, so that I can implement complaint editing correctly.

#### Acceptance Criteria

1. THE API_Documentation SHALL include a dedicated section for `POST /api/v1/user/complaint/update` with method, full endpoint path, and authentication requirement clearly stated.
2. THE API_Documentation SHALL document `complaintUniqueId` (string) as a required request body field.
3. THE API_Documentation SHALL document the following optional request body fields: `complaintTitle` (string), `complaintDescription` (string, minimum 20 characters), `municipality` (string), `photoUrl` (string), `categoryId` (string).
4. THE API_Documentation SHALL document `photos` as an optional binary file query parameter.
5. THE API_Documentation SHALL specify that this endpoint requires a valid Auth_Token and that the Citizen may only update complaints belonging to their own account.
6. THE API_Documentation SHALL show the Standard_Response_Wrapper structure as the response format.

---

### Requirement 3: Document the List Nearby Complaints Endpoint (Dual-Auth)

**User Story:** As a developer integrating with the Hamro Awaz backend, I want a complete reference for the `POST /api/v1/user/complaint/list/nearBy` endpoint including its dual-auth behavior, so that I can implement both authenticated and guest map views correctly.

#### Acceptance Criteria

1. THE API_Documentation SHALL include a dedicated section for `POST /api/v1/user/complaint/list/nearBy` with method, full endpoint path, and authentication mode clearly labeled as "Optional (Dual-Auth)".
2. THE API_Documentation SHALL document `latitude` (number, required), `longitude` (number, required), and `radiusKm` (number, optional, default: 0.1, minimum: 0.1) as request body fields.
3. THE API_Documentation SHALL document `searchParam` as an optional query parameter of type object.
4. THE API_Documentation SHALL include a dedicated sub-section or table row that explicitly describes the Authenticated Mode behavior: the endpoint returns nearby complaints and highlights complaints submitted by the currently logged-in Citizen.
5. THE API_Documentation SHALL include a dedicated sub-section or table row that explicitly describes the Guest/Public Mode behavior: the endpoint returns nearby complaints without any user-specific data.
6. THE API_Documentation SHALL show the Standard_Response_Wrapper structure as the response format for both modes.
7. WHEN no Auth_Token is present in the request, THE API_Documentation SHALL note that the endpoint operates in Guest/Public Mode and returns no user-specific fields.
8. WHEN a valid Auth_Token is present in the request, THE API_Documentation SHALL note that the endpoint operates in Authenticated Mode and includes personalization data in the response.

---

### Requirement 4: Document the Standard Response Wrapper

**User Story:** As a developer integrating with the Hamro Awaz backend, I want a single canonical reference for the Standard_Response_Wrapper, so that I can parse all API responses consistently.

#### Acceptance Criteria

1. THE API_Documentation SHALL include a dedicated Standard_Response_Wrapper section with a field table containing: Field, Type, and Description columns.
2. THE API_Documentation SHALL document all six fields: `httpStatus` (string), `message` (string), `code` (number), `data` (object), `timestamp` (string, ISO 8601), `asyncRequest` (boolean).
3. THE API_Documentation SHALL provide a concrete JSON example of the Standard_Response_Wrapper.

---

### Requirement 5: Update User Roles and Permissions Table

**User Story:** As a developer or project stakeholder reviewing access control, I want the User Roles & Permissions table to reflect the actual access rules for all three complaint endpoints, so that authorization logic is implemented correctly.

#### Acceptance Criteria

1. THE API_Documentation SHALL include a User Roles & Permissions table with columns: Endpoint, Guest Access, Citizen Access, and Notes.
2. THE API_Documentation SHALL document `POST /api/v1/user/complaint/create` as requiring Citizen authentication, with Guest access denied.
3. THE API_Documentation SHALL document `POST /api/v1/user/complaint/update` as requiring Citizen authentication and ownership of the complaint, with Guest access denied.
4. THE API_Documentation SHALL document `POST /api/v1/user/complaint/list/nearBy` as publicly accessible (Guest access allowed) with a note that authenticated Citizens receive additional personalized data.

---

### Requirement 6: Maintain Consistent Document Format and Style

**User Story:** As a project maintainer, I want the API documentation to follow the same professional Word document format and style used elsewhere in the project, so that the documentation is cohesive and easy to navigate.

#### Acceptance Criteria

1. THE API_Documentation SHALL use consistent heading levels, table formatting, and section ordering matching the existing project documentation style.
2. THE API_Documentation SHALL present each endpoint in a summary table (Method, Endpoint, Auth, Description) before the detailed field tables.
3. THE API_Documentation SHALL use clear section separators between each endpoint's documentation block.
4. WHERE a field has a default value or constraint (e.g., minimum length, minimum value), THE API_Documentation SHALL include that constraint in the Description column of the relevant table.
