from pyflink.table import EnvironmentSettings, TableEnvironment


TRANSACTIONS_TOPIC = "transactions"
SUSPICIOUS_TOPIC = "suspicious-transactions"
KAFKA_BROKER = "kafka:9092"
HIGH_VALUE_THRESHOLD = 5000.0


def main():
    env_settings = EnvironmentSettings.in_streaming_mode()
    t_env = TableEnvironment.create(env_settings)

    source_ddl = f"""
    CREATE TABLE transactions_source (
        transaction_id VARCHAR(100),
        user_id VARCHAR(100),
        amount DOUBLE,
        country VARCHAR(10),
        `timestamp` VARCHAR(50)
    ) WITH (
        'connector' = 'kafka',
        'topic' = '{TRANSACTIONS_TOPIC}',
        'properties.bootstrap.servers' = '{KAFKA_BROKER}',
        'properties.group.id' = 'flink-fraud-detector',
        'format' = 'json',
        'json.fail-on-missing-field' = 'false',
        'json.ignore-parse-errors' = 'true'
    )
    """

    sink_ddl = f"""
    CREATE TABLE suspicious_sink (
        transaction_id VARCHAR(100),
        user_id VARCHAR(100),
        amount DOUBLE,
        country VARCHAR(10),
        reason VARCHAR(50),
        `timestamp` VARCHAR(50)
    ) WITH (
        'connector' = 'kafka',
        'topic' = '{SUSPICIOUS_TOPIC}',
        'properties.bootstrap.servers' = '{KAFKA_BROKER}',
        'format' = 'json'
    )
    """

    t_env.execute_sql(source_ddl)
    t_env.execute_sql(sink_ddl)

    t_env.execute_sql(f"""
        INSERT INTO suspicious_sink
        SELECT 
            transaction_id,
            user_id,
            amount,
            country,
            'HIGH_VALUE' AS reason,
            `timestamp`
        FROM transactions_source
        WHERE amount >= {HIGH_VALUE_THRESHOLD}
    """)


if __name__ == "__main__":
    main()
