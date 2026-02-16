# Blood Donation System - Demo MVP

A Django-based blood donation management system with HTML/CSS/JS frontend for managing blood requests and donor responses.

## Features

- **Admin Features:**
  - Create blood requests with blood group, units needed, urgency level, and notes
  - Automatically notify matching donors in the database
  - View request details and see list of accepted donors with contact info

- **Donor Features:**
  - View blood donation notifications matching their blood group
  - Accept or reject blood donation requests
  - Track response history

- **System Features:**
  - Session-based authentication
  - Unique constraint preventing duplicate responses
  - Real-time UI updates using JavaScript fetch API
  - Responsive design with modern CSS

## Setup Instructions

### 1. Install Dependencies

Ensure you have Python 3.8+ installed, then install Django:

```bash
pip install django
```

### 2. Run Migrations

Create the database tables:

```bash
python manage.py makemigrations
python manage.py migrate
```

### 3. Create Admin User

Create a superuser (admin) account:

```bash
python manage.py createsuperuser
```

Follow the prompts:
- Username: admin
- Email: admin@example.com (or leave blank)
- Password: admin123 (or your choice)

### 4. Create Donor Users via Django Shell

Open the Django shell:

```bash
python manage.py shell
```

Then run the following commands:

```python
from django.contrib.auth.models import User
from careapp.models import DonorProfile

# Create donor user 1
donor1 = User.objects.create_user(username='john_donor', password='donor123', email='john@example.com')
DonorProfile.objects.create(user=donor1, phone='+1234567890', blood_group='A+', is_available=True)

# Create donor user 2
donor2 = User.objects.create_user(username='sarah_donor', password='donor123', email='sarah@example.com')
DonorProfile.objects.create(user=donor2, phone='+1987654321', blood_group='A+', is_available=True)

# Create donor user 3 with different blood group
donor3 = User.objects.create_user(username='mike_donor', password='donor123', email='mike@example.com')
DonorProfile.objects.create(user=donor3, phone='+1122334455', blood_group='O+', is_available=True)

print("Donors created successfully!")
exit()
```

### 5. Run the Development Server

```bash
python manage.py runserver
```

The server will start at `http://127.0.0.1:8000/`

## Demo Workflow

### Step 1: Admin Creates Blood Request

1. Open browser and navigate to `http://127.0.0.1:8000/accounts/login/`
2. Login as admin:
   - Username: `admin`
   - Password: `admin123` (or what you set)
3. You'll be redirected to the create request page (or navigate to `http://127.0.0.1:8000/demo/admin/create-request/`)
4. Fill out the form:
   - Blood Group: **A+**
   - Units Needed: **2**
   - Urgency: **Critical**
   - Note: "Urgent surgery scheduled for tomorrow morning"
5. Click "Create Request & Notify Donors"
6. System will:
   - Create the blood request
   - Find all donors with blood group A+ and is_available=True
   - Create notification rows in the database
   - Show success message: "Blood request created successfully! 2 donors notified."
7. You'll be redirected to the request detail page showing:
   - Request information
   - Number of notified donors
   - List of accepted donors (initially empty)

### Step 2: Donor Views Notifications

1. Logout from admin account (click Logout in navbar)
2. Login as donor:
   - Username: `john_donor`
   - Password: `donor123`
3. You'll be redirected to notifications page (or navigate to `http://127.0.0.1:8000/demo/donor/notifications/`)
4. You'll see the blood request notification with:
   - Request details (Blood Group: A+, Units: 2, Urgency: Critical)
   - Notes from admin
   - Two buttons: "Accept & Donate" and "Can't Donate"

### Step 3: Donor Responds to Request

1. Click "Accept & Donate" button
2. JavaScript fetch will:
   - Send POST request to `/demo/donor/respond/`
   - Include CSRF token automatically
   - Send blood_request_id and response
3. Backend will:
   - Create DonorResponse record
   - Mark notification as read
   - Return JSON response
4. UI will update:
   - Buttons disappear
   - Show "✓ You accepted this request" message
   - Card becomes slightly faded (responded state)
5. Alert will show: "Response recorded: accepted"

### Step 4: Admin Views Accepted Donors

1. Logout and login as admin again
2. Navigate to `http://127.0.0.1:8000/demo/admin/request/<id>/` (use the request ID from Step 1)
   - Or go to "Create Request" page and look for the link
3. You'll see:
   - Request details
   - Statistics: "2 Donors Notified", "1 Donors Accepted"
   - Table with accepted donor information:
     - Username: john_donor
     - Phone: +1234567890
     - Blood Group: A+
     - Responded At: (timestamp)

### Step 5: Test Duplicate Response Prevention

1. Login as `john_donor` again
2. Try to respond to the same request again
3. You'll see the card already shows "✓ You accepted this request"
4. The unique constraint prevents duplicate responses

### Step 6: Test Another Donor

1. Logout and login as `sarah_donor` (password: `donor123`)
2. View notifications - same request will appear
3. Click "Can't Donate"
4. Response will be recorded as "rejected"
5. Admin won't see this donor in the accepted list (only accepted donors appear)

## URLs Reference

### Authentication
- Login: `http://127.0.0.1:8000/accounts/login/`
- Logout: `http://127.0.0.1:8000/accounts/logout/`

### Admin Pages (requires is_staff=True)
- Create Request: `http://127.0.0.1:8000/demo/admin/create-request/`
- Request Detail: `http://127.0.0.1:8000/demo/admin/request/<id>/`

### Donor Pages (requires login)
- Notifications: `http://127.0.0.1:8000/demo/donor/notifications/`

### API Endpoints
- Respond to Request: `POST http://127.0.0.1:8000/demo/donor/respond/`

## Testing via Django Admin Panel

You can also manage data via Django admin:

1. Navigate to `http://127.0.0.1:8000/admin/`
2. Login with admin credentials
3. You can view/edit:
   - Donor Profiles
   - Blood Requests
   - Notifications
   - Donor Responses

## Database Models

### DonorProfile
- user (OneToOne → User)
- phone
- blood_group (A+, A-, B+, B-, O+, O-, AB+, AB-)
- is_available (default True)
- created_at

### BloodRequest
- blood_group
- units_needed (default 1)
- urgency (critical/high/medium)
- note
- created_by (FK → User)
- is_active (default True)
- created_at

### Notification
- user (FK → User)
- blood_request (FK → BloodRequest)
- is_read (default False)
- created_at
- **unique_together**: (user, blood_request)

### DonorResponse
- blood_request (FK → BloodRequest)
- donor (FK → User)
- response (accepted/rejected)
- responded_at
- **unique_together**: (blood_request, donor)

## Technology Stack

- **Backend**: Django 5.2.10
- **Database**: SQLite (default)
- **Frontend**: HTML5, CSS3, Vanilla JavaScript
- **Authentication**: Django session auth (no JWT)
- **API**: JSON responses with fetch API

## Security Features

- CSRF token protection on all POST requests
- Login required decorators on all views
- Staff-only access for admin pages
- Unique constraints preventing duplicate responses
- SQL injection protection (Django ORM)

## Future Enhancements (Not in Demo)

- SMS/WhatsApp notifications via Twilio
- Email notifications
- Real-time updates with WebSockets
- Donor location tracking
- Blood bank inventory management
- Appointment scheduling
- Mobile app (Flutter)

## Troubleshooting

### "CSRF token missing or incorrect"
- The JavaScript includes automatic CSRF token handling from cookies
- Ensure cookies are enabled in your browser

### "No module named 'careapp'"
- Make sure 'careapp' is in INSTALLED_APPS in settings.py
- Run migrations again

### Templates not found
- Ensure templates directory exists: `templates/`
- Check TEMPLATES['DIRS'] in settings.py includes BASE_DIR / 'templates'

### Donors not getting notified
- Check donor's blood_group matches the request
- Check donor's is_available is True
- Check in Django admin: Notifications table

## Contact

For questions or issues, refer to the code comments or Django documentation.

---

**Note**: This is a demo/MVP implementation. For production use, add proper error handling, logging, testing, and security hardening.
