#!/bin/bash

PATH=/usr/bin:/bin:/root/bin

LOGDIR=/var/log/chkrootkit-scan-log/

LOGFILE=${LOGDIR}`date +%Y%m%d%H%M%S`.log
INFECTED_LOGFILE={$LOGFILE}_INFECTED.log

EMERCOMDIR=/root/chkrootkitcmd

if [ ! -e ${LOGDIR} ]; then
`mkdir ${LOGDIR}`
fi

#退避先が無いときのみ、chkrootkit使用コマンドを退避先ディレクトリへコピー
if [ ! -e ${EMERCOMDIR} ]; then
`mkdir ${EMERCOMDIR}`
cp `which --skip-alias awk cut echo egrep find head id ls netstat ps strings sed ssh uname` ${EMERCOMDIR}/
fi

touch ${LOGFILE}

#多重起動防止機講
# 同じ名前のプロセスが起動していたら起動しない。
if [ $$ != "`pgrep -fo $0`" ]
then
    echo "既に実行中のため、終了します。" >>${LOGFILE}
    exit 1;
fi


# ファイル更新日時が10日を越えたログファイルを削除
PARAM_DATE_NUM=10
find ${LOGDIR} -name "*.log" -type f -mtime +${PARAM_DATE_NUM} -exec rm -f {} \;

# chkrootkit実行
chkrootkit -p ${EMERCOMDIR}|grep INFECTED >> ${LOGFILE}

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

if [  -e ${INFECTED_LOGFILE} ]; then
chmod o+r ${INFECTED_LOGFILE}
fi


