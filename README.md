# gost-self-build

Скрипт для самостоятельной сборки [go-gost/gost](https://github.com/go-gost/gost) из исходников последнего релиза.

Собирает кросс-платформенные бинарники для Windows, macOS и Linux (amd64 и arm64) в Docker — локально ставить Go не нужно.

## Что нужно

- bash
- git
- curl
- [Docker](https://docs.docker.com/get-docker/)

## Как пользоваться

```bash
chmod +x build.sh
./build.sh
```

Скрипт:

1. Узнаёт последний релиз gost через GitHub API
2. Клонирует исходники нужного тега
3. Собирает 6 бинарников параллельно в контейнере `golang`
4. Кладёт результат в `dist/` и удаляет временные файлы

## Результат

После успешной сборки:

```
dist/
├── windows/
│   ├── gost-windows-amd64.exe
│   └── gost-windows-arm64.exe
├── macos/
│   ├── gost-macos-amd64
│   └── gost-macos-arm64
└── linux/
    ├── gost-linux-amd64
    └── gost-linux-arm64
```

## Примечания

- Папки `dist/` и `gost_build_tmp/` в git не коммитятся (см. `.gitignore`)
- Сборка идёт с `CGO_ENABLED=0` и флагами `-trimpath -ldflags "-s -w"` — статичные урезанные бинарники
- Версия образа Go задана в `build.sh` (`golang:1.26.3-alpine3.23`)
