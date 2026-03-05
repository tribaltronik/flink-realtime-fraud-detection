#!/bin/bash

echo 'Waiting for JobManager to be ready...'
until curl -sf http://jobmanager:8081/overview | grep -q 'taskmanagers.*1'; do
    sleep 2
done
echo 'JobManager ready, waiting for Kafka...'
sleep 10
echo 'Submitting Flink SQL job...'

cat > /tmp/submit.sql << 'EOFSQL'
CREATE TABLE transactions (
    transaction_id STRING,
    user_id STRING,
    amount DOUBLE,
    country STRING,
    `timestamp` BIGINT
) WITH (
    'connector' = 'kafka',
    'topic' = 'transactions',
    'properties.bootstrap.servers' = 'kafka:9092',
    'format' = 'json',
    'scan.startup.mode' = 'earliest-offset'
);

CREATE TABLE suspicious_transactions (
    transaction_id STRING,
    user_id STRING,
    amount DOUBLE,
    country STRING,
    `timestamp` BIGINT,
    reasons ARRAY<STRING>,
    detected_at TIMESTAMP(3)
) WITH (
    'connector' = 'print'
);

INSERT INTO suspicious_transactions
SELECT 
    transaction_id,
    user_id,
    amount,
    country,
    `timestamp`,
    reasons,
    CAST(CURRENT_TIMESTAMP AS TIMESTAMP(3))
FROM (
    SELECT 
        *,
        ARRAY[
            CASE WHEN amount >= 5000 THEN 'HIGH_VALUE' END,
            CASE WHEN country IN ('XX', 'YY', 'ZZ') THEN 'RISK_COUNTRY' END,
            CASE WHEN amount > 3000 AND MOD(CAST(amount AS INT), 1000) = 0 THEN 'ROUND_AMOUNT' END
        ] AS reasons
    FROM transactions
)
WHERE 
    amount >= 5000 
    OR country IN ('XX', 'YY', 'ZZ')
    OR (amount > 3000 AND MOD(CAST(amount AS INT), 1000) = 0);
EOFSQL

cp /tmp/submit.sql /job/submit.sql

echo "SQL file prepared. Job will be submitted."

SQL_PID=$!

echo "SQL client started with PID $SQL_PID"

sleep 180

echo 'Done!'
tail -100 /tmp/sql-client.log
