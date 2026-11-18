FROM python:3.13-slim

RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Обратите внимание на путь app/
COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/app.py .

RUN mkdir -p /data && chown -R 1000:1000 /app /data
USER 1000

ENV PORT=8000
ENV STORAGE=redis
ENV REDIS_URL=redis://redis:6379/0
ENV GREETING="Hello, Docker!"

EXPOSE 8000
CMD ["python", "app.py"]
