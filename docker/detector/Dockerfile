FROM python:3.12-slim

RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

RUN uv venv /venv
ENV VIRTUAL_ENV=/venv
ENV PATH="/venv/bin:$PATH"

RUN uv pip install kafka-python-ng

WORKDIR /app

COPY src/simple_detector.py .

ENV KAFKA_BROKER=kafka:9092

CMD ["python", "simple_detector.py"]
