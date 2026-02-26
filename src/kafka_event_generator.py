import json
import os
import random
import string
import time
from datetime import datetime

from kafka import KafkaProducer

KAFKA_BROKER = os.environ.get("KAFKA_BROKER", "localhost:9093")
TOPIC = "transactions"

USERS = [f"user_{i}" for i in range(1, 21)]
COUNTRIES = ["PT", "ES", "FR", "DE", "US", "BR"]


def random_transaction():
    user_id = random.choice(USERS)
    amount = round(random.uniform(1, 10000), 2)
    country = random.choice(COUNTRIES)
    tx_id = "".join(random.choices(string.ascii_uppercase + string.digits, k=10))
    return {
        "transaction_id": tx_id,
        "user_id": user_id,
        "amount": amount,
        "country": country,
        "timestamp": datetime.utcnow().isoformat() + "Z",
    }


def main():
    producer = KafkaProducer(
        bootstrap_servers=KAFKA_BROKER,
        value_serializer=lambda v: json.dumps(v).encode("utf-8"),
    )

    print("Starting transaction generator...")
    while True:
        tx = random_transaction()
        producer.send(TOPIC, tx)
        print("Sent:", tx)
        time.sleep(random.uniform(0.1, 1.0))


if __name__ == "__main__":
    main()
