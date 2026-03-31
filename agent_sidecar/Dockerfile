FROM python:3.12-slim-bookworm

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . ./agent_sidecar/

ENV PYTHONPATH=/app

EXPOSE 5000

CMD ["uvicorn", "agent_sidecar.main:app", "--host", "0.0.0.0", "--port", "5000"]
