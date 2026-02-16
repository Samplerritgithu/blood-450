# ⚡ Quick Start - REST API

## 🚀 3 Commands to Get Started

```bash
# 1. Install dependencies
pip install -r requirements.txt

# 2. Run migrations
python manage.py migrate

# 3. Start server
python manage.py runserver
```

## 🌐 Open in Browser

```
http://127.0.0.1:8000/api/
```

You'll see the **Browsable API** - a beautiful web interface to test all endpoints!

---

## 🧪 Quick Test

### 1. Login (Get JWT Token)

Click on `/auth/login/` in the browsable API, or use cURL:

```bash
curl -X POST http://127.0.0.1:8000/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

**Copy the `access` token from response**

### 2. Use Token

```bash
curl -X GET http://127.0.0.1:8000/api/notifications/ \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN_HERE"
```

---

## 📱 For Flutter Development

### Android Emulator:
```dart
baseUrl: 'http://10.0.2.2:8000/api/'
```

### Physical Device:
1. Find your PC's IP address:
   ```bash
   ipconfig  # Windows
   ifconfig  # Mac/Linux
   ```

2. Update `settings.py`:
   ```python
   ALLOWED_HOSTS = ['localhost', '127.0.0.1', '192.168.1.100']
   ```

3. Run server:
   ```bash
   python manage.py runserver 0.0.0.0:8000
   ```

4. Use in Flutter:
   ```dart
   baseUrl: 'http://192.168.1.100:8000/api/'
   ```

---

## 📚 Documentation

- **API Endpoints:** See `API_DOCUMENTATION.md`
- **Setup Guide:** See `API_SETUP_GUIDE.md`
- **Complete Info:** See `REST_API_COMPLETE.md`

---

## ✅ Verify It Works

- [ ] Can access: `http://127.0.0.1:8000/api/`
- [ ] Can login and get JWT token
- [ ] Can access protected endpoints with token
- [ ] Web interface still works: `http://127.0.0.1:8000/`

---

## 🎯 Key Endpoints

```
POST   /api/auth/login/              - Login
GET    /api/auth/me/                 - Current user
GET    /api/notifications/           - My notifications
POST   /api/respond/                 - Accept/reject request
POST   /api/blood-requests/          - Create request (admin)
GET    /api/dashboard/               - Dashboard stats (admin)
```

---

**That's it! Your API is ready for Flutter!** 🎉
