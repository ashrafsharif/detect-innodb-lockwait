# detect-innodb-lockwait

1) Enable performance schema query intstrumentation:

```sql
UPDATE performance_schema.setup_consumers SET ENABLED = 'YES' WHERE NAME = 'events_statements_history';
UPDATE performance_schema.setup_consumers SET ENABLED = 'YES' WHERE NAME = 'events_statements_history_long';
```

2) Verify that the following is enabled:

```sql
mysql> SELECT * FROM performance_schema.setup_consumers;
+--------------------------------+---------+
| NAME                           | ENABLED |
+--------------------------------+---------+
| events_stages_current          | NO      |
| events_stages_history          | NO      |
| events_stages_history_long     | NO      |
| events_statements_current      | YES     |
| events_statements_history      | YES     |
| events_statements_history_long | YES     |
| events_waits_current           | NO      |
| events_waits_history           | NO      |
| events_waits_history_long      | NO      |
| global_instrumentation         | YES     |
| thread_instrumentation         | YES     |
| statements_digest              | YES     |
+--------------------------------+---------+
```

3) Configure MySQL client credentials inside `~/.my.cnf`. If you are running as root, make sure the following line exist inside `/root/.my.cnf`:

```
[mysql]
user=root
password=theS3cr3tP4ss
```

4) Modify the following:

```bash
#-------- Change me -------#
# Directory to produce the report
OUTPUT_DIR=/root/troubleshooting/lock_wait/
# Interval to check in seconds
INTERVAL=2
# Database name
SCHEMA='dbname'
# Send notification via telegram, require in PATH: https://github.com/fabianonline/telegram.sh
NOTIFY_TELEGRAM=1
# Create the report if the active transactions are more than 10.
ACTIVE_TRX=10
#--------------------------#
```

5) Run the script in the background:

```bash
nohup ./detect_lock &
````

## Notes

* `NOTIFY_TELEGRAM=1` requires you to create a bot and channel. Refer to [this blog](https://severalnines.com/database-blog/mobile-alerts-notifications-your-database-using-telegram) for example. Whenever lock-wait transactions are detected for every `INTERVAL` with more than `ACTIVE_TRX` as in InnoDB engine status, you shall receive a notification in your Telegram channel.
* If you are suffering from this `ERROR 1205 (HY000): Lock wait timeout exceeded; try restarting transaction`, you probably want to set `innodb_rollback_on_timeout=1` first (require MySQL/MariaDB restart) for a full rollback of the failed transaction.
* `INTERVAL=10` should be a good value to start, for the default `innodb_lock_wait_timeout` (50 seconds). Reduce this number if you want it to be more aggresive.
* The example of generated report file name under `OUTPUT_DIR` is `report_1603310559`, in the format of `report_{UNIXtimestamp}`. To modify this, find the `filename` variable.
