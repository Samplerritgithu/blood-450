# Blood Donation System - Setup Guide

## Quick Setup (3 Steps)

### Step 1: Create Superuser
```bash
python manage.py createsuperuser
```
Enter your desired username, email (optional), and password.

### Step 2: Start Server
```bash
python manage.py runserver
```
Server will start at: http://127.0.0.1:8000

### Step 3: Access Admin Panel
Open: http://127.0.0.1:8000/admin/
Login with the superuser credentials you created.

---

## Creating Users

### 1. Create Admin User (if not already created)
- Use `python manage.py createsuperuser` command above
- Or create through Django admin panel

### 2. Create Donor Users

**Via Django Admin Panel:**

1. Go to http://127.0.0.1:8000/admin/
2. Click **"Users"** → **"Add User"**
3. Enter username and password
4. Click **"Save"**
5. In the user detail page:
   - **Do NOT check "Staff status"** (donors are not staff)
   - Fill in other details if needed
   - Click **"Save"**

6. Now create the Donor Profile:
   - Click **"Donor profiles"** → **"Add donor profile"**
   - Select the user you just created
   - Enter phone number (e.g., +1234567890)
   - Select blood group (A+, A-, B+, B-, O+, O-, AB+, AB-)
   - Check **"Is available"** (important!)
   - Click **"Save"**

**Example Donors:**
- Username: `john` | Blood Group: A+ | Phone: +1234567890
- Username: `sarah` | Blood Group: A+ | Phone: +9876543210
- Username: `mike` | Blood Group: O+ | Phone: +1122334455

---

## How It Works

### Admin Flow:
1. **Login** as admin (staff user)
2. Navigate to: http://127.0.0.1:8000/demo/admin/create-request/
3. **Create blood request:**
   - Select blood group
   - Enter units needed
   - Select urgency level (Critical/High/Medium)
   - Add any notes
4. **Submit** - System automatically notifies matching donors
5. **View responses** at: http://127.0.0.1:8000/demo/admin/request/1/

### Donor Flow:
1. **Login** as donor (regular user)
2. Automatically redirected to: http://127.0.0.1:8000/demo/donor/notifications/
3. **View blood requests** matching your blood group
4. **Accept or Reject** the request
5. Response is saved and admin can see it

---

## Important URLs

- **Login:** http://127.0.0.1:8000/accounts/login/
- **Admin Panel:** http://127.0.0.1:8000/admin/
- **Create Blood Request (Admin):** http://127.0.0.1:8000/demo/admin/create-request/
- **View Request Details (Admin):** http://127.0.0.1:8000/demo/admin/request/<id>/
- **Donor Notifications:** http://127.0.0.1:8000/demo/donor/notifications/

---

## Testing the System

### 1. Create Test Data
- Create 1 admin user (with staff status)
- Create 2-3 donor users with donor profiles
- Make sure donors have different blood groups

### 2. Test Admin Creates Request
- Login as admin
- Create A+ blood request
- System should notify all A+ donors

### 3. Test Donor Response
- Logout from admin
- Login as donor (A+ blood group)
- See the notification
- Click "Accept & Donate"
- UI updates instantly

### 4. Test Admin Views Results
- Logout from donor
- Login as admin again
- View the request detail page
- See the accepted donor with contact info

---

## Troubleshooting

### CSRF Token Error
1. Clear browser cache (Ctrl + Shift + Delete)
2. Restart Django server
3. Try in incognito/private window

### Donors Not Getting Notified
- Check donor's blood group matches the request
- Check donor's "Is available" is checked
- Verify DonorProfile exists for the user

### Can't Access Admin Pages
- Ensure user has "Staff status" checked
- Regular donors should NOT have staff status

### Accept/Reject Not Working
- Check browser console (F12) for errors
- Ensure JavaScript is enabled
- Clear browser cache

---

## User Roles

### Admin User (Staff)
- **Staff status:** ✓ Checked
- **Permissions:** Can create blood requests
- **Access:** Admin panel + Create request page
- **No DonorProfile needed**

### Donor User (Regular)
- **Staff status:** ✗ Not checked
- **Permissions:** Can view notifications and respond
- **Access:** Donor notifications page only
- **Requires:** DonorProfile with blood group and phone

---

## Database Tables

The system uses these models:

1. **User** (Django built-in)
   - username, email, password, is_staff

2. **DonorProfile** (linked to User)
   - phone, blood_group, is_available

3. **BloodRequest** (created by admin)
   - blood_group, units_needed, urgency, note

4. **Notification** (auto-created)
   - Links user to blood request

5. **DonorResponse** (donor's accept/reject)
   - blood_request, donor, response

---

## Quick Commands

```bash
# Create superuser
python manage.py createsuperuser

# Start server
python manage.py runserver

# Access Django shell
python manage.py shell

# Check system
python manage.py check

# View migrations
python manage.py showmigrations
```

---

## That's It!

The system is now ready to use. Just:
1. Create users through Django admin
2. Admin creates blood requests
3. Donors receive notifications and respond
4. Admin views accepted donors

No complicated setup scripts needed! 🎉
