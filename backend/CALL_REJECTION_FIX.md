# Call Rejection & Disconnect Fix

## 🐛 Issues Fixed

### Issue #1: Call Rejection Not Reflecting in Admin Dashboard
**Problem:** When the astrologer declined a call, the admin dashboard UI didn't clear.

**Root Cause:** Socket.IO room name mismatch:
- Admin dashboard joined room: `admin:` (no ID suffix)
- Backend sent rejection to: `admin:admin` ❌
- **They never connected!**

**Solution:** Modified `roomFor()` function to return just `admin:` for admin users:
```javascript
function roomFor(type, id) {
  if (!type) return null;
  const prefix = ROOM_PREFIX[type.toUpperCase()];
  if (!prefix) return null;
  
  // Special case: admin room is just 'admin:' with no ID suffix
  if (type.toLowerCase() === 'admin') {
    return prefix; // Returns 'admin:'
  }
  
  if (!id) return null;
  return `${prefix}${id}`;
}
```

### Issue #2: Call Still Ringing in Flutter When Admin Disconnects
**Problem:** When admin ended a call, the Flutter app kept ringing/showing the call UI.

**Root Cause:** The `CALL.END` handler wasn't properly determining and notifying the other party.

**Solution:** Updated `CALL.END` handler to:
1. Fetch the call record
2. Determine the OTHER party (caller or recipient)
3. Use `roomFor()` to get the correct room
4. Emit `CALL.END` event to that room

```javascript
// Determine the OTHER party (the one who didn't end the call)
const currentUserId = socket.userId || socket.user?._id;
const otherPartyId = (currentUserId === call.callerId) ? call.recipientId : call.callerId;
const otherPartyType = (currentUserId === call.callerId) ? call.recipientType : call.callerType;

// Notify other party
const otherPartyRoom = roomFor(otherPartyType, otherPartyId);
io.to(otherPartyRoom).emit(CALL.END, { callId, duration, reason });
```

## 🔧 Files Modified

### `backend/src/socket/handlers/callHandler.js`
- **`roomFor()` function:** Added special handling for admin room
- **`CALL.REJECT` handler:** Now derives caller info from call record
- **`CALL.END` handler:** Properly determines and notifies the other party
- **`CALL.ACCEPT` handler:** Updated for consistency
- **`CALL.CONNECTED` handler:** Updated for consistency

## ✅ Expected Behavior Now

### Call Rejection (Astrologer Declines)
1. Admin initiates call → Admin joins room `admin:`
2. Astrologer declines call → Backend receives `call:reject`
3. Backend derives caller info from call record
4. Backend emits to room `admin:` ✅
5. Admin dashboard receives rejection and clears UI ✅

### Call End (Admin Disconnects)
1. Call is active between admin and astrologer
2. Admin ends call → Backend receives `call:end`
3. Backend determines other party (astrologer)
4. Backend emits to room `astrologer:6935056d55fcb5a4615f8e8d` ✅
5. Flutter app receives notification and clears UI ✅

### Call End (Astrologer Disconnects)
1. Call is active between admin and astrologer
2. Astrologer ends call → Backend receives `call:end`
3. Backend determines other party (admin)
4. Backend emits to room `admin:` ✅
5. Admin dashboard receives notification and clears UI ✅

## 🧪 Testing Steps

1. **Clear browser cache** (Ctrl+Shift+R) to ensure latest code
2. **Test Rejection:**
   - Admin initiates call to astrologer
   - Astrologer declines from app
   - ✅ Admin UI should immediately clear
3. **Test Admin Disconnect:**
   - Admin initiates call
   - Astrologer accepts
   - Admin ends call
   - ✅ Flutter app should immediately stop ringing/disconnect
4. **Test Astrologer Disconnect:**
   - Admin initiates call
   - Astrologer accepts
   - Astrologer ends call
   - ✅ Admin dashboard should immediately clear

## 📊 Backend Logs to Verify

```
✅ [SOCKET] Auto-joined admin to personal room: admin:
❌ [CALL] Call XXX rejected by 6935056d55fcb5a4615f8e8d
🔍 [CALL] Derived from call record - contactId: admin, type: admin
📴 [CALL] Reject notification sent to admin room: admin:  ← Should be admin: not admin:admin
```

```
📴 [CALL] Call XXX ended by admin (duration: 5s)
🔍 [CALL] Notifying other party - type: astrologer, id: 6935056d55fcb5a4615f8e8d
📴 [CALL] End notification sent to astrologer room: astrologer:6935056d55fcb5a4615f8e8d
```

## 🚀 Deployment

- **Committed:** `9e57487`
- **Pushed to:** Railway (main branch)
- **Deploy Time:** ~2-3 minutes
- **Status:** ✅ Deployed

## 📝 Notes

- The admin room is special: it's just `admin:` with no ID suffix
- All other user types use `{prefix}{userId}` format (e.g., `astrologer:6935056d55fcb5a4615f8e8d`)
- The `roomFor()` function now handles this edge case automatically
- All call handlers (`REJECT`, `END`, `ACCEPT`, `CONNECTED`) use `roomFor()` consistently











