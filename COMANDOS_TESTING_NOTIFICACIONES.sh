#!/bin/bash

# 🔔 COMANDOS ÚTILES PARA TESTING DE NOTIFICACIONES
# Usa estos comandos en tu terminal para probar rápidamente

echo "📲 === UTILIDADES PARA TESTING DE NOTIFICACIONES ==="
echo ""

# ═══════════════════════════════════════════════════════════
# 1. COMPILAR Y EJECUTAR LA APP
# ═══════════════════════════════════════════════════════════
echo "1️⃣ COMPILAR Y EJECUTAR"
echo "   flutter clean && flutter pub get && flutter run -v"
echo ""

# ═══════════════════════════════════════════════════════════
# 2. VER LOGS EN TIEMPO REAL
# ═══════════════════════════════════════════════════════════
echo "2️⃣ VER LOGS EN TIEMPO REAL"
echo "   flutter run -v 2>&1 | grep -i notification"
echo "   flutter run -v 2>&1 | grep -E '(✅|❌)'"
echo ""

# ═══════════════════════════════════════════════════════════
# 3. VERIFICAR PERMISOS EN ANDROID
# ═══════════════════════════════════════════════════════════
echo "3️⃣ VERIFICAR PERMISOS ANDROID"
echo "   adb shell dumpsys package com.tupaquete | grep NOTIFICATION"
echo "   adb shell dumpsys package com.tupaquete | grep VIBRATE"
echo ""

# ═══════════════════════════════════════════════════════════
# 4. VER CANALES CREADOS
# ═══════════════════════════════════════════════════════════
echo "4️⃣ VER CANALES DE NOTIFICACIÓN CREADOS"
echo "   adb shell cmd notification list_notification_channels com.tupaquete"
echo ""

# ═══════════════════════════════════════════════════════════
# 5. SIMULAR NOTIFICACIÓN EN ANDROID
# ═══════════════════════════════════════════════════════════
echo "5️⃣ SIMULAR NOTIFICACIÓN (Android)"
echo "   adb shell am start -n com.google.android.gms/.app.NotificationCenter"
echo ""

# ═══════════════════════════════════════════════════════════
# 6. BORRAR CACHÉ
# ═══════════════════════════════════════════════════════════
echo "6️⃣ LIMPIAR CACHÉ COMPLETO"
echo "   flutter clean"
echo "   rm -rf build/ .dart_tool/"
echo "   flutter pub get"
echo ""

# ═══════════════════════════════════════════════════════════
# 7. LISTAR DISPOSITIVOS CONECTADOS
# ═══════════════════════════════════════════════════════════
echo "7️⃣ DISPOSITIVOS DISPONIBLES"
echo "   flutter devices"
echo "   adb devices -l"
echo ""

# ═══════════════════════════════════════════════════════════
# 8. EMULADOR (iOS)
# ═══════════════════════════════════════════════════════════
echo "8️⃣ EJECUTAR EN EMULADOR iOS"
echo "   open -a Simulator"
echo "   flutter run -d macos"
echo ""

# ═══════════════════════════════════════════════════════════
# FUNCIONES AUXILIARES
# ═══════════════════════════════════════════════════════════

# Función para limpiar y compilar
rebuild_app() {
    echo "🔧 Limpiando y recompilando..."
    flutter clean
    flutter pub get
    flutter run
}

# Función para ver solo errores
show_errors() {
    echo "❌ Mostrando solo errores y advertencias..."
    flutter run -v 2>&1 | grep -i -E "(error|warning|fail)"
}

# Función para ver logs de notificaciones
show_notification_logs() {
    echo "📲 Mostrando solo logs de notificaciones..."
    flutter run -v 2>&1 | grep -i -E "(notification|notify|channel)"
}

# Función para obtener package name
get_package_name() {
    echo "📦 Package name de la app..."
    grep 'package=' android/app/build.gradle | head -1
    # O desde pubspec:
    grep '^name:' pubspec.yaml
}

# ═══════════════════════════════════════════════════════════
# EJEMPLOS DE USO
# ═══════════════════════════════════════════════════════════

echo ""
echo "📝 EJEMPLOS DE USO:"
echo ""
echo "   # Opción 1: Compilar y ver logs filtrados"
echo "   flutter clean && flutter pub get && flutter run -v 2>&1 | grep -E '(✅|❌|notification)'"
echo ""
echo "   # Opción 2: Ver solo errores"
echo "   flutter run -v 2>&1 | grep -i error"
echo ""
echo "   # Opción 3: Verificar permisos"
echo "   adb shell dumpsys package com.tuapk | grep NOTIFICATION"
echo ""
echo "   # Opción 4: Listar canales en Android"
echo "   adb shell cmd notification list_notification_channels com.tuapk"
echo ""

# ═══════════════════════════════════════════════════════════
# CHECKLIST RÁPIDO
# ═══════════════════════════════════════════════════════════

echo ""
echo "✅ CHECKLIST RÁPIDO:"
echo "   [ ] 1. flutter clean"
echo "   [ ] 2. flutter pub get"
echo "   [ ] 3. flutter run"
echo "   [ ] 4. Esperar a ver '📊 ESTADO DEL SERVICIO DE NOTIFICACIONES'"
echo "   [ ] 5. Presionar HOME"
echo "   [ ] 6. Abrir otra app"
echo "   [ ] 7. Dispara notificación desde backend"
echo "   [ ] 8. Verifica en barra superior ✅"
echo ""

# ═══════════════════════════════════════════════════════════
# NOTAS IMPORTANTES
# ═══════════════════════════════════════════════════════════

echo ""
echo "⚠️ NOTAS IMPORTANTES:"
echo ""
echo "   1. En Windows, reemplaza los comandos adb con: flutter run"
echo "   2. Asegúrate de tener el emulador o dispositivo conectado"
echo "   3. Los logs pueden ser lentos, usa grep para filtrar"
echo "   4. Si algo falla, intenta: flutter pub cache clean"
echo "   5. Para iOS: Verifica que permisos estén en Info.plist"
echo ""
