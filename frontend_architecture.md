# Complete API Documentation

*(System Note: Writing Flutter Architecture documentation based on codebase analysis.)*

# 1. Project Overview

- **Project Name:** spdms_app
- **Flutter Version:** Compatible with Dart SDK ^3.11.0 (Implies Flutter 3.19+)
- **Dart Version:** ^3.11.0
- **Architecture Style:** Hybrid (Layer-first globally, Feature-first in newer modules)
- **State Management:** Provider (`ChangeNotifierProvider`)
- **Navigation Pattern:** Basic Flutter Navigator 1.0 (Push/Pop/Replacement)
- **Dependency Injection:** Provider-based injection (`MultiProvider` at root)
- **API Pattern:** Raw HTTP requests via `http` package
- **Local Storage:** Not explicitly implemented as a global service (likely SharedPreferences or none)
- **Backend Integration:** REST API to Spring Boot via HTTP with Bearer tokens
- **Overall Architecture Diagram:**

```text
UI (Screens/Tabs) <---> Providers (State) <---> Services/Repositories (API Logic) <---> Spring Boot Backend
```

---

# 2. Complete Folder Structure

```text
lib/
 ├── admin/
 │    └── activity/               # Feature-first modularization for Admin Activities
 │         ├── models/            # Activity specific models
 │         ├── pages/             # Activity UI pages
 │         ├── providers/         # Activity state management
 │         ├── repository/        # Activity data abstraction
 │         ├── services/          # Activity API logic
 │         ├── utils/             # Constants and validators
 │         └── widgets/           # Activity specific reusable UI components
 ├── core/
 │    └── config/                 # Global configuration (api_config.dart)
 ├── models/                      # Global models (student.dart, team.dart)
 ├── providers/                   # Global state management (badge_provider, xp_provider)
 ├── repositories/                # Global repositories (badge_repository)
 ├── screens/                     # Global Presentation Layer
 │    ├── admin/                  # Admin role dashboards and tabs
 │    ├── captain/                # Captain role dashboards and tabs
 │    ├── login/                  # Authentication screens
 │    ├── student/                # Student role dashboards and tabs
 │    └── teacher/                # Teacher role dashboards and tabs
 ├── services/                    # Global services for API calls
 └── main.dart                    # Application entry point
```

**Responsibilities:**
- `core/config/`: Houses global app configs like Base URLs.
- `screens/`: Holds layer-first organized UI grouped by user role.
- `providers/`: Holds business logic and global state.
- `admin/activity/`: Represents a shift to Feature-first architecture where a single domain encapsulates all its layers.

---

# 3. Application Startup Flow

The application follows a standard Provider-based initialization flow.

```text
main()
  ↓
RunApp()
  ↓
MultiProvider (Initializes XpProvider, BadgeProvider)
  ↓
MyApp (MaterialApp)
  ↓
LoginPage (Initial Screen)
  ↓
Authentication Check
  ↓
Role-Based Dashboard (Student/Teacher/Admin/Captain)
```

---

# 4. Layered Architecture

The project contains a mix of architectural patterns but generally follows:

- **Presentation Layer:** Found in `screens/` and `pages/`. Responsible for rendering the UI and listening to state changes.
- **Business/State Layer:** Found in `providers/`. Responsible for managing application state, though it currently leaks into API calls.
- **Service/API Layer:** Found in `services/`. Uses the `http` package to communicate with the Spring Boot backend.
- **Repository Layer:** Partially implemented in `repositories/`. Supposed to abstract data sources, but often bypassed by Providers.
- **Data Layer:** `models/`. Dart classes with `fromJson` serialization.

**Communication Flow:**
UI -> Provider (Calls Method) -> Service/Repository (Calls API) -> Backend.
*(Note: Some Providers currently bypass the Service layer and call HTTP directly).*

---

# 5. Module Breakdown

### Authentication
- **Purpose:** Handles user login and role routing.
- **Screens:** `login_page.dart`
- **Dependencies:** Provider, HTTP.

### Dashboards (Student, Teacher, Admin, Captain)
- **Purpose:** Role-specific landing pages and tab navigation.
- **Screens:** `student_dashboard_page.dart`, `admin_dashboard.dart`, etc.
- **Tabs:** Divided into sub-features like `profile_tab.dart`, `leaderboard_tab.dart`, `activity_tab.dart`.

### Admin Activity Management (`admin/activity/`)
- **Purpose:** Comprehensive module for managing activities, stages, and groups by admins.
- **Screens:** `create_activity_page.dart`, `group_activity_execution_page.dart`, etc.
- **Services/Providers:** `activity_service.dart`, `activity_provider.dart`.
- **Widgets:** `activity_card.dart`, `xp_selector.dart`, `evidence_selector.dart`.

---

# 6. Navigation Architecture

Navigation relies on simple `Navigator.push()` and `Navigator.pushReplacement()`.

```text
Splash (Implicit)
  ↓
LoginPage
  ├──> Student Dashboard
  │      ├── Activities Tab
  │      ├── Leaderboard Tab
  │      └── Profile Tab
  ├──> Teacher Dashboard
  │      ├── Students Tab
  │      ├── Badge Claims Tab
  │      └── Profile Tab
  ├──> Admin Dashboard
  │      ├── Overview Tab
  │      ├── Departments Tab
  │      └── Activity Creation Flow
  └──> Captain Dashboard
```

---

# 7. State Management Analysis

- **Provider (`ChangeNotifier`):** The exclusive state management solution used across the app.
- **Usage:** Used globally in `main.dart` (`XpProvider`, `BadgeProvider`) and locally in feature modules (`ActivityProvider`).
- **setState:** Used for transient, local UI state (like tab selection or form inputs) inside StatefulWidgets.

---

# 8. API Architecture

- **API Client:** Raw `http` package (`import 'package:http/http.dart' as http;`).
- **Base URL:** Centrally managed in `ApiConfig.baseUrl`.
- **Authentication:** JWT Tokens passed manually into headers: `headers: {"Authorization": "Bearer $token"}`.
- **Error Handling:** Basic `try-catch` blocks. Errors are generally swallowed and mapped to empty arrays or empty objects (e.g., `_history = [];`).
- **Missing Features:** No robust interceptors, automated token refresh logic, or global error handling middleware.

**Request Flow:**
UI Triggers Action -> Provider passes token to HTTP -> `http.get` / `http.post` -> Awaits JSON Response -> `jsonDecode` -> Updates State -> `notifyListeners()`.

---

# 9. Service Layer

- `group_activity_service.dart`: Handles API calls for group/team based activities.
- `student_service.dart`: Handles fetching student lists.
- `activity_service.dart` (Admin): Handles CRUD operations for activities.
- **Note:** The service layer is inconsistently utilized. `XpProvider`, for instance, makes raw HTTP calls directly instead of injecting a service.

---

# 10. Repository Pattern

- **Exists:** Yes, but partially and inconsistently.
- **Usage:** `badge_repository.dart` and `activity_repository.dart` exist.
- **Diagram:**
  Provider -> Repository -> HTTP/API -> Backend.
- **Issue:** Many Providers bypass repositories entirely.

---

# 11. Data Models

Examples:
- `student.dart`
- `team.dart`
- `activity_model.dart`
- **Fields:** Mirror the Spring Boot DTOs (e.g., `id`, `name`, `totalXp`).
- **Serialization:** Manual `fromJson` and `toJson` factory methods using `dart:convert`.
- **Relationships:** Represented as nested objects or lists of related IDs.

---

# 12. Widget Architecture

- **Reusable Widgets:** The `admin/activity/widgets/` directory shows good use of compositional widgets (`activity_card.dart`, `frequency_selector.dart`, `sticky_bottom_buttons.dart`).
- **Shared Widgets:** There is a lack of a global `lib/widgets/` or `lib/core/widgets/` directory for application-wide UI components like custom buttons or text fields, leading to likely code duplication across role screens.

---

# 13. Screen Architecture

- **Architecture:** Standard Stateful/Stateless widgets acting as screen containers.
- **Dashboards:** Dashboards utilize a `BottomNavigationBar` or `TabBar` to switch between independent sub-screens located in the `tabs/` directories.
- **State:** Screens observe state using `context.watch<T>()` or `Consumer<T>`.

---

# 14. Dependency Graph

**Authentication Flow:**
`LoginPage` -> HTTP Auth Call -> Receives JWT -> Stores JWT -> `Navigator.pushReplacement(Dashboard)`.

**XP Fetching Flow:**
`StudentDashboard` -> calls `XpProvider.fetchSummary(studentId, token)` -> `http.get(/api/v1/xp/summary)` -> parses JSON -> `notifyListeners()` -> UI Rebuilds.

---

# 15. Asset Management

- Handled via standard `pubspec.yaml` configurations.
- Dependencies include `cupertino_icons` and `fl_chart` for visual rendering.
- No dedicated local asset folder (`assets/images/`) was detected in the `lib` level, implying minimal static assets or they exist at the root but aren't strictly structured.

---

# 16. Configuration

- `api_config.dart` contains the hardcoded base IP address for the Spring Boot backend.
- `pubspec.yaml` defines dependencies (`provider`, `http`, `file_picker`, `fl_chart`).
- Lacks a robust `.env` file structure for managing different environments (Dev, Staging, Prod).

---

# 17. Code Quality & Architectural Smells

- **God Providers:** `XpProvider` is acting as a state manager, a service, and a repository simultaneously. It directly handles HTTP requests, parses JSON, and stores state.
- **Tight Coupling:** UI components and state logic are tightly coupled to manual token passing and direct API routing.
- **Swallowed Exceptions:** Catch blocks like `catch (e) { _xpByCategory = {}; }` hide critical network and parsing failures from the user and crashlytics.
- **Inconsistent Folder Structure:** The project mixes "Layer-first" (global screens, services folders) with "Feature-first" (`admin/activity/`).

---

# 18. Performance Analysis

- **Widget Rebuilds:** Using `ChangeNotifierProvider` globally can lead to unnecessary widget rebuilds if `Consumer` is not scoped precisely.
- **Network Calls:** No caching layer is visible. `fetchSummary` fetches fresh data repeatedly.
- **Pagination:** Supported via query params in endpoints like `fetchHistory(page=0&size=50)`, which is good for memory.

---

# 19. Security Analysis

- **Token Storage:** Tokens appear to be passed around dynamically. If they are stored in `SharedPreferences` without encryption (like `flutter_secure_storage`), they are vulnerable on rooted/jailbroken devices.
- **Hardcoded URLs:** The API Base URL is hardcoded in `api_config.dart` rather than injected securely via environment variables.

---

# 20. Architecture Problems

| Problem | Impact | Severity | Recommendation |
|---------|--------|----------|----------------|
| **God Providers (Direct HTTP)** | Hard to test, breaks SRP | High | Extract all `http` calls into dedicated Services/Repositories. Providers should only hold state. |
| **Swallowed Errors** | Silent failures, impossible to debug | High | Implement a global error handler and use `Either<Failure, Success>` or custom Exceptions. |
| **Inconsistent Folder Structure** | Hard to scale and onboard devs | Medium | Standardize on a Feature-first architecture application-wide. |
| **Missing Interceptors** | Repetitive header injection logic | Medium | Use `dio` package with interceptors for auth tokens and logging. |

---

# 21. Modularization Readiness

- **Current Architecture:** Transitional. Half layer-based, half feature-based.
- **Feature-first readiness:** High. The `admin/activity` module proves the team understands how to group by feature.
- **Scalability:** Requires resolving the God Provider anti-pattern before scaling further to prevent massive, unmaintainable classes.

---

# 22. Recommended Architecture

**Recommendation: Feature-First (Modular) Clean Architecture**
- **Why:** The application is growing to support multiple user roles (Admin, Teacher, Student, Captain) and complex domains (Activities, XP, Badges). Layered architectures become chaotic at this scale. Grouping everything by feature (`lib/features/auth`, `lib/features/xp_management`) ensures isolated, highly maintainable, and easily testable modules.

---

# 23. Architecture Score

- Project Structure: 5/10
- Folder Organization: 6/10
- Scalability: 5/10
- Maintainability: 6/10
- Performance: 7/10
- Security: 5/10
- Readability: 7/10
- Reusability: 5/10
- **Overall Architecture: 5.7/10**

---

# 24. Final Summary

**Strengths:**
- Basic implementation is functional and achieves the business requirements.
- The recent introduction of the `admin/activity` folder shows a positive shift toward modular design.
- Appropriate use of Provider for state management.

**Weaknesses & Technical Debt:**
- Business logic, network logic, and state management are tightly tangled inside Providers.
- Lack of centralized error handling and API interceptors.
- Inconsistent folder architecture.

**Immediate Improvements:**
1. Migrate from the basic `http` package to `Dio` to implement Auth Interceptors (so you don't have to manually pass tokens to every function).
2. Refactor `XpProvider` to delegate HTTP calls to an `XpService` or `XpRepository`.
3. Stop swallowing exceptions; show Snackbars/Dialogs to the user when API calls fail.

**Long-term Improvements:**
- Migrate the entire `lib` folder to a strict Feature-first architecture matching the `admin/activity` module.
- Implement an environment variable setup (`.env`) to manage API Base URLs.
- Adopt a proper routing package like `go_router` for deep linking and role-based route guarding.
