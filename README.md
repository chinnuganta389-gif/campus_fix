# CampusFix V2 — Campus Maintenance & Operations Platform

> **"Fixing Campus. Improving Life."**  
> A modern, scalable, role-based campus maintenance and complaint management mobile platform built with Flutter and Firebase.

---

## 🌟 Executive Summary & Features

CampusFix V2 is engineered from the ground up to replace legacy college complaint tracking systems with an enterprise-grade mobile application. It features clean role-based architecture, modern aesthetic design principles, real-time Firestore persistence, offline tolerance, and complete workflow traceability.

### Application Roles
- **STUDENT**:
  - Quick action dashboard with greeting, status metrics, and "Report a Problem" call-to-action.
  - **4-Step Problem Reporting**:
    1. Visual Category Grid (Electrical, Plumbing, Cleaning, Water, Furniture, Internet, Classroom, Hostel, Washroom, Infrastructure, Other).
    2. Detailed Description, Title, and Precise Campus Location.
    3. Photographic Evidence Attachment (Camera & Gallery picker).
    4. Review & Confirmation generating standardized Tracking ID (`CF-YYYY-XXXXXX`).
  - Real-time **My Complaints** tracking with Search, Filter by category, and Status tabs (All, Pending, In Progress, Resolved).
  - Dynamic **Interactive Timeline** detailing every state transition with actor names, timestamps, and notes.
  - Profile management, password reset, and settings.

- **STAFF**:
  - Facility operations dashboard with live KPI counters (Total Requests, Pending, Assigned, In Progress, Resolved).
  - Category distribution analytics with visual progress breakdown.
  - Complaint assignment modal with technician directory and priority setting (LOW, MEDIUM, HIGH, URGENT).
  - Search and filter across student complaints.

- **WORKER / TECHNICIAN**:
  - Field task dashboard organized into Assigned, In Progress, and Resolved tabs.
  - One-tap status transitions: `Start Work` (transitions to In Progress and logs start timestamp).
  - Task resolution workflow: `Mark Resolved` bottom sheet requiring resolution notes and optional photographic proof.
  - Personal workload counter and performance tracking.

- **ADMIN**:
  - Master control console with campus-wide resolution health tracking and resolution rate metrics.
  - User Management: Search, filter by role (Student, Staff, Worker, Admin), activate/deactivate account toggle, and role promotion/demotion.
  - Worker Management: Monitor technician workloads, completed tasks, and active tasks.
  - Audit Logging: Chronological audit trail of all high-impact actions.

- **NOTIFICATION CENTER**:
  - In-app notification hub for real-time state changes (submission, assignment, work started, resolution).
  - Unread badge counter, mark-as-read, and mark-all-read operations.

---

## 🛠️ Architecture & Tech Stack

```
lib/
├── app/
│   ├── app.dart                   # Root MaterialApp with theme & routing
│   ├── routes/
│   │   └── app_routes.dart        # Centralized route table & navigation
│   └── theme/
│       ├── app_colors.dart        # Centralized design system color palette
│       ├── app_typography.dart    # Clean typographic scale
│       └── app_theme.dart         # Material 3 light & dark theme definitions
├── core/
│   ├── constants/
│   │   └── app_constants.dart     # Collections, categories, roles, and keys
│   ├── errors/
│   │   └── app_exceptions.dart    # Human-readable Firebase exception mapping
│   ├── utils/
│   │   ├── date_formatter.dart    # Relative and absolute date formatting
│   │   ├── id_generator.dart      # CF-YYYY-XXXXXX generator
│   │   └── validators.dart        # Form input validators
│   └── widgets/
│       ├── avatar_image.dart      # Initials & profile photo avatar
│       ├── custom_button.dart     # Tactile button with loading spinner
│       ├── custom_text_field.dart # Form inputs with password toggles
│       ├── empty_view.dart        # Empty state with call-to-action
│       ├── error_view.dart        # Error view with retry callback
│       ├── loading_view.dart      # Branded spinner
│       ├── offline_banner.dart    # Offline indicator banner
│       ├── priority_badge.dart    # Colored priority pills
│       ├── responsive_scaffold.dart # Adaptive layout (Mobile bottom nav / Desktop rail)
│       └── status_badge.dart      # Status badge with icon & color
├── features/
│   ├── splash/                    # Animated splash screen with role-based routing
│   ├── onboarding/                # 3-step introductory walkthrough
│   ├── auth/                      # Login, Register, Forgot Password
│   ├── student/                   # Dashboard, Report Problem, Complaints, Profile
│   ├── staff/                     # Operations Hub & Worker Assignment
│   ├── worker/                    # Field tasks, Start Work, Mark Resolved
│   ├── admin/                     # System analytics, User & Worker management, Audit logs
│   └── notifications/             # Notification center
├── models/
│   ├── user_model.dart            # User profile schema
│   ├── complaint_model.dart       # Complaint schema
│   ├── complaint_history_model.dart # Timeline history item schema
│   ├── notification_model.dart    # User notification schema
│   └── activity_log_model.dart    # System audit log schema
└── services/
    ├── auth_service.dart          # Firebase Auth integration
    ├── firestore_service.dart     # Cloud Firestore queries & real-time streams
    ├── storage_service.dart       # Firebase Storage uploads
    ├── notification_service.dart  # FCM push notification handler
    └── providers.dart             # Riverpod dependency injection & streams
```

---

## 🔒 Security Rules

Strict security rules are declared in `firestore.rules` and `storage.rules`:
- Role-based authorization enforced directly at the database layer.
- Students can only read and create their own complaints.
- Technicians can only view and update tasks explicitly assigned to them.
- Only administrators can deactivate accounts or alter user roles.

---

## 🚀 Building & Running

### Prerequisites
- Flutter SDK 3.47+
- Dart SDK 3.13+
- Android SDK 34+

### Verification Commands
```bash
# Analyze project
flutter analyze

# Run unit and widget tests
flutter test

# Build production Android APK
flutter build apk --release

# Build production App Bundle (AAB)
flutter build appbundle --release
```
