#!/bin/bash

set -e

TIMEOUT=60
SERVICES=(
    "localhost:2181:zookeeper"
    "localhost:9092:kafka"
    "localhost:8081:jobmanager"
)

wait_for_service() {
    local host=$1
    local port=$2
    local name=$3
    local count=0

    echo "Waiting for $name ($host:$port)..."

    while ! nc -z "$host" "$port" 2>/dev/null; do
        count=$((count + 1))
        if [ $count -ge $TIMEOUT ]; then
            echo "ERROR: $name ($host:$port) not ready after ${TIMEOUT}s"
            exit 1
        fi
        sleep 1
    done

    echo "$name is ready!"
}

for service in "${SERVICES[@]}"; do
    host=$(echo "$service" | cut -d: -f1)
    port=$(echo "$service" | cut -d: -f2)
    name=$(echo "$service" | cut -d: -f3)
    wait_for_service "$host" "$port" "$name"
done

echo "All services are ready!"
