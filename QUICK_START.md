# Phase 5 Quick Start Guide

## 🚀 For Developers - Get Started in 5 Minutes

### Step 1: Understand the Architecture (2 min)
Read: `ARCHITECTURE_DIAGRAM.md` - Visual overview of how everything connects

### Step 2: Review Your Integration Points (1 min)

#### Option A: Simple - Just Add Connection Indicator
```dart
AppBar(
  actions: const [EstadosConnectionIndicator()],
)
```

#### Option B: Medium - Add Connection Banner
```dart
Scaffold(
  body: Column(
    children: [
      const EstadosConnectionBanner(),
      // Your list here
    ],
  ),
)
```

#### Option C: Advanced - Full Real-Time Integration
```dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Auto-updates when WebSocket events arrive
    final estado = ref.watch(
      estadoPorCodigoProvider(('entrega', 'EN_CAMINO'))
    );

    return estado.when(
      data: (data) => Text(data?.nombre ?? 'N/A'),
      loading: () => CircularProgressIndicator(),
      error: (err, _) => Text('Error'),
    );
  }
}
```

### Step 3: Test It (2 min)
1. Run app: `flutter run`
2. Check AppBar - should show green indicator (✓ En vivo)
3. Open DevTools Flutter Logs
4. Search for: `EstadosRealtimeService`
5. Should see: `✓ WebSocket conectado`

---

## 📚 Documentation Map

**For architects/leads:**
- `ARCHITECTURE_DIAGRAM.md` - System design
- `PHASE_SUMMARY.md` - Project overview
- `FASE5_IMPLEMENTATION_GUIDE.md` - Integration details

**For developers integrating features:**
- `SESSION_PHASE5_SUMMARY.md` - What was built
- `QUICK_START.md` - This file!

**For troubleshooting:**
- `FASE5_IMPLEMENTATION_GUIDE.md` → "Troubleshooting" section

---

## 🔌 Most Common Integration Patterns

### Pattern 1: Show Estado Badge (Most Common)
```dart
// Anywhere in your UI
EstadoBadgeWidget(
  categoria: 'entrega',
  estadoCodigo: entrega.estado,
)
// Auto-updates when WebSocket sends evento:cambio
```

### Pattern 2: Filter Estados
```dart
// For dropdowns, chips, or buttons
EstadoFilterDropdown(
  categoria: 'entrega',
  selectedEstadoCodigo: _filtro,
  onChanged: (value) => setState(() => _filtro = value),
)
```

### Pattern 3: Show Connection Status
```dart
// In AppBar
AppBar(
  actions: const [EstadosConnectionIndicator()],
)

// Or as banner
Column(
  children: [
    const EstadosConnectionBanner(),
    Expanded(child: YourContent()),
  ],
)
```

### Pattern 4: React to Real-Time Changes
```dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch for connection changes
    final connection = ref.watch(estadosConnectionStateStreamProvider);

    // Watch for event changes
    final eventos = ref.watch(estadosEventStreamProvider);

    return connection.when(
      data: (state) => Text(state.isConnected ? 'Online' : 'Offline'),
      loading: () => CircularProgressIndicator(),
      error: (err, _) => Text('Error'),
    );
  }
}
```

---

## 🎯 What Each File Does

| File | Purpose | Use When |
|------|---------|----------|
| `estado_event.dart` | Event models | Understanding real-time events |
| `estados_realtime_service.dart` | WebSocket connection | System-level integration |
| `estados_realtime_provider.dart` | Riverpod providers | Watching streams in widgets |
| `estados_realtime_cache_sync.dart` | Cache invalidation | Understanding sync logic |
| `estados_connection_indicator.dart` | UI components | Showing connection status |

---

## 🧪 Testing Checklist

- [ ] App starts without errors
- [ ] Green indicator appears in AppBar (✓ En vivo)
- [ ] Flutter logs show "WebSocket conectado"
- [ ] Estado badges display correctly
- [ ] Change estado in backend → UI updates in <1 second
- [ ] Close network → banner shows orange (Sincronizando)
- [ ] Restore network → indicator turns green
- [ ] No crashes in logs

---

## ❌ Common Mistakes (Don't Do These)

### ❌ Wrong
```dart
// Don't import realtime provider directly
import 'providers/estados_realtime_provider.dart';
import 'providers/estados_provider.dart';  // ← Both

// Don't manually manage connection
EstadosRealtimeService().connect();  // ← Creates new instance
```

### ✅ Right
```dart
// Use Riverpod providers (they're singletons)
final service = ref.watch(estadosRealtimeServiceProvider);

// Let Riverpod manage lifetime
// (automatically connects on first watch)
```

---

## 🔧 Configuration Needed

**Only one thing to check:**

1. **`.env` file in Flutter project root**
```env
BASE_URL=http://192.168.100.21:8000/api
WEBSOCKET_URL=http://192.168.100.21:3000
```

**If WEBSOCKET_URL is missing:**
- Service will log error but app continues working
- Uses cached data instead
- Reconnect attempts continue (exponential backoff)

---

## 📞 Quick Troubleshooting

### "Green indicator but no events arriving"
**Check:**
1. Is backend emitting Socket.IO events?
2. Is Node.js server running on port 3000?
3. Look in browser DevTools → Network → WebSocket tab

### "Red X indicator (Sin conexión)"
**Check:**
1. WEBSOCKET_URL correct in .env?
2. Node.js server running?
3. User authenticated (token in FlutterSecureStorage)?

### "Widget showing loading forever"
**Check:**
1. Use fallback parameter:
```dart
ref.watch(
  estadosPorCategoriaProvider('entrega'),
).whenData((estados) => /* ... */);
```

### "Build errors"
**Run:**
```bash
flutter clean
flutter pub get
flutter analyze
```

---

## 📊 Performance Tips

### Cache Hits
- First app launch: API fetch (slow)
- Second app launch: Cache read (fast)
- After 7 days: Cache expires, need API

### Bandwidth Savings
- **Polling (5s interval):** 500KB/min per user
- **WebSocket (events only):** 1KB/min per user
- **Savings: 99%**

### Optimization
If slow performance:
```dart
// Clear old cache
ref.watch(refreshEstadosProvider);

// Manual reconnect
ref.watch(estadosForceReconnectProvider);
```

---

## 🎓 Learning Resources

### Videos to Watch (if available)
- None yet - record a demo!

### Code Examples to Study
- `FASE4_INTEGRATION_EXAMPLE.md` - Flutter widget patterns
- `FASE5_IMPLEMENTATION_GUIDE.md` - Real-time patterns

### Concepts
- **FutureProvider:** Async data from API
- **StreamProvider:** Real-time event streams
- **ref.watch():** Subscribe to changes
- **Exponential backoff:** Retry strategy

---

## 🚀 Deployment Checklist

Before deploying to production:

- [ ] WEBSOCKET_URL in .env (backend team set up Node.js)
- [ ] EstadosConnectionIndicator in main screens
- [ ] Backend emitting Socket.IO events
- [ ] Firebase/analytics tracking real-time updates
- [ ] Monitoring WebSocket connection health
- [ ] Plan for WebSocket server failover
- [ ] Document for users (might see "Sincronizando")

---

## 📞 Support

### Need Help?
1. **For architecture questions:** Read `ARCHITECTURE_DIAGRAM.md`
2. **For integration questions:** Read `FASE5_IMPLEMENTATION_GUIDE.md`
3. **For troubleshooting:** See section above
4. **For examples:** Check `FASE4_INTEGRATION_EXAMPLE.md`

### For Backend Team (Node.js/Laravel)

#### What backend must do:
1. **Emit Socket.IO events** when estado changes:
```php
broadcast(new EstadoUpdated($estado))->toOthers();
```

2. **Event format must be:**
```json
{
  "type": "updated",
  "categoria": "entrega",
  "codigo": "EN_CAMINO",
  "nombre": "En Camino",
  "color": "#10b981",
  "icono": "🚚",
  "timestamp": "2025-12-31T10:30:00Z"
}
```

3. **Validate Bearer token** in WebSocket auth headers
4. **Run Node.js WebSocket server** on WEBSOCKET_URL

---

## ✅ Success Indicators

You know Phase 5 is working when:

✅ Green WiFi icon appears in AppBar
✅ Admin changes estado → UI updates instantly (<1s)
✅ No manual refresh needed
✅ Connection indicator changes state smoothly
✅ App works offline (shows cached data)
✅ Zero WebSocket errors in logs

---

## 🎉 You're Ready!

Start integrating:

1. Add EstadosConnectionIndicator to 1 screen
2. Test it works
3. Add to other screens
4. Deploy!

**Total time to integrate: < 1 hour per screen**

Questions? Check `FASE5_IMPLEMENTATION_GUIDE.md` → Troubleshooting section.

Good luck! 🚀
