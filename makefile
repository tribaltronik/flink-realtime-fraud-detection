.PHONY: start stop build up down generate job docker-compose kubernetes test test-generator test-detector build-generator build-detector

start: build up

build: build-generator build-detector

build-generator:
	docker build -f docker/generator/Dockerfile -t fraud-generator .

build-detector:
	docker build -f docker/detector/Dockerfile -t fraud-detector .

up:
	cd docker && docker-compose up -d
	./scripts/wait-for-infra.sh
	cd docker && docker-compose exec -T kafka kafka-topics --create --topic transactions --bootstrap-server kafka:9092 --partitions 3 --replication-factor 1 || true
	cd docker && docker-compose exec -T kafka kafka-topics --create --topic suspicious-transactions --bootstrap-server kafka:9092 --partitions 3 --replication-factor 1 || true

down:
	cd docker && docker-compose down

stop:
	cd docker && docker-compose down

docker-compose:
	cd docker && docker-compose up -d

kubernetes:
	kind create cluster --config k8s/kind-config.yaml
	kubectl apply -f k8s/kafka.yaml
	kubectl apply -f k8s/flink-cluster.yaml
	kubectl port-forward svc/flink-jobmanager 8081:8081

generate:
	cd docker && docker-compose up generator

job:
	@echo "To run the detection job, you need pyflink installed locally:"
	@echo "  uv pip install apache-flink"
	@echo "Then run:"
	@echo "  python src/fraud_detection_job.py"

test: test-generator

test-generator:
	@echo "Testing generator container..."
	@docker run --rm --entrypoint python fraud-generator -c "from kafka import KafkaProducer; print('kafka-python OK')"
	@docker run --rm --entrypoint python fraud-generator -c "import json; print('json OK')"
	@echo "Generator container tests passed!"

test-detector:
	@echo "Testing detector container..."
	@docker run --rm --entrypoint python fraud-detector -c "from pyflink.datastream import StreamExecutionEnvironment; print('pyflink OK')"
	@echo "Detector container tests passed!"

build-all: build-generator build-detector
