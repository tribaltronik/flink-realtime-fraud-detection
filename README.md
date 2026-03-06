# Real-Time Fraud Detection

Two approaches to demonstrate real-time fraud detection:

- **Approach 1**: Kafka + Generator + Python Detector (with checkpoint simulation)
- **Approach 2**: Kafka + Flink Cluster + Generator (SQL-based fraud detection)

---

## Architecture Diagram

### Approach 1: Python Detector

![Approach 1](./docs/approach1.svg)

### Approach 2: Apache Flink Cluster

![Approach 2](./docs/approach2.svg)

---

## Quick Start

### Approach 1 (With Checkpoint Simulation)

```bash
make up
```

Features:
- Python detector with checkpoint simulation
- Detects HIGH_VALUE and HIGH_VELOCITY
- Checkpoint info shown in alerts

```bash
# Watch alerts
docker exec docker-kafka-1 kafka-console-consumer --topic suspicious-transactions --from-beginning --bootstrap-server localhost:9092
```

---

### Approach 2 (Flink Cluster - Auto Job Submission)

```bash
make up-flink
```

Features:
- Flink JobManager + TaskManager running
- Fraud detection job **automatically submitted**
- Flink UI: http://localhost:8081
- Suspicious transactions written to Kafka topic

```bash
# Watch suspicious transactions
docker exec docker-kafka-1 kafka-console-consumer --topic suspicious-transactions --from-beginning --bootstrap-server localhost:9092

# Or view Flink UI
# http://localhost:8081
```

---

## Comparison

| Feature | Approach 1 | Approach 2 |
|---------|-----------|------------|
| Processor | Python | Flink SQL |
| Checkpoint | Simulated | Real |
| Job in Flink UI | No | Yes (auto-submitted) |
| Output | Kafka topic | Kafka topic |
| Complexity | Low | Medium |
| Use Case | Demo/checkpoint sim | Production-like |

---

## Makefile Commands

```bash
make up        # Start Approach 1
make up-flink  # Start Approach 2 (Flink cluster only)
make down      # Stop all
make clean     # Clean up
```

---

## Stop

```bash
make down
```
