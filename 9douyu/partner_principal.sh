#!/bin/bash
#desc : transform user principal data from jdy core database and create partner interest source data
#date : 2016-11-30
#author : zhang.shuang@9douyu.com

set -e

#db user
mysql_user="jiudouyu_w"

export MYSQL_PWD='TfTdPb3UujpPW7I'

#mysql host
mysql_host="rm-2ze208831wye022r6.mysql.rds.aliyuncs.com"

#mysql port
mysql_port=3306

#module dbname
module_db="jiudouyu_module_db"

#coer dbname
core_db="jiudouyu_core_db"

#invite table
invite_table="module_invite"

#partner invite pricipal table
partner_invite_table="module_partner_principal"

partner_invite_bak_table="module_partner_principal_bak"

#module current principal table
module_current_table="module_current_principal"

#module term principal table
module_term_table="module_term_principal"

#core current principal table
core_current_table="core_current_principal"

#core term principal table
core_term_table="core_term_principal"

#mysql cmd
mysql_cmd="/opt/lampp/bin/mysql -h${mysql_host} -u${mysql_user} -P${mysql_port}"

today=`date +%Y-%m-%d`

function truncate_partner_table(){

#truncate table
`$mysql_cmd <<EOF

        truncate table $module_db.$partner_invite_table;

EOF`

}

#query principal num
function query_principal_num(){

num1=`$mysql_cmd -N <<EOF
    select count(*) as num from $module_db.$module_current_table where created_at > '${today}';
EOF`

num2=`$mysql_cmd -N <<EOF
    select count(*) as num from $module_db.$module_term_table where created_at > '${today}';
EOF`

if [ $num1 -eq 0 ] || [ $num2 -eq 0 ];then
    echo "user principal data is empty"
    exit 1
fi

}

function back_principal_data(){

local yesterday=`date -d last-day +%Y-%m-%d`


`$mysql_cmd <<EOF

        INSERT INTO $module_db.$partner_invite_bak_table(user_id,invited_user_id,current_principal,term_principal,date,created_at,updated_at)
        SELECT user_id,invited_user_id,current_principal,term_principal,'${yesterday}' as date,created_at,updated_at
        FROM $module_db.$partner_invite_table where created_at > '${today}';

EOF`
}

function import_partner_data(){

#combine principal data
`$mysql_cmd <<EOF

    insert into
        $module_db.$partner_invite_table(user_id,current_principal,term_principal,invited_user_id)
    select
        t1.user_id,
        ifnull(t2.principal,0) as current_principal,
        ifnull(t3.principal,0) as term_principal,
        t1.other_user_id as invited_user_id
    from
        $module_db.$invite_table as t1
    left join $module_db.$module_current_table as t2 on t1.other_user_id = t2.user_id
    left join $module_db.$module_term_table as t3 on t1.other_user_id = t3.user_id
    where
        t1.user_type = 1
    and
        t1.created_at < '${today}';

EOF`

}

function truncate_principal_table(){

`$mysql_cmd <<EOF

	truncate table $module_db.$module_current_table;
	truncate table $module_db.$module_term_table;

EOF`

}


#import current principal data
function import_current_data(){


    `$mysql_cmd <<EOF

        INSERT INTO $module_db.$module_current_table
        SELECT * FROM $core_db.$core_current_table where created_at > '${today}';

EOF`

}

#import term principal data
function import_term_data(){


`$mysql_cmd <<EOF

        INSERT INTO $module_db.$module_term_table
        SELECT * FROM $core_db.$core_term_table where created_at > '${today}';

EOF`
}

function run_cmd(){

    local func=$1

    t=`date`
    echo $t":" $func
    $func
    if [ $? -ne 0 ];then
        echo "execute function $func failed"
        exit 1
    fi

}

#import principal data
function import_data(){

    local funcs="truncate_principal_table import_current_data import_term_data"

    for func in $funcs;
    do
        run_cmd $func
    done

}

#create partner principal
function combine_data(){

    local funcs="truncate_partner_table query_principal_num import_partner_data back_principal_data"

    for func in $funcs;
    do
        run_cmd $func
    done

}


function new_egg() {

    import_data
    combine_data

}

#程序入口
action=${1:-help}
if [ $# -lt 1 ]; then
    echo "Usage sh $0 help";
    exit 1
fi


function help() {

	cat <<-EOF

    Usage: manager.sh [options]

        Valid options are:

            new_egg                   import data and create partner principal data (import data && combine data)

            import_data               first execute import_data second combine data

            combine_data

            help                      show this help message and exit

EOF
}


$action "$@"


