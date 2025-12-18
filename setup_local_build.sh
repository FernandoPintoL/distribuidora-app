#!/bin/bash

# Script para configurar directorios de build locales
# Esto evita problemas con sistemas de archivos de red

PROJECT_DIR="/Volumes/laptop-fpl/paucara/distribuidora-app"
LOCAL_BUILD_DIR="$HOME/.flutter_builds/distribuidora-app"

echo "Configurando directorios de build locales..."

# Crear directorio local para builds
mkdir -p "$LOCAL_BUILD_DIR"

# Si existe el directorio build en la red, respaldarlo
if [ -d "$PROJECT_DIR/build" ]; then
    echo "Respaldando build existente..."
    mv "$PROJECT_DIR/build" "$PROJECT_DIR/build.bak"
fi

# Crear symlink desde la red hacia el directorio local
ln -sf "$LOCAL_BUILD_DIR" "$PROJECT_DIR/build"

# Lo mismo para .dart_tool
if [ -d "$PROJECT_DIR/.dart_tool" ]; then
    echo "Respaldando .dart_tool existente..."
    mv "$PROJECT_DIR/.dart_tool" "$PROJECT_DIR/.dart_tool.bak"
fi

mkdir -p "$LOCAL_BUILD_DIR/.dart_tool"
ln -sf "$LOCAL_BUILD_DIR/.dart_tool" "$PROJECT_DIR/.dart_tool"

# Para iOS
mkdir -p "$LOCAL_BUILD_DIR/ios"
if [ -d "$PROJECT_DIR/ios/build" ]; then
    mv "$PROJECT_DIR/ios/build" "$PROJECT_DIR/ios/build.bak"
fi
ln -sf "$LOCAL_BUILD_DIR/ios" "$PROJECT_DIR/ios/build"

echo "Configuración completada!"
echo "Los builds ahora se almacenarán en: $LOCAL_BUILD_DIR"
echo ""
echo "Para limpiar, ejecuta: flutter clean"
