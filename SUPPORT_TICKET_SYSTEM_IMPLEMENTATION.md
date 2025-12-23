# Support Ticket System - Backend Implementation

## ✅ Complete Implementation

This document describes the full Support Ticket System backend implementation for the Astrologer App.

## 📁 Files Created

### Database Models (`backend/src/models/`)

1. **SupportTicket.js**
   - Ticket management with auto-generated ticket numbers (`TKT-YYYYMMDD-00001`)
   - Fields: title, description, category, priority, status, user info, admin assignment
   - Response time & resolution time tracking
   - Internal notes, attachments, user ratings
   - Automatic first response and resolution time calculation

2. **TicketMessage.js**
   - Messages for ticket conversations
   - Support for user, admin, and system messages
   - Internal notes (admin-only)
   - Read receipts tracking
   - Attachment support

3. **HelpArticle.js**
   - Knowledge base articles
   - Categories, tags, SEO fields (slug, meta description)
   - View count, helpful/not helpful tracking
   - Publishing workflow (draft → published → archived)
   - Full-text search support

4. **FAQ.js**
   - Frequently Asked Questions
   - Categorized and ordered FAQs
   - Helpful/not helpful tracking
   - View count metrics

### Routes (`backend/src/routes/`)

1. **support.js** - User-facing ticket routes
   - `POST /api/support/tickets` - Create new ticket
   - `GET /api/support/tickets` - Get user's tickets (paginated, filtered)
   - `GET /api/support/tickets/:id` - Get ticket details with messages
   - `POST /api/support/tickets/:id/messages` - Add message to ticket
   - `PATCH /api/support/tickets/:id/close` - Close ticket
   - `POST /api/support/tickets/upload` - Upload attachment
   - `GET /api/support/categories` - Get categories & priorities

2. **adminSupport.js** - Admin ticket management routes
   - `GET /api/admin/support/tickets` - Get all tickets (with filters, search, stats)
   - `GET /api/admin/support/tickets/:id` - Get ticket details (admin view with internal notes)
   - `PATCH /api/admin/support/tickets/:id/assign` - Assign ticket to admin
   - `PATCH /api/admin/support/tickets/:id/status` - Update ticket status
   - `PATCH /api/admin/support/tickets/:id/priority` - Update ticket priority
   - `POST /api/admin/support/tickets/:id/messages` - Add admin reply or internal note
   - `POST /api/admin/support/tickets/:id/internal-notes` - Add internal note
   - `POST /api/admin/support/tickets/bulk-action` - Bulk actions (assign, close, update status)
   - `GET /api/admin/support/stats` - Get ticket statistics for dashboard

3. **helpSupport.js** - Help Articles & FAQ routes
   - **User endpoints:**
     - `GET /api/support/articles` - Get published articles
     - `GET /api/support/articles/:id` - Get article by ID (increments view count)
     - `GET /api/support/articles/search?q=...` - Search articles
     - `POST /api/support/articles/:id/helpful` - Mark article as helpful/not helpful
     - `GET /api/support/faq` - Get published FAQs
     - `POST /api/support/faq/:id/helpful` - Mark FAQ as helpful/not helpful
     - `GET /api/support/categories` - Get all categories
   
   - **Admin endpoints:**
     - `GET /api/admin/support/articles` - Get all articles (including drafts)
     - `POST /api/admin/support/articles` - Create article
     - `PUT /api/admin/support/articles/:id` - Update article
     - `DELETE /api/admin/support/articles/:id` - Delete article
     - `PATCH /api/admin/support/articles/:id/publish` - Publish/unpublish article
     - `GET /api/admin/support/faq` - Get all FAQs
     - `POST /api/admin/support/faq` - Create FAQ
     - `PUT /api/admin/support/faq/:id` - Update FAQ
     - `DELETE /api/admin/support/faq/:id` - Delete FAQ
     - `PATCH /api/admin/support/faq/:id/reorder` - Update FAQ order

### Socket.IO Handlers (`backend/src/socket/handlers/`)

**supportTicketHandler.js**

Real-time Socket.IO events for ticket updates:

**Socket Events:**
- `join_ticket` - Join ticket room for real-time updates
- `leave_ticket` - Leave ticket room
- `ticket:typing` - Typing indicator
- `admin_join_ticket_monitor` - Admin joins global ticket monitor

**Broadcast Functions (exported for use in HTTP routes):**
- `broadcastTicketMessage(io, ticketId, message)` - Broadcast new message
- `broadcastTicketStatusChange(io, ticketId, statusUpdate)` - Broadcast status change
- `broadcastTicketAssigned(io, ticketId, assignmentData)` - Broadcast assignment
- `broadcastNewTicket(io, ticket)` - Broadcast new ticket to admin monitor
- `broadcastTicketPriorityChange(io, ticketId, priorityData)` - Broadcast priority change

**Socket Rooms:**
- `ticket:{ticketId}` - Individual ticket room (user + assigned admin)
- `admin:ticket_monitor` - Admin dashboard monitor for all new tickets
- `admin:{adminId}` - Personal admin room for notifications

## 🔗 Integration Points

### 1. Socket.IO Integration (`backend/src/socket/index.js`)
- Support ticket handler initialized on connection
- Broadcast functions exported for use in routes

### 2. Server Routes (`backend/src/server.js`)
- User ticket routes: `/api/support/*`
- Admin ticket routes: `/api/admin/support/*`
- Help articles & FAQ: `/api/support/articles/*`, `/api/support/faq/*`

### 3. Middleware Used
- `auth` - Astrologer authentication (from existing middleware)
- `adminAuth` - Admin authentication (from existing middleware)
- `multer` - File upload for ticket attachments (10MB limit, images/PDFs/docs)

## 📊 Features Implemented

### Ticket Management
✅ Auto-generated unique ticket numbers (`TKT-YYYYMMDD-00001`)
✅ 8 ticket categories (Account Issues, Calendar Problems, etc.)
✅ 4 priority levels (Low, Medium, High, Urgent)
✅ 4 status states (open, in_progress, waiting_for_user, closed)
✅ Ticket assignment to admins
✅ Attachments support (images, PDFs, documents)
✅ Response time tracking (first admin response)
✅ Resolution time tracking (ticket close)
✅ Message count tracking
✅ Internal admin notes (not visible to users)
✅ User satisfaction ratings (after ticket closure)
✅ Tagging system
✅ Pagination & filtering
✅ Full-text search

### Real-Time Features
✅ Socket.IO rooms per ticket
✅ Typing indicators
✅ Instant message delivery
✅ Status change notifications
✅ Assignment notifications
✅ Admin dashboard monitor (all new tickets)
✅ Read receipts tracking

### Knowledge Base
✅ Help Articles with categories
✅ Full-text search on articles
✅ View count tracking
✅ Helpful/not helpful feedback
✅ Publishing workflow (draft/published/archived)
✅ SEO fields (slug, meta description)
✅ Popular articles tracking

### FAQ System
✅ Categorized FAQs
✅ Custom ordering within categories
✅ Helpful/not helpful tracking
✅ View count metrics
✅ Publish/unpublish control

### Admin Features
✅ Ticket list with advanced filters (status, priority, category, assigned to)
✅ Search across tickets (title, description, ticket number, user name)
✅ Ticket assignment management
✅ Bulk actions (assign, close, update status/priority)
✅ Internal notes (private admin notes)
✅ Statistics dashboard (response time, resolution time, satisfaction rate)
✅ Trends analysis (tickets by day, top categories, top admins)
✅ User ticket history
✅ Admin performance metrics

## 🎯 API Response Format

All endpoints follow the standard format:

**Success:**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { /* response data */ }
}
```

**Error:**
```json
{
  "success": false,
  "message": "Error description",
  "error": "Detailed error message"
}
```

## 🔐 Authentication

- **User routes** (`/api/support/*`): Require `auth` middleware (Bearer token)
- **Admin routes** (`/api/admin/support/*`): Require `adminAuth` middleware
- **Socket.IO**: Uses `optionalSocketAuth` middleware from existing implementation

## 📝 Ticket Workflow

1. **User creates ticket** → Status: `open`
2. **Admin assigns ticket** → Status: `in_progress`
3. **Admin replies** → Status: `waiting_for_user` (first response time recorded)
4. **User replies** → Status: `in_progress`
5. **Admin/User closes ticket** → Status: `closed` (resolution time recorded)
6. **Optional: User rates ticket** → Satisfaction rating saved

## 🚀 Next Steps for Flutter Integration

The Flutter app already has the BLoC architecture and models in place:
- `HelpArticle`, `FAQItem`, `SupportTicket`, `TicketMessage` models exist
- `HelpSupportRepository` interface defined
- `HelpSupportBloc` with events and states
- UI screens for ticket creation and viewing

**To complete integration:**
1. Implement `HelpSupportRepositoryImpl` to call these new backend APIs
2. Update BLoC to handle responses from real APIs
3. Add Socket.IO listeners in relevant screens for real-time updates
4. Test ticket creation, messaging, and real-time features

## 🎨 Admin Dashboard Integration

For the admin dashboard (web):
1. Use the `/api/admin/support/*` endpoints
2. Connect to Socket.IO for real-time ticket updates
3. Implement ticket list with filters/search
4. Add ticket detail view with message thread
5. Include statistics dashboard with charts

## 📦 Dependencies

All dependencies already exist in the project:
- `express` - Web framework
- `mongoose` - MongoDB ODM
- `multer` - File upload
- `socket.io` - Real-time communication
- JWT authentication middleware (already implemented)

## 🔍 Testing Endpoints

**Create a ticket:**
```bash
POST http://localhost:7566/api/support/tickets
Authorization: Bearer {astrologer_token}
Content-Type: application/json

{
  "title": "Cannot update my availability",
  "description": "When I try to add availability, I get a 403 error",
  "category": "Calendar Problems",
  "priority": "High"
}
```

**Get tickets:**
```bash
GET http://localhost:7566/api/support/tickets?status=open&page=1&limit=20
Authorization: Bearer {astrologer_token}
```

**Admin get all tickets:**
```bash
GET http://localhost:7566/api/admin/support/tickets?status=open&priority=High
Authorization: Bearer {admin_token}
```

**Admin assign ticket:**
```bash
PATCH http://localhost:7566/api/admin/support/tickets/{ticketId}/assign
Authorization: Bearer {admin_token}
Content-Type: application/json

{
  "assignedTo": "admin_id_123",
  "assignedToName": "John Admin"
}
```

## ✨ Summary

**Complete backend implementation delivered:**
- ✅ 4 Mongoose models
- ✅ 3 route files with 35+ API endpoints
- ✅ Socket.IO real-time handler with 5 broadcast functions
- ✅ Integrated into existing server architecture
- ✅ Full CRUD for tickets, messages, help articles, and FAQs
- ✅ Admin dashboard support with statistics
- ✅ Real-time updates via Socket.IO
- ✅ File upload support
- ✅ Advanced filtering, search, and pagination
- ✅ Metrics tracking (response time, resolution time, satisfaction)

**Ready for Flutter integration using existing BLoC architecture!** 🚀
