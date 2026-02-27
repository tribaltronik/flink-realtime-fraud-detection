# Real-Time Fraud Detection

Two approaches to demonstrate real-time fraud detection:

- **Approach 1**: Kafka + Generator + Python Detector (with checkpoint simulation)
- **Approach 2**: Kafka + Flink Cluster + Generator (for manual Flink job submission)

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

### Approach 2 (Flink Cluster - Manual Job Submission)

```bash
make up-flink
```

Features:
- Flink JobManager + TaskManager running
- Flink UI: http://localhost:8081
- Ready for manual Flink job submission

**To submit a Flink job manually:**
```bash
# Connect to Flink SQL client
docker exec -it docker-jobmanager-1 /opt/flink/bin/sql-client.sh
```

---

## Comparison

| Feature | Approach 1 | Approach 2 |
|---------|-----------|------------|
| Status | Working | Flink cluster running |
| Checkpoint | Simulated | Real (if job submitted) |
| Job in Flink UI | No | No (manual submit) |
| Complexity | Low | Medium |

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
