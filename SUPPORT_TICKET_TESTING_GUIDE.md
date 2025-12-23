# Support Ticket System - Quick Testing Guide

## 🧪 Test the Backend APIs

### Prerequisites
- Backend server running on Railway or locally
- Valid astrologer JWT token
- Valid admin JWT token (if testing admin endpoints)

## 📝 Test User Ticket Routes

### 1. Create a Ticket
```bash
curl -X POST https://your-backend-url/api/support/tickets \
  -H "Authorization: Bearer YOUR_ASTROLOGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Cannot update my availability",
    "description": "When I try to add availability for next week, I get a 403 error. I have tried multiple times.",
    "category": "Calendar Problems",
    "priority": "High"
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Support ticket created successfully",
  "data": {
    "ticketNumber": "TKT-20251223-00001",
    "title": "Cannot update my availability",
    "status": "open",
    "priority": "High",
    ...
  }
}
```

### 2. Get My Tickets
```bash
curl -X GET "https://your-backend-url/api/support/tickets?status=open&page=1&limit=20" \
  -H "Authorization: Bearer YOUR_ASTROLOGER_TOKEN"
```

### 3. Get Ticket Details
```bash
curl -X GET "https://your-backend-url/api/support/tickets/TICKET_ID" \
  -H "Authorization: Bearer YOUR_ASTROLOGER_TOKEN"
```

### 4. Add Message to Ticket
```bash
curl -X POST https://your-backend-url/api/support/tickets/TICKET_ID/messages \
  -H "Authorization: Bearer YOUR_ASTROLOGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "I have also noticed that this happens only when I try to set availability for weekends."
  }'
```

### 5. Close Ticket
```bash
curl -X PATCH "https://your-backend-url/api/support/tickets/TICKET_ID/close" \
  -H "Authorization: Bearer YOUR_ASTROLOGER_TOKEN"
```

## 🛠️ Test Admin Ticket Routes

### 1. Get All Tickets (Admin View)
```bash
curl -X GET "https://your-backend-url/api/admin/support/tickets?status=open&priority=High&page=1" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

**Query Parameters:**
- `status`: open, in_progress, waiting_for_user, closed
- `priority`: Low, Medium, High, Urgent
- `category`: Account Issues, Calendar Problems, etc.
- `assignedTo`: admin_id or "me"
- `search`: Search in title/description/ticket number
- `page`, `limit`: Pagination
- `sortBy`, `sortOrder`: Sorting

### 2. Assign Ticket to Admin
```bash
curl -X PATCH "https://your-backend-url/api/admin/support/tickets/TICKET_ID/assign" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "assignedTo": "admin_123",
    "assignedToName": "John Smith"
  }'
```

### 3. Update Ticket Status
```bash
curl -X PATCH "https://your-backend-url/api/admin/support/tickets/TICKET_ID/status" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "status": "in_progress",
    "internalNote": "Working on this issue with dev team"
  }'
```

### 4. Update Ticket Priority
```bash
curl -X PATCH "https://your-backend-url/api/admin/support/tickets/TICKET_ID/priority" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "priority": "Urgent"
  }'
```

### 5. Add Admin Reply
```bash
curl -X POST "https://your-backend-url/api/admin/support/tickets/TICKET_ID/messages" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Thank you for reporting this. We have identified the issue and are working on a fix. This will be resolved in the next update.",
    "isInternal": false
  }'
```

### 6. Add Internal Note (Admin Only)
```bash
curl -X POST "https://your-backend-url/api/admin/support/tickets/TICKET_ID/messages" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Backend team confirmed this is due to the recent rate limiting update. Fix scheduled for v2.1.3.",
    "isInternal": true
  }'
```

### 7. Get Ticket Statistics
```bash
curl -X GET "https://your-backend-url/api/admin/support/stats?period=7d" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

**Period Options:** 1d, 7d, 30d, 90d, all

### 8. Bulk Actions
```bash
curl -X POST "https://your-backend-url/api/admin/support/tickets/bulk-action" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "assign",
    "ticketIds": ["ticket_id_1", "ticket_id_2"],
    "actionData": {
      "assignedTo": "admin_123",
      "assignedToName": "John Smith"
    }
  }'
```

**Bulk Actions:**
- `assign`: Assign multiple tickets
- `update_status`: Update status of multiple tickets
- `update_priority`: Update priority
- `close`: Close multiple tickets

## 📚 Test Help Articles

### 1. Get Published Articles
```bash
curl -X GET "https://your-backend-url/api/support/articles?category=Calendar%20%26%20Scheduling" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 2. Search Articles
```bash
curl -X GET "https://your-backend-url/api/support/articles/search?q=availability&limit=10" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 3. Mark Article as Helpful
```bash
curl -X POST "https://your-backend-url/api/support/articles/ARTICLE_ID/helpful" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "isHelpful": true
  }'
```

### 4. Create Article (Admin)
```bash
curl -X POST "https://your-backend-url/api/admin/support/articles" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "How to Set Your Availability",
    "content": "Follow these steps to set your availability...",
    "category": "Calendar & Scheduling",
    "tags": ["calendar", "availability", "schedule"],
    "metaDescription": "Learn how to manage your availability calendar",
    "status": "published"
  }'
```

## ❓ Test FAQ

### 1. Get All FAQs
```bash
curl -X GET "https://your-backend-url/api/support/faq?category=Calendar%20%26%20Availability" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 2. Create FAQ (Admin)
```bash
curl -X POST "https://your-backend-url/api/admin/support/faq" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "question": "How do I block dates for holidays?",
    "answer": "Navigate to Calendar > Holidays, then tap the + button to add a new holiday.",
    "category": "Calendar & Availability",
    "order": 1,
    "isPublished": true
  }'
```

## 🔌 Test Socket.IO Real-Time

### JavaScript Client Example
```javascript
import io from 'socket.io-client';

const socket = io('https://your-backend-url', {
  auth: {
    token: 'YOUR_ASTROLOGER_TOKEN'
  }
});

// Join ticket room
socket.emit('join_ticket', { ticketId: 'TICKET_ID' });

// Listen for new messages
socket.on('ticket:new_message', (data) => {
  console.log('New message:', data);
});

// Listen for status changes
socket.on('ticket:status_changed', (data) => {
  console.log('Status changed:', data);
});

// Send typing indicator
socket.emit('ticket:typing', { ticketId: 'TICKET_ID', isTyping: true });

// Admin: Join ticket monitor
socket.emit('admin_join_ticket_monitor');

// Admin: Listen for new tickets
socket.on('ticket:new_ticket', (data) => {
  console.log('New ticket created:', data);
});
```

## 🎯 Common Test Scenarios

### Scenario 1: User Reports Issue → Admin Resolves
1. User creates ticket with "Calendar Problems" category
2. User adds initial description
3. Admin gets notification (via Socket.IO monitor)
4. Admin assigns ticket to themselves
5. Admin replies with solution
6. User confirms issue is resolved
7. Admin or User closes ticket
8. System records resolution time

### Scenario 2: Multiple Users, Priority Management
1. User A creates High priority ticket
2. User B creates Urgent priority ticket
3. Admin filters tickets by priority
4. Admin assigns Urgent ticket to Admin 1
5. Admin assigns High ticket to Admin 2
6. Both admins work simultaneously
7. Admin uses bulk action to close multiple resolved tickets

### Scenario 3: Knowledge Base Usage
1. User searches for "availability" in help articles
2. User reads article on calendar management
3. User marks article as helpful
4. If not satisfied, user creates support ticket
5. Admin sees pattern in tickets, creates new FAQ
6. Future users find answer in FAQ, reducing ticket volume

## 🐛 Troubleshooting

### "Ticket not found"
- Verify ticket ID is correct MongoDB ObjectId
- Check if user owns the ticket (users can only access their own tickets)

### "Forbidden - Not your ticket"
- User is trying to access another user's ticket
- Ensure authentication token is valid

### "Admin only"
- Endpoint requires admin authentication
- Verify admin token is being used

### Socket.IO not connecting
- Check CORS settings in backend
- Verify auth token is passed in handshake
- Check Railway logs for Socket.IO initialization

## 📊 Expected Metrics

After implementation, you should see:
- Average response time (minutes until first admin reply)
- Average resolution time (minutes until ticket closed)
- User satisfaction ratings (1-5 stars)
- Ticket volume by category
- Admin performance metrics
- Popular help articles

## 🚀 Next Steps

1. Test all endpoints with Postman or curl
2. Verify Socket.IO real-time updates
3. Integrate Flutter app with these APIs
4. Build admin dashboard UI for ticket management
5. Set up FCM notifications for new tickets/messages
6. Monitor metrics in production

## 📝 Notes

- All routes require authentication (except public help/FAQ browsing)
- Attachments require multipart/form-data upload
- Socket.IO requires valid JWT in auth handshake
- Admin routes use separate `adminAuth` middleware
- Ticket numbers auto-increment daily (TKT-YYYYMMDD-#####)
