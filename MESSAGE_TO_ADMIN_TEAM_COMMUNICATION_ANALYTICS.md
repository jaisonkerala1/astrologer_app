# Communication Analytics APIs Ready! 🎉

Hi Admin Dashboard Team,

The backend **Communication Analytics APIs are now live** on Railway and ready for integration!

---

## 📋 Your Task (15 minutes)

Replace dummy data generators in your Communication Analytics with real API calls.

**File to edit:** `admin_dashboard/src/api/communication.ts`

---

## 🔧 Quick Fix

**Replace the entire `communicationApi` export with this:**

```typescript
import apiClient from './client';

export const communicationApi = {
  // Get overview statistics
  getCommunicationStats: async (period: CommunicationPeriod = '7d'): Promise<ApiResponse<CommunicationStats>> => {
    const response = await apiClient.get('/admin/communications/stats', {
      params: { period },
    });
    return response.data;
  },

  // Get communication trends over time
  getCommunicationTrends: async (period: CommunicationPeriod = '7d'): Promise<ApiResponse<CommunicationTrend[]>> => {
    const response = await apiClient.get('/admin/communications/trends', {
      params: { period },
    });
    return response.data;
  },

  // Get communication stats by astrologer
  getAstrologerCommunicationStats: async (period: CommunicationPeriod = '7d'): Promise<ApiResponse<AstrologerCommunicationStats[]>> => {
    const response = await apiClient.get('/admin/communications/astrologers', {
      params: { period },
    });
    return response.data;
  },

  // Get call duration statistics
  getCallDurationStats: async (period: CommunicationPeriod = '7d'): Promise<ApiResponse<CallDurationStats[]>> => {
    const response = await apiClient.get('/admin/communications/call-duration', {
      params: { period },
    });
    return response.data;
  },

  // Get peak hours data
  getPeakHours: async (period: CommunicationPeriod = '7d'): Promise<ApiResponse<PeakHoursData[]>> => {
    const response = await apiClient.get('/admin/communications/peak-hours', {
      params: { period },
    });
    return response.data;
  },

  // Get call success rate trends
  getCallSuccessRateTrends: async (period: CommunicationPeriod = '7d'): Promise<ApiResponse<CallSuccessRateTrend[]>> => {
    const response = await apiClient.get('/admin/communications/success-rates', {
      params: { period },
    });
    return response.data;
  },
};
```

**Then delete all these dummy generator functions:**
- `generateDummyStats`
- `generateDummyTrends`
- `generateDummyAstrologerStats`
- `generateDummyCallDurationStats`
- `generateDummyPeakHours`
- `generateDummySuccessRateTrends`

---

## ✅ What Backend Provides

**6 Real-time Analytics Endpoints:**

1. `/api/admin/communications/stats` - Overview (total messages, calls, avg duration, etc.)
2. `/api/admin/communications/trends` - Daily time-series data
3. `/api/admin/communications/astrologers` - Volume by astrologer
4. `/api/admin/communications/call-duration` - Average duration per astrologer
5. `/api/admin/communications/peak-hours` - Hourly breakdown (0-23)
6. `/api/admin/communications/success-rates` - Call success rate trends

**All endpoints:**
- Support `period=1d|7d|30d|90d|1y` parameter (defaults to `7d`)
- Return aggregated real data from `DirectMessage` and `Call` collections
- Include both admin↔astrologer AND user↔astrologer communications
- Protected with admin authentication (`x-admin-key` header)

---

## 🧪 Test It First

**Using browser console:**
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

**Expected response:**
```json
{
  "success": true,
  "data": {
    "totalMessages": <real number>,
    "totalVoiceCalls": <real number>,
    ...
  }
}
```

If you get `401` or `403` → admin key is wrong or missing.

---

## 📊 Response Format

All endpoints return the same structure:

**Success:**
```json
{
  "success": true,
  "data": { /* your data */ }
}
```

**Error:**
```json
{
  "success": false,
  "message": "Error description",
  "error": "Details"
}
```

---

## 📝 What Happens After Integration

Once you update `communication.ts` and deploy:

1. **All 6 charts will show real data** instead of random numbers
2. **Data will update when period changes** (1d, 7d, 30d, etc.)
3. **Empty states work correctly** (backend fills missing dates/hours with zeros)
4. **Astrologer names are real** (fetched from database)

---

## 🚀 Deployment Steps

1. Edit `admin_dashboard/src/api/communication.ts` (see code above)
2. Test locally (if you have a dev env)
3. Commit and deploy to production
4. Verify charts populate with real data

---

## 📁 Additional Resources

- Full API documentation: `COMMUNICATION_ANALYTICS_API_READY.md`
- Test script (Node.js): `backend/test-communication-analytics.js`

---

**Backend is ready. Time to connect the dashboard! 🚀**

Any questions? Let me know!

— Backend Team
