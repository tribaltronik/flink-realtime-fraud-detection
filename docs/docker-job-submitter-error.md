# Docker Job Submitter Troubleshooting

## Original Error (March 2026)

```
docker logs docker-job-submitter-1
cp: cannot stat '/job/submit.sql': No such file or directory
bash: line 3: docker: command not found
bash: line 4: docker: command not found
```

## Root Cause Analysis

### Issue 1: Missing SQL File
The job-submitter service expected `/job/submit.sql` to exist at `docker/detector-flink/submit.sql`, but the file didn't exist initially.

### Issue 2: Docker-in-Docker Not Available
The original job-submitter attempted to use `docker exec` inside the container:
```yaml
command: >
  bash -c "
    cp /job/submit.sql /tmp/;
    docker exec docker-jobmanager-1 cp /job/submit.sql /tmp/;
    docker exec -d docker-jobmanager-1 /opt/flink/bin/sql-client.sh -f /tmp/submit.sql;
    sleep infinity
  "
```
This requires Docker-in-Docker (DinD), which was not configured.

### Issue 3: Job-Submitter Did Nothing
After initial fixes, the job-submitter was set to `sleep infinity` - it started the cluster but **never submitted the job**:
```yaml
job-submitter:
  command: ["sleep", "infinity"]
```

When running `make up-flink`, the Flink cluster started but no job was created.

---

## Current Fix (Implemented)

The `make up-flink` command now automatically submits the job:

1. **Docker Compose** starts the Flink cluster (JobManager, TaskManager, Kafka, Generator)
2. **Makefile** runs `./submit-job.sh` after containers are healthy
3. **submit-job.sh** runs the SQL Client inside the JobManager container via `docker exec`

### How It Works

```bash
# In makefile:
make up-flink
  -> docker-compose up -d
  -> sleep 15
  -> ./submit-job.sh  # Runs from host, executes SQL Client in jobmanager container
```

The `submit-job.sh` script:
1. Waits for JobManager REST API to respond
2. Copies SQL file to JobManager container
3. Executes SQL Client inside JobManager container via `docker exec`
4. Submits the INSERT statement which creates the running job

### Job-Submitter Container

The `job-submitter` service in docker-compose is now a placeholder that stays alive for potential debugging:
```yaml
job-submitter:
  command: ["sleep", "infinity"]
```

---

## How to Run

### Option 1: Auto-Submit (Recommended)

```bash
make up-flink
```

This now automatically:
1. Starts Kafka, Flink JobManager, TaskManager
2. Waits for cluster to be ready
3. Submits the fraud detection SQL job
4. Starts the transaction generator

Verify job is running:
```bash
curl -s http://localhost:8081/jobs
```

### Option 2: Manual Submission

If you need to modify the SQL before running:

```bash
make up-flink
# Edit docker/detector-flink/submit.sql
./submit-job.sh
```

---

## Verification Steps

After running `make up-flink`:

1. **Check job-submitter logs:**
   ```bash
   docker logs docker-job-submitter-1
   ```
   Look for: `Job submitted. Keeping container alive.`

2. **Check Flink jobs:**
   ```bash
   curl -s http://localhost:8081/jobs
   ```

3. **Check Flink UI:**
   - Open http://localhost:8081
   - Look for running job: "Flink SQL" or the sink table name

4. **Watch suspicious transactions:**
   ```bash
   docker exec docker-kafka-1 kafka-console-consumer \
     --topic suspicious-transactions --from-beginning \
     --bootstrap-server localhost:9092
   ```

---

## Common Issues

| Issue | Symptom | Solution |
|-------|---------|----------|
| JobManager not ready | "Waiting for Flink JobManager..." timeout | Increase sleep time or check `docker logs docker-jobmanager-1` |
| Kafka not ready | "Could not find any factory for identifier 'kafka'" | Check Kafka connector download in JobManager |
| Schema mismatch | "Column types do not match" | Update `submit.sql` timestamp type to STRING |

---

## Files Modified

| File | Change |
|------|--------|
| `docker/docker-compose.with-flink.yml` | Added auto-submit logic to job-submitter service |
| `docker/detector-flink/submit.sql` | SQL fraud detection rules |
| `submit-job.sh` | Manual submission script (still works if needed) |
