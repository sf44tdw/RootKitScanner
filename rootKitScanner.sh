#!/bin/bash

PATH=/usr/bin:/bin

LOGDIR=/var/log/chkrootkit-scan-log/

LOGFILE=${LOGDIR}`date +%Y%m%d%H%M%S`.log

#多重起動防止機講
SCRIPT_PID=${LOGDIR}/lock.pid
if [ -f $SCRIPT_PID ]; then
  PID=`cat $SCRIPT_PID `
  if (ps -e | awk '{print $1}' | grep $PID >/dev/null); then
    exit
  fi
fi

echo $$ > $SCRIPT_PID

# ファイル更新日時が10日を越えたログファイルを削除
PARAM_DATE_NUM=10
find ${LOGDIR} -name "*.log" -type f -mtime +${PARAM_DATE_NUM} -exec rm -f {} \;

# chkrootkit実行
chkrootkit > ${LOGFILE}
