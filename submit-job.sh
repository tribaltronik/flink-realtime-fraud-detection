#!/bin/bash

FLINK_HOST="${FLINK_HOST:-localhost}"
FLINK_PORT="${FLINK_PORT:-8081}"

echo "Waiting for Flink JobManager at ${FLINK_HOST}:${FLINK_PORT}..."
until curl -sf "http://${FLINK_HOST}:${FLINK_PORT}/overview" | grep -q 'taskmanagers'; do
    sleep 2
done
echo "Flink cluster ready!"

SQL_FILE="${1:-docker/detector-flink/submit.sql}"

if [ ! -f "$SQL_FILE" ]; then
    echo "Error: SQL file not found: $SQL_FILE"
    exit 1
fi

SQL_CONTAINER="${SQL_CONTAINER:-docker-jobmanager-1}"

echo "Copying SQL file to container..."
docker cp "$SQL_FILE" "${SQL_CONTAINER}:/tmp/submit.sql"

echo "Submitting SQL job from $SQL_FILE..."
docker exec "${SQL_CONTAINER}" /opt/flink/bin/sql-client.sh -f /tmp/submit.sql
