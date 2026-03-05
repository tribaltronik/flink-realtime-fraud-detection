# Architecture

## Overview

This project demonstrates real-time fraud detection using two approaches:

- **Approach 1**: Kafka + Python Detector (checkpoint simulation)
- **Approach 2**: Kafka + Apache Flink Cluster (SQL-based)

---

## Approach 1: Python Detector

```
┌─────────────────┐     ┌─────────┐     ┌──────────────────┐     ┌──────────────────────────┐
│  Transaction    │────▶│  Kafka  │────▶│  Python Detector │────▶│  Suspicious Transactions │
│  Generator       │     │ :9092   │     │  (flink_detector │     │  (Kafka Topic)           │
└─────────────────┘     └─────────┘     │   .py)           │     └──────────────────────────┘
                                        └──────────────────┘
```

### Components

| Component | Description |
|-----------|-------------|
| Generator | Produces fake transactions to Kafka `transactions` topic |
| Kafka | Message broker (confluentinc/cp-kafka:7.5.0) |
| Python Detector | Kafka consumer that applies fraud detection rules |
| Output | Suspicious transactions written to `suspicious-transactions` topic |

### Fraud Detection Rules

| Rule | Condition |
|------|-----------|
| HIGH_VALUE | amount >= 5000 |
| HIGH_VELOCITY | >5 transactions in 5 minutes per user |
| RISK_COUNTRY | transactions from XX, YY, ZZ |
| ROUND_AMOUNT | round amounts (multiples of 1000) > 3000 |

### How to Run

```bash
make up
```

Watch alerts:
```bash
docker exec docker-kafka-1 kafka-console-consumer --topic suspicious-transactions --from-beginning --bootstrap-server localhost:9092
```

### Pros

- Simple to understand and debug
- Easy to customize detection logic in Python
- No additional infrastructure needed

### Cons

- No built-in parallelism (single consumer)
- No state management (in-memory only, lost on restart)
- Checkpoint is simulated (not real)
- Manual scaling

---

## Approach 2: Apache Flink Cluster

```
┌─────────────────┐     ┌─────────┐     ┌──────────────────────────────────────────┐
│  Transaction    │────▶│  Kafka  │────▶│           Flink Cluster                  │
│  Generator       │     │ :9092   │     │  ┌────────────┐    ┌────────────────┐   │
└─────────────────┘     └─────────┘     │  │ JobManager │───▶│  TaskManager   │   │
                                          │  (REST :8081)│    │  (Fraud SQL)  │   │
                                          └────────────┘    └────────────────┘   │
                                          │                      │              │
                                          │                      ▼              │
                                          │           ┌─────────────────────┐    │
                                          │           │  Print Sink         │    │
                                          │           │  (taskmanager logs) │    │
                                          │           └─────────────────────┘    │
                                          └──────────────────────────────────────┘
```

### Components

| Component | Description |
|-----------|-------------|
| Generator | Produces fake transactions to Kafka |
| Kafka | Message broker (confluentinc/cp-kafka:7.5.0) |
| Flink JobManager | Cluster manager + REST API (port 8081) |
| Flink TaskManager | Executes the fraud detection job |
| SQL Job | Flink SQL processing streaming data |

### Fraud Detection Rules (Flink SQL)

| Rule | Condition |
|------|-----------|
| HIGH_VALUE | amount >= 5000 |
| RISK_COUNTRY | country IN ('XX', 'YY', 'ZZ') |
| ROUND_AMOUNT | amount > 3000 AND MOD(CAST(amount AS INT), 1000) = 0 |

### How to Run

```bash
make up-flink
```

This automatically:
1. Starts Kafka, Zookeeper, Flink JobManager/TaskManager
2. Creates Kafka topic `transactions`
3. Submits the fraud detection SQL job
4. Starts the transaction generator

### Verify Job is Running

```bash
# Check Flink jobs
curl -s http://localhost:8081/jobs

# Watch suspicious transactions (TaskManager logs)
docker logs -f docker-taskmanager-1

# Open Flink UI
# http://localhost:8081
```

### Manual Job Submission (Optional)

If you need to modify the SQL or re-submit:

```bash
# Edit the SQL file
vim docker/detector-flink/submit.sql

# Re-submit
./submit-job.sh
```

### Pros

- Exactly-once processing with checkpointing
- Stateful processing with fault tolerance
- Parallel processing out of the box
- Event time and windowing support
- Savepoints for stop/resume
- Built-in metrics

### Cons

- More complex setup
- Requires learning Flink SQL
- Additional infrastructure (Flink cluster)
- Output goes to logs (not Kafka) - can be changed to Kafka sink

---

## Comparison

| Feature | Approach 1 (Python) | Approach 2 (Flink) |
|---------|---------------------|---------------------|
| Processor | Python | Flink SQL |
| Checkpoint | Simulated | Real (if configured) |
| Parallelism | Manual | Built-in |
| Fault Tolerance | None | Checkpoints |
| State Management | In-memory | RocksDB (if enabled) |
| Windowing | Manual | Native |
| Exactly-once | No | Yes |
| Scaling | Manual | Automatic |
| Monitoring | Custom | Built-in (Flink UI) |
| Complexity | Low | Medium |
| Output | Kafka topic | Print to logs |
| Use Case | Demo/POC | Production-like |

---

## Technology Stack

| Component | Version |
|-----------|---------|
| Kafka | 7.5.0 |
| Zookeeper | 7.5.0 |
| Flink | 1.18 |
| Python | 3.x |
| Kafka Connector | 3.2.0-1.18 |

---

## Project Structure

```
flink-realtime-fraud-detection/
├── docker/
│   ├── docker-compose.without-flink.yml  # Approach 1
│   ├── docker-compose.with-flink.yml     # Approach 2
│   ├── detector/
│   │   └── Dockerfile                    # Python fraud detector
│   ├── detector-flink/
│   │   └── submit.sql                    # Flink SQL fraud detection
│   └── generator/                        # Kafka message generator
├── src/
│   ├── fraud_detector.py              # Python fraud detector
│   └── kafka_event_generator.py      # Kafka message generator
├── docs/                                 # Documentation
├── submit-job.sh                         # Manual job submission script
├── makefile                              # Build automation
└── README.md
```
