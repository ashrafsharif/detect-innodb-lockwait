#!/bin/bash

dir=/root/troubleshooting/lock_wait/collection10
counter=0
INTERVAL=2
SCHEMA='dbname'

while true; do
#output=$(mysql -e 'select * from information_schema.innodb_trx where trx_istate = "LOCK WAIT"\G')
output=$(mysql -e 'select * from information_schema.INNODB_LOCK_WAITS\G')

if [[ ! -z $output ]]; then
        ts=$(date +%s)
        filename=a${ts}
        date > $dir/$filename
        echo 'INNODB_LOCK_WAIT' >> $dir/$filename
        echo '================' >> $dir/$filename
        mysql -e 'select * from information_schema.INNODB_LOCK_WAITS\G' >> $dir/$filename
        echo >> $dir/$filename
        echo 'INNODB TRANSACTION' >> $dir/$filename
        echo '==================' >> $dir/$filename
        mysql -e 'select * from information_schema.innodb_trx\G' >> $dir/$filename
        echo >> $dir/$filename
        echo 'CURRENT QUERIES' >> $dir/$filename
        echo '===============' >> $dir/$filename
        mysql -e "select * from performance_schema.events_statements_current WHERE CURRENT_SCHEMA = "$SCHEMA" ORDER BY THREAD_ID\G" >> $dir/$filename
        echo >> $dir/$filename
        echo 'QUERIES HISTORY' >> $dir/$filename
        echo '===============' >> $dir/$filename
        mysql -e 'select * from performance_schema.events_statements_history order by event_id\G' >> $dir/$filename
        echo >> $dir/$filename
        echo 'INFO SCHEMA' >> $dir/$filename
        echo '===============' >> $dir/$filename
	mysql -e 'SELECT ps.id "PROCESS ID", esh.event_name "EVENT NAME", esh.sql_text "SQL" FROM information_schema.innodb_trx trx JOIN information_schema.processlist ps ON trx.trx_mysql_thread_id = ps.id JOIN performance_schema.threads th ON th.processlist_id = trx.trx_mysql_thread_id JOIN performance_schema.events_statements_history_long esh ON esh.thread_id = th.thread_id WHERE ps.USER != "SYSTEM_USER" ORDER BY esh.EVENT_ID;' >> $dir/$filename
        echo >> $dir/$filename
        echo 'PROCESSLIST' >> $dir/$filename
        echo '===========' >> $dir/$filename
        mysql -e 'show full processlist' >> $dir/$filename
        echo >> $dir/$filename
        echo 'INNODB STATUS' >> $dir/$filename
        echo '=============' >> $dir/$filename
        mysql -e 'show engine innodb status\G' >> $dir/$filename
        if [ $(grep -i "active" $dir/$filename | wc -l) -gt 16 ]; then
		grep -i "active" $dir/$filename | telegram -
	else
		rm -Rf $dir/$filename
	fi
        counter=$(( $counter + 1 ))
fi
sleep $INTERVAL

done
