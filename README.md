# 🎓 Student Performance & Discipline Monitoring System (SPDMS)

A comprehensive web and mobile platform designed to monitor, evaluate, and improve student performance across academics, training, placements, co-curricular activities, and discipline.

---

## 📖 Overview

The Student Performance & Discipline Monitoring System (SPDMS) enables colleges to maintain a centralized record of student achievements and disciplinary activities.

Unlike traditional disciplinary systems that focus only on penalties, SPDMS follows a balanced scoring model where students can earn points for positive contributions and lose points for violations.

The system promotes:

- Academic Excellence
- Placement Readiness
- Professional Behaviour
- Campus Discipline
- Student Development

---

## 🎯 Objectives

- Track student performance throughout their academic journey.
- Reward positive achievements.
- Record disciplinary violations transparently.
- Provide faculty with monitoring tools.
- Allow students and parents to view progress.
- Generate reports and analytics for administration.

---

# 👥 User Roles

### Admin

- Manage users
- Manage departments
- Configure scoring rules
- View analytics
- Generate reports

### HOD

- View department statistics
- Approve disciplinary actions
- Review performance reports

### Faculty

- Add achievements
- Report violations
- View student records
- Monitor progress

### Placement Officer

- Award placement-related points
- Track training participation
- Manage placement activities

### Student

- View current score
- View achievements
- View violations
- Check leaderboard rank

### Parent

- Monitor student performance
- View score history
- Receive notifications

---

# ⭐ Scoring System

## Initial Score

```text
Every Student Starts With 0 Points
```

---

## Positive Activities

| Activity | Points |
|-----------|---------|
| Attendance Above 95% | +10 |
| Placement Training Completion | +15 |
| Internship Completion | +20 |
| Technical Event Participation | +10 |
| Hackathon Winner | +25 |
| Academic Topper | +30 |
| Club Leadership | +20 |
| Faculty Appreciation | +10 |

---

## Negative Activities

| Violation | Points |
|-----------|---------|
| Shirt Not Tucked | -2 |
| Late Arrival | -3 |
| Missing ID Card | -2 |
| Mobile Usage in Class | -5 |
| Misbehavior | -10 |
| Proxy Attendance | -15 |
| Ragging | -50 |
| Severe Misconduct | -100 |

---

# 🏗️ System Architecture

## Frontend

### Web Application

```text
React.js
TypeScript
Tailwind CSS
Axios
```

### Mobile Application

```text
Flutter
Dart
REST API
Provider / Riverpod
```

---

## Backend

```text
Spring Boot 3
Spring Security
JWT Authentication
Hibernate / JPA
REST APIs
```

---

## Database

```text
PostgreSQL
```

---

## Cache

```text
Redis
```

---

## Documentation

```text
Swagger / OpenAPI
```

---

# 🏛️ Major Modules

## Authentication Module

Features:

- Login
- Logout
- JWT Authentication
- Role-Based Access Control
- Password Reset

---

## Student Module

Features:

- Student Profile
- Academic Information
- Score History
- Achievement History
- Violation History

---

## Achievement Module

Tracks:

- Academics
- Placement Activities
- Certifications
- Internships
- Hackathons
- Workshops
- Sports
- Clubs

---

## Discipline Module

Tracks:

- Attendance Violations
- Dress Code Violations
- Misconduct Cases
- Mobile Usage
- Other Disciplinary Records

---

## Score Engine

Responsible for:

```text
Positive Points
-
Negative Points
=
Final Student Score
```

---

## Leaderboard Module

Provides:

- College Rank
- Department Rank
- Year-wise Rank
- Top Performers

---

## Notification Module

Supports:

- Email Notifications
- Push Notifications
- Parent Alerts
- Achievement Updates

---

## Reporting Module

Generates:

- Student Reports
- Department Reports
- Monthly Reports
- Violation Reports
- Achievement Reports

---

# 🗄️ Database Design

## Students

```sql
students
---------
id
register_no
name
department
year
current_score
created_at
```

---

## Achievements

```sql
achievements
------------
id
student_id
title
category
points
faculty_id
created_at
```

---

## Violations

```sql
violations
----------
id
student_id
violation_type
severity
points_deducted
reported_by
created_at
```

---

## Score Ledger

```sql
score_ledger
------------
id
student_id
transaction_type
points
reason
created_at
```

---

# 🔌 API Endpoints

## Authentication

```http
POST /api/auth/login
POST /api/auth/logout
POST /api/auth/refresh
```

---

## Students

```http
GET /api/students
GET /api/students/{id}
PUT /api/students/{id}
```

---

## Achievements

```http
POST /api/achievements
GET /api/achievements
PUT /api/achievements/{id}
DELETE /api/achievements/{id}
```

---

## Violations

```http
POST /api/violations
GET /api/violations
PUT /api/violations/{id}
DELETE /api/violations/{id}
```

---

## Scores

```http
GET /api/scores/{studentId}
GET /api/leaderboard
```

---

# 📱 Flutter Application Structure

```text
lib
│
├── main.dart
│
├── screens
│   ├── login
│   ├── student
│   ├── faculty
│   ├── admin
│
├── models
│
├── services
│
├── providers
│
├── widgets
│
├── routes
│
├── constants
│
└── utils
```

---

# 🌐 React Application Structure

```text
src
│
├── pages
├── components
├── services
├── hooks
├── routes
├── layouts
├── contexts
├── assets
└── utils
```

---

# 🔐 Security Features

- JWT Authentication
- Role Based Access Control (RBAC)
- Password Encryption
- HTTPS Communication
- Input Validation
- Audit Logging
- Secure API Access

---

# 📊 Future Enhancements

- AI-Based Student Performance Prediction
- Placement Readiness Score
- Attendance Analytics
- Behavioral Trend Analysis
- Mobile Push Notifications
- QR-Based Attendance Integration

---

# 🚀 Installation

## Backend

```bash
git clone <repository-url>

cd backend

mvn clean install

mvn spring-boot:run
```

---

## Frontend (React)

```bash
cd frontend

npm install

npm run dev
```

---

## Mobile App (Flutter)

```bash
cd mobile

flutter pub get

flutter run
```

---

# 👨‍💻 Team

Project Title:

**Student Performance & Discipline Monitoring System (SPDMS)**

Developed for:

**College Student Monitoring and Performance Enhancement**

---

## License

This project is developed for educational and academic purposes.
