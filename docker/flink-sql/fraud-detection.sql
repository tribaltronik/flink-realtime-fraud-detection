-- Flink SQL Fraud Detection Job
-- Create source table using datagen (for testing)
CREATE TABLE transactions (
    transaction_id STRING,
    user_id STRING,
    amount DOUBLE,
    country STRING,
    `timestamp` BIGINT
) WITH (
    'connector' = 'datagen',
    'rows-per-second' = '5',
    'fields.transaction_id.kind' = 'random',
    'fields.user_id.kind' = 'random',
    'fields.amount.min' = '1',
    'fields.amount.max' = '10000',
    'fields.country.kind' = 'random',
    'fields.country.length' = '2',
    'fields.timestamp.kind' = 'sequence',
    'fields.timestamp.start' = '1000',
    'fields.timestamp.end' = '2000'
);

-- Create sink table for suspicious transactions
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

-- Insert suspicious transactions with fraud detection rules
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

EXIT;
