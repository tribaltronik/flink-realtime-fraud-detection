# Real-Time Fraud Detection with Apache Flink

This repository contains a **real-time fraud detection pipeline** built with **Apache Flink** and **Apache Kafka**.  
It simulates a stream of financial transactions, processes them with Flink’s stateful streaming APIs, and flags suspicious transactions based on simple fraud rules.

The project provides two local environments:

- **Docker Compose** — fast local development and configuration testing
- **Kubernetes (kind)** — production-like deployment and integration testing

---

## High-level architecture

- A **Kafka event generator** simulates financial transactions.
- **Flink** consumes the transaction stream from Kafka.
- Flink applies **fraud detection logic** (e.g., high-value transactions, velocity checks per user).
- Suspicious transactions are written to a separate Kafka topic and logged.

See `docs/architecture.md` and `docs/diagrams/architecture.txt` for more details.

---

## Repository structure

```text
src/
  fraud_detection_job.py      # Flink job (PyFlink)
  kafka_event_generator.py    # Transaction simulator

docker/
  docker-compose.yml          # Flink + Kafka stack
  flink-conf/                 # Flink configuration

k8s/
  kind-config.yaml            # kind cluster config
  flink-cluster.yaml          # Flink on K8s (SessionCluster)
  kafka.yaml                  # Kafka on K8s (simple deployment)

docs/
  architecture.md
  diagrams/architecture.txt

```
