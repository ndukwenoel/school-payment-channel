FROM python:3.9-slim

WORKDIR /app

# Install system dependencies (needed for some python packages like psycopg2-binary if used, or gcc)
RUN apt-get update && apt-get install -y gcc libpq-dev && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Expose port
EXPOSE 8000

# Command to run
CMD ["uvicorn", "server.main:app", "--host", "0.0.0.0", "--port", "8000"]
