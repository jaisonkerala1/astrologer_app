# Manual Consultation Database Integration Guide

This guide explains the complete database integration for manual consultations in the astrologer app, allowing users to create, update, delete, and manage consultations with full MongoDB persistence.

## 🏗️ Database Structure

### Consultation Model (MongoDB Schema)

The `Consultation` model in `backend/src/models/Consultation.js` provides a comprehensive structure for managing consultations:

#### Core Fields
- **Basic Information**
  - `clientName` (String, required): Client's full name
  - `clientPhone` (String, required): Client's phone number
  - `clientEmail` (String, optional): Client's email address

- **Scheduling**
  - `scheduledTime` (Date, required): When the consultation is scheduled
  - `duration` (Number, required): Duration in minutes (15-180 min)

- **Financial**
  - `amount` (Number, required): Consultation fee
  - `currency` (String, default: 'INR'): Currency type

- **Consultation Details**
  - `type` (Enum): 'phone', 'video', 'inPerson', 'chat'
  - `status` (Enum): 'scheduled', 'inProgress', 'completed', 'cancelled', 'noShow'
  - `astrologerId` (ObjectId, required): Reference to astrologer

- **Content & Notes**
  - `notes` (String, optional): Consultation notes
  - `consultationTopics` (Array): Topics discussed
  - `rating` (Number, 1-5): Client rating
  - `feedback` (String): Client feedback

- **Metadata**
  - `isManual` (Boolean, default: true): Manual consultation flag
  - `source` (Enum): 'app', 'website', 'admin'
  - `createdAt`, `updatedAt`: Automatic timestamps

#### Advanced Features
- **Cancellation Tracking**
  - `cancelledAt`, `cancelledBy`, `cancellationReason`

- **Reminder System**
  - `reminderSent`, `reminderSentAt`

- **Client Information**
  - `clientAge`, `clientGender`, `preferredLanguage`

## 🔌 API Endpoints

### Base URL: `/api/consultation`

#### 1. Get All Consultations
```
GET /api/consultation/:astrologerId
```
**Query Parameters:**
- `status`: Filter by status
- `type`: Filter by consultation type
- `startDate`, `endDate`: Date range filter
- `page`, `limit`: Pagination
- `sortBy`, `sortOrder`: Sorting options

**Response:**
```json
{
  "success": true,
  "data": {
    "consultations": [...],
    "pagination": {
      "currentPage": 1,
      "totalPages": 5,
      "totalItems": 100,
      "itemsPerPage": 20
    }
  }
}
```

#### 2. Get Single Consultation
```
GET /api/consultation/detail/:consultationId
```

#### 3. Create Consultation
```
POST /api/consultation/:astrologerId
```
**Request Body:**
```json
{
  "clientName": "John Doe",
  "clientPhone": "+1234567890",
  "clientEmail": "john@example.com",
  "scheduledTime": "2024-01-15T10:00:00Z",
  "duration": 30,
  "amount": 500,
  "type": "phone",
  "notes": "Career guidance consultation"
}
```

#### 4. Update Consultation
```
PUT /api/consultation/:consultationId
```

#### 5. Update Status Only
```
PATCH /api/consultation/status/:consultationId
```
**Request Body:**
```json
{
  "status": "completed",
  "notes": "Consultation completed successfully",
  "cancelledBy": "astrologer",
  "cancellationReason": "Client requested cancellation"
}
```

#### 6. Delete Consultation
```
DELETE /api/consultation/:consultationId
```

#### 7. Specialized Endpoints
- `GET /api/consultation/upcoming/:astrologerId` - Upcoming consultations
- `GET /api/consultation/today/:astrologerId` - Today's consultations
- `GET /api/consultation/stats/:astrologerId` - Statistics
- `PATCH /api/consultation/notes/:consultationId` - Add notes
- `PATCH /api/consultation/rating/:consultationId` - Add rating

## 📱 Frontend Integration

### Service Layer (`ConsultationsService`)

The service provides methods for all CRUD operations with automatic fallback to local storage for development:

```dart
// Get consultations with filtering
Future<List<ConsultationModel>> getConsultations({
  String? status,
  String? type,
  DateTime? startDate,
  DateTime? endDate,
  int page = 1,
  int limit = 20,
});

// Create new consultation
Future<ConsultationModel> addConsultation(ConsultationModel consultation);

// Update consultation
Future<ConsultationModel> updateConsultation(ConsultationModel consultation);

// Update status with additional data
Future<ConsultationModel> updateConsultationStatus(
  String consultationId,
  ConsultationStatus newStatus, {
  String? notes,
  String? cancelledBy,
  String? cancellationReason,
});

// Delete consultation
Future<void> deleteConsultation(String consultationId);

// Specialized methods
Future<List<ConsultationModel>> getUpcomingConsultations({int limit = 10});
Future<List<ConsultationModel>> getTodaysConsultations();
Future<Map<String, dynamic>> getConsultationStats();
Future<ConsultationModel> addConsultationNotes(String consultationId, String notes);
Future<ConsultationModel> addConsultationRating(String consultationId, int rating, String? feedback);
```

### BLoC Integration

The consultation BLoC handles all state management with comprehensive events:

#### Events
- `LoadConsultationsEvent` - Load all consultations
- `RefreshConsultationsEvent` - Refresh data
- `AddConsultationEvent` - Create new consultation
- `UpdateConsultationEvent` - Update existing consultation
- `UpdateConsultationStatusEvent` - Update status with notes/reason
- `DeleteConsultationEvent` - Delete consultation
- `AddConsultationNotesEvent` - Add notes to consultation
- `AddConsultationRatingEvent` - Add rating and feedback
- `FilterConsultationsEvent` - Apply filters

#### States
- `ConsultationsInitial` - Initial state
- `ConsultationsLoading` - Loading state
- `ConsultationsLoaded` - Data loaded with filtering
- `ConsultationUpdating` - Update in progress
- `ConsultationUpdated` - Update completed
- `ConsultationDeleted` - Deletion completed
- `ConsultationsError` - Error state

## 🔧 Usage Examples

### Creating a New Consultation

```dart
// In your widget
final consultation = ConsultationModel(
  id: '', // Will be generated by backend
  clientName: 'John Doe',
  clientPhone: '+1234567890',
  scheduledTime: DateTime.now().add(Duration(hours: 2)),
  duration: 30,
  amount: 500.0,
  status: ConsultationStatus.scheduled,
  type: ConsultationType.phone,
  createdAt: DateTime.now(),
);

context.read<ConsultationsBloc>().add(
  AddConsultationEvent(consultation: consultation),
);
```

### Updating Consultation Status

```dart
context.read<ConsultationsBloc>().add(
  UpdateConsultationStatusEvent(
    consultationId: 'consultation_id',
    newStatus: ConsultationStatus.completed,
    notes: 'Great consultation, client was very satisfied',
  ),
);
```

### Filtering Consultations

```dart
context.read<ConsultationsBloc>().add(
  FilterConsultationsEvent(
    statusFilter: ConsultationStatus.scheduled,
    dateFilter: DateTime.now(),
  ),
);
```

## 🛡️ Error Handling

The system includes comprehensive error handling:

1. **Backend Validation**: All fields are validated with proper error messages
2. **Frontend Fallbacks**: Service methods fall back to local storage if API fails
3. **User Feedback**: BLoC emits error states with descriptive messages
4. **Network Resilience**: Automatic retry mechanisms for network failures

## 📊 Database Indexes

Optimized indexes for performance:
- `astrologerId + scheduledTime` - Primary query index
- `clientPhone` - Client lookup
- `status` - Status filtering
- `scheduledTime` - Time-based queries
- `isManual` - Manual consultation filtering

## 🔄 Data Synchronization

The system maintains data consistency through:

1. **Real-time Updates**: All changes are immediately synced to database
2. **Local Caching**: Frontend caches data for offline capability
3. **Conflict Resolution**: Last-write-wins strategy for concurrent updates
4. **Data Validation**: Comprehensive validation at both frontend and backend

## 🚀 Getting Started

1. **Backend Setup**: Ensure MongoDB is running and connection string is configured
2. **API Testing**: Use the provided endpoints to test CRUD operations
3. **Frontend Integration**: Use the BLoC pattern for state management
4. **Error Handling**: Implement proper error handling in UI components

## 📝 Notes

- All timestamps are stored in UTC and converted to local time in frontend
- Currency is configurable (default: INR)
- Duration is stored in minutes for flexibility
- Status changes are tracked with timestamps
- Soft delete is implemented for completed consultations
- Rating system supports 1-5 stars with optional feedback

This implementation provides a robust, scalable foundation for managing manual consultations with full database persistence and comprehensive error handling.
