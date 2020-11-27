#!/bin/bash
## Detect InnoDB lockwait timeout by observing information_schema.INNODB_LOCK_WAITS and collect all information at the particular point
## Collected information are: innodb_lock_waits, innodb_trx, events_statements_history, events_statements_current, processlist, innodb status
## To run in background, run:
## nohup ./detect_lock &
## 

#-------- Change me -------#
# Directory to produce the report
OUTPUT_DIR=/root/troubleshooting/lock_wait/
# Interval to check in seconds
INTERVAL=10
# Database name
SCHEMA='dbname'
# Send notification via telegram, require in PATH: https://github.com/fabianonline/telegram.sh
NOTIFY_TELEGRAM=1
# Create the report if the active transactions are more than 10.
ACTIVE_TRX=10
#--------------------------#

COUNTER=0

[ -d $OUTPUT_DIR ] || mkdir -p $OUTPUT_DIR

while true; do
output=$(mysql -e 'SELECT * FROM information_schema.INNODB_LOCK_WAITS\G')

if [[ ! -z $output ]]; then
        ts=$(date +%s)
        filename=report_${ts}
	
        date > $OUTPUT_DIR/$filename
        echo 'INNODB_LOCK_WAIT' >> $OUTPUT_DIR/$filename
        echo '================' >> $OUTPUT_DIR/$filename
        mysql -e 'SELECT * FROM information_schema.INNODB_LOCK_WAITS\G' >> $OUTPUT_DIR/$filename
        echo >> $OUTPUT_DIR/$filename
	
        echo 'INNODB TRANSACTION' >> $OUTPUT_DIR/$filename
        echo '==================' >> $OUTPUT_DIR/$filename
        mysql -e 'SELECT * FROM information_schema.innodb_trx\G' >> $OUTPUT_DIR/$filename
        echo >> $OUTPUT_DIR/$filename
	
        echo 'CURRENT QUERIES' >> $OUTPUT_DIR/$filename
        echo '===============' >> $OUTPUT_DIR/$filename
        mysql -e "SELECT * FROM performance_schema.events_statements_current WHERE CURRENT_SCHEMA = \"$SCHEMA\" ORDER BY THREAD_ID\G" >> $OUTPUT_DIR/$filename
        echo >> $OUTPUT_DIR/$filename
	
        echo 'QUERIES HISTORY' >> $OUTPUT_DIR/$filename
        echo '===============' >> $OUTPUT_DIR/$filename
        mysql -e 'SELECT * FROM performance_schema.events_statements_history ORDER BY event_id\G' >> $OUTPUT_DIR/$filename
        echo >> $OUTPUT_DIR/$filename
	
        echo 'INFO SCHEMA' >> $OUTPUT_DIR/$filename
        echo '===============' >> $OUTPUT_DIR/$filename
	mysql -e 'SELECT ps.id "PROCESS ID", esh.event_name "EVENT NAME", esh.sql_text "SQL" FROM information_schema.innodb_trx trx JOIN information_schema.processlist ps ON trx.trx_mysql_thread_id = ps.id JOIN performance_schema.threads th ON th.processlist_id = trx.trx_mysql_thread_id JOIN performance_schema.events_statements_history_long esh ON esh.thread_id = th.thread_id WHERE ps.USER != "SYSTEM_USER" ORDER BY esh.EVENT_ID;' >> $OUTPUT_DIR/$filename
        echo >> $OUTPUT_DIR/$filename
	
        echo 'PROCESSLIST' >> $OUTPUT_DIR/$filename
        echo '===========' >> $OUTPUT_DIR/$filename
        mysql -e 'SHOW FULL PROCESSLIST' >> $OUTPUT_DIR/$filename
        echo >> $OUTPUT_DIR/$filename
	
        echo 'INNODB STATUS' >> $OUTPUT_DIR/$filename
        echo '=============' >> $OUTPUT_DIR/$filename
        mysql -e 'SHOW ENGINE INNODB STATUS\G' >> $OUTPUT_DIR/$filename
	
	# Only captures if there are more than ACTIVE_TRX value. Default is 10 transactions. Otherwise, remove the created report.
        if [ $(grep -i "active" $OUTPUT_DIR/$filename | wc -l) -gt $ACTIVE_TRX ]; then
		[ $NOTIFY_TELEGRAM -eq 1 ] && grep -i "active" $OUTPUT_DIR/$filename | telegram -
	else
		rm -Rf $OUTPUT_DIR/$filename
	fi
	
        COUNTER=$(( $COUNTER + 1 ))
fi
sleep $INTERVAL

done
