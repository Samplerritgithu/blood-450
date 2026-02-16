# Quick Start Guide - Blood Donation System Demo

## 🚀 Setup (5 minutes)

### 1. Create Admin User

```bash
python manage.py createsuperuser
```

Enter:
- Username: `admin`
- Email: (press Enter to skip)
- Password: `admin123`
- Confirm password: `admin123`

### 2. Create Demo Donors

```bash
python manage.py shell < setup_demo_data.py
```

This creates 4 donor accounts:
- `john_donor` (A+)
- `sarah_donor` (A+)
- `mike_donor` (O+)
- `lisa_donor` (B+)

All donors have password: `donor123`

### 3. Start Server

```bash
python manage.py runserver
```

Server starts at: `http://127.0.0.1:8000/`

---

## 🎬 Demo Workflow (2 minutes)

### Part 1: Admin Creates Blood Request

1. **Login as Admin**
   - Go to: `http://127.0.0.1:8000/accounts/login/`
   - Username: `admin`
   - Password: `admin123`

2. **Create Request**
   - You'll see "Create Blood Request" page
   - Fill in:
     - Blood Group: **A+**
     - Units Needed: **2**
     - Urgency: **Critical**
     - Note: "Urgent surgery tomorrow"
   - Click **"Create Request & Notify Donors"**

3. **View Results**
   - Success message: "2 donors notified"
   - You'll see the request detail page
   - Note the Request ID (e.g., #1)

### Part 2: Donor Responds

1. **Logout** (click Logout in navbar)

2. **Login as Donor**
   - Username: `john_donor`
   - Password: `donor123`

3. **View Notification**
   - You'll see the blood request notification
   - Details show: A+, 2 units, Critical priority
   - Two buttons: "Accept & Donate" and "Can't Donate"

4. **Accept Request**
   - Click **"Accept & Donate"**
   - UI updates immediately
   - Shows: "✓ You accepted this request"
   - Alert confirms: "Response recorded: accepted"

### Part 3: Admin Views Accepted Donors

1. **Logout and Login as Admin** again

2. **View Request Details**
   - Go to: `http://127.0.0.1:8000/demo/admin/request/1/`
   - Or click "Create Another Request" then navigate

3. **See Accepted Donors Table**
   - Shows: john_donor
   - Phone: +1234567890
   - Blood Group: A+
   - Timestamp

---

## 📋 Quick Reference

### URLs

**Login:** `http://127.0.0.1:8000/accounts/login/`

**Admin:**
- Create Request: `/demo/admin/create-request/`
- View Request: `/demo/admin/request/<id>/`

**Donor:**
- Notifications: `/demo/donor/notifications/`

**Django Admin:** `http://127.0.0.1:8000/admin/`

### Test Accounts

| Username | Password | Role | Blood Group |
|----------|----------|------|-------------|
| admin | admin123 | Admin | - |
| john_donor | donor123 | Donor | A+ |
| sarah_donor | donor123 | Donor | A+ |
| mike_donor | donor123 | Donor | O+ |
| lisa_donor | donor123 | Donor | B+ |

---

## 🧪 Testing Scenarios

### Scenario 1: Multiple Donors Accept
1. Admin creates A+ request
2. Login as `john_donor` → Accept
3. Login as `sarah_donor` → Accept
4. Admin sees both in accepted list

### Scenario 2: Donor Rejects
1. Admin creates O+ request
2. Login as `mike_donor` → Click "Can't Donate"
3. Response recorded but won't show in admin's accepted list

### Scenario 3: No Duplicate Responses
1. Login as `john_donor`
2. Accept a request
3. Refresh page
4. Same request shows "✓ You accepted this request"
5. Can't respond again (unique constraint)

### Scenario 4: Different Blood Groups
1. Admin creates B+ request
2. Only `lisa_donor` gets notified (matched blood group)
3. Other donors won't see it in their notifications

---

## 🐛 Troubleshooting

**Problem:** "CSRF verification failed"
- **Solution:** Clear browser cookies and try again

**Problem:** Donors not getting notified
- **Check:** Blood group matches AND is_available=True
- **View:** Django admin → Notifications table

**Problem:** Can't login
- **Reset:** Delete db.sqlite3, run migrations, recreate users

**Problem:** Template not found
- **Check:** templates/ folder exists in project root
- **Check:** settings.py has `'DIRS': [BASE_DIR / 'templates']`

---

## 📱 What's Working

✅ Admin creates blood requests  
✅ Auto-notify matching donors (DB only, no SMS)  
✅ Donors view notifications  
✅ Donors accept/reject requests  
✅ Admin sees accepted donors list  
✅ Duplicate response prevention  
✅ Session authentication  
✅ CSRF protection  
✅ Responsive UI  

## 🚧 Not in Demo (Future)

❌ SMS/WhatsApp notifications  
❌ Email alerts  
❌ Real-time updates  
❌ Mobile app  
❌ Payment integration  

---

## 🎯 Success Criteria

Your demo is working correctly if:
1. ✅ Admin can create requests and see notification count
2. ✅ Donors see matching blood group requests
3. ✅ Accept/Reject buttons work without page refresh
4. ✅ Admin sees accepted donors with contact info
5. ✅ Can't respond to same request twice

---

**Need help?** Check README_DEMO.md for detailed documentation.
