# Admin Dashboard - Support Ticket System Integration Guide

## 📋 Overview

The backend team has **fully implemented** the Support Ticket System API with comprehensive endpoints for managing user tickets, help articles, and FAQs. This document provides all the information your admin dashboard development team needs to integrate the ticket management system.

---

## 🎯 What Has Been Implemented

### Backend Components
✅ **4 Database Models** - SupportTicket, TicketMessage, HelpArticle, FAQ  
✅ **35+ API Endpoints** - Complete CRUD operations  
✅ **Real-time Socket.IO** - Live updates for tickets and messages  
✅ **Authentication** - Admin-only routes secured with JWT  
✅ **File Uploads** - Support for attachments (images, PDFs, documents)  
✅ **Advanced Features** - Search, filters, pagination, statistics, bulk actions  

### Production Status
- **Deployed to Railway**: ✅ Live and operational
- **Database**: MongoDB with indexes optimized for performance
- **Real-time**: Socket.IO configured and ready
- **Documentation**: Complete API documentation provided below

---

## 🔗 Base URL

```
Production: https://astrologerapp-production.up.railway.app
Development: http://localhost:7566
```

---

## 🔐 Authentication

All admin endpoints require JWT authentication.

### Headers Required
```javascript
{
  "Authorization": "Bearer YOUR_ADMIN_JWT_TOKEN",
  "Content-Type": "application/json"
}
```

### Admin Authentication Endpoint
```http
POST /api/auth/admin/login
Content-Type: application/json

{
  "email": "admin@example.com",
  "password": "admin_password"
}

Response:
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "admin_id",
    "name": "Admin Name",
    "email": "admin@example.com",
    "role": "admin"
  }
}
```

---

## 📊 API Endpoints for Admin Dashboard

### 1. Ticket Management

#### 1.1 Get All Tickets (with filters & search)
```http
GET /api/admin/support/tickets

Query Parameters:
  - status: open | in_progress | waiting_for_user | closed
  - priority: Low | Medium | High | Urgent
  - category: Account Issues | Calendar Problems | Consultation Issues | Payment Problems | Technical Support | Feature Request | Bug Report | Other
  - assignedTo: admin_id (or "me" for current admin's tickets)
  - search: Search in title, description, ticket number, user name
  - page: Page number (default: 1)
  - limit: Items per page (default: 20)
  - sortBy: Field to sort by (default: createdAt)
  - sortOrder: asc | desc (default: desc)

Example Request:
GET /api/admin/support/tickets?status=open&priority=High&page=1&limit=20

Response:
{
  "success": true,
  "data": {
    "tickets": [
      {
        "id": "ticket_id",
        "ticketNumber": "TKT-20251223-00001",
        "title": "Cannot update my availability",
        "description": "When I try to add availability...",
        "category": "Calendar Problems",
        "priority": "High",
        "status": "open",
        "userId": "user_id",
        "userName": "John Doe",
        "userEmail": "john@example.com",
        "assignedTo": null,
        "assignedToName": null,
        "messagesCount": 3,
        "createdAt": "2025-12-23T10:30:00Z",
        "updatedAt": "2025-12-23T12:45:00Z"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 5,
      "totalItems": 97,
      "itemsPerPage": 20
    },
    "stats": {
      "totalTickets": 450,
      "openTickets": 97,
      "inProgressTickets": 45,
      "closedToday": 12,
      "avgResponseTime": 45,
      "avgResolutionTime": 180,
      "byPriority": {
        "Low": 120,
        "Medium": 180,
        "High": 100,
        "Urgent": 50
      },
      "byCategory": {
        "Calendar Problems": 150,
        "Payment Problems": 100,
        "Technical Support": 80
      }
    }
  }
}
```

#### 1.2 Get Ticket Details (Admin View)
```http
GET /api/admin/support/tickets/:ticketId

Response:
{
  "success": true,
  "data": {
    "id": "ticket_id",
    "ticketNumber": "TKT-20251223-00001",
    "title": "Cannot update my availability",
    "description": "Full description...",
    "category": "Calendar Problems",
    "priority": "High",
    "status": "in_progress",
    "userId": "user_id",
    "userName": "John Doe",
    "userEmail": "john@example.com",
    "userPhone": "+1234567890",
    "assignedTo": "admin_123",
    "assignedToName": "Sarah Admin",
    "assignedAt": "2025-12-23T11:00:00Z",
    "messages": [
      {
        "id": "msg_id",
        "senderId": "user_id",
        "senderName": "John Doe",
        "senderType": "user",
        "message": "Initial message from user",
        "isInternal": false,
        "isSystemMessage": false,
        "createdAt": "2025-12-23T10:30:00Z"
      },
      {
        "id": "msg_id_2",
        "senderId": "admin_123",
        "senderName": "Sarah Admin",
        "senderType": "admin",
        "message": "We're looking into this",
        "isInternal": false,
        "isSystemMessage": false,
        "createdAt": "2025-12-23T11:05:00Z"
      },
      {
        "id": "msg_id_3",
        "senderId": "admin_123",
        "senderName": "Sarah Admin",
        "senderType": "admin",
        "message": "Internal note: Bug confirmed in v2.1.2",
        "isInternal": true,
        "isSystemMessage": false,
        "createdAt": "2025-12-23T11:10:00Z"
      }
    ],
    "attachments": [],
    "internalNotes": "[2025-12-23] Admin note: Escalated to dev team",
    "responseTime": 35,
    "resolutionTime": null,
    "userHistory": {
      "totalTickets": 5,
      "closedTickets": 4,
      "avgRating": 4.5
    },
    "createdAt": "2025-12-23T10:30:00Z",
    "updatedAt": "2025-12-23T11:10:00Z"
  }
}
```

#### 1.3 Assign Ticket to Admin
```http
PATCH /api/admin/support/tickets/:ticketId/assign
Content-Type: application/json

Body:
{
  "assignedTo": "admin_id",
  "assignedToName": "Admin Full Name"
}

// To unassign:
{
  "assignedTo": null,
  "assignedToName": null
}

Response:
{
  "success": true,
  "message": "Ticket assignment updated",
  "data": {
    "ticketId": "ticket_id",
    "assignedTo": "admin_id",
    "assignedToName": "Admin Full Name",
    "assignedAt": "2025-12-23T11:00:00Z",
    "status": "in_progress"
  }
}
```

#### 1.4 Update Ticket Status
```http
PATCH /api/admin/support/tickets/:ticketId/status
Content-Type: application/json

Body:
{
  "status": "in_progress",
  "internalNote": "Optional internal note about status change"
}

Status values: "open" | "in_progress" | "waiting_for_user" | "closed"

Response:
{
  "success": true,
  "message": "Ticket status updated",
  "data": {
    "ticketId": "ticket_id",
    "status": "in_progress",
    "updatedAt": "2025-12-23T11:15:00Z"
  }
}
```

#### 1.5 Update Ticket Priority
```http
PATCH /api/admin/support/tickets/:ticketId/priority
Content-Type: application/json

Body:
{
  "priority": "Urgent"
}

Priority values: "Low" | "Medium" | "High" | "Urgent"

Response:
{
  "success": true,
  "message": "Ticket priority updated",
  "data": {
    "ticketId": "ticket_id",
    "priority": "Urgent"
  }
}
```

#### 1.6 Add Admin Reply
```http
POST /api/admin/support/tickets/:ticketId/messages
Content-Type: application/json

Body:
{
  "message": "Your reply to the user",
  "isInternal": false,
  "attachments": [
    {
      "url": "/uploads/tickets/file.pdf",
      "filename": "solution.pdf",
      "size": 245760
    }
  ]
}

// For internal admin note:
{
  "message": "Internal note visible only to admins",
  "isInternal": true
}

Response:
{
  "success": true,
  "message": "Reply sent successfully",
  "data": {
    "id": "message_id",
    "ticketId": "ticket_id",
    "senderId": "admin_id",
    "senderName": "Admin Name",
    "senderType": "admin",
    "message": "Your reply",
    "isInternal": false,
    "createdAt": "2025-12-23T11:20:00Z"
  }
}
```

#### 1.7 Add Internal Note
```http
POST /api/admin/support/tickets/:ticketId/internal-notes
Content-Type: application/json

Body:
{
  "note": "Internal note for admins only"
}

Response:
{
  "success": true,
  "message": "Internal note added",
  "data": {
    "ticketId": "ticket_id",
    "internalNotes": "...[2025-12-23] Admin: Internal note for admins only"
  }
}
```

#### 1.8 Bulk Actions
```http
POST /api/admin/support/tickets/bulk-action
Content-Type: application/json

// Bulk Assign:
{
  "action": "assign",
  "ticketIds": ["ticket_id_1", "ticket_id_2", "ticket_id_3"],
  "actionData": {
    "assignedTo": "admin_id",
    "assignedToName": "Admin Name"
  }
}

// Bulk Update Status:
{
  "action": "update_status",
  "ticketIds": ["ticket_id_1", "ticket_id_2"],
  "actionData": {
    "status": "closed"
  }
}

// Bulk Update Priority:
{
  "action": "update_priority",
  "ticketIds": ["ticket_id_1", "ticket_id_2"],
  "actionData": {
    "priority": "High"
  }
}

// Bulk Close:
{
  "action": "close",
  "ticketIds": ["ticket_id_1", "ticket_id_2", "ticket_id_3"]
}

Response:
{
  "success": true,
  "message": "3 tickets assigned",
  "data": {
    "modifiedCount": 3
  }
}
```

### 2. Statistics & Analytics

#### 2.1 Get Ticket Statistics
```http
GET /api/admin/support/stats?period=7d

Query Parameters:
  - period: 1d | 7d | 30d | 90d | all (default: 7d)

Response:
{
  "success": true,
  "data": {
    "overview": {
      "totalTickets": 156,
      "openTickets": 45,
      "avgResponseTime": 42,
      "avgResolutionTime": 180,
      "satisfactionRate": 4.3
    },
    "trends": [
      {
        "date": "2025-12-17",
        "opened": 12,
        "closed": 8,
        "avgResponseTime": 38
      },
      {
        "date": "2025-12-18",
        "opened": 15,
        "closed": 10,
        "avgResponseTime": 45
      }
    ],
    "topCategories": [
      {
        "category": "Calendar Problems",
        "count": 45
      },
      {
        "category": "Payment Problems",
        "count": 32
      }
    ],
    "topAdmins": [
      {
        "adminId": "admin_123",
        "name": "Sarah Admin",
        "ticketsResolved": 28,
        "avgResolutionTime": 150
      }
    ]
  }
}
```

### 3. Help Articles Management

#### 3.1 Get All Articles (Admin View)
```http
GET /api/admin/support/articles?status=published&page=1&limit=50

Query Parameters:
  - status: draft | published | archived
  - category: Category name
  - page, limit: Pagination

Response:
{
  "success": true,
  "data": {
    "articles": [
      {
        "id": "article_id",
        "title": "How to Set Your Availability",
        "content": "Full article content...",
        "category": "Calendar & Scheduling",
        "tags": ["calendar", "availability"],
        "slug": "how-to-set-your-availability",
        "status": "published",
        "viewCount": 245,
        "helpfulCount": 32,
        "notHelpfulCount": 3,
        "authorName": "Admin Name",
        "createdAt": "2025-12-01T10:00:00Z"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 3,
      "totalItems": 45
    }
  }
}
```

#### 3.2 Create Help Article
```http
POST /api/admin/support/articles
Content-Type: application/json

Body:
{
  "title": "How to Update Your Profile",
  "content": "Full article content in HTML or Markdown...",
  "category": "Account Management",
  "tags": ["profile", "account", "settings"],
  "metaDescription": "Learn how to update your profile information",
  "status": "draft"
}

Status values: "draft" | "published" | "archived"

Response:
{
  "success": true,
  "message": "Article created successfully",
  "data": {
    "id": "article_id",
    "title": "How to Update Your Profile",
    "slug": "how-to-update-your-profile",
    "status": "draft",
    "createdAt": "2025-12-23T11:30:00Z"
  }
}
```

#### 3.3 Update Help Article
```http
PUT /api/admin/support/articles/:articleId
Content-Type: application/json

Body:
{
  "title": "Updated Title",
  "content": "Updated content...",
  "category": "Account Management",
  "tags": ["updated", "tags"],
  "metaDescription": "Updated description",
  "status": "published"
}

Response:
{
  "success": true,
  "message": "Article updated successfully",
  "data": { /* updated article */ }
}
```

#### 3.4 Delete Help Article
```http
DELETE /api/admin/support/articles/:articleId

Response:
{
  "success": true,
  "message": "Article deleted successfully"
}
```

#### 3.5 Publish/Unpublish Article
```http
PATCH /api/admin/support/articles/:articleId/publish
Content-Type: application/json

Body:
{
  "publish": true
}

Response:
{
  "success": true,
  "message": "Article published successfully",
  "data": { /* updated article */ }
}
```

### 4. FAQ Management

#### 4.1 Get All FAQs (Admin View)
```http
GET /api/admin/support/faq?category=General

Query Parameters:
  - category: FAQ category
  - isPublished: true | false

Response:
{
  "success": true,
  "data": [
    {
      "id": "faq_id",
      "question": "How do I reset my password?",
      "answer": "To reset your password...",
      "category": "Account & Profile",
      "order": 1,
      "isPublished": true,
      "helpfulCount": 45,
      "notHelpfulCount": 2,
      "viewCount": 312,
      "createdAt": "2025-12-01T10:00:00Z"
    }
  ]
}
```

#### 4.2 Create FAQ
```http
POST /api/admin/support/faq
Content-Type: application/json

Body:
{
  "question": "How do I block dates for holidays?",
  "answer": "Navigate to Calendar > Holidays, then tap the + button...",
  "category": "Calendar & Availability",
  "order": 1,
  "isPublished": true
}

Response:
{
  "success": true,
  "message": "FAQ created successfully",
  "data": { /* created FAQ */ }
}
```

#### 4.3 Update FAQ
```http
PUT /api/admin/support/faq/:faqId
Content-Type: application/json

Body:
{
  "question": "Updated question?",
  "answer": "Updated answer...",
  "category": "General",
  "order": 2,
  "isPublished": true
}

Response:
{
  "success": true,
  "message": "FAQ updated successfully",
  "data": { /* updated FAQ */ }
}
```

#### 4.4 Delete FAQ
```http
DELETE /api/admin/support/faq/:faqId

Response:
{
  "success": true,
  "message": "FAQ deleted successfully"
}
```

#### 4.5 Reorder FAQ
```http
PATCH /api/admin/support/faq/:faqId/reorder
Content-Type: application/json

Body:
{
  "order": 5
}

Response:
{
  "success": true,
  "message": "FAQ order updated",
  "data": {
    "id": "faq_id",
    "order": 5
  }
}
```

### 5. Reference Data

#### 5.1 Get Categories
```http
GET /api/support/categories

Response:
{
  "success": true,
  "data": {
    "articleCategories": [
      "Getting Started",
      "Account Management",
      "Calendar & Scheduling",
      "Consultations",
      "Payments & Earnings",
      "Live Streaming",
      "Technical Issues",
      "Best Practices",
      "Other"
    ],
    "faqCategories": [
      "General",
      "Account & Profile",
      "Calendar & Availability",
      "Consultations",
      "Payments",
      "Live Streaming",
      "Technical",
      "Policies",
      "Other"
    ]
  }
}
```

---

## 🔌 Real-Time Updates (Socket.IO)

### Socket.IO Connection

```javascript
import io from 'socket.io-client';

const socket = io('https://astrologerapp-production.up.railway.app', {
  auth: {
    token: 'ADMIN_JWT_TOKEN'
  },
  transports: ['websocket', 'polling']
});

// Connection established
socket.on('connected', (data) => {
  console.log('Connected to Socket.IO:', data);
});

// Join admin ticket monitor (receives all new tickets)
socket.emit('admin_join_ticket_monitor');

socket.on('ticket:admin_monitor_joined', (data) => {
  console.log('Joined admin ticket monitor:', data);
});

// Listen for new tickets
socket.on('ticket:new_ticket', (data) => {
  console.log('New ticket created:', data.ticket);
  // Update UI with new ticket
});

// Join specific ticket room
socket.emit('join_ticket', { ticketId: 'ticket_id' });

socket.on('ticket:joined', (data) => {
  console.log('Joined ticket room:', data);
});

// Listen for new messages in ticket
socket.on('ticket:new_message', (data) => {
  console.log('New message:', data.message);
  // Update message list in UI
});

// Listen for status changes
socket.on('ticket:status_changed', (data) => {
  console.log('Status changed:', data);
  // Update ticket status in UI
});

// Listen for assignments
socket.on('ticket:assigned', (data) => {
  console.log('Ticket assigned:', data);
  // Update ticket assignment in UI
});

// Listen for priority changes
socket.on('ticket:priority_changed', (data) => {
  console.log('Priority changed:', data);
  // Update ticket priority in UI
});

// Listen for user typing
socket.on('ticket:typing', (data) => {
  console.log(`${data.userName} is typing...`);
  // Show typing indicator
});

// Send typing indicator
socket.emit('ticket:typing', {
  ticketId: 'ticket_id',
  isTyping: true
});

// Leave ticket room
socket.emit('leave_ticket', { ticketId: 'ticket_id' });

// Handle errors
socket.on('ticket:error', (data) => {
  console.error('Socket error:', data.message);
});
```

---

## 🎨 UI Components to Build

### 1. Ticket List View
**Components needed:**
- Ticket table/list with columns: Ticket #, Title, Category, Priority, Status, Assigned To, Created Date
- Filter sidebar: Status, Priority, Category, Assigned To
- Search bar (searches title, description, ticket number, user name)
- Pagination controls
- Bulk action toolbar (select multiple tickets for bulk operations)
- Sort controls (by date, priority, status)

**Data source:** `GET /api/admin/support/tickets`

### 2. Ticket Detail View
**Components needed:**
- Ticket header: Ticket #, Status badge, Priority badge, Created date
- User information card: Name, Email, Phone, Ticket history
- Ticket actions: Assign, Change Status, Change Priority, Close
- Message thread: Display all messages (user + admin + system)
- Admin reply form: Text area, attachment upload, "Send as internal note" checkbox
- Internal notes section (collapsed by default, admin-only)
- Ticket metrics: Response time, Resolution time

**Data source:** `GET /api/admin/support/tickets/:id`

### 3. Dashboard/Statistics View
**Components needed:**
- Overview cards: Total Tickets, Open Tickets, Avg Response Time, Avg Resolution Time, Satisfaction Rate
- Trend chart: Tickets opened/closed over time
- Category pie chart: Tickets by category
- Admin performance table: Top admins, tickets resolved, avg resolution time

**Data source:** `GET /api/admin/support/stats`

### 4. Help Articles Management
**Components needed:**
- Article list table: Title, Category, Status, Views, Helpful/Not Helpful ratio
- Rich text editor for creating/editing articles
- Category selector, tags input, slug field
- Publish/Unpublish toggle
- Preview modal

**Data sources:**
- List: `GET /api/admin/support/articles`
- Create: `POST /api/admin/support/articles`
- Update: `PUT /api/admin/support/articles/:id`

### 5. FAQ Management
**Components needed:**
- FAQ list grouped by category
- Drag-and-drop reordering within categories
- Add/Edit FAQ form (question, answer, category)
- Publish/Unpublish toggle
- Helpful/Not Helpful metrics display

**Data sources:**
- List: `GET /api/admin/support/faq`
- Create: `POST /api/admin/support/faq`
- Update: `PUT /api/admin/support/faq/:id`

---

## 📋 Recommended Technology Stack

**Frontend Framework:**
- React.js or Next.js
- TypeScript (recommended)

**State Management:**
- Redux Toolkit with RTK Query (API calls)
- Redux Toolkit with Saga (if preferred)
- Or React Context + React Query

**UI Library:**
- Material-UI (MUI)
- Ant Design
- Chakra UI
- Or custom Tailwind CSS

**Real-time:**
- socket.io-client

**Rich Text Editor (for articles):**
- TinyMCE
- Quill
- Draft.js

**Charts:**
- Recharts
- Chart.js
- ApexCharts

---

## 🚀 Implementation Steps

### Phase 1: Core Ticket Management (Week 1)
1. Set up project and authentication
2. Implement ticket list view with filters
3. Implement ticket detail view
4. Add ticket assignment functionality
5. Add status/priority update functionality

### Phase 2: Messaging & Real-time (Week 2)
1. Implement message thread display
2. Add admin reply functionality
3. Integrate Socket.IO for real-time updates
4. Add typing indicators
5. Implement file upload for attachments

### Phase 3: Analytics & Bulk Actions (Week 3)
1. Create statistics dashboard
2. Add charts for trends and categories
3. Implement bulk actions (assign, close, update)
4. Add search functionality
5. Optimize performance and pagination

### Phase 4: Knowledge Base (Week 4)
1. Implement help articles management
2. Add rich text editor
3. Create FAQ management interface
4. Add drag-and-drop reordering
5. Implement article preview

### Phase 5: Polish & Testing (Week 5)
1. Add loading states and error handling
2. Implement responsive design
3. Add keyboard shortcuts
4. Performance optimization
5. Testing and bug fixes

---

## 🧪 Testing the APIs

Use the provided `SUPPORT_TICKET_TESTING_GUIDE.md` for detailed testing instructions with cURL examples.

**Recommended Tools:**
- Postman (create a collection)
- Insomnia
- Thunder Client (VS Code extension)

---

## 📞 Support & Questions

If you encounter any issues or need clarifications:

1. **Backend Documentation**: Refer to `SUPPORT_TICKET_SYSTEM_IMPLEMENTATION.md`
2. **Testing Guide**: Check `SUPPORT_TICKET_TESTING_GUIDE.md`
3. **API Issues**: Check Railway logs for backend errors
4. **Socket.IO**: Ensure proper authentication token in handshake

---

## 📝 Notes

- All timestamps are in ISO 8601 format (UTC)
- All IDs are MongoDB ObjectIds (24 character hex strings)
- File uploads limited to 10MB
- Supported file types: images (jpg, png), PDFs, documents (doc, docx, txt)
- Pagination limit maximum: 100 items per page
- Search is case-insensitive
- Real-time updates require Socket.IO connection

---

## ✅ Checklist for Admin Dashboard Team

- [ ] Set up development environment
- [ ] Test authentication with admin credentials
- [ ] Test all API endpoints with Postman/Insomnia
- [ ] Set up Socket.IO connection and test real-time events
- [ ] Design UI mockups for all views
- [ ] Implement ticket list view
- [ ] Implement ticket detail view
- [ ] Implement messaging and real-time updates
- [ ] Implement statistics dashboard
- [ ] Implement help articles management
- [ ] Implement FAQ management
- [ ] Test on staging environment
- [ ] Deploy to production

---

**Backend is 100% ready and deployed. Start building the admin dashboard UI now! 🚀**
