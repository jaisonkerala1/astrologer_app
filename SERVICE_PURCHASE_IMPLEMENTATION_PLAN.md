# Service Purchase Flow - Implementation Plan

## 🎯 Overview
Complete service booking and purchase flow following BLoC architecture with clean separation for easy backend migration.

---

## 📋 Requirements Summary
- **Payment**: Razorpay (implement later, keep placeholder)
- **Service Types**: 
  - Live (Audio/Video/Chat)
  - Report-based (Written analysis)
- **Scheduling**: Use existing astrologer calendar availability
- **Refund Policy**: 7 days
- **Notifications**: Email + SMS (backend integration ready)
- **Architecture**: BLoC pattern with repository abstraction

---

## 🏗️ Architecture Design

### Layer Structure
```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  (Screens + Widgets + BLoC Builders)   │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│           BLoC Layer                    │
│  (Business Logic + State Management)   │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│        Repository Layer                 │
│    (Abstract Interface + Caching)      │
└─────────────────┬───────────────────────┘
                  │
        ┌─────────┴─────────┐
        │                   │
┌───────▼────────┐  ┌───────▼────────┐
│ Local DataSource│  │ Remote DataSource│
│  (Mock/Cache)   │  │   (Future API)   │
└─────────────────┘  └──────────────────┘
```

---

## 📁 File Structure

```
lib/
├── features/
│   └── services/
│       ├── models/
│       │   ├── service_model.dart
│       │   ├── service_type_enum.dart
│       │   ├── delivery_method_enum.dart
│       │   ├── booking_model.dart
│       │   ├── order_model.dart
│       │   ├── order_status_enum.dart
│       │   ├── time_slot_model.dart
│       │   └── add_on_model.dart
│       │
│       ├── data/
│       │   ├── datasources/
│       │   │   ├── service_local_datasource.dart
│       │   │   └── service_remote_datasource.dart (interface)
│       │   └── repositories/
│       │       └── service_repository_impl.dart
│       │
│       ├── domain/
│       │   ├── repositories/
│       │   │   └── service_repository.dart (abstract)
│       │   └── usecases/
│       │       ├── get_service_details.dart
│       │       ├── create_booking.dart
│       │       ├── get_available_slots.dart
│       │       └── get_my_orders.dart
│       │
│       ├── presentation/
│       │   ├── bloc/
│       │   │   ├── service_detail/
│       │   │   │   ├── service_detail_bloc.dart
│       │   │   │   ├── service_detail_event.dart
│       │   │   │   └── service_detail_state.dart
│       │   │   │
│       │   │   ├── booking/
│       │   │   │   ├── booking_bloc.dart
│       │   │   │   ├── booking_event.dart
│       │   │   │   └── booking_state.dart
│       │   │   │
│       │   │   ├── checkout/
│       │   │   │   ├── checkout_bloc.dart
│       │   │   │   ├── checkout_event.dart
│       │   │   │   └── checkout_state.dart
│       │   │   │
│       │   │   └── my_orders/
│       │   │       ├── my_orders_bloc.dart
│       │   │       ├── my_orders_event.dart
│       │   │       └── my_orders_state.dart
│       │   │
│       │   ├── screens/
│       │   │   ├── service_detail_screen.dart
│       │   │   ├── booking_preferences_screen.dart
│       │   │   ├── booking_information_screen.dart
│       │   │   ├── checkout_screen.dart
│       │   │   ├── order_confirmation_screen.dart
│       │   │   └── my_orders_screen.dart
│       │   │
│       │   └── widgets/
│       │       ├── service_header_widget.dart
│       │       ├── whats_included_widget.dart
│       │       ├── delivery_method_selector.dart
│       │       ├── time_slot_picker.dart
│       │       ├── add_ons_selector.dart
│       │       ├── price_breakdown_card.dart
│       │       ├── payment_method_selector.dart
│       │       ├── order_summary_card.dart
│       │       ├── order_status_card.dart
│       │       └── order_timeline_widget.dart
│       │
│       └── utils/
│           ├── service_validators.dart
│           └── booking_helpers.dart
│
└── core/
    └── payment/
        └── razorpay_service.dart (placeholder)
```

---

## 🎨 Design System Specifications

### Colors (Using Theme Service)
```dart
- Primary: themeService.primaryColor (#E67E22)
- Background: themeService.backgroundColor
- Surface: themeService.surfaceColor
- Text Primary: themeService.textPrimary
- Text Secondary: themeService.textSecondary
- Border: themeService.borderColor
- Success: Color(0xFF10B981)
- Warning: Color(0xFFF59E0B)
- Error: Color(0xFFEF4444)
```

### Typography
```dart
- Page Title: 24px, FontWeight.w700, -0.8 letterSpacing
- Section Header: 18px, FontWeight.w600, -0.4 letterSpacing
- Card Title: 16px, FontWeight.w600
- Body: 14px, FontWeight.w500, 1.4 height
- Caption: 12px, FontWeight.w500
- Price Large: 28px, FontWeight.w800
- Price Small: 18px, FontWeight.w700
```

### Component Styles
```dart
// Cards
- borderRadius: BorderRadius.circular(12)
- padding: EdgeInsets.all(16)
- shadow: BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 2))

// Buttons
- Primary: height 50, borderRadius 30, fontSize 16, fontWeight.w600
- Secondary: same as primary but outlined
- Small: height 36, borderRadius 20, fontSize 14

// Input Fields
- borderRadius: BorderRadius.circular(8)
- height: 50
- border: 1px solid borderColor
- focusedBorder: 2px solid primaryColor

// Selection Cards
- borderRadius: BorderRadius.circular(12)
- border: 2px (selected: primary, unselected: border)
- padding: 16
```

---

## 📱 Screen Flow & Wireframes

### 1. Service Detail Screen
```
┌─────────────────────────────────┐
│ ← Service Detail            ⋮   │
├─────────────────────────────────┤
│  [Icon Hero Animation]          │
│                                 │
│  Kundali Analysis               │
│  by Dr. Rajesh Kumar ★ 4.8     │
│  ─────────────────────          │
│                                 │
│  Duration: 60 mins              │
│  Delivery: Video/Report         │
│  Price: ₹1,500                  │
│                                 │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━    │
│                                 │
│  📋 What's Included             │
│  • Complete birth chart         │
│  • Planetary analysis           │
│  • Life predictions             │
│  • Remedies & suggestions       │
│                                 │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━    │
│                                 │
│  📖 About This Service          │
│  Detailed description...        │
│                                 │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━    │
│                                 │
│  🔄 How It Works                │
│  1. Share birth details         │
│  2. Schedule consultation       │
│  3. Receive analysis            │
│                                 │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━    │
│                                 │
│  ⭐ Service Reviews (24)        │
│  [Review cards...]              │
│                                 │
└─────────────────────────────────┘
  ┌─────────────────────────────┐
  │ ₹1,500  [Book Now →]       │
  └─────────────────────────────┘
```

### 2. Booking Preferences Screen
```
┌─────────────────────────────────┐
│ ← Booking Preferences           │
│ ●━━━○━━━○  Step 1 of 3         │
├─────────────────────────────────┤
│                                 │
│  🎯 Choose Delivery Method      │
│  ┌─────────────────────────┐   │
│  │ 📹 Video Consultation   │✓  │
│  │ Live session via app    │   │
│  └─────────────────────────┘   │
│  ┌─────────────────────────┐   │
│  │ 📞 Phone Call           │   │
│  │ Voice consultation      │   │
│  └─────────────────────────┘   │
│  ┌─────────────────────────┐   │
│  │ 📄 Written Report       │   │
│  │ Detailed PDF analysis   │   │
│  └─────────────────────────┘   │
│                                 │
│  📅 Select Date & Time          │
│  ┌─────────────────────────┐   │
│  │   May 2024              │   │
│  │ Su Mo Tu We Th Fr Sa    │   │
│  │              1  2  3    │   │
│  │  4  5  6  7  8  9 10    │   │
│  │ 11 12 [13]14 15 16 17   │   │
│  └─────────────────────────┘   │
│                                 │
│  ⏰ Available Time Slots         │
│  [10:00] [11:00] [14:00]       │
│  [15:00] [16:00] [17:00]       │
│                                 │
│  🎁 Add Enhancement (Optional)  │
│  □ Express Delivery +₹200       │
│  □ Follow-up Session +₹500      │
│  □ Written Report +₹300         │
│                                 │
└─────────────────────────────────┘
  ┌─────────────────────────────┐
  │      [Continue →]           │
  └─────────────────────────────┘
```

### 3. Booking Information Screen
```
┌─────────────────────────────────┐
│ ← Your Information              │
│ ●━━━●━━━○  Step 2 of 3         │
├─────────────────────────────────┤
│                                 │
│  📝 Required Details            │
│                                 │
│  Birth Date *                   │
│  [DD/MM/YYYY        ]          │
│                                 │
│  Birth Time *                   │
│  [HH:MM AM/PM       ]          │
│                                 │
│  Birth Place *                  │
│  [City/Town         ]          │
│                                 │
│  Your Question/Concern          │
│  [Text area...                 │
│   Multiple lines               │
│   ]                            │
│                                 │
│  📎 Upload Documents (Optional) │
│  [+ Add Document]               │
│                                 │
│  Special Instructions           │
│  [Any specific areas to focus  │
│   ]                            │
│                                 │
│  ℹ️ Your information is secure  │
│     and confidential            │
│                                 │
└─────────────────────────────────┘
  ┌─────────────────────────────┐
  │      [Continue →]           │
  └─────────────────────────────┘
```

### 4. Checkout Screen
```
┌─────────────────────────────────┐
│ ← Review & Payment              │
│ ●━━━●━━━●  Step 3 of 3         │
├─────────────────────────────────┤
│                                 │
│  📦 Order Summary               │
│  ┌─────────────────────────┐   │
│  │ Kundali Analysis        │   │
│  │ Dr. Rajesh Kumar        │   │
│  │ ─────────────────       │   │
│  │ 📹 Video Call           │   │
│  │ 📅 May 13, 2024, 10 AM  │   │
│  │ ⏱️ 60 mins              │   │
│  └─────────────────────────┘   │
│                                 │
│  💰 Price Details               │
│  Service Fee        ₹1,500      │
│  Add-ons             ₹500       │
│  Platform Fee         ₹50       │
│  ─────────────────────          │
│  Total              ₹2,050      │
│                                 │
│  🎟️ Have a promo code?          │
│  [Enter code    ] [Apply]      │
│                                 │
│  💳 Payment Method              │
│  (Payment integration later)    │
│  ┌─────────────────────────┐   │
│  │ Pay ₹2,050 via Razorpay│   │
│  │ (Coming Soon)           │   │
│  └─────────────────────────┘   │
│                                 │
│  □ I agree to Terms & Privacy   │
│                                 │
│  ⚡ 7-day refund policy          │
│                                 │
└─────────────────────────────────┘
  ┌─────────────────────────────┐
  │ [Complete Booking - ₹2,050] │
  └─────────────────────────────┘
```

### 5. Order Confirmation Screen
```
┌─────────────────────────────────┐
│           ✓ Success             │
├─────────────────────────────────┤
│                                 │
│      [Success Animation]        │
│                                 │
│   Booking Confirmed!            │
│                                 │
│   Order ID: #ORD123456          │
│                                 │
│  ┌─────────────────────────┐   │
│  │ Kundali Analysis        │   │
│  │ with Dr. Rajesh Kumar   │   │
│  │ ─────────────────       │   │
│  │ 📹 Video Call           │   │
│  │ 📅 May 13, 2024         │   │
│  │ ⏰ 10:00 AM - 11:00 AM  │   │
│  │ ─────────────────       │   │
│  │ Amount Paid: ₹2,050     │   │
│  └─────────────────────────┘   │
│                                 │
│  📧 Confirmation sent to email  │
│  📱 SMS notification sent       │
│                                 │
│  🔔 What's Next?                │
│  1. We'll notify you 1 day      │
│     before appointment          │
│  2. Join via video link         │
│  3. Receive analysis report     │
│                                 │
│  📞 Need help?                  │
│  Contact: support@app.com       │
│                                 │
│  [View Order Details]           │
│  [Message Astrologer]           │
│  [Go to Home]                   │
│                                 │
└─────────────────────────────────┘
```

### 6. My Orders Screen
```
┌─────────────────────────────────┐
│ ← My Services                   │
├─────────────────────────────────┤
│                                 │
│  [Upcoming] [Past] [Cancelled]  │
│                                 │
│  ┌─────────────────────────┐   │
│  │ 📹 Kundali Analysis     │   │
│  │ Dr. Rajesh Kumar        │   │
│  │ May 13, 10:00 AM        │   │
│  │ Status: Confirmed ●     │   │
│  │ [Join Now] [Details]    │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ 📄 Career Guidance      │   │
│  │ Dr. Priya Sharma        │   │
│  │ May 15, 2:00 PM         │   │
│  │ Status: Pending ⏳      │   │
│  │ [Reschedule] [Cancel]   │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ 📄 Marriage Matching    │   │
│  │ Dr. Amit Verma          │   │
│  │ May 1, 11:00 AM         │   │
│  │ Status: Completed ✓     │   │
│  │ [Download] [Review]     │   │
│  └─────────────────────────┘   │
│                                 │
│  [Load More...]                 │
│                                 │
└─────────────────────────────────┘
```

---

## 🔧 Implementation Steps

### Step 1: Models & Enums (Day 1-2)
Create all data models with JSON serialization ready for API

### Step 2: Repository Layer (Day 2-3)
Abstract repository interface + mock implementation

### Step 3: BLoC Setup (Day 3-4)
All BLoC events, states, and business logic

### Step 4: UI - Service Detail (Day 5-6)
Hero animation, service info display, reviews

### Step 5: UI - Booking Flow (Day 7-9)
Preferences → Information → Checkout screens

### Step 6: UI - Post-Purchase (Day 10-11)
Confirmation screen + My Orders dashboard

### Step 7: Integration & Testing (Day 12-14)
Connect all flows, add animations, test edge cases

---

## 🔌 Backend Migration Readiness

### API Endpoints Structure (Future)
```dart
// Already designed in repository interface
POST   /api/services/{serviceId}/book
GET    /api/services/{serviceId}
GET    /api/astrologers/{id}/availability
GET    /api/orders/my-orders
POST   /api/orders/{orderId}/cancel
POST   /api/payments/razorpay/create
POST   /api/payments/razorpay/verify
```

### Environment Configuration
```dart
// Will use from existing backend config
class ApiConstants {
  static const String baseUrl = 'YOUR_BACKEND_URL';
  static const String razorpayKey = 'YOUR_KEY';
}
```

---

## 📊 State Management Pattern

```dart
// Example: Booking Bloc States
sealed class BookingState {}
class BookingInitial extends BookingState {}
class BookingLoading extends BookingState {}
class BookingPreferencesLoaded extends BookingState {
  final List<TimeSlot> availableSlots;
  final List<AddOn> addOns;
}
class BookingSuccess extends BookingState {
  final OrderModel order;
}
class BookingError extends BookingState {
  final String message;
}
```

---

## ✅ Quality Checklist

- [ ] BLoC pattern for all business logic
- [ ] Repository abstraction for easy API swap
- [ ] Theme service integration
- [ ] Proper error handling
- [ ] Loading states
- [ ] Form validation
- [ ] Responsive design
- [ ] Accessibility (semantic labels)
- [ ] Animations & transitions
- [ ] Haptic feedback
- [ ] Empty states
- [ ] Error states
- [ ] Success states
- [ ] Pull to refresh
- [ ] Infinite scroll for orders
- [ ] Image caching
- [ ] Analytics events ready
- [ ] Crashlytics integration ready

---

## 🎯 Success Metrics

- User can complete booking in < 2 minutes
- < 5% booking abandonment rate
- Clear refund policy visibility
- Smooth 60fps animations
- All fields validated with clear error messages
- Order tracking accessible from multiple entry points

---

## 🚀 Ready to Start?

Would you like me to begin with:
1. **Models & Enums** - Foundation data structures
2. **Repository Setup** - Clean architecture layer
3. **First Screen** - Service Detail with hero animation

Let me know and I'll start building! 🎨

