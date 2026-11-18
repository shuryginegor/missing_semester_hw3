# ДЗ 3: Docker

## Описание решения

Веб-приложение со счётчиком упаковано в Docker с использованием Docker Compose.
Приложение работает в режиме Redis: счётчик хранится в отдельном контейнере Redis
с именованным volume, что обеспечивает сохранение данных между перезапусками.

Оба сервиса имеют healthcheck для корректного порядка запуска.

## Структура файлов

- Dockerfile — сборка образа на python:3.13-slim, установка curl, запуск от UID 1000
- compose.yaml — два сервиса (app и redis), healthcheck, именованный volume
- .dockerignore — исключение мусора из образа
- .env.example — шаблон переменных окружения
- app/ — исходный код приложения (не изменён)

## Запуск

Сборка и запуск:
docker compose up -d --build

Остановка:
docker compose down

Просмотр логов:
docker compose logs -f app

## Настройки (через .env)

Скопируйте .env.example в .env и при необходимости измените значения:
cp .env.example .env
## Проверки

### 1. Сохранение данных после перезапуска контейнеров

Выполняем несколько инкрементов:
curl -X POST http://127.0.0.1:8080/increment
curl -X POST http://127.0.0.1:8080/increment

Проверяем значение (должно быть count: 2):
curl http://127.0.0.1:8080/

Вывод:
{"greeting": "Hello from Compose", "count": 1, "hostname": "71a0eb892461", "storage": "redis"}{"greeting": "Hello from Compose", "count": 2, "hostname": "71a0eb892461", "storage": "redis"}

Перезапускаем контейнеры:
docker compose down
docker compose up -d

Проверяем, что счётчик сохранился (должно остаться count: 2):
curl http://127.0.0.1:8080/

Вывод:
[+] down 3/3
 ✔ Container hw_3-app-1   Removed                                          10.2s
 ✔ Container hw_3-redis-1 Removed                                           0.2s
 ✔ Network hw_3_default   Removed                                           0.1s
[+] up 3/3
 ✔ Network hw_3_default   Created                                           0.0s
 ✔ Container hw_3-redis-1 Healthy                                          10.8s
 ✔ Container hw_3-app-1   Started                                          11.0s
{"greeting": "Hello from Compose", "count": 2, "hostname": "92e63955b77f", "storage": "redis"}

### 2. Проверка недоступности Redis

Останавливаем Redis:
docker compose stop redis

Проверяем healthz (должен вернуть 200):
curl -w "%{http_code}\n" http://127.0.0.1:8080/healthz

Проверяем readyz (должен вернуть 503):
curl -w "%{http_code}\n" http://127.0.0.1:8080/readyz

Проверяем increment (должен вернуть 503):
curl -w "%{http_code}\n" -X POST http://127.0.0.1:8080/increment

Вывод:
[+] stop 1/1
 ✔ Container hw_3-redis-1 Stopped                                           0.2s
200
503
503

### 3. Восстановление после перезапуска Redis

Запускаем Redis обратно:
docker compose start redis

Ждём готовности:
sleep 15

Проверяем, что счётчик сохранился (должно быть count: 3):
curl http://127.0.0.1:8080/

Проверяем, что инкремент работает (должно стать count: 4):
curl -X POST http://127.0.0.1:8080/increment

Вывод:
[+] start 1/1
 ✔ Container hw_3-redis-1 Started                                           0.2s
{"greeting": "Hello from Compose", "count": 2, "hostname": "92e63955b77f", "storage": "redis"}{"greeting": "Hello from Compose", "count": 3, "hostname": "92e63955b77f", "storage": "redis"}
