#!/bin/bash
#jdy logs backup
#Author: zhang.shuang@9douyu.com

set -e

hostname=$(hostname)
prt_path=/home/work/web/www.9douyu.com
subbix_path=storage/logs
bak_path=/data/bak_log
today=`date +%Y-%m-%d`

for prt_name in 9douyu-service 9douyu-core 9douyu-module
do
    log_path=$prt_path/$prt_name/$subbix_path	

    echo "`date`: backup $prt_name log file begin..."

    cd $log_path
    # tar log file
    find . -name "*.log" | grep -v $today | awk '{printf "tar zcf %s.tgz %s \n", $0,$0}' | bash
    
    # remove origin log file
    find . -name "*.log*.tgz" | grep -v $today | awk '{printf "rm -f %s \n",$0}' | sed 's/.tgz//g' | bash

    target_path=$bak_path/$hostname/$prt_name

    if [ ! -d $target_path ];
    then
        mkdir -p $target_path
    fi
    tar_file=$(find . -name "*.tgz" | wc -l)
    if [ $tar_file -eq 0 ];
    then
	echo "$prt_name tgz log file not found"
    else
        
        # copy tgz file to target dir 
        cp *.tgz $target_path
        # remove tgz log file
        rm -f *.tgz
    fi
    echo "`date`: backup $prt_name log file end..."
done

