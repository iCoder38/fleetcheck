# FleetCheck Mobile App — API Integration Document

**App Name:** FleetCheck  
**Package:** `com.FleetCheck.Evs`  
**Base URL:** `https://demo1.evirtualservices.com/fleetcheck/api`  
**Auth:** Bearer Token (JWT) in `Authorization` header  
**Content-Type:** `application/json`  
**API Version:** v1  

---

## Standard Response Format

Every endpoint returns:
```json
{
  "success": true | false,
  "message": "Human-readable message",
  "data": { ... }
}
```

Error responses:
```json
{
  "success": false,
  "message": "Error description",
  "errors": { "field": "validation error" }
}
```

---

## HTTP Status Codes Used

| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Created |
| 400 | Bad Request / Validation Error |
| 401 | Unauthorized (token missing or expired) |
| 403 | Forbidden |
| 404 | Resource not found |
| 422 | Unprocessable Entity |
| 500 | Server Error |

---

## 1. AUTHENTICATION APIs

### 1.1 Login
**POST** `/auth/login`  
**Auth:** None  
**Screen:** Login Screen

**Request Body:**
```json
{
  "identifier": "EMP-001",
  "password": "SecurePass@123"
}
```
> `identifier` accepts Employee ID, Badge ID, or Phone Number

**Success Response (200):**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "driver": {
      "id": 1,
      "full_name": "John Smith",
      "employee_id": "EMP-001",
      "badge_id": "BDG-001",
      "phone": "+1 555-000-1234",
      "email": "john.smith@company.com",
      "license_number": "DL-XXXXXXXXX",
      "license_expiry": "2026-12-31",
      "photo_url": "https://domain.com/photos/driver_1.jpg",
      "status": "active"
    }
  }
}
```

**Error Responses:**
- `401` — Invalid credentials
- `403` — Account inactive/suspended
- `400` — Missing required fields

---

### 1.2 Logout
**POST** `/auth/logout`  
**Auth:** Bearer Token  
**Screen:** Dashboard → Logout button (confirmation popup)

**Request Body:** _(empty)_

**Success Response (200):**
```json
{ "success": true, "message": "Logged out successfully" }
```

---

### 1.3 Forgot Password — Send OTP
**POST** `/auth/forgot-password`  
**Auth:** None  
**Screen:** Forgot Password Screen

**Request Body:**
```json
{ "identifier": "EMP-001" }
```

**Success Response (200):**
```json
{ "success": true, "message": "OTP sent to your registered phone/email" }
```

**Error Responses:**
- `404` — Identifier not found
- `429` — Max OTP attempts reached (3 per 24 hours)

**Backend must:**
- Generate 6-digit numeric OTP
- Store with 45-second expiry
- Track attempt count per identifier per 24 hours
- Send via SMS to registered phone OR email

---

### 1.4 Verify OTP
**POST** `/auth/verify-otp`  
**Auth:** None  
**Screen:** Verify OTP Screen

**Request Body:**
```json
{
  "identifier": "EMP-001",
  "otp": "483921"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "OTP verified successfully",
  "data": {
    "reset_token": "abc123def456ghi789..."
  }
}
```

**Error Responses:**
- `400` — Invalid OTP
- `410` — OTP expired (after 45 seconds)
- `429` — Max attempts exceeded

---

### 1.5 Resend OTP
**POST** `/auth/resend-otp`  
**Auth:** None  
**Screen:** Verify OTP Screen → Resend button

**Request Body:**
```json
{ "identifier": "EMP-001" }
```

**Success Response (200):**
```json
{ "success": true, "message": "New OTP sent successfully" }
```

**Error Responses:**
- `429` — Max resend attempts reached (3 total within 24h)

---

### 1.6 Reset Password
**POST** `/auth/reset-password`  
**Auth:** None (uses reset_token from verify-otp)  
**Screen:** Create New Password Screen

**Request Body:**
```json
{
  "reset_token": "abc123def456ghi789...",
  "password": "NewSecure@123",
  "confirm_password": "NewSecure@123"
}
```

**Success Response (200):**
```json
{ "success": true, "message": "Password reset successfully" }
```

**Error Responses:**
- `400` — Passwords don't match
- `400` — Invalid or expired reset_token
- `422` — Password too short (min 6 chars)

---

### 1.7 Change Password
**POST** `/auth/change-password`  
**Auth:** Bearer Token  
**Screen:** Driver Profile → Change Password

**Request Body:**
```json
{
  "current_password": "OldPass@123",
  "new_password": "NewSecure@456",
  "confirm_password": "NewSecure@456"
}
```

**Success Response (200):**
```json
{ "success": true, "message": "Password changed successfully" }
```

**Error Responses:**
- `401` — Current password incorrect
- `400` — New passwords don't match
- `422` — Password too short

---

## 2. DRIVER APIs

### 2.1 Get Driver Profile
**GET** `/driver/profile`  
**Auth:** Bearer Token  
**Screen:** Driver Profile Screen

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "driver": {
      "id": 1,
      "full_name": "John Smith",
      "employee_id": "EMP-001",
      "badge_id": "BDG-001",
      "phone": "+1 555-000-1234",
      "email": "john.smith@company.com",
      "license_number": "DL-XXXXXXXXX",
      "license_expiry": "2026-12-31",
      "photo_url": "https://domain.com/photos/driver_1.jpg",
      "status": "active"
    }
  }
}
```

---

### 2.2 Update Driver Profile
**PUT** `/driver/update-profile`  
**Auth:** Bearer Token  
**Content-Type:** `multipart/form-data` (when photo is included) or `application/json`  
**Screen:** Driver Profile → Edit Profile

**Request Body (JSON — no photo):**
```json
{
  "phone": "+1 555-111-9999",
  "email": "new.email@company.com"
}
```

**Request Body (multipart — with photo):**
```
phone: +1 555-111-9999
email: new.email@company.com
photo: [binary file data]
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "data": {
    "driver": { ...updated driver object... }
  }
}
```

**Note:** Only `phone`, `email`, and `photo` are editable fields. Employee ID, Badge ID, License info are read-only and managed by admin.

---

### 2.3 Get Driver Stats
**GET** `/driver/stats`  
**Auth:** Bearer Token  
**Screen:** Dashboard (4 stat boxes)

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "stats": {
      "total_assigned": 24,
      "pre_trip_completed": 10,
      "post_trip_completed": 8,
      "pending": 6
    }
  }
}
```

---

## 3. QR CODE APIs

### 3.1 Scan QR Code
**POST** `/qr/scan`  
**Auth:** Bearer Token  
**Screen:** QR Scanner Screen → after successful scan

**Request Body:**
```json
{ "qr_code": "FC-1-5-a3f8b2c1" }
```
> QR code format generated by sub-admin: `FC-{company_id}-{vehicle_id}-{8hex}`

**Success Response (200):**
```json
{
  "success": true,
  "message": "QR Code verified",
  "data": {
    "qr_data": {
      "qr_code_string": "FC-1-5-a3f8b2c1",
      "vehicle_number":  "TRK-4857",
      "vehicle_type":    "Truck",
      "vin":             "1HGBH41JXMN109186",
      "trailer_number":  "TRL-0023",
      "plate_number":    "ABC-1234",
      "fleet_number":    "FLT-047",
      "company_name":    "ABC Logistics Ltd",
      "driver_name":     "John Smith",
      "employee_id":     "EMP-001",
      "inspection_type": null
    }
  }
}
```

> `inspection_type` is `null` when driver can choose. If admin pre-assigned it, returns `"pre_trip"` or `"post_trip"`.

**Error Responses:**
- `404` — QR code not found or not registered
- `403` — QR code not assigned to this driver
- `400` — Malformed QR code string

---

## 4. INSPECTION APIs

### 4.1 Submit Inspection
**POST** `/inspection/submit`  
**Auth:** Bearer Token  
**Screen:** Inspection Review → Submit button

**Request Body:**
```json
{
  "qr_code_string": "FC-1-5-a3f8b2c1",
  "inspection_type": "pre_trip",
  "responses": [
    {
      "item_id":        "s1_headlights",
      "section_id":     "s1",
      "item_label":     "Headlights",
      "selected_option": "Good"
    },
    {
      "item_id":        "s1_brakelights",
      "section_id":     "s1",
      "item_label":     "Brake Lights",
      "selected_option": "Defective"
    },
    {
      "item_id":        "s5_extinguisher",
      "section_id":     "s5",
      "item_label":     "Fire Extinguisher",
      "selected_option": "Available"
    }
  ],
  "defects": [
    {
      "category":    "Body Damage",
      "severity":    "medium",
      "description": "Dent on passenger door, approximately 15cm wide."
    }
  ],
  "additional_notes": "Vehicle was clean and ready for inspection.",
  "gps_location": {
    "latitude":    40.712776,
    "longitude":   -74.005974,
    "address":     "123 Fleet Ave, New York, NY 10001, USA",
    "captured_at": "2025-06-15T08:30:00Z"
  },
  "started_at": "2025-06-15T08:15:00Z"
}
```

**Inspection Types:** `pre_trip` | `post_trip`

**Pre-Trip `selected_option` values:**
- Sections 1–4: `"Good"` | `"Defective"`
- Section 5 (Safety Equipment): `"Available"` | `"Not Available"`

**Post-Trip additional Section 6 `selected_option` values:**
- `"Yes"` | `"No"` (for Body Damage, Tire Damage, Mechanical Issues, Accident Report)

**Defect `severity` values:** `"low"` | `"medium"` | `"high"` | `"critical"`

**Success Response (201):**
```json
{
  "success": true,
  "message": "Inspection submitted successfully",
  "data": {
    "inspection": {
      "id":               1,
      "inspection_id":    "FC-2025-0001",
      "vehicle_number":   "TRK-4857",
      "inspection_type":  "pre_trip",
      "submitted_at":     "2025-06-15T08:30:00Z",
      "status":           "completed",
      "gps_location": {
        "latitude":   40.712776,
        "longitude":  -74.005974,
        "address":    "123 Fleet Ave, New York, NY 10001, USA",
        "captured_at":"2025-06-15T08:30:00Z"
      }
    }
  }
}
```

**Error Responses:**
- `400` — Missing required checklist items (all items must have a response)
- `400` — GPS location missing or invalid
- `404` — QR code not found
- `409` — Duplicate inspection (same vehicle + same type within 1 hour)

---

### 4.2 Get Inspection List
**GET** `/inspection/list`  
**Auth:** Bearer Token  
**Screen:** Inspection History Screen, Dashboard Recent Activity

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `date_range` | string | No | `today` \| `yesterday` \| `week` \| `custom` |
| `vehicle_number` | string | No | Filter by vehicle number (partial match) |
| `type` | string | No | `pre_trip` \| `post_trip` |
| `status` | string | No | `completed` \| `pending` \| `rejected` \| `under_review` |
| `page` | int | No | Page number, default `1` |
| `limit` | int | No | Items per page, default `20` |
| `recent` | int | No | Set to `1` to get last 3 for dashboard |

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "inspections": [
      {
        "id":               1,
        "inspection_id":    "FC-2025-0001",
        "vehicle_number":   "TRK-4857",
        "inspection_type":  "pre_trip",
        "date":             "2025-06-15",
        "submitted_at":     "2025-06-15T08:30:00Z",
        "status":           "completed"
      }
    ],
    "pagination": {
      "current_page":  1,
      "total_pages":   5,
      "total_records": 92,
      "per_page":      20
    }
  }
}
```

---

### 4.3 Get Inspection Detail
**GET** `/inspection/detail/{id}`  
**Auth:** Bearer Token  
**Screen:** Inspection History Detail Screen

**URL Example:** `/inspection/detail/1`

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "inspection": {
      "id":               1,
      "inspection_id":    "FC-2025-0001",
      "driver_name":      "John Smith",
      "vehicle_number":   "TRK-4857",
      "vin":              "1HGBH41JXMN109186",
      "fleet_number":     "FLT-047",
      "company_name":     "ABC Logistics Ltd",
      "inspection_type":  "pre_trip",
      "status":           "completed",
      "submitted_at":     "2025-06-15T08:30:00Z",
      "additional_notes": "Vehicle was clean.",
      "gps_location": {
        "latitude":   40.712776,
        "longitude":  -74.005974,
        "address":    "123 Fleet Ave, New York, NY 10001, USA",
        "captured_at":"2025-06-15T08:30:00Z"
      },
      "responses": [
        {
          "item_id":         "s1_headlights",
          "section_id":      "s1",
          "item_label":      "Headlights",
          "selected_option": "Good"
        }
      ],
      "defects": [
        {
          "id":          1,
          "category":    "Body Damage",
          "severity":    "medium",
          "description": "Dent on passenger door",
          "status":      "open"
        }
      ]
    }
  }
}
```

---

### 4.4 Download Inspection Report (PDF)
**GET** `/inspection/report/{id}`  
**Auth:** Bearer Token  
**Screen:** Submission Success → Download PDF | Inspection History Detail → Download PDF

**Response:** Binary PDF file  
**Content-Type:** `application/pdf`  
**Content-Disposition:** `attachment; filename="FleetCheck_Inspection_FC-2025-0001.pdf"`

**PDF must include:**
- FleetCheck logo + branding
- Inspection ID, Date & Time
- Driver Name, Employee ID
- Vehicle details (Number, VIN, Fleet, Company)
- Complete checklist answers grouped by section
- Defect reports (if any)
- GPS Location with timestamp
- Additional Notes
- Submission timestamp

---

## 5. NOTIFICATIONS APIs

### 5.1 Get Notifications
**GET** `/notifications`  
**Auth:** Bearer Token  
**Screen:** Notifications Screen

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `page` | int | Page number (default: 1) |
| `unread_only` | int | `1` to fetch only unread notifications |

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "notifications": [
      {
        "id":           1,
        "type":         "new_assignment",
        "title":        "New Inspection Assigned",
        "message":      "Pre-trip inspection for TRK-4857 has been assigned to you.",
        "reference_id": "FC-2025-0042",
        "is_read":      0,
        "created_at":   "2025-06-15T07:00:00Z"
      },
      {
        "id":           2,
        "type":         "reminder",
        "title":        "Inspection Reminder",
        "message":      "Post-trip inspection for VAN-1234 is due today.",
        "reference_id": null,
        "is_read":      1,
        "created_at":   "2025-06-14T17:00:00Z"
      },
      {
        "id":           3,
        "type":         "management",
        "title":        "Message from Manager",
        "message":      "All drivers please submit inspections by 5 PM today.",
        "reference_id": null,
        "is_read":      0,
        "created_at":   "2025-06-14T09:30:00Z"
      }
    ],
    "unread_count": 2,
    "pagination": {
      "current_page": 1,
      "total_pages":  2,
      "total_records":12
    }
  }
}
```

**Notification `type` values:**
- `new_assignment` — New inspection job assigned
- `reminder` — Inspection reminder
- `management` — Message from manager/admin

---

### 5.2 Mark Notification as Read
**POST** `/notifications/mark-read`  
**Auth:** Bearer Token  
**Screen:** Notifications Screen → tap notification

**Request Body:**
```json
{ "id": 1 }
```

**Success Response (200):**
```json
{ "success": true, "message": "Notification marked as read" }
```

---

### 5.3 Update FCM Token
**POST** `/notifications/fcm-token`  
**Auth:** Bearer Token  
**Screen:** Called on login / app startup

**Request Body:**
```json
{ "fcm_token": "dXBfcmVnaXN0cmF0aW9uX3Rva2Vu..." }
```

**Success Response (200):**
```json
{ "success": true, "message": "FCM token updated" }
```

**Purpose:** Stores the Firebase Cloud Messaging token so sub-admin can send push notifications to specific drivers.

---

## 6. CHECKLIST DATA REFERENCE

### Pre-Trip Sections (6 sections)

| Section | Items | Response Options |
|---------|-------|-----------------|
| S1 — Vehicle Exterior | Headlights, Brake Lights, Turn Signals, Reflectors, Mirrors, Windshield, Wipers, Horn | Good / Defective |
| S2 — Tires & Wheels | Tire Pressure, Tire Condition, Wheel Nuts, Rims, Suspension | Good / Defective |
| S3 — Engine Compartment | Oil Level, Coolant Level, Belts, Battery, Air Compressor | Good / Defective |
| S4 — Brakes | Parking Brake, Service Brake, Air Brake System, Brake Hoses | Good / Defective |
| S5 — Safety Equipment | Fire Extinguisher, Emergency Triangles, First Aid Kit, Seat Belt | Available / Not Available |
| S6 — Additional Notes | Free text (max 1000 characters) | Optional |

### Post-Trip Sections (7 sections)

Same as Pre-Trip Sections 1–5, plus:

| Section | Items | Response Options |
|---------|-------|-----------------|
| S6 — Vehicle Damage | Body Damage, Tire Damage, Mechanical Issues, Accident Report | Yes / No |
| S7 — Additional Notes | Free text (max 1000 characters) | Optional |

> **Note:** When any Vehicle Damage item is `"Yes"`, the Defect Report Screen appears before continuing.

### Defect Report Fields

| Field | Values |
|-------|--------|
| `category` | Body Damage, Tire Damage, Mechanical Issues, Accident Report |
| `severity` | low, medium, high, critical |
| `description` | Free text description |

---

## 7. AUTHENTICATION FLOW

```
App Launch
    │
    ├── Token exists in SecureStorage? ──YES──► Navigate to Dashboard
    │
    └──NO──► First launch?
                │
                ├── YES ──► Intro Screens (4) ──► Login Screen
                │
                └── NO  ──► Login Screen

Login Screen
    │
    └── POST /auth/login
            │
            ├── Success ──► Store token in SecureStorage ──► Dashboard
            │
            └── Failure ──► Show error message

Token Expiry (401 response)
    │
    └── Clear token ──► Navigate to Login Screen
```

---

## 8. INSPECTION FLOW

```
Dashboard → Scan QR Code
    │
    └── POST /qr/scan (qr_code_string)
            │
            ├── Success ──► Inspection Type Screen
            │                     │
            │               Select Pre-Trip or Post-Trip
            │                     │
            │               Truck Info Screen (auto-filled from QR)
            │                     │
            │               Checklist Screen (6 or 7 sections)
            │               [Each section: all items must be checked]
            │                     │
            │               If Post-Trip + Vehicle Damage = Yes
            │               ──► Defect Report Screen
            │                     │
            │               GPS Verification Screen
            │               [Auto-capture lat/lng/address]
            │                     │
            │               Inspection Review Screen
            │               [Edit or Submit]
            │                     │
            │               POST /inspection/submit
            │                     │
            │               Submission Success Screen
            │               [Download PDF / Share / Return Dashboard]
            │
            └── Failure ──► Show error: "Invalid QR Code"
```

---

## 9. BACKEND DATABASE TABLES NEEDED

The app relies on these existing sub-admin database tables (already in `database_FULL.sql`):

| Table | Used For |
|-------|---------|
| `drivers` | Driver login, profile, stats |
| `vehicles` | Vehicle info from QR code |
| `qr_codes` | QR code verification and vehicle linking |
| `inspections` | Storing submitted inspections |
| `checklist_sections` | Section definitions |
| `checklist_items` | Item definitions per section |
| `inspection_responses` | Per-item responses (Good/Defective etc.) |
| `defect_reports` | Vehicle damage/defect records |
| `qr_scan_logs` | QR scan history |

**New table needed — `driver_fcm_tokens`:**
```sql
CREATE TABLE driver_fcm_tokens (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  driver_id   INT NOT NULL,
  fcm_token   VARCHAR(255) NOT NULL,
  device_type VARCHAR(20) DEFAULT 'mobile',
  updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (driver_id) REFERENCES drivers(id) ON DELETE CASCADE,
  UNIQUE KEY unique_driver (driver_id)
);
```

**New table needed — `driver_otps`:**
```sql
CREATE TABLE driver_otps (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  driver_id    INT NOT NULL,
  otp          VARCHAR(10) NOT NULL,
  reset_token  VARCHAR(255) DEFAULT NULL,
  attempts     INT DEFAULT 0,
  expires_at   DATETIME NOT NULL,
  created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (driver_id) REFERENCES drivers(id) ON DELETE CASCADE
);
```

---

## 10. SECURITY REQUIREMENTS

| Requirement | Implementation |
|-------------|---------------|
| Token storage | `flutter_secure_storage` (AES encrypted on Android, Keychain on iOS) |
| Token type | JWT with expiry (recommend 7 days) |
| HTTPS | All API calls must use HTTPS |
| OTP | 6-digit numeric, 45-second expiry, 3 attempts max per 24h |
| Password | Min 6 characters, alphanumeric |
| Input validation | All fields validated server-side |

---

## 11. PUSH NOTIFICATION PAYLOAD (Firebase FCM)

When sub-admin sends a notification, the FCM payload should be:

```json
{
  "to": "DRIVER_FCM_TOKEN",
  "notification": {
    "title": "New Inspection Assigned",
    "body": "Pre-trip inspection for TRK-4857 assigned to you."
  },
  "data": {
    "type":         "new_assignment",
    "reference_id": "FC-2025-0042",
    "driver_id":    "1"
  }
}
```

**Notification types to support:**
- `new_assignment` — New job assigned
- `reminder` — Inspection reminder
- `management` — Admin/manager broadcast message

---

*Document Version: 1.0 | Generated for FleetCheck Mobile App v1.0.0*
