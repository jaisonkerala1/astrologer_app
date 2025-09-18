# Astrologer App Backend 🚀

Node.js/Express backend for the Astrologer App with Twilio SMS integration.

## 🔥 Railway Deployment

This backend is optimized for deployment on [Railway](https://railway.com).

### Quick Deploy to Railway

1. **Fork this repository** on GitHub
2. **Create Railway account** at [railway.com](https://railway.com)
3. **Click "Deploy from GitHub"** 
4. **Select your forked repository**
5. **Set root directory** to `/backend` (if deploying backend only)
6. **Add environment variables** (see below)
7. **Deploy!** 🎉

### Environment Variables for Railway

Add these in your Railway project settings:

```env
# Required for Railway
PORT=7566

# JWT Configuration
JWT_SECRET=your_super_secret_jwt_key_change_this_in_production
JWT_EXPIRES_IN=7d

# Twilio Configuration (Get from https://twilio.com)
TWILIO_ACCOUNT_SID=your_twilio_account_sid_here
TWILIO_AUTH_TOKEN=your_twilio_auth_token_here
TWILIO_PHONE_NUMBER=your_twilio_phone_number_here

# CORS (Set to your frontend domain)
CORS_ORIGIN=*

# Database (Optional - currently using in-memory storage)
# MONGODB_URI=your_mongodb_connection_string
```

### 🔧 Package.json Scripts

```json
{
  "scripts": {
    "start": "node src/server.js",
    "dev": "nodemon src/server.js",
    "test": "echo \"No tests yet\""
  }
}
```

### 📦 Dependencies

- **express** - Web framework
- **cors** - Cross-origin requests
- **jsonwebtoken** - JWT tokens
- **twilio** - SMS service
- **dotenv** - Environment variables

## 🌐 API Endpoints

Base URL: `https://your-railway-app.railway.app/api`

### Authentication
- `POST /auth/send-otp` - Send OTP
- `POST /auth/verify-otp` - Verify & Login  
- `POST /auth/signup` - Register
- `POST /auth/logout` - Logout

### Profile
- `GET /profile` - Get profile
- `PUT /profile` - Update profile

### Dashboard  
- `GET /dashboard/stats` - Get stats

## 🔐 Security Features

- **JWT Authentication** - Secure tokens
- **CORS Protection** - Controlled access
- **Environment Variables** - Secure config
- **Input Validation** - Clean data

## 🚀 Performance

- **In-Memory Storage** - Fast response times
- **Lightweight** - Minimal dependencies
- **Stateless** - Horizontally scalable

## 📊 Monitoring

Railway provides built-in:
- **Logs** - Real-time application logs
- **Metrics** - CPU, memory, network usage
- **Uptime** - Service availability
- **Deployments** - Version history

## 🐛 Troubleshooting

### Common Issues

1. **Port Issues**: Railway automatically sets PORT via environment
2. **CORS Errors**: Update CORS_ORIGIN to your frontend domain
3. **Twilio Errors**: Verify account SID and auth token
4. **JWT Errors**: Ensure JWT_SECRET is set

### Debug Mode

Set `NODE_ENV=development` for detailed error logs.

## 📈 Scaling

Railway auto-scales based on traffic. For high-traffic applications:

1. **Add PostgreSQL** - Replace in-memory storage
2. **Add Redis** - For session management  
3. **Load Balancing** - Railway handles automatically
4. **CDN** - For static assets

---

**Deploy Status**: [![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/template/your-template)

**Live Demo**: https://your-railway-app.railway.app