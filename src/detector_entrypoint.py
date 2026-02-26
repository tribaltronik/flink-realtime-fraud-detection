import requests
import time

job_manager = "http://jobmanager:8081"

print("Waiting for Flink JobManager...")
for _ in range(30):
    try:
        r = requests.get(f"{job_manager}/overview", timeout=5)
        if r.status_code == 200:
            print("JobManager is ready!")
            break
    except Exception as e:
        print(f"Waiting... {e}")
    time.sleep(2)
else:
    print("JobManager not available after 60 seconds, exiting")
    exit(1)

print("Submitting fraud detection job...")

from pyflink.table import EnvironmentSettings, TableEnvironment

env_settings = EnvironmentSettings.in_streaming_mode()
t_env = TableEnvironment.create(env_settings)

t_env.get_config().set("execution.checkpointing.interval", "10s")

result = t_env.execute_sql("""
    CREATE TABLE transactions_source (
        transaction_id VARCHAR(100),
        user_id VARCHAR(100),
        amount DOUBLE,
        country VARCHAR(10),
        `timestamp` VARCHAR(50)
    ) WITH (
        'connector' = 'kafka',
        'topic' = 'transactions',
        'properties.bootstrap.servers' = 'kafka:9092',
        'properties.group.id' = 'flink-fraud-detector',
        'format' = 'json',
        'json.fail-on-missing-field' = 'false',
        'json.ignore-parse-errors' = 'true'
    )
""")
result.wait()

result = t_env.execute_sql("""
    CREATE TABLE suspicious_sink (
        transaction_id VARCHAR(100),
        user_id VARCHAR(100),
        amount DOUBLE,
        country VARCHAR(10),
        reason VARCHAR(50),
        `timestamp` VARCHAR(50)
    ) WITH (
        'connector' = 'kafka',
        'topic' = 'suspicious-transactions',
        'properties.bootstrap.servers' = 'kafka:9092',
        'format' = 'json'
    )
""")
result.wait()

result = t_env.execute_sql("""
    INSERT INTO suspicious_sink
    SELECT 
        transaction_id,
        user_id,
        amount,
        country,
        'HIGH_VALUE' AS reason,
        `timestamp`
    FROM transactions_source
    WHERE amount >= 5000
""")

print("Fraud detection job submitted successfully!")
result.wait()
