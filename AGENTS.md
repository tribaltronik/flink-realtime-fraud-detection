# AGENTS.md - Agent Guidelines for This Repository

## Project Overview

Real-time fraud detection system using Kafka and Apache Flink. Two approaches:
- **Approach 1**: Kafka + Python Generator + Python Detector (with checkpoint simulation)
- **Approach 2**: Kafka + Flink Cluster + Generator (SQL-based fraud detection)

## Build / Run Commands

### Docker / Environment

```bash
# Start Approach 1 (Kafka + Generator + Python Detector)
make up

# Start Approach 2 (Flink Cluster only - manual job submission)
make up-flink

# Stop all containers
make down

# Stop and remove volumes
make clean
```

### Manual Job Submission (Flink)

```bash
# Submit SQL job to Flink cluster
./submit-job.sh

# Watch suspicious transactions
docker exec docker-kafka-1 kafka-console-consumer --topic suspicious-transactions --from-beginning --bootstrap-server localhost:9092
```

### Python Development

```bash
# Install dependencies
pip install -r src/requirements.txt

# Run Kafka event generator
python src/kafka_event_generator.py

# Run Python fraud detector
python src/flink_detector.py
```

---

## Code Style Guidelines

### Python Code Conventions

**Naming Conventions:**
- `snake_case` for functions, variables, and methods
- `CamelCase` for class names
- `UPPER_SNAKE_CASE` for constants
- Descriptive names: `user_transaction_counts` not `utc`

**Formatting:**
- Line length: 100 characters max
- 4 spaces for indentation (no tabs)
- Use Black-style formatting
- One blank line between top-level definitions

**Type Hints (Recommended):**
```python
def process_transaction(tx: dict) -> list[str]:
    reasons: list[str] = []
    return reasons
```

**Imports:**
- Standard library first
- Third-party libraries second
- Local imports last
- Sort alphabetically within each group

```python
import json
import os
from datetime import datetime, timedelta

from kafka import KafkaConsumer, KafkaProducer
```

**Docstrings:**
- Use Google-style docstrings for public functions
- Keep brief (1-2 sentences)

```python
def detect_fraud(transaction: dict) -> list[str]:
    """Detect fraud patterns in a transaction.
    
    Args:
        transaction: Transaction data dictionary.
        
    Returns:
        List of fraud detection reasons.
    """
```

### Error Handling

- Use try/except blocks for I/O operations
- Log errors with context
- Fail gracefully where appropriate

```python
try:
    producer.send(TOPIC, value=tx)
    producer.flush()
except Exception as e:
    print(f"Failed to send transaction: {e}", flush=True)
```

### Logging

- Use `print()` with `flush=True` for Docker compatibility
- Include context in log messages

---

## Project Structure

```
flink-realtime-fraud-detection/
├── src/
│   ├── flink_detector.py       # Python-based fraud detector
│   └── kafka_event_generator.py # Kafka message generator
├── docker/
│   ├── docker-compose.with-flink.yml    # Flink cluster setup
│   ├── docker-compose.without-flink.yml # Python detector setup
│   ├── detector-flink/
│   │   └── submit.sql           # Flink SQL job definition
│   ├── generator/               # Docker image for generator
│   └── flink-sql/               # Flink SQL scripts
├── docs/
│   └── docker-job-submitter-error.md
├── submit-job.sh                # Flink job submission script
├── makefile                     # Build automation
└── README.md
```

---

## Key Configuration

### Kafka Topics

- `transactions` - Source topic for transaction events
- `suspicious-transactions` - Sink for detected fraud alerts

### Fraud Detection Rules (Python)

- `HIGH_VALUE_THRESHOLD = 5000`
- `VELOCITY_WINDOW_MINUTES = 5`
- `VELOCITY_MAX_TRANSACTIONS = 5`
- `RISK_COUNTRIES = ["XX", "YY", "ZZ"]`

### Environment Variables

- `KAFKA_BROKER` - Kafka broker address (default: `kafka:9092`)

---

## Testing

There are currently no automated tests in this project. When adding tests:

```bash
# Run pytest
pytest tests/

# Run a single test file
pytest tests/test_fraud_detector.py

# Run a single test
pytest tests/test_fraud_detector.py::test_high_value_detection
```

---

## Linting

This project uses ruff (cache present). To run:

```bash
# Install ruff
pip install ruff

# Check for issues
ruff check src/

# Auto-fix issues
ruff check src/ --fix
```

---

## Common Tasks

### Add a New Fraud Detection Rule

1. Add rule logic in `src/flink_detector.py`
2. Add corresponding SQL in `docker/detector-flink/submit.sql`
3. Update constants if needed

### Update Flink SQL Job

1. Edit `docker/detector-flink/submit.sql`
2. Cancel existing job: `curl -X DELETE http://localhost:8081/jobs/<job-id>`
3. Resubmit: `./submit-job.sh`

### Add New Kafka Topic

```bash
docker exec docker-kafka-1 kafka-topics \
  --create --topic new-topic \
  --bootstrap-server localhost:9092 \
  --partitions 3 --replication-factor 1
```
