# API Quick Reference - Admin Dashboard

## 🔗 Base URL
```
Production: https://astrologerapp-production.up.railway.app
```

## 🔐 Authentication Header
```javascript
{
  "Authorization": "Bearer YOUR_ADMIN_JWT_TOKEN",
  "Content-Type": "application/json"
}
```

---

## 📋 TICKET MANAGEMENT

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/admin/support/tickets` | Get all tickets with filters |
| `GET` | `/api/admin/support/tickets/:id` | Get ticket details |
| `PATCH` | `/api/admin/support/tickets/:id/assign` | Assign ticket |
| `PATCH` | `/api/admin/support/tickets/:id/status` | Update status |
| `PATCH` | `/api/admin/support/tickets/:id/priority` | Update priority |
| `POST` | `/api/admin/support/tickets/:id/messages` | Add reply/note |
| `POST` | `/api/admin/support/tickets/:id/internal-notes` | Add internal note |
| `POST` | `/api/admin/support/tickets/bulk-action` | Bulk operations |

### Query Parameters for GET /tickets
```javascript
{
  status: 'open' | 'in_progress' | 'waiting_for_user' | 'closed',
  priority: 'Low' | 'Medium' | 'High' | 'Urgent',
  category: 'Account Issues' | 'Calendar Problems' | ...,
  assignedTo: 'admin_id' | 'me',
  search: 'search text',
  page: 1,
  limit: 20,
  sortBy: 'createdAt' | 'priority' | 'status',
  sortOrder: 'asc' | 'desc'
}
```

---

## 📊 STATISTICS

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/admin/support/stats?period=7d` | Get ticket statistics |

**Period options:** `1d` | `7d` | `30d` | `90d` | `all`

---

## 📚 HELP ARTICLES

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/admin/support/articles` | Get all articles |
| `POST` | `/api/admin/support/articles` | Create article |
| `PUT` | `/api/admin/support/articles/:id` | Update article |
| `DELETE` | `/api/admin/support/articles/:id` | Delete article |
| `PATCH` | `/api/admin/support/articles/:id/publish` | Publish/unpublish |

---

## ❓ FAQ MANAGEMENT

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/admin/support/faq` | Get all FAQs |
| `POST` | `/api/admin/support/faq` | Create FAQ |
| `PUT` | `/api/admin/support/faq/:id` | Update FAQ |
| `DELETE` | `/api/admin/support/faq/:id` | Delete FAQ |
| `PATCH` | `/api/admin/support/faq/:id/reorder` | Reorder FAQ |

---

## 🔌 SOCKET.IO EVENTS

### Emit (Send from Admin Dashboard)

```javascript
// Join admin monitor (all new tickets)
socket.emit('admin_join_ticket_monitor');

// Join specific ticket room
socket.emit('join_ticket', { ticketId: 'ticket_id' });

// Leave ticket room
socket.emit('leave_ticket', { ticketId: 'ticket_id' });

// Send typing indicator
socket.emit('ticket:typing', { ticketId: 'ticket_id', isTyping: true });
```

### Listen (Receive in Admin Dashboard)

```javascript
// Admin monitor joined
socket.on('ticket:admin_monitor_joined', (data) => { });

// New ticket created
socket.on('ticket:new_ticket', (data) => { });

// Joined ticket room
socket.on('ticket:joined', (data) => { });

// New message in ticket
socket.on('ticket:new_message', (data) => { });

// Ticket status changed
socket.on('ticket:status_changed', (data) => { });

// Ticket assigned
socket.on('ticket:assigned', (data) => { });

// Ticket priority changed
socket.on('ticket:priority_changed', (data) => { });

// User typing
socket.on('ticket:typing', (data) => { });

// Errors
socket.on('ticket:error', (data) => { });
```

---

## 📝 COMMON REQUEST BODIES

### Assign Ticket
```json
{
  "assignedTo": "admin_id",
  "assignedToName": "Admin Name"
}
```

### Update Status
```json
{
  "status": "in_progress",
  "internalNote": "Optional note"
}
```

### Update Priority
```json
{
  "priority": "High"
}
```

### Add Reply
```json
{
  "message": "Your reply text",
  "isInternal": false,
  "attachments": []
}
```

### Bulk Assign
```json
{
  "action": "assign",
  "ticketIds": ["id1", "id2"],
  "actionData": {
    "assignedTo": "admin_id",
    "assignedToName": "Admin Name"
  }
}
```

### Create Article
```json
{
  "title": "Article Title",
  "content": "Full content...",
  "category": "Category Name",
  "tags": ["tag1", "tag2"],
  "metaDescription": "SEO description",
  "status": "published"
}
```

### Create FAQ
```json
{
  "question": "Question text?",
  "answer": "Answer text...",
  "category": "General",
  "order": 1,
  "isPublished": true
}
```

---

## 📋 REFERENCE DATA

### Ticket Categories
```
Account Issues
Calendar Problems
Consultation Issues
Payment Problems
Technical Support
Feature Request
Bug Report
Other
```

### Priority Levels
```
Low
Medium
High
Urgent
```

### Status Values
```
open
in_progress
waiting_for_user
closed
```

### Article Categories
```
Getting Started
Account Management
Calendar & Scheduling
Consultations
Payments & Earnings
Live Streaming
Technical Issues
Best Practices
Other
```

### FAQ Categories
```
General
Account & Profile
Calendar & Availability
Consultations
Payments
Live Streaming
Technical
Policies
Other
```

---

## ✅ RESPONSE FORMAT

### Success Response
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { /* response data */ }
}
```

### Error Response
```json
{
  "success": false,
  "message": "Error description",
  "error": "Detailed error"
}
```

---

## 🧪 QUICK TEST

```bash
# Get all tickets
curl -X GET "https://astrologerapp-production.up.railway.app/api/admin/support/tickets" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Get statistics
curl -X GET "https://astrologerapp-production.up.railway.app/api/admin/support/stats?period=7d" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Assign ticket
curl -X PATCH "https://astrologerapp-production.up.railway.app/api/admin/support/tickets/TICKET_ID/assign" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"assignedTo":"admin_123","assignedToName":"John Admin"}'
```

---

**Print this as a quick reference while developing! 📌**
