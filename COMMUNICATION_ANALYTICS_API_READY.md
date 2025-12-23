# Communication Analytics APIs - Ready for Admin Dashboard

## ✅ Status: DEPLOYED TO RAILWAY

The backend Communication Analytics API endpoints are now **live in production** and ready for the admin dashboard to connect.

---

## 🔗 Base URL
```
https://astrologerapp-production.up.railway.app/api
```

## 🔐 Authentication
All endpoints require admin authentication:

**Header:**
```
x-admin-key: admin123
```

---

## 📊 Available Endpoints

### 1. Overview Statistics
```http
GET /api/admin/communications/stats?period=7d

Response:
{
  "success": true,
  "data": {
    "totalMessages": 1250,
    "totalVoiceCalls": 450,
    "totalVideoCalls": 320,
    "totalCommunications": 2020,
    "avgCallDuration": 18.5,
    "activeConversations": 180,
    "completedCalls": 680,
    "missedCalls": 90,
    "rejectedCalls": 40
  }
}
```

### 2. Daily Trends
```http
GET /api/admin/communications/trends?period=7d

Response:
{
  "success": true,
  "data": [
    {
      "date": "2025-12-17",
      "messages": 45,
      "voiceCalls": 12,
      "videoCalls": 8,
      "total": 65
    },
    {
      "date": "2025-12-18",
      "messages": 52,
      "voiceCalls": 15,
      "videoCalls": 10,
      "total": 77
    }
    // ... more days
  ]
}
```

### 3. By Astrologer
```http
GET /api/admin/communications/astrologers?period=7d

Response:
{
  "success": true,
  "data": [
    {
      "astrologerId": "6935056d55fcb5a4615f8e8d",
      "astrologerName": "Guru",
      "messages": 150,
      "voiceCalls": 45,
      "videoCalls": 30,
      "total": 225
    }
    // ... more astrologers, sorted by total desc
  ]
}
```

### 4. Call Duration Stats
```http
GET /api/admin/communications/call-duration?period=7d

Response:
{
  "success": true,
  "data": [
    {
      "astrologerId": "6935056d55fcb5a4615f8e8d",
      "astrologerName": "Guru",
      "avgVoiceCallDuration": 18.5,
      "avgVideoCallDuration": 25.3,
      "totalVoiceCalls": 45,
      "totalVideoCalls": 30
    }
    // ... more astrologers
  ]
}
```

### 5. Peak Hours (0-23)
```http
GET /api/admin/communications/peak-hours?period=7d

Response:
{
  "success": true,
  "data": [
    {
      "hour": 0,
      "messages": 5,
      "voiceCalls": 1,
      "videoCalls": 0,
      "total": 6
    },
    {
      "hour": 1,
      "messages": 3,
      "voiceCalls": 0,
      "videoCalls": 0,
      "total": 3
    }
    // ... hours 0-23
  ]
}
```

### 6. Call Success Rates
```http
GET /api/admin/communications/success-rates?period=7d

Response:
{
  "success": true,
  "data": [
    {
      "date": "2025-12-17",
      "completedRate": 85.5,
      "missedRate": 10.2,
      "rejectedRate": 4.3
    }
    // ... more days
  ]
}
```

---

## 🎯 Period Parameter

All endpoints support the `period` query parameter:

- `1d` - Last 1 day
- `7d` - Last 7 days (default)
- `30d` - Last 30 days
- `90d` - Last 90 days
- `1y` - Last 1 year

---

## 📋 Data Scope

**Includes:**
- ✅ Admin ↔ Astrologer communications
- ✅ User ↔ Astrologer communications

**Excludes:**
- ❌ Admin ↔ Admin
- ❌ Astrologer ↔ Astrologer

**Data Sources:**
- **Messages:** `DirectMessage` collection (excludes `call_log` messages and deleted messages)
- **Calls:** `Call` collection (voice and video)

**Call Status Mapping:**
- **Completed:** `status='ended'` OR `endReason='completed'`
- **Missed:** `status='missed'` OR `endReason IN ['missed','timeout']`
- **Rejected:** `status='rejected'` OR `endReason='declined'`

---

## 🧪 How to Test

### Using Postman/Insomnia:

**1. Create a new request:**
```
GET https://astrologerapp-production.up.railway.app/api/admin/communications/stats?period=7d
```

**2. Add header:**
```
x-admin-key: admin123
```

**3. Send request**

You should get a `200 OK` with real data from the database.

### Using JavaScript (Browser Console):

```javascript
fetch('https://astrologerapp-production.up.railway.app/api/admin/communications/stats?period=7d', {
  headers: {
    'x-admin-key': 'admin123',
    'Content-Type': 'application/json'
  }
})
.then(res => res.json())
.then(data => console.log(data));
```

---

## 📁 What Admin Dashboard Team Needs to Change

**File:** `admin_dashboard/src/api/communication.ts`

**Replace all dummy generator functions with real API calls:**

```typescript
import apiClient from './client';

export const communicationApi = {
  getCommunicationStats: async (period = '7d') => {
    const response = await apiClient.get('/admin/communications/stats', {
      params: { period },
    });
    return response.data;
  },

  getCommunicationTrends: async (period = '7d') => {
    const response = await apiClient.get('/admin/communications/trends', {
      params: { period },
    });
    return response.data;
  },

  getAstrologerCommunicationStats: async (period = '7d') => {
    const response = await apiClient.get('/admin/communications/astrologers', {
      params: { period },
    });
    return response.data;
  },

  getCallDurationStats: async (period = '7d') => {
    const response = await apiClient.get('/admin/communications/call-duration', {
      params: { period },
    });
    return response.data;
  },

  getPeakHours: async (period = '7d') => {
    const response = await apiClient.get('/admin/communications/peak-hours', {
      params: { period },
    });
    return response.data;
  },

  getCallSuccessRateTrends: async (period = '7d') => {
    const response = await apiClient.get('/admin/communications/success-rates', {
      params: { period },
    });
    return response.data;
  },
};
```

**Remove these dummy functions:**
- `generateDummyStats`
- `generateDummyTrends`
- `generateDummyAstrologerStats`
- `generateDummyCallDurationStats`
- `generateDummyPeakHours`
- `generateDummySuccessRateTrends`

That's it! After this change, all 6 charts will show real data from production database.

---

## ✅ Verification Checklist

- [ ] Backend endpoints deployed to Railway
- [ ] Admin dashboard API file updated
- [ ] Test with Postman/browser console
- [ ] Verify charts show real data
- [ ] Check that empty data doesn't break UI (show "No data" message)

---

## 🚀 Backend Details

**Route File:** `backend/src/routes/adminCommunications.js`
**Registered in:** `backend/src/server.js` at `/api/admin/communications`
**Authentication:** `backend/src/middleware/adminAuth.js`
**Models Used:** `DirectMessage`, `Call`, `Astrologer`

**Features:**
- MongoDB aggregations for efficient queries
- Missing dates/hours automatically filled (charts won't break)
- Astrologer names auto-looked up
- Call duration converted from seconds to minutes
- Success rates computed as percentages

---

**Backend is 100% ready. Admin dashboard team can connect now! 🎉**
