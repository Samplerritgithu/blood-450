# Quick Demo Guide - Blood Donation System

## Setup (2 Minutes)

### Step 1: Use Two Different Browsers
- **Browser 1 (Chrome)**: For ADMIN
- **Browser 2 (Firefox/Edge)**: For DONOR/USER

**OR use Incognito:**
- **Normal Chrome**: For ADMIN  
- **Chrome Incognito (Ctrl+Shift+N)**: For DONOR/USER

### Step 2: Login in Both Browsers

**Browser 1 (ADMIN):**
1. Go to `http://127.0.0.1:8000/`
2. Login with admin credentials
3. You'll see the Admin Dashboard

**Browser 2 (DONOR):**
1. Go to `http://127.0.0.1:8000/`
2. Login with donor credentials
3. You'll see the Donor Notifications page
4. **AUTO-REFRESH IS NOW ENABLED** - page refreshes every 3 seconds

### Step 3: Demo the Real-Time Flow

**In Browser 1 (Admin):**
1. Click "Create Request" button in navbar
2. Fill in the form:
   - Blood Group: Select any (e.g., A+)
   - Units Needed: 1
   - Urgency Level: Critical
   - Notes: "Urgent need for surgery"
3. Click "Create Request & Notify Donors"

**In Browser 2 (Donor):**
- **Watch the page automatically refresh every 3 seconds**
- New notification will appear within 3 seconds!
- Donor can click "Accept & Donate" or "Can't Donate"

### Auto-Refresh Feature
- ✅ **Enabled by default** - refreshes every 3 seconds
- Toggle ON/OFF with the button at the top
- Shows "Checking for new requests every 3 seconds" message

## Important Notes

### CSRF Fix Applied
All CSRF token issues are fixed! Just make sure:
1. ✅ Use TWO DIFFERENT BROWSERS (or incognito)
2. ✅ Clear cache if you have old pages open (Ctrl+Shift+Delete)
3. ✅ Login FRESH in each browser

### If You Still Get CSRF Error:
1. **Close ALL tabs** for `localhost:8000`
2. **Clear cookies**: Press F12 → Application → Cookies → Delete all for `127.0.0.1:8000`
3. **Hard refresh**: Ctrl+F5
4. **Login again**

### Demo Flow
```
┌─────────────────┐         ┌──────────────────┐
│  Browser 1      │         │   Browser 2      │
│  (Chrome)       │         │   (Firefox)      │
│                 │         │                  │
│  ADMIN          │         │   DONOR          │
│  Dashboard      │         │   Notifications  │
│                 │         │   (Auto-refresh) │
└────────┬────────┘         └────────┬─────────┘
         │                           │
         │ 1. Create Request         │
         │    - Blood: A+            │
         │    - Units: 1             │
         │    - Urgent: Critical     │
         │                           │
         │ 2. Click Submit           │
         │                           │
         │                           │ 3. Auto-refresh
         │                           │    (every 3 sec)
         │                           │
         │                           │ 4. NEW NOTIFICATION
         │                           │    appears!
         │                           │
         │                           │ 5. Donor responds
         │                           │    "Accept & Donate"
         │                           │
         │ 6. See accepted           │
         │    donor in dashboard     │
         └───────────────────────────┘
```

## Troubleshooting

### Problem: "Forbidden (CSRF token error)"
**Solution:** You're using the same browser for both users!
- Use 2 different browsers OR
- Use normal + incognito mode

### Problem: Notification doesn't appear
**Solution:** 
- Wait up to 3 seconds (auto-refresh)
- Check if donor's blood group is compatible
- Verify donor has `is_available = True` in profile

### Problem: Can't login second user
**Solution:** 
- You're using same browser = same session
- Use different browsers!

## Quick Command Reference

**Start Server:**
```bash
python manage.py runserver
```

**Access URLs:**
- Login: `http://127.0.0.1:8000/`
- Admin Dashboard: `http://127.0.0.1:8000/dashboard/`
- Donor Notifications: `http://127.0.0.1:8000/notifications/`

## Demo Script for Client

**Say this:**
"Let me show you how fast donors get notified when there's a blood request...

1. On the left screen (admin), I'll create an urgent request for A+ blood
2. On the right screen (donor), watch the notification appear automatically
3. The system refreshes every 3 seconds, so donors see requests almost instantly
4. The donor can accept or reject with one click
5. The admin immediately sees who accepted"

**Then show:**
1. Create request in admin browser
2. Point to donor browser auto-refreshing
3. New notification appears (within 3 seconds)
4. Donor clicks "Accept & Donate"
5. Show admin dashboard with accepted donor

## Success Indicators

✅ Admin can create requests without CSRF errors
✅ Donor notifications page auto-refreshes every 3 seconds
✅ New notifications appear automatically
✅ Donor can accept/reject without manual refresh
✅ Admin sees responses in real-time

## Time Estimate
- Setup: 30 seconds
- Demo: 1 minute
- Total: 90 seconds ✅
