# Purchase Registry System

A full-stack mobile application for managing vendors, tracking item prices, logging purchases, and recording financial payments. 

Built with **Flutter** (Frontend) and **Node.js + PostgreSQL** (Backend).

## 🚀 Features
- **Role-Based Access Control (RBAC):** Admin, Manager, and User roles.
- **Vendor Management:** Create and track vendor details.
- **Price Management:** Managers can assign unique prices to items per vendor.
- **Purchase Tracking:** Users can log hardware/material purchases.
- **Payment Tracking:** Managers can log payments made to vendors.
- **Financial Dashboard:** Real-time summary of total purchases, total payments, and pending balances per vendor.
- **Security:** JWT authentication and role-based endpoint protection.

---

## 👥 User Roles & Permissions

| Role | Capabilities | Default Login |
|------|--------------|---------------|
| **Admin** | Create users, manage items, manage vendor profiles. | `admin` / `admin123` |
| **Manager** | View dashboard, manage vendor prices, record payments. | `manager1` / `manager123` |
| **User** | Record purchases (cannot see prices/financials). | `user1` / `user123` |

*(Note: There is a self-registration option on the login screen, which automatically creates a `user` role account).*

---

## 🏗️ Tech Stack

**Frontend:**
- Flutter (Dart)
- Provider (State Management)
- Material 3 Design

**Backend:**
- Node.js & Express
- PostgreSQL (Database)
- JSON Web Tokens (JWT Auth)
- bcryptjs (Password Hashing)

---

## 💻 Local Development Setup

### 1. Database Setup
1. Install PostgreSQL.
2. Create a database named `purchase_registry`.
3. Create the schema and seed data manually using the SQL scripts, or run the seed command (see below).

### 2. Backend Setup
```bash
cd backend

# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Edit .env with your local PostgreSQL credentials

# Seed the database (creates tables + default admin user)
npm run seed

# Start the development server
npm run dev
```
The backend will run on `http://localhost:3000`.

### 3. Frontend Setup
```bash
cd flutter_app

# Install dependencies
flutter pub get

# Change the API Base URL in api_service.dart
# (lib/services/api_service.dart) to point to your local LAN IP
# Example: static const String baseUrl = 'http://192.168.x.x:3000/api';

# Run the app
flutter run
```

---

## ☁️ Cloud Deployment (Production)

This backend is configured to be deployed natively on cloud platforms like **Render.com**.

1. Create a PostgreSQL instance on Render.
2. Create a Node Web Service connected to this repository (`backend` folder).
3. Set the following Environment Variables in Render:
   - `DATABASE_URL` = Your Render DB Internal URL
   - `JWT_SECRET` = A strong, random string
   - `JWT_EXPIRES_IN` = `7d`
4. Deploy the backend.
5. In your `flutter_app/lib/services/api_service.dart`, update the `baseUrl` to your Render app URL.
6. Build your release APK:
   ```bash
   cd flutter_app
   flutter build apk --release
   ```

*(Note: To fix the default admin password in the cloud DB after the initial schema run, use `node fix_admin.js` with your `DATABASE_URL`).*
