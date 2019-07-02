<?php
    /**
     * Author : zhang.shuang@9douyu.com
     * Desc : transform  9douyu credit link data
     */

    # prod must update blew config
    $config = [
        'host' => '127.0.0.1',
        'port' => 3306,
        'user' => 'root',
        'passwd' => '1234',
        'charset' => 'utf8',
        'db' => 'jiudouyu_module_db'
    ];

    $config_types = [
        10 => [
            'source' => 10,
            'type' => 50,
        ],
        20 => [
            'source' => 20,
            'type' => 50,
        ],
        30 => [
            'source' => 30,
            'type' => 50,
         ],
        40 => [
            'source' => 40,
            'type' => 50,
         ],
        60 => [
            'source' => 0,
            'type' => 60
        ],
        70 => [
            'source' => 0,
            'type' => 70
        ]
    ];


    $page_size = 100;
    $conn = new mysqli($config['host'],$config['user'],$config['passwd'],$config['db'],$config['port']);

    if (mysqli_connect_errno()) {

        printf("Connect failed: %s\n", mysqli_connect_error());
        exit();
    }

    $conn->set_charset($config['charset']);

    $sql = "select count(id) as rowcount from module_project_link_credit";
    $result = $conn->query($sql);
    $row = $result->fetch_assoc();

    $rowcount = $row['rowcount'];

    $pages = ceil($row['rowcount'] / $page_size);

    $sql = "select id,source,type,outer_id from module_credit";
    $result = $conn->query($sql);
    $credit_data = $result->fetch_all(MYSQLI_ASSOC);

    $credit_list = [];

    foreach($credit_data as $item) {

        if($item['type'] == 70 || $item['type'] == 60){
            $source = 0;
        }else{
            $source = $item['source'];
        }
        $key = $item['outer_id'].'_'.$source.'_'.$item['type'];
        $credit_list[$key] = $item['id'];
    }

    $count = 0;
    for($page = 1; $page <= $pages;$page++){

        $base_insert_sql = "insert into module_project_link_credit_new(project_id,credit_id,created_at,updated_at) values";
        $insert_sql = '';

        $offset =  ($page - 1) * $page_size;
        $sql = sprintf("select * from module_project_link_credit limit %s,%s",$offset,$page_size);

        error_log("\r\n $sql",3,'sql_access.log');

        $result = $conn->query($sql);
        $data = $result->fetch_all(MYSQLI_ASSOC);

        foreach($data as $item){

            $project_id = $item['project_id'];
            $created_at = $item['created_at'];
            $updated_at = $item['updated_at'];

            $credit_info = json_decode($item['credit_info'],true);

            foreach($credit_info as $link_info){

                $type = $link_info['type'];
                $credit_id = $link_info['credit_id'];

                if(isset($config_types[$type])){

                    $key = $credit_id.'_'.$config_types[$type]['source'].'_'.$config_types[$type]['type'];
                    if(isset($credit_list[$key])){
                        $id = $credit_list[$key];
                        $count ++;
                    }else{
                        continue;
                    }
                }else{
                    continue;
                }

                $insert_sql .= "({$project_id},{$id},'{$created_at}','{$updated_at}'),";
            }
        }

        # batch insert data
        if($insert_sql){
            $insert_sql = trim($insert_sql,',');
            $final_sql = $base_insert_sql.$insert_sql;
            error_log("\r\n insert sql: ". $final_sql,3,'sql_insert.log');
            $conn->begin_transaction();
			$resultat = $conn->query($final_sql);
            if (!$resultat) {
            	$conn->rollback();
                error_log("\r\n failed sql: ". $final_sql,3,'sql_failed.log');
                continue;
            }
            $conn->commit();
        }
    }
    $conn->close();

    echo $count."\n";
