#!/bin/bash
set -e

echo "==> Instalando Flutter..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1 /opt/flutter
export PATH="$PATH:/opt/flutter/bin"

echo "==> Aceptando licencias Android..."
flutter config --no-analytics

echo "==> Instalando dependencias..."
flutter pub get

echo "==> Construyendo Flutter Web..."
flutter build web --release \
  --dart-define=API_BASE_URL=${API_BASE_URL:-https://celucenter-api.onrender.com}

echo "==> Build listo en build/web/"
