.PHONY: help up down clean

help:
	@echo "Real-Time Fraud Detection - Approach 1 (Without Flink)"
	@echo ""
	@echo "  make up     # Start Kafka + Generator + Detector"
	@echo "  make down   # Stop all containers"
	@echo "  make clean  # Remove containers and volumes"
	@echo ""
	@echo "Watch alerts:"
	@echo "  docker exec docker-kafka-1 kafka-console-consumer --topic suspicious-transactions --from-beginning --bootstrap-server localhost:9092"

up:
	cd docker && docker-compose -f docker-compose.without-flink.yml up -d
	@echo "Waiting for Kafka..."
	@sleep 10
	cd docker && docker exec docker-kafka-1 kafka-topics --create --topic transactions --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1 2>/dev/null || true
	cd docker && docker exec docker-kafka-1 kafka-topics --create --topic suspicious-transactions --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1 2>/dev/null || true
	@echo "Done! Watch alerts with:"
	@echo "  docker exec docker-kafka-1 kafka-console-consumer --topic suspicious-transactions --from-beginning --bootstrap-server localhost:9092"

down:
	cd docker && docker-compose -f docker-compose.without-flink.yml down

clean:
	cd docker && docker-compose -f docker-compose.without-flink.yml down -v
