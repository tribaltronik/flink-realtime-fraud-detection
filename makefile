.PHONY: help up up-flink down clean

help:
	@echo "Real-Time Fraud Detection"
	@echo ""
	@echo "Approach 1 (With checkpoint simulation):"
	@echo "  make up          # Kafka + Generator + Detector (checkpoint simulation)"
	@echo ""
	@echo "Approach 2 (Flink cluster only - for manual Flink job submission):"
	@echo "  make up-flink    # Kafka + Flink Cluster + Generator"
	@echo ""
	@echo "Common:"
	@echo "  make down        # Stop all containers"
	@echo "  make clean      # Remove containers and volumes"
	@echo ""
	@echo "Watch alerts:"
	@echo "  docker exec docker-kafka-1 kafka-console-consumer --topic suspicious-transactions --from-beginning --bootstrap-server localhost:9092"

# Approach 1: With checkpoint simulation
up:
	cd docker && docker-compose -f docker-compose.without-flink.yml up -d
	@echo "Waiting for Kafka..."
	@sleep 10
	cd docker && docker exec docker-kafka-1 kafka-topics --create --topic transactions --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1 2>/dev/null || true
	cd docker && docker exec docker-kafka-1 kafka-topics --create --topic suspicious-transactions --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1 2>/dev/null || true
	@echo "Done! Watch alerts with:"
	@echo "  docker exec docker-kafka-1 kafka-console-consumer --topic suspicious-transactions --from-beginning --bootstrap-server localhost:9092"

# Approach 2: Flink cluster with auto job submission
up-flink:
	cd docker && docker-compose -f docker-compose.with-flink.yml up -d
	@echo "Waiting for Kafka and Flink..."
	@sleep 15
	cd docker && docker exec docker-kafka-1 kafka-topics --create --topic transactions --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1 2>/dev/null || true
	@echo "Submitting fraud detection job..."
	$(CURDIR)/submit-job.sh
	@echo "Done! Flink cluster is running with fraud detection job."
	@echo "  - Flink UI: http://localhost:8081"
	@echo "  - Watch alerts: docker exec docker-kafka-1 kafka-console-consumer --topic suspicious-transactions --from-beginning --bootstrap-server localhost:9092"

down:
	cd docker && docker-compose -f docker-compose.without-flink.yml down 2>/dev/null || true
	cd docker && docker-compose -f docker-compose.with-flink.yml down 2>/dev/null || true

clean:
	cd docker && docker-compose -f docker-compose.without-flink.yml down -v 2>/dev/null || true
	cd docker && docker-compose -f docker-compose.with-flink.yml down -v 2>/dev/null || true
