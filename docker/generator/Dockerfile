FROM python:3.11-slim

RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

RUN uv venv /venv
ENV VIRTUAL_ENV=/venv
ENV PATH="/venv/bin:$PATH"

WORKDIR /app

COPY src/requirements.txt .
RUN uv pip install -r requirements.txt

COPY src/kafka_event_generator.py .

CMD ["python", "kafka_event_generator.py"]
