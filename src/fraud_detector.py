import os
import json
from datetime import datetime, timedelta
from kafka import KafkaProducer, KafkaConsumer
from collections import defaultdict

KAFKA_BROKER = os.getenv("KAFKA_BROKER", "kafka:9092")

HIGH_VALUE_THRESHOLD = 5000
VELOCITY_WINDOW_MINUTES = 5
VELOCITY_MAX_TRANSACTIONS = 5
RISK_COUNTRIES = ["XX", "YY", "ZZ"]


class FraudDetector:
    def __init__(self):
        self.user_transaction_counts = defaultdict(list)
        self.user_last_amounts = defaultdict(list)
        self.producer = KafkaProducer(
            bootstrap_servers=KAFKA_BROKER,
            value_serializer=lambda v: json.dumps(v).encode("utf-8"),
        )
        print(f"Initialized fraud detector", flush=True)

    def check_high_value(self, tx):
        if tx.get("amount", 0) >= HIGH_VALUE_THRESHOLD:
            return "HIGH_VALUE"
        return None

    def check_velocity(self, tx):
        user_id = tx.get("user_id")
        now = datetime.utcnow()

        self.user_transaction_counts[user_id] = [
            t
            for t in self.user_transaction_counts[user_id]
            if now - t < timedelta(minutes=VELOCITY_WINDOW_MINUTES)
        ]

        self.user_transaction_counts[user_id].append(now)

        if len(self.user_transaction_counts[user_id]) > VELOCITY_MAX_TRANSACTIONS:
            return "HIGH_VELOCITY"
        return None

    def check_unusual_country(self, tx):
        if tx.get("country") in RISK_COUNTRIES:
            return "RISK_COUNTRY"
        return None

    def check_amount_pattern(self, tx):
        amount = tx.get("amount", 0)
        if amount > 0 and amount % 1000 == 0 and amount > 3000:
            return "ROUND_AMOUNT"
        return None

    def check_rapid_increase(self, tx):
        user_id = tx.get("user_id")
        amount = tx.get("amount", 0)

        self.user_last_amounts[user_id].append(amount)
        recent = self.user_last_amounts[user_id][-5:]

        if len(recent) >= 3:
            if all(recent[i] < recent[i + 1] for i in range(len(recent) - 1)):
                if amount > sum(recent[:-1]) / len(recent[:-1]) * 2:
                    return "RAPID_INCREASE"
        return None

    def check_alternating_countries(self, tx):
        user_id = tx.get("user_id")
        return None

    def detect(self, tx):
        reasons = []

        for check in [
            self.check_high_value,
            self.check_velocity,
            self.check_unusual_country,
            self.check_amount_pattern,
            self.check_rapid_increase,
        ]:
            reason = check(tx)
            if reason:
                reasons.append(reason)

        if reasons:
            tx["reasons"] = reasons
            tx["detected_at"] = datetime.utcnow().isoformat() + "Z"
            return True
        return False

    def run(self):
        print("Starting complex fraud detector...", flush=True)

        consumer = KafkaConsumer(
            "transactions",
            bootstrap_servers=KAFKA_BROKER,
            value_deserializer=lambda m: json.loads(m.decode("utf-8")),
            auto_offset_reset="latest",
            group_id="flink-fraud-detector",
        )

        print(f"Listening on 'transactions' topic...", flush=True)

        for message in consumer:
            try:
                tx = message.value

                if self.detect(tx):
                    self.producer.send("suspicious-transactions", tx)
                    self.producer.flush()
                    print(
                        f"FLINK ALERT: {tx.get('transaction_id')} - {tx.get('reasons')}",
                        flush=True,
                    )

            except Exception as e:
                print(f"Error: {e}", flush=True)


if __name__ == "__main__":
    detector = FraudDetector()
    detector.run()
