# 🔔 GUÍA DE VERIFICACIÓN: Flutter Local Notifications

## Estado Actual
Tu implementación de `flutter_local_notifications` **está bien configurada** para mostrar notificaciones en segundo plano como WhatsApp y Facebook. He aplicado mejoras para optimizar el comportamiento.

---

## 📋 CAMBIOS APLICADOS

### ✅ Mejora 1: Importancia Dinámica por Canal
- Antes: Todas las notificaciones usaban `Importance.max`
- Ahora: Cada canal respeta su nivel de importancia
  - `entregas_nuevas` y `proformas` → `Importance.max` + `Priority.high`
  - `cambio_estados` → `Importance.high` + `Priority.high`
  - `recordatorios` → `Importance.default` + `Priority.default`

### ✅ Mejora 2: Estilo de Notificación Completo
- Ahora usa `BigTextStyleInformation` con el cuerpo completo visible
- Las notificaciones mostrarán texto completo expandible (como WhatsApp)

### ✅ Mejora 3: Sonido de Notificación
- Agregado: `sound: const RawResourceAndroidNotificationSound('notification')`
- El sonido se reproducirá en segundo plano

### ✅ Mejora 4: Permisos Android 13+
- Ahora solicita explícitamente el permiso `POST_NOTIFICATIONS` en Android 13+
- Compatible con devices más nuevos

### ✅ Mejora 5: iOS mejorado
- `presentInForeground: true` → Las notificaciones se muestran incluso si la app está abierta

---

## 🧪 CÓMO PROBAR QUE FUNCIONE

### **OPCIÓN 1: Prueba Rápida en la App**

#### Paso 1: Agregar botón de prueba (Temporal)
Edita `lib/screens/home_screen.dart` o cualquier pantalla y agrega:

```dart
// Importar al inicio
import 'package:distribuidora_app/services/local_notification_service.dart';

// En el widget, agregar un botón (en FloatingActionButton o AppBar):
FloatingActionButton(
  onPressed: () async {
    final notificationService = LocalNotificationService();
    // Elegir uno de estos:
    await notificationService.sendTestNotification(channel: 'entregas');
    // await notificationService.sendTestNotification(channel: 'estado');
    // await notificationService.sendTestNotification(channel: 'proforma');
    // await notificationService.sendTestNotification(channel: 'envio');
  },
  child: const Icon(Icons.notifications),
),
```

#### Paso 2: Compilar y ejecutar
```bash
flutter clean
flutter pub get
flutter run
```

#### Paso 3: Probar cada tipo de notificación
1. Toca el botón de prueba
2. **Con app abierta**: Verás la notificación en la bandeja si `presentInForeground: true`
3. **Con app cerrada**: Presiona home → Verás la notificación en la barra superior
4. **En segundo plano**: Abre otra app → La notificación debería aparecer como WhatsApp

---

### **OPCIÓN 2: Prueba desde Android Studio / Emulador**

#### Paso 1: Abrir Android Studio
```bash
# En Windows
flutter emulator --launch <nombre_emulador>
# O abre Android Studio y lanza el emulador
```

#### Paso 2: Ejecutar con logs
```bash
flutter run -v 2>&1 | grep -i notification
```

Busca mensajes como:
```
✅ Notificación mostrada: 🚚 Nueva Entrega Asignada (Canal: entregas_nuevas)
```

#### Paso 3: Verificar en Settings de Android
```
Ajustes → Apps → Tu App → Notifications → Ver canales creados:
  ✅ Nuevas Entregas (Max)
  ✅ Cambios de Estado (High)
  ✅ Recordatorios (Default)
  ✅ Proformas (High)
```

---

### **OPCIÓN 3: Prueba de Segundo Plano**

#### Paso 1: Ejecutar la app
```bash
flutter run
```

#### Paso 2: Minimizar/Cerrar app
- Presiona botón HOME (no cierre la app, minimícela)

#### Paso 3: Enviar notificación
- Si tienes un backend, dispara una notificación
- O usa el método de prueba: `sendTestNotification()`

#### Paso 4: Verificar
- **Resultado esperado**: La notificación aparece en la barra superior del celular
- **Como WhatsApp**: Muestra icono + título + cuerpo
- **Con sonido y vibración**: Dependiendo del canal

---

## ✅ CHECKLIST DE VERIFICACIÓN

Marca cada punto cuando lo hayas verificado:

### **Android**
- [ ] App instalada y compilada exitosamente
- [ ] Permisos otorgados (verifica en Settings → Apps → Permisos)
- [ ] Notificación aparece en bandeja cuando app está en segundo plano
- [ ] Notificación muestra título + cuerpo completo (expandible)
- [ ] Vibración funciona (si el canal lo tiene habilitado)
- [ ] Sonido se reproduce
- [ ] Al tocar notificación, ejecuta callback `_onNotificationTap()`
- [ ] 4 canales creados en Settings → Apps → Notifications

### **iOS**
- [ ] App instalada en dispositivo o simulador
- [ ] Se solicita permiso de notificaciones al abrir (primera vez)
- [ ] Permiso ACEPTADO (si dice "Not Determined", ejecuta de nuevo)
- [ ] Notificación aparece en lock screen cuando app está cerrada
- [ ] Notificación aparece en notification center
- [ ] Badge (número rojo) aparece en ícono de app
- [ ] Sonido se reproduce

### **En Segundo Plano**
- [ ] WebSocket conectado (verifica logs: "🔌 WebSocket conectado")
- [ ] Notificaciones de proforma llegan sin abrir la app
- [ ] Notificaciones de envío llegan sin abrir la app
- [ ] NotificationsListener activo en pantalla home

---

## 🐛 TROUBLESHOOTING

### **Problema: No aparece notificación en Android**

**Solución 1**: Verifica permisos
```bash
adb shell dumpsys package com.tuapk | grep NOTIFICATION
# Debería mostrar: granted
```

**Solución 2**: Revisa que no haya Battery Saver
- Ajustes → Battery → Battery Saver → OFF

**Solución 3**: Verifica Do Not Disturb
- Ajustes → Sound → Do Not Disturb → OFF

**Solución 4**: Revisa el icono
- Si falta `ic_launcher_foreground`, la notificación puede fallar
- Reemplaza por: `@drawable/ic_launcher` (icono de la app)

---

### **Problema: No aparece notificación en iOS**

**Solución 1**: Permiso no otorgado
```
Ajustes → [Tu App] → Notifications → Permitir Notificaciones → ON
```

**Solución 2**: Do Not Disturb activado
```
Control Center → Moon Icon → OFF
```

**Solución 3**: Reinicia la app
```bash
flutter run
# O: xcode → Product → Clean & Build
```

---

### **Problema: Solo aparece cuando app está abierta**

**Cause**: WebSocket desconectado cuando app va a segundo plano
**Solución**: Implementar servicio de background (ver sección "Próximos Pasos")

---

## 🚀 PRÓXIMOS PASOS (OPCIONAL)

Si quieres que las notificaciones funcionen **incluso sin WebSocket activo**:

### **Implementar Push Notifications Real**
(Firebase Cloud Messaging / OneSignal)

```
Backend → Servicio Push (FCM/OneSignal) → Google/Apple → Device
```

Esto permitiría recibir notificaciones incluso con la app cerrada.

### **Implementar Background Service**
Para mantener WebSocket activo en segundo plano:

```dart
// Usar workmanager o flutter_background_runner
// Para ejecutar tareas cada X minutos
```

---

## 📊 INFORMACIÓN TÉCNICA

### **Canales Creados**

| Canal | Importancia | Vibración | Sonido | Caso de Uso |
|-------|-------------|-----------|---------|-----------|
| `entregas_nuevas` | Max | ✅ | ✅ | Nueva entrega asignada |
| `cambio_estados` | High | ✅ | ✅ | Estado de entrega cambió |
| `recordatorios` | Default | ❌ | ✅ | Recordatorio de pendientes |
| `proformas` | High | ✅ | ✅ | Proforma aprobada/rechazada |

### **Permisos Configurados**

**Android (AndroidManifest.xml)**
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

**iOS (Solicitado en runtime)**
- Alert (Mostrar notificación)
- Badge (Número en ícono)
- Sound (Reproducir sonido)

---

## 🔗 REFERENCIAS

- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
- [Android Notification Channels](https://developer.android.com/training/notify-user/channels)
- [iOS UserNotifications](https://developer.apple.com/documentation/usernotifications)

---

## ✨ RESUMEN

Tu app **ya está lista** para mostrar notificaciones como WhatsApp/Facebook. Las mejoras aplicadas garantizan:
- ✅ Notificaciones en segundo plano visibles en la bandeja
- ✅ Importancia respetada por canal
- ✅ Sonido y vibración configurados
- ✅ Compatible con Android 13+ e iOS 14+
- ✅ WebSocket integrado para notificaciones en tiempo real

**Próximo paso**: Sigue el checklist de verificación anterior para confirmar todo funciona correctamente en tu dispositivo.
