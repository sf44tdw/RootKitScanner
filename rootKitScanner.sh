#!/bin/bash

PATH=/usr/bin:/bin

LOGDIR=/var/log/chkrootkit-scan-log/

LOGFILE=${LOGDIR}`date +%Y%m%d%H%M%S`.log
INFECTED_LOGFILE={$LOGFILE}_INFECTED.log

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

# SMTPSのbindshell誤検知対応
if [ ! -z "$(grep 465 ${LOGFILE})" ] && \
   [ -z $(/usr/sbin/lsof -i:465|grep bindshell) ]; then
        sed -i '/465/d' ${LOGFILE}
fi

# upstartパッケージ更新時のSuckit誤検知対応
if [ ! -z "$(grep Suckit ${LOGFILE})" ] && \
   [ -z $(rpm -V `rpm -qf /sbin/init`) ]; then
        sed -i '/Suckit/d' ${LOGFILE}
fi

# rootkit検知時のみroot宛メール送信
[ ! -z "$(grep INFECTED ${LOGFILE})" ] && \
grep INFECTED ${LOGFILE} > ${INFECTED_LOGFILE}

chmod o+r ${LOGFILE}

if [ ! -e ${INFECTED_LOGFILE}]; then
chmod o+r ${INFECTED_LOGFILE}
fi

rm $SCRIPT_PID
