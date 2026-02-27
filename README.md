# Real-Time Fraud Detection

A real-time fraud detection pipeline demonstrating two approaches:
1. **Without Flink** - Simple Kafka consumer (current)
2. **With Flink** - Flink streaming (next iteration)

---

## Quick Start (Without Flink)

```bash
# Start infrastructure
cd docker && docker-compose up -d

# Create Kafka topics
docker exec docker-kafka-1 kafka-topics --create --topic transactions --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1
docker exec docker-kafka-1 kafka-topics --create --topic suspicious-transactions --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1

# Watch fraud alerts
docker exec docker-kafka-1 kafka-console-consumer --topic suspicious-transactions --from-beginning --bootstrap-server localhost:9092
```

Or use the Makefile:

```bash
make up      # Start all services
make down    # Stop all services
```

---

## Architecture

### Current (Without Flink)
```
Generator → Kafka → Python Detector → Suspicious Transactions
```

- **Generator**: Produces fake transactions to Kafka
- **Python Detector**: Kafka consumer with fraud detection rules
- **Output**: Suspicious transactions in Kafka topic

### Fraud Detection Rules
- `HIGH_VALUE` - amount ≥ 5000
- `HIGH_VELOCITY` - >5 transactions in 5 min per user
- `RISK_COUNTRY` - XX, YY, ZZ
- `ROUND_AMOUNT` - multiples of 1000, >3000
- `RAPID_INCREASE` - amount doubling

### Access Points
- Flink UI: http://localhost:8081 (running but not used)
- Kafka: localhost:9092

---

## Files

```
src/
  kafka_event_generator.py    # Transaction producer
  flink_detector.py           # Fraud detection logic

docker/
  docker-compose.yml          # Infrastructure
  generator/Dockerfile        # Generator container
  detector/Dockerfile         # Detector container
  lib/                        # Flink connectors (for next iteration)
  flink-sql/                  # Flink SQL (for next iteration)

docs/
  architecture.md             # Architecture comparison
```

---

## Next Iteration: With Flink

See `docs/architecture.md` for details on adding Flink.

Key Flink benefits:
- Exactly-once processing
- Stateful processing with fault tolerance
- Horizontal parallelism
- Windowing & aggregations
- Savepoints for stop/resume
- Built-in metrics

---

## Stop

```bash
make down
```
