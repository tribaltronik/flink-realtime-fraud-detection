# Architecture

## Approach 1: Without Flink (Current POC)

```
┌─────────────────┐     ┌─────────┐     ┌──────────────────┐     ┌──────────────────────────┐
│  Transaction    │────▶│  Kafka  │────▶│  Python Detector │────▶│  Suspicious Transactions │
│  Generator       │     │ :9092   │     │  (Kafka Consumer)│     │  (Kafka Topic)           │
└─────────────────┘     └─────────┘     └──────────────────┘     └──────────────────────────┘
```

### Components
- **Generator**: Produces fake transactions to Kafka `transactions` topic
- **Kafka**: Message broker
- **Python Detector**: Kafka consumer that applies fraud detection rules
- **Output**: Suspicious transactions written to `suspicious-transactions` topic

### Fraud Detection Rules
- `HIGH_VALUE` - amount ≥ 5000
- `HIGH_VELOCITY` - >5 transactions in 5 minutes per user
- `RISK_COUNTRY` - transactions from XX, YY, ZZ
- `ROUND_AMOUNT` - round amounts (multiples of 1000) > 3000
- `RAPID_INCREASE` - amount doubling vs recent average

### Pros
- Simple to understand and debug
- Easy to customize detection logic in Python
- No additional infrastructure needed

### Cons
- No built-in parallelism (single consumer)
- No state management (in-memory only, lost on restart)
- No checkpointing/savepoints
- Manual scaling

---

## Approach 2: With Flink (POC)

```
┌─────────────────┐     ┌─────────┐     ┌──────────────────┐     ┌──────────────────────────┐
│  Transaction    │────▶│  Kafka  │────▶│  Flink Job       │────▶│  Suspicious Transactions │
│  Generator       │     │ :9092   │     │  (Flink SQL)     │     │  (Kafka Topic)           │
└─────────────────┘     └─────────┘     └──────────────────┘     └──────────────────────────┘
                              ▲
                              │
                        ┌─────┴─────┐
                        │  Flink    │
                        │  Cluster  │
                        │ JM + TM   │
                        └───────────┘
```

### Components
- **Generator**: Produces fake transactions
- **Kafka**: Message broker
- **Flink Cluster**: JobManager + TaskManager
- **Flink SQL Job**: Processes streaming data with fault tolerance

### Flink SQL Features Demonstrated
- **Checkpointing** - Every 10 seconds for fault tolerance
- **Event Time Processing** - Using timestamps and watermarks
- **Windowing** - Tumbling windows for velocity detection
- **Exactly-once** - Kafka exactly-once semantics
- **Fault Tolerance** - Job can restart from checkpoint

### Fraud Detection Rules (Flink SQL)
- `HIGH_VALUE` - amount ≥ 5000 (filter)
- `HIGH_VELOCITY` - >5 transactions in 5 min window (tumbling window)
- `RISK_COUNTRY` - XX, YY, ZZ (filter)

### How to Submit Job

1. Start the cluster:
   ```bash
   make up-flink
   ```

2. Access Flink SQL client:
   ```bash
   docker exec -it docker-flink-sql-1 /opt/flink/bin/sql-client.sh
   ```

3. Paste the SQL from `docker/flink-sql/fraud-detection.sql`

4. Check Flink UI: http://localhost:8081

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

---

## Comparison

| Feature | Without Flink | With Flink |
|---------|---------------|------------|
| Complexity | Low | Medium |
| Parallelism | Manual | Built-in |
| Fault Tolerance | None | Checkpoints |
| State Management | In-memory | RocksDB |
| Windowing | Manual | Native |
| Exactly-once | No | Yes |
| Scaling | Manual | Automatic |
| Monitoring | Custom | Built-in |

---

## Note on Flink SQL Client

The Flink SQL client in standalone mode runs in "embedded" mode, which means it executes queries locally. For production or proper job submission, you would need:

1. **Flink SQL Gateway** - REST API for job submission
2. **Build Flink JAR** - Compile SQL into a proper Flink job
3. **Session Cluster** - Submit jobs to an existing cluster

For this POC, the SQL client is provided for manual job submission and experimentation.

---

## Next Steps

1. Test both approaches
2. Compare performance and features
3. For Kubernetes deployment, use Flink Kubernetes Operator
4. Add more complex fraud detection rules
5. Add metrics and monitoring
