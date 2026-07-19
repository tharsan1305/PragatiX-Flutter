# Frontend Deep Architecture Document

## lib/main.dart

**File Name:** `main.dart`
**Full Path:** `lib/main.dart`
**Purpose:** Application entry point. Initializes the Flutter app, sets up global state providers, and defines the initial route.
**Module:** Core
**Imports:** 
- `package:flutter/material.dart`
- `package:provider/provider.dart`
- `providers/xp_provider.dart`
- `providers/badge_provider.dart`
- `screens/login/login_page.dart`
**Exports:** None
**Classes:** 
- `MyApp` (extends `StatelessWidget`)
**Functions:** 
- `main()`
**Providers used:** `XpProvider`, `BadgeProvider`
**Services used:** None directly
**Repositories used:** None directly
**Models used:** None directly
**Widgets used:** `MultiProvider`, `ChangeNotifierProvider`, `MaterialApp`, `LoginPage`
**Routes connected:** Home route (`/`) mapped to `LoginPage`
**API endpoints called:** None
**State management:** Initializes `Provider` tree at the root.
**Navigation source:** OS Launcher
**Navigation destination:** `LoginPage`
**Dependencies:** `provider` package
**Files depending on this file:** None
**Reusable components:** None
**Complexity:** Low
**Code responsibility:** Bootstrapping the application and injecting global state.

---

## lib/admin/activity/models/activity_model.dart

**File Name:** `activity_model.dart`
**Full Path:** `lib/admin/activity/models/activity_model.dart`
**Purpose:** Domain model representing an Activity within the system, including its configuration, XP parameters, and assignment rules.
**Module:** Admin/Activity
**Imports:** None
**Exports:** None
**Classes:** 
- `ActivityModel`
**Fields:** `id`, `name`, `description`, `ownerDepartment`, `departmentId`, `teacherId`, `ownerSubrole`, `evidence`, `xp`, `type`, `justification`, `assignmentSummary`, `xpCategory`, `displayOrder`, `status`, `awardXp`, `awardEnabled`, `penaltyEnabled`, `penaltyXp`, `awardType`, `cap`, `awardFrequency`, `awardDays`, `xpType`, `assignmentMode`.
**fromJson():** Factory constructor containing complex parsing logic (handling missing fields, mapping old keys like `frequency` and `resetPeriod` to `awardFrequency`, and interpreting `awardEnabled` flags).
**toJson():** Method mapping fields back to JSON map.
**Relationships:** Embedded lists of maps for `assignmentSummary`.
**Used By:** `ActivityProvider`, `ActivityService`, `ActivityDetailsPage`, `ActivityCard`, etc.
**Complexity:** Medium (complex JSON parsing fallback logic).
**Code responsibility:** Defining the shape of activity data and safely parsing it from varying API response shapes.

---

## lib/admin/activity/models/execution_student_model.dart

**File Name:** `execution_student_model.dart`
**Full Path:** `lib/admin/activity/models/execution_student_model.dart`
**Purpose:** Domain models representing a student during an activity execution, and detailed assignment properties.
**Module:** Admin/Activity
**Imports:** None
**Exports:** None
**Classes:** 
- `ExecutionStudentModel`
- `ActivityExecutionDetailModel`
- `AssignmentExecutionDetailModel`
- `MyActivityStudentsResponseModel`
**Fields (ExecutionStudentModel):** `id`, `fullName`, `studentId`, `regNo`, `departmentName`, `sectionName`, `totalXp`, `score`.
**Fields (ActivityExecutionDetailModel):** `id`, `name`, `description`, `department`, `evidence`, `frequency`, `type`, `awardEnabled`, `awardXp`, `penaltyEnabled`, `penaltyXp`, `xpCategory`, `cap`.
**Fields (AssignmentExecutionDetailModel):** `id`, `assignedBy`, `assignedAt`, `assignedFacultyName`, `assignmentMode`.
**Fields (MyActivityStudentsResponseModel):** `activity` (ActivityExecutionDetailModel), `students` (List<ExecutionStudentModel>), `xpLimit`, `assignment` (AssignmentExecutionDetailModel).
**fromJson():** Implemented for all classes with null safety fallbacks.
**toJson():** Implemented for `ExecutionStudentModel`.
**Relationships:** `MyActivityStudentsResponseModel` composes the other models.
**Used By:** `GroupActivityExecutionPage`, `ActivityService`.
**Complexity:** Low.
**Code responsibility:** Strong typing for activity execution API responses containing lists of students.

---

## lib/admin/activity/models/my_activity_model.dart

**File Name:** `my_activity_model.dart`
**Full Path:** `lib/admin/activity/models/my_activity_model.dart`
**Purpose:** Domain model for activities specifically assigned to the current user (Teacher/Admin), essentially a specialized subset/variant of ActivityModel.
**Module:** Admin/Activity
**Imports:** `activity_model.dart`
**Exports:** None
**Classes:** 
- `MyActivityModel`
**Fields:** Contains most fields from `ActivityModel` plus `activityId`, `departmentName`, `sectionId`, `sectionName`, `assignedBy`, `assignedAt`.
**Functions:** `toActivityModel()` (Maps this DTO back to a standard `ActivityModel`).
**fromJson():** Implemented with complex fallback logic identical to `ActivityModel`.
**toJson():** None.
**Relationships:** Tightly coupled to `ActivityModel`.
**Used By:** `ActivityService`, Teacher Dashboards.
**Complexity:** Medium.
**Code responsibility:** Parsing assigned activity DTOs and providing a mapper to the generic ActivityModel format.

---

## lib/admin/activity/pages/activity_details_page.dart

**Screen Name:** `ActivityDetailsPage`
**Location:** `lib/admin/activity/pages/activity_details_page.dart`
**Purpose:** A read-only screen displaying the full details of a specific `ActivityModel`.
**Parent Screen:** Typically `ActivityListPage` or Dashboards.
**Child Screens:** None.
**Widgets Used:** `Scaffold`, `AppBar`, `ListView`, `Card`, `Row`, `Column`, `Icon`, `Text`, `_DetailCard` (Private widget).
**Dialogs Used:** None.
**Bottom Sheets:** None.
**Forms:** None.
**Controllers:** None.
**Providers:** None directly injected.
**Repositories:** None.
**Services:** None.
**Models:** `ActivityModel`.
**Navigation Flow:** Pops back to previous screen on back arrow via `Navigator.pop()`.
**API Calls:** None.
**State Flow:** Stateless, receives `ActivityModel` entirely through constructor parameters.
**Complexity:** Low.
**Code responsibility:** UI Presentation of activity details in a styled list of cards.

**Widget Name:** `_DetailCard`
**Location:** `lib/admin/activity/pages/activity_details_page.dart`
**Type:** Private Reusable UI Component
**Stateless/Stateful:** Stateless
**Reusable:** Only within this file.
**Used By:** `ActivityDetailsPage`
**Properties:** `icon`, `title`, `content`, `color`.
**Dependencies:** Flutter Material.

---

## lib/admin/activity/pages/activity_execution_page.dart

**File Name:** `activity_execution_page.dart`
**Full Path:** `lib/admin/activity/pages/activity_execution_page.dart`
**Purpose:** Screen for faculty to view students assigned to an activity and manually award XP to them individually.
**Module:** Admin/Activity
**Layer:** Presentation
**Responsibilities:** Fetching execution students list, filtering by search query, providing UI to input XP and remarks, calling award API, and displaying summary statistics of awarded XP.
**Imports:** 
- `package:flutter/material.dart`
- `../models/execution_student_model.dart`
- `../services/activity_service.dart`
**Exports:** None
**Classes:** 
- `ActivityExecutionPage` (StatefulWidget)
- `_ActivityExecutionPageState` (State)
**Functions:** 
- `_loadData()`
- `_submitAward()`
- `_openAwardDialog()`
**Enums:** None
**Extensions:** None
**Mixins:** None
**Global Variables:** None
**Constants:** `_primary`, `_dark`
**Dependencies:** `ActivityService`
**Used By:** `ActivityListPage` (via navigation)
**Uses:** `ActivityService`, `MyActivityStudentsResponseModel`, `ExecutionStudentModel`
**Widgets Used:** `Scaffold`, `CustomScrollView`, `SliverList`, `SliverToBoxAdapter`, `Card`, `TextField`, `ElevatedButton`, `AlertDialog`, `SnackBar`, `TextFormField`.
**Providers Used:** None (uses direct Service instantiation)
**Repositories Used:** None
**Services Used:** `ActivityService`
**Models Used:** `MyActivityStudentsResponseModel`, `ExecutionStudentModel`
**Utilities Used:** None
**Navigation Source:** `ActivityListPage`
**Navigation Destination:** None (Popup dialogs only)
**API Endpoints:** 
- `GET /api/v1/faculty/my-activities/{id}/students` (via service)
- `POST /api/v1/faculty/award-xp` (via service)
**Business Logic:** Handles validation of max XP limits before awarding, maintains local state of awarded students to update UI dynamically without full re-fetch.
**State Management:** Local State (`setState`)
**Reusable:** No
**Complexity:** High (complex local state, sliver-based scrolling, form validation).
**Notes:** Creates a new instance of `ActivityService` rather than using dependency injection.

---

## lib/admin/activity/pages/activity_execution_page_v2.dart

**File Name:** `activity_execution_page_v2.dart`
**Full Path:** `lib/admin/activity/pages/activity_execution_page_v2.dart`
**Purpose:** Upgraded version of the execution page supporting "PASS/FAIL" discrete outcomes rather than raw numeric XP inputs (used for penalty/discipline tracking).
**Module:** Admin/Activity
**Layer:** Presentation
**Responsibilities:** Same as v1, but introduces conditional logic to display radio buttons for PASS/FAIL if both award and penalty are enabled, automatically resolving XP values based on selection.
**Imports:** 
- `package:flutter/material.dart`
- `../models/execution_student_model.dart`
- `../services/activity_service.dart`
**Exports:** None
**Classes:** 
- `ActivityExecutionPage` (StatefulWidget)
- `_ActivityExecutionPageState` (State)
**Functions:** 
- `_loadData()`
- `_submitAward()`
- `_openAwardDialog()`
**Enums:** None
**Extensions:** None
**Mixins:** None
**Global Variables:** None
**Constants:** `_primary`, `_dark`
**Dependencies:** `ActivityService`
**Used By:** Unclear (might be an A/B test or replacement for v1)
**Uses:** `ActivityService`, `MyActivityStudentsResponseModel`
**Widgets Used:** `RadioListTile`, `StatefulBuilder` (inside dialog), `Scaffold`, `SliverList`.
**Providers Used:** None
**Repositories Used:** None
**Services Used:** `ActivityService`
**Models Used:** `MyActivityStudentsResponseModel`, `ExecutionStudentModel`
**Utilities Used:** None
**Navigation Source:** Unclear
**Navigation Destination:** None
**API Endpoints:** Same as v1, but sends `result` (PASS/FAIL) in payload.
**Business Logic:** Dynamic determination of XP based on PASS/FAIL choice and the activity's configured `awardXp` and `penaltyXp`.
**State Management:** Local State (`setState`, `StatefulBuilder`)
**Reusable:** No
**Complexity:** High
**Notes:** Code duplication with v1 is extremely high. They should likely be merged into a single configurable widget.

---

## lib/admin/activity/pages/activity_list_page.dart

**File Name:** `activity_list_page.dart`
**Full Path:** `lib/admin/activity/pages/activity_list_page.dart`
**Purpose:** Lists all activities configured for a specific subgroup, or lists assigned activities for the current user. Entry point for activity management.
**Module:** Admin/Activity
**Layer:** Presentation
**Responsibilities:** Initializing `ActivityProvider`, triggering data load, providing navigation to Create, Edit, Detail, Assign, and Execution screens, and confirming deletions.
**Imports:** Multiple models, pages, providers, repositories, services, and widgets from `admin/activity` module.
**Exports:** None
**Classes:** 
- `ActivityListPage` (StatefulWidget)
- `_ActivityListPageState` (State)
**Functions:** 
- `_getCleanName()`
- `_openCreate()`
- `_openAssign()`
- `_openEdit()`
- `_confirmDelete()`
**Enums:** None
**Extensions:** None
**Mixins:** None
**Global Variables:** None
**Constants:** `_primary`, `_dark`
**Dependencies:** `ActivityProvider`
**Used By:** Subgroup Details Page, Teacher/Admin Dashboards
**Uses:** `ActivityProvider`, `ActivityCard`, `CreateActivityPage`, `EditActivityPage`, `ActivityExecutionPage`, `AdminActivityDetailPage`, `AssignFacultyPage`.
**Widgets Used:** `Scaffold`, `ListenableBuilder`, `CustomScrollView`, `SliverList`, `FloatingActionButton`.
**Providers Used:** `ActivityProvider` (Instantiated locally, not globally)
**Repositories Used:** `ActivityRepository`
**Services Used:** `ActivityService`
**Models Used:** `ActivityModel`, `MyActivityModel`
**Utilities Used:** None
**Navigation Source:** Dashboards, Subgroup Views
**Navigation Destination:** 
- `CreateActivityPage`
- `AssignFacultyPage`
- `EditActivityPage`
- `AdminActivityDetailPage`
- `GroupActivityYearPage`
- `ActivityExecutionPage`
**API Endpoints:** None directly (Delegated to Provider)
**Business Logic:** Decides routing logic (Group vs Individual activity) and Admin vs ReadOnly modes based on constructor flags.
**State Management:** `ListenableBuilder` listening to locally scoped `ActivityProvider`.
**Reusable:** Yes (Used for both Admin configuration view and Teacher execution view).
**Complexity:** High (Heavy routing logic and scoped provider management).
**Notes:** The provider is instantiated inside `initState()` and disposed in `dispose()`, meaning it acts as a scoped ViewModel rather than a global singleton.

---

## lib/admin/activity/pages/admin_activity_detail_page.dart

**File Name:** `admin_activity_detail_page.dart`
**Full Path:** `lib/admin/activity/pages/admin_activity_detail_page.dart`
**Purpose:** A multi-step wizard allowing Admins to navigate through Year -> Department -> Section to manually adjust/award points to specific students for a specific activity.
**Module:** Admin/Activity
**Layer:** Presentation
**Responsibilities:** Fetching college hierarchy metadata (Years, Depts, Students) and providing a drill-down UI. Calls backend to directly adjust student points.
**Imports:** 
- `dart:convert`
- `package:http/http.dart`
- `core/config/api_config.dart`
- `../models/activity_model.dart`
**Exports:** None
**Classes:** 
- `AdminActivityDetailPage` (Step 1: Year)
- `AdminActivityDeptSelectionPage` (Step 2: Department)
- `AdminActivitySectionSelectionPage` (Step 3: Section)
- `AdminActivityStudentPointsPage` (Step 4: Student List & Award)
**Functions:** 
- `_getYearAliases()`
- `_loadAllData()`
- `_handleDeptSelection()`
- `_submitAward()`
**Enums:** None
**Extensions:** None
**Mixins:** None
**Global Variables:** None
**Constants:** `_primary`, `_dark`, `_bg`
**Dependencies:** `http` package directly.
**Used By:** `ActivityListPage`
**Uses:** Raw HTTP calls.
**Widgets Used:** `Scaffold`, `ListView`, `Card`, `InkWell`, `AlertDialog`.
**Providers Used:** None
**Repositories Used:** None
**Services Used:** None (Uses direct HTTP calls, breaking architecture).
**Models Used:** `ActivityModel`
**Utilities Used:** `ApiConfig`
**Navigation Source:** `ActivityListPage`
**Navigation Destination:** Self (internal wizard routing)
**API Endpoints:** 
- `GET /api/v1/admin/years`
- `GET /api/v1/admin/departments`
- `GET /api/v1/students`
- `POST /api/v1/students/{id}/adjust-points`
**Business Logic:** Year matching logic using aliases (e.g. mapping "1" to "first", "1st"). Client-side filtering of a massive list of all students (2000+) to find sections.
**State Management:** Local State (`setState`)
**Reusable:** No
**Complexity:** Very High (Complex client-side relational mapping of massive flat JSON structures).
**Notes:** **ARCHITECTURAL VIOLATION:** This file bypasses the Service and Repository layers entirely, making raw `http.get` and `http.post` calls directly from the UI. Client-side filtering of 2000 students is highly inefficient.

---

## lib/admin/activity/pages/assign_faculty_page.dart

**File Name:** `assign_faculty_page.dart`
**Full Path:** `lib/admin/activity/pages/assign_faculty_page.dart`
**Purpose:** Complex configuration screen allowing Admins to assign an Activity globally, to Class Coordinators, or specifically to departments/sections/individual teachers.
**Module:** Admin/Activity
**Layer:** Presentation
**Responsibilities:** Parsing existing assignments, mapping them to department configs, rendering a dynamic form, and serializing the assignments back to the API format.
**Imports:** `activity_model.dart`, `activity_provider.dart`, `sticky_bottom_buttons.dart`
**Exports:** None
**Classes:** 
- `AssignFacultyPage`
- `_AssignFacultyPageState`
- `SearchableFacultySelector`
- `_FacultySearchSheet`
**Functions:** 
- `_initializeStateFromActivity()`
- `_getTeachersForDepartment()`
- `_getSectionsForDepartment()`
- `_onSave()`
- `_getCcForSection()`
**Enums:** None
**Extensions:** None
**Mixins:** None
**Global Variables:** None
**Constants:** `_primary`, `_dark`
**Dependencies:** `ActivityProvider`
**Used By:** `ActivityListPage`
**Uses:** `ActivityProvider`, `SearchableFacultySelector`
**Widgets Used:** `SwitchListTile`, `StickyBottomButtons`, `BottomSheet`, `ListView`.
**Providers Used:** `ActivityProvider` (Passed via constructor).
**Repositories Used:** None directly.
**Services Used:** None directly.
**Models Used:** `ActivityModel`
**Utilities Used:** None
**Navigation Source:** `ActivityListPage`
**Navigation Destination:** Pops back on save.
**API Endpoints:** `provider.saveAssignments()`
**Business Logic:** Handles mutually exclusive assignment scopes (GLOBAL vs CLASS_COORDINATOR vs DEPARTMENT/SECTION). Highly complex state mapping from flat API DTO to nested UI dictionary.
**State Management:** Local State heavily managing a deep Map `_deptConfigs`.
**Reusable:** No
**Complexity:** Extremely High (One of the most complex state management files in the project).
**Notes:** The state dictionary `_deptConfigs` is deeply nested and difficult to trace. 
