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

## Approach 2: With Flink (Next Iteration)

```
┌─────────────────┐     ┌─────────┐     ┌──────────────────┐     ┌──────────────────────────┐
│  Transaction    │────▶│  Kafka  │────▶│  Flink Job       │────▶│  Suspicious Transactions │
│  Generator       │     │ :9092   │     │  (SQL or Python)│     │  (Kafka Topic)           │
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
- **Flink Job**: Processes streaming data with fault tolerance

### Flink Advantages
- **Exactly-once processing** - checkpointing
- **Stateful processing** - fault-tolerant state
- **Parallelism** - scale horizontally
- **Event time** - windowing, late data handling
- **Savepoints** - stop/resume jobs
- **Metrics** - built-in monitoring
- **Windowing** - tumbling, sliding, session windows

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

## Next Steps (Flink Iteration)

1. Set up Flink cluster properly
2. Use Flink SQL for fraud detection
3. Add windowed aggregations
4. Implement stateful processing
5. Add checkpointing
6. Configure alerting
7. Deploy to Kubernetes
