#!/bin/bash

# Прерываем выполнение при любой ошибке
set -e

echo "🔍 Ищем последний релиз go-gost..."
LATEST_TAG=$(curl -s https://api.github.com/repos/go-gost/gost/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$LATEST_TAG" ]; then
    echo "❌ Ошибка: не удалось получить информацию о последнем релизе."
    exit 1
fi

echo "✅ Найден релиз: $LATEST_TAG"

TMP_DIR="gost_build_tmp"
DIST_DIR="dist"

echo "🧹 Очищаем предыдущую сборку..."
rm -rf "$TMP_DIR" "$DIST_DIR"

echo "📦 Клонируем исходный код..."
git clone --quiet --branch "$LATEST_TAG" --depth 1 https://github.com/go-gost/gost.git "$TMP_DIR"

echo "🐳 Запускаем параллельную кросс-компиляцию в Docker..."
docker run --rm \
    -v "$(pwd)/$TMP_DIR:/app" \
    -w /app \
    golang:1.26.3-alpine3.23 \
    sh -c '
        set -e
        echo "📥 Загрузка зависимостей..."
        go mod download
        cd cmd/gost

        echo "🚀 Запуск параллельных сборок..."
        CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build -trimpath -ldflags "-s -w" -o /app/gost-windows-amd64.exe . &
        pid_win_amd=$!
        CGO_ENABLED=0 GOOS=windows GOARCH=arm64 go build -trimpath -ldflags "-s -w" -o /app/gost-windows-arm64.exe . &
        pid_win_arm=$!
        CGO_ENABLED=0 GOOS=darwin  GOARCH=amd64 go build -trimpath -ldflags "-s -w" -o /app/gost-macos-amd64 . &
        pid_mac_amd=$!
        CGO_ENABLED=0 GOOS=darwin  GOARCH=arm64 go build -trimpath -ldflags "-s -w" -o /app/gost-macos-arm64 . &
        pid_mac_arm=$!
        CGO_ENABLED=0 GOOS=linux   GOARCH=amd64 go build -trimpath -ldflags "-s -w" -o /app/gost-linux-amd64 . &
        pid_lin_amd=$!
        CGO_ENABLED=0 GOOS=linux   GOARCH=arm64 go build -trimpath -ldflags "-s -w" -o /app/gost-linux-arm64 . &
        pid_lin_arm=$!

        fail=0
        wait "$pid_win_amd" || fail=1
        wait "$pid_win_arm" || fail=1
        wait "$pid_mac_amd" || fail=1
        wait "$pid_mac_arm" || fail=1
        wait "$pid_lin_amd" || fail=1
        wait "$pid_lin_arm" || fail=1

        if [ "$fail" -ne 0 ]; then
            echo "❌ Одна или несколько сборок завершились с ошибкой"
            exit 1
        fi
        echo "✅ Все сборки завершены"
    '

echo "📁 Раскладываем бинарники по папкам dist/..."
mkdir -p "$DIST_DIR/windows" "$DIST_DIR/macos" "$DIST_DIR/linux"

mv "$TMP_DIR/gost-windows-amd64.exe" "$DIST_DIR/windows/"
mv "$TMP_DIR/gost-windows-arm64.exe" "$DIST_DIR/windows/"
mv "$TMP_DIR/gost-macos-amd64" "$DIST_DIR/macos/"
mv "$TMP_DIR/gost-macos-arm64" "$DIST_DIR/macos/"
mv "$TMP_DIR/gost-linux-amd64" "$DIST_DIR/linux/"
mv "$TMP_DIR/gost-linux-arm64" "$DIST_DIR/linux/"

chmod +x \
    "$DIST_DIR/macos/gost-macos-amd64" \
    "$DIST_DIR/macos/gost-macos-arm64" \
    "$DIST_DIR/linux/gost-linux-amd64" \
    "$DIST_DIR/linux/gost-linux-arm64"

echo "🧹 Очищаем временные файлы..."
rm -rf "$TMP_DIR"

echo "🎉 Готово! Бинарники ($LATEST_TAG) в $(pwd)/$DIST_DIR/:"
echo "  - $DIST_DIR/windows/gost-windows-amd64.exe"
echo "  - $DIST_DIR/windows/gost-windows-arm64.exe"
echo "  - $DIST_DIR/macos/gost-macos-amd64"
echo "  - $DIST_DIR/macos/gost-macos-arm64"
echo "  - $DIST_DIR/linux/gost-linux-amd64"
echo "  - $DIST_DIR/linux/gost-linux-arm64"
