# Real-Time Fraud Detection

Two approaches to demonstrate real-time fraud detection:

- **Approach 1**: Kafka + Generator + Python Detector (with checkpoint simulation)
- **Approach 2**: Kafka + Flink Cluster + Generator (SQL-based fraud detection)

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           APPROACH 1                                        │
│                    (Python Detector + Checkpoint Simulation)               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌──────────┐      ┌─────────────────┐      ┌──────────────────────┐       │
│   │  Kafka   │ ───▶ │ Python Detector │ ───▶ │  Kafka Topic        │       │
│   │ Generator│      │  (flink_detector│      │  suspicious-        │       │
│   └──────────┘      │   .py)          │      │  transactions       │       │
│                     │                 │      └──────────────────────┘       │
│                     │ • HIGH_VALUE    │              │                     │
│                     │ • HIGH_VELOCITY │              ▼                     │
│                     │ • Checkpoint    │      ┌──────────────────────┐      │
│                     │   Simulation    │      │  Console Consumer    │      │
│                     └─────────────────┘      └──────────────────────┘      │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                           APPROACH 2                                        │
│                      (Apache Flink Cluster)                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌──────────┐      ┌─────────────────────────────────────────────────┐   │
│   │  Kafka   │ ───▶ │              Flink Cluster                       │   │
│   │ Generator│      │  ┌─────────────┐       ┌─────────────────┐    │   │
│   └──────────┘      │  │ JobManager  │──────▶│  TaskManager    │    │   │
│                     │  │  (REST API) │       │  (Fraud SQL)    │    │   │
│                     │  └─────────────┘       └─────────────────┘    │   │
│                     │         │                        │               │   │
│                     │         │                        ▼               │   │
│                     │         │              ┌─────────────────┐     │   │
│                     │         └──────────────▶│  Print Sink     │     │   │
│                     │                        │  (taskmanager   │     │   │
│                     │                        │   logs)         │     │   │
│                     │                        └─────────────────┘     │   │
│                     │                                                      │   │
│                     │  Fraud Rules (SQL):                                 │   │
│                     │  • amount >= 5000 → HIGH_VALUE                     │   │
│                     │  • country IN ('XX','YY','ZZ') → RISK_COUNTRY     │   │
│                     │  • amount > 3000 AND round → ROUND_AMOUNT         │   │
│                     └──────────────────────────────────────────────────────┘   │
│                                         │                                    │
│                                         ▼                                    │
│                              ┌──────────────────────┐                       │
│                              │   Flink UI           │                       │
│                              │   http://localhost:   │                       │
│                              │   8081               │                       │
│                              └──────────────────────┘                       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

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
- Suspicious transactions printed to TaskManager logs

```bash
# Watch suspicious transactions (TaskManager logs)
docker logs -f docker-taskmanager-1

# Or via Flink UI
# Open http://localhost:8081
```

---

## Comparison

| Feature | Approach 1 | Approach 2 |
|---------|-----------|------------|
| Processor | Python | Flink SQL |
| Checkpoint | Simulated | Real |
| Job in Flink UI | No | Yes (auto-submitted) |
| Output | Kafka topic | Print to logs |
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
