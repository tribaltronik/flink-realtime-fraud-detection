# Flink Job Submission - Step by Step Guide

## Overview

This document provides a step-by-step guide for submitting a Flink SQL job to detect fraud in real-time transactions.

## Quick Start

```bash
make up-flink
```

This single command:
1. Starts Kafka, Zookeeper, Flink JobManager, TaskManager
2. Waits for cluster to be ready
3. **Automatically submits the fraud detection SQL job**
4. Starts the transaction generator

Verify job is running:
```bash
curl -s http://localhost:8081/jobs
```

---

## Prerequisites

1. Docker and Docker Compose installed
2. Kafka topic `transactions` created (auto-created by makefile)

## Step-by-Step Process

### Step 1: Verify Flink Cluster is Running

```bash
docker ps --filter "name=flink" --filter "name=kafka"
```

Expected output:
```
NAMES            STATUS
docker-kafka-1   Up (healthy)
docker-jobmanager-1   Up
docker-taskmanager-1   Up
```

### Step 2: Check JobManager Status

```bash
curl -sf "http://localhost:8081/overview"
```

Expected output (formatted):
```json
{
    "taskmanagers": 1,
    "slots-total": 1,
    "slots-available": 1,
    "jobs-running": 0,
    ...
}
```

### Step 3: Check for Existing Jobs

```bash
curl -s http://localhost:8081/jobs
```

If no jobs exist, you will see:
```json
{"jobs": []}
```

### Step 4: Verify SQL File Exists

```bash
ls -la docker/detector-flink/submit.sql
```

### Step 5: Copy SQL File to JobManager Container

```bash
docker cp docker/detector-flink/submit.sql docker-jobmanager-1:/tmp/submit.sql
```

Verify:
```bash
docker exec docker-jobmanager-1 ls -la /tmp/submit.sql
```

### Step 6: Submit the SQL Job

```bash
docker exec docker-jobmanager-1 /opt/flink/bin/sql-client.sh -f /tmp/submit.sql
```

Expected output:
```
[INFO] Executing SQL from file.
[INFO] Execute statement succeed.
[INFO] Execute statement succeed.
[INFO] Submitting SQL update statement to the cluster...
[INFO] SQL update statement has been successfully submitted to the cluster:
Job ID: <job-id>
```

### Step 7: Verify Job is Running

```bash
curl -s http://localhost:8081/jobs
```

Expected output:
```json
{
    "jobs": [
        {
            "id": "<job-id>",
            "status": "RUNNING"
        }
    ]
}
```

### Step 8: Check Job Details

```bash
curl -s "http://localhost:8081/jobs/<job-id>"
```

Look for:
- `"state": "RUNNING"`
- Vertices status: `"RUNNING"`

---

## Common Issues and Solutions

### Issue 1: Missing SQL File

**Error:**
```
cp: cannot stat '/job/submit.sql': No such file or directory
```

**Solution:** Ensure `docker/detector-flink/submit.sql` exists.

---

### Issue 2: Docker-in-Docker Not Available

**Error:**
```
bash: line 3: docker: command not found
```

**Solution:** Use `docker exec` from host instead of inside container:
```bash
docker exec docker-jobmanager-1 /opt/flink/bin/sql-client.sh -f /tmp/submit.sql
```

---

### Issue 3: Kafka Connector Not Available

**Error:**
```
ValidationException: Could not find any factory for identifier 'kafka'
```

**Solution:** The jobmanager/taskmanager containers should have the Kafka connector JAR. If missing, add to docker-compose:
```yaml
command: >
  bash -c "
    if [ ! -f /opt/flink/lib/flink-connector-kafka-3.2.0-1.18.jar ]; then
      curl -sL -o /opt/flink/lib/flink-connector-kafka-3.2.0-1.18.jar https://repo1.maven.org/maven2/org/apache/flink/flink-connector-kafka/3.2.0-1.18/flink-connector-kafka-3.2.0-1.18.jar;
      curl -sL -o /opt/flink/lib/kafka-clients-3.2.0.jar https://repo1.maven.org/maven2/org/apache/kafka/kafka-clients/3.2.0/kafka-clients-3.2.0.jar;
    fi;
    /docker-entrypoint.sh jobmanager
  "
```

---

### Issue 4: Schema Mismatch - Timestamp Type

**Error:**
```
ValidationException: Column types of query result and sink do not match.
Incompatible types for sink column 'timestamp' at position 4.
Query schema: [..., timestamp: BIGINT, ...]
Sink schema: [..., timestamp: STRING, ...]
```

**Solution:** The Kafka messages contain `timestamp` as ISO string (e.g., `"2026-03-02T21:56:52.924215Z"`), not epoch milliseconds. Update `submit.sql`:

```sql
CREATE TABLE transactions (
    ...
    `timestamp` STRING  -- NOT BIGINT
) WITH (...);
```

---

### Issue 5: Non-TTY Environment

**Error:**
```
the input device is not a TTY
```

**Solution:** Remove `-it` flag:
```bash
docker exec docker-jobmanager-1 /opt/flink/bin/sql-client.sh -f /tmp/submit.sql
```

---

## Automated Submission

Use the provided script:

```bash
./submit-job.sh
```

This script:
1. Waits for JobManager to be ready
2. Copies SQL file to container
3. Submits job via SQL Client

---

## Quick Reference

| Action | Command |
|--------|---------|
| Start cluster + auto-submit job | `make up-flink` |
| Manual job submission | `./submit-job.sh` |
| Check jobs | `curl -s http://localhost:8081/jobs` |
| Cancel job | `curl -s -X DELETE http://localhost:8081/jobs/<job-id>` |
| View Flink UI | http://localhost:8081 |
| Watch alerts | `docker exec docker-kafka-1 kafka-console-consumer --topic suspicious-transactions --from-beginning --bootstrap-server localhost:9092` |

---

## Manual Submission (Optional)

If you need to modify the SQL or re-submit after changes:

```bash
# Edit the SQL file
vim docker/detector-flink/submit.sql

# Re-submit
./submit-job.sh
```

---

## Current Job Status

When running `make up-flink`, the job-submitter container will:
1. Download Kafka connector JARs if needed
2. Wait for JobManager REST API to respond
3. Submit the SQL job automatically

Check job-submitter logs:
```bash
docker logs docker-job-submitter-1
```

Expected output:
```
Waiting for Flink JobManager...
JobManager ready. Submitting SQL job...
Job submitted. Keeping container alive.
```
