# 🎨 Unified Communication Interface

## Overview

World-class, Instagram-inspired unified communication interface that consolidates messages, voice calls, and video calls into a single, beautiful view with intelligent filtering.

## ✨ Key Features

### 1. **Unified Inbox**
- All communication types in one place
- Sort by timestamp (newest first)
- Single source of truth for all interactions

### 2. **Smart Filtering**
- **All**: Shows everything (default)
- **Calls**: Voice calls only
- **Messages**: Text messages only  
- **Video**: Video calls only

### 3. **Minimal Design**
- Instagram-style UI
- Clean, modern aesthetics
- Smooth animations
- Context-aware FAB

### 4. **Billing Integrity**
- Separate pricing maintained for each type
- Backend receives correct type ('call', 'message', 'video')
- No mixing of billing logic

## 📁 Architecture

```
lib/features/communication/
├── models/
│   └── communication_item.dart          # Unified data model
├── services/
│   └── communication_service.dart       # Enhanced with filtering
├── screens/
│   ├── communication_screen.dart        # Legacy wrapper
│   └── unified_communication_screen.dart # Main screen
└── widgets/
    ├── communication_filter_chip.dart   # Filter UI
    └── communication_item_card.dart     # Beautiful card design
```

## 🎯 User Experience

### Filter Interaction
1. Tap any filter chip to filter instantly
2. Count badges show items per category
3. Active filter has blue background
4. FAB changes based on active filter

### List Items
- **Messages**: Blue badge, unread count, preview text
- **Voice Calls**: Green badge, call duration, status icon
- **Video Calls**: Purple badge, duration, charged amount

### Empty States
- Contextual messages based on active filter
- Beautiful iconography
- Clear call-to-action

## 🔒 Technical Details

### Data Flow
```
CommunicationService
    ├── _allCommunications (List<CommunicationItem>)
    ├── _activeFilter (CommunicationFilter)
    └── filteredCommunications (computed getter)
```

### Billing Safety
- Each CommunicationItem has a `type` field
- Type maps to backend Session model:
  - `CommunicationType.message` → 'message'
  - `CommunicationType.voiceCall` → 'call'
  - `CommunicationType.videoCall` → 'video'
- Pricing logic remains separate and intact

### Performance
- Filter is instant (local operation)
- List virtualization for large datasets
- Optimistic UI updates
- Efficient rebuild strategy

## 🎨 Design System

### Colors
- **Primary**: #667EEA (Messages)
- **Success**: #10B981 (Voice Calls)
- **Purple**: #8B5CF6 (Video Calls)
- **Error**: #F56565 (Missed/Unread)

### Typography
- **Title**: 24px, Bold (-0.5 letter spacing)
- **Name**: 16px, SemiBold
- **Preview**: 14px, Regular
- **Metadata**: 12px, Medium

### Spacing (8px grid)
- Card padding: 16px
- Filter chip: 20px horizontal, 10px vertical
- Avatar: 56px diameter
- Gap between items: 8px

### Animations
- Filter transition: 200ms ease-out
- FAB scale: 200ms ease-in-out
- List switch: 300ms fade/slide

## 🚀 Usage

### Navigation
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const CommunicationScreen(),
  ),
);
```

### Filtering Programmatically
```dart
final commService = Provider.of<CommunicationService>(context, listen: false);
commService.setFilter(CommunicationFilter.messages);
```

### Adding New Communications
```dart
// Add message
commService.addNewMessage(
  name: 'John Doe',
  preview: 'Hello there!',
  avatar: 'JD',
  isOnline: true,
);

// Add call
commService.addNewCall(
  name: 'Jane Smith',
  type: 'Incoming',
  status: 'answered',
  avatar: 'JS',
);
```

## 🧪 Testing

### Test New Message
1. Tap menu (⋮)
2. Select "Test New Message"
3. Verify new message appears at top
4. Check unread count updates

### Test Missed Call
1. Tap menu (⋮)
2. Select "Test Missed Call"
3. Verify call appears with missed status
4. Check badge updates

### Test Filtering
1. Switch between filters
2. Verify list updates instantly
3. Check empty states
4. Verify FAB changes

## 📱 Responsive Behavior

### Phone
- Horizontal scrolling for filter chips
- Optimized card layout
- Touch-friendly tap targets (48dp minimum)

### Tablet
- Wider cards with more breathing room
- Potentially side-by-side layout (future)

## 🔮 Future Enhancements

- [ ] Search across all communications
- [ ] Swipe actions (call back, archive, delete)
- [ ] Pin important conversations
- [ ] Archive old items
- [ ] Mark as starred
- [ ] Quick reply from notification
- [ ] Voice message support
- [ ] Read receipts
- [ ] Typing indicators
- [ ] Group calls/messages

## 🐛 Troubleshooting

### Filters Not Working
- Check `CommunicationService` is provided at app level
- Verify `filteredCommunications` getter logic

### Items Not Appearing
- Check `_buildUnifiedList()` is called after data changes
- Verify timestamp parsing in `CommunicationItem`

### Billing Issues
- Always check `type` field is set correctly
- Verify backend receives correct Session type
- Check `ratePerMinute` calculation

## 📚 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0  # State management
```

## 🎓 Best Practices

1. **Always rebuild unified list** after adding/removing items
2. **Use proper type mapping** for backend compatibility
3. **Test all filters** to ensure correctness
4. **Maintain backward compatibility** with legacy code
5. **Update unread counts** synchronously with list changes

## 📄 License

Part of the Astrologer App project.

---

**Built with ❤️ following Instagram's design principles**


