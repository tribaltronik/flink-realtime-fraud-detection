import json
import os
import sys
from kafka import KafkaConsumer, KafkaProducer

KAFKA_BROKER = os.getenv("KAFKA_BROKER", "kafka:9092")
THRESHOLD = 5000

print(f"Starting fraud detector, threshold: {THRESHOLD}", flush=True)

consumer = KafkaConsumer(
    "transactions",
    bootstrap_servers=KAFKA_BROKER,
    value_deserializer=lambda m: json.loads(m.decode("utf-8")),
    auto_offset_reset="earliest",
    group_id="fraud-detector",
)

producer = KafkaProducer(
    bootstrap_servers=KAFKA_BROKER,
    value_serializer=lambda v: json.dumps(v).encode("utf-8"),
)

print(f"Listening on 'transactions' topic...", flush=True)

for message in consumer:
    try:
        tx = message.value
        amount = tx.get("amount", 0)

        if amount >= THRESHOLD:
            tx["reason"] = "HIGH_VALUE"
            producer.send("suspicious-transactions", tx)
            producer.flush()
            print(
                f"ALERT: High-value transaction: {tx.get('transaction_id')} - ${amount}",
                flush=True,
            )
    except Exception as e:
        print(f"Error processing message: {e}", flush=True)
