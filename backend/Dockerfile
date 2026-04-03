FROM python:3.11-slim

WORKDIR /app

# Dependencias del sistema (necesarias para OpenCV, librosa, etc.)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 \
    libsndfile1 \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Copiar e instalar dependencias Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar código fuente
COPY . .

# Exponer puerto
EXPOSE 8000

# Comando de arranque
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
