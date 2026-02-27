SET execution.checkpointing.interval = 10s;
SET pipeline.jars = file:///opt/flink/lib/flink-sql-connector-kafka-3.1.0-1.18.jar;

CREATE TABLE transactions_source (
    transaction_id STRING,
    user_id STRING,
    amount DOUBLE,
    country STRING,
    `timestamp` STRING
) WITH (
    'connector' = 'kafka',
    'topic' = 'transactions',
    'properties.bootstrap.servers' = 'kafka:9092',
    'properties.group.id' = 'flink-sql-detector',
    'format' = 'json',
    'json.fail-on-missing-field' = 'false',
    'json.ignore-parse-errors' = 'true',
    'scan.startup.mode' = 'latest-offset'
);

CREATE TABLE suspicious_sink (
    transaction_id STRING,
    user_id STRING,
    amount DOUBLE,
    country STRING,
    reason STRING,
    `timestamp` STRING,
    detected_at TIMESTAMP(3)
) WITH (
    'connector' = 'kafka',
    'topic' = 'suspicious-transactions-flink',
    'properties.bootstrap.servers' = 'kafka:9092',
    'format' = 'json'
);

INSERT INTO suspicious_sink
SELECT 
    transaction_id,
    user_id,
    amount,
    country,
    'HIGH_VALUE' AS reason,
    `timestamp`,
    CAST(CURRENT_TIMESTAMP AS TIMESTAMP(3))
FROM transactions_source
WHERE amount >= 5000;
