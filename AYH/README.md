# Blood Donation Management System

A Django-based blood donation system where admins create blood requests and donors receive notifications to accept or reject.

## Features

- ✅ Admin creates blood requests with urgency levels
- ✅ Automatic notification to matching donors
- ✅ Donors can accept or reject requests
- ✅ Real-time UI updates (no page reload)
- ✅ Admin views accepted donors with contact info

## Quick Start

### 1. Create Admin User
```bash
python manage.py createsuperuser
```

### 2. Start Server
```bash
python manage.py runserver
```

### 3. Setup Users
1. Go to http://127.0.0.1:8000/admin/
2. Create donor users under "Users"
3. Create donor profiles under "Donor profiles" (link to user, add phone & blood group)

### 4. Use the System

**Admin:**
- Login → Go to http://127.0.0.1:8000/demo/admin/create-request/
- Create blood request → System notifies matching donors

**Donor:**
- Login → Automatically see notifications
- Accept or Reject → Admin sees your response

## Important URLs

- **Login:** http://127.0.0.1:8000/accounts/login/
- **Admin Panel:** http://127.0.0.1:8000/admin/
- **Create Request:** http://127.0.0.1:8000/demo/admin/create-request/
- **Donor Notifications:** http://127.0.0.1:8000/demo/donor/notifications/

## User Roles

**Admin (Staff User):**
- Check "Staff status" when creating user
- Can create blood requests
- Can view accepted donors

**Donor (Regular User):**
- Do NOT check "Staff status"
- Must have DonorProfile (phone + blood group + available)
- Can view notifications and respond

## Technology

- Backend: Django 5.x
- Frontend: HTML + CSS + JavaScript
- Database: SQLite
- Authentication: Django Sessions

## Documentation

- **SETUP_GUIDE.md** - Detailed setup instructions
- **TROUBLESHOOTING.md** - Common issues and solutions

## Support

For issues, check TROUBLESHOOTING.md or review the code comments.

---

**Simple. Clean. Functional.** 🩸
