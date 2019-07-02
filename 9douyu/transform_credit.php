<?php
    /**
     * Author : zhang.shuang@9douyu.com
     * Desc : merge 9douyu credit to module_credit
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

	$tables = [
    	'module_credit_building_mortgages',
    	'module_credit_factoring',
    	'module_credit_group',
    	'module_credit_loan',
    	'module_credit_nine',
    	'module_credit_third',
	];

	$common_fields = [
    	'company_name',
    	'loan_username',
    	'loan_user_identity',
    	'loan_amounts',
    	'interest_rate',
    	'repayment_method',
    	'expiration_date',
    	'loan_deadline',
    	'contract_no',
    	'type',
    	'source',
    	'status_code',
    	'credit_tag',
        'outer_id',
        'created_at',
        'updated_at'
	];

    $page_size = 100;
    $conn = new mysqli($config['host'],$config['user'],$config['passwd'],$config['db'],$config['port']);

    if (mysqli_connect_errno()) {

        printf("Connect failed: %s\n", mysqli_connect_error());
        exit();
    }

    $conn->set_charset($config['charset']);

	foreach($tables as $table){

        $sql = sprintf("select count(id) as rowcount from %s",$table);
        $result = $conn->query($sql);
        $row = $result->fetch_assoc();

        $rowcount = $row['rowcount'];

        $pages = ceil($row['rowcount'] / $page_size);

        $fields = implode(",",$common_fields);

        $base_credit_sql = "insert into module_credit({$fields}) values(";
        $base_credit_extend_sql = "insert into module_credit_extend(credit_id,extra) values(?,?)";

        for($page = 1; $page <= $pages;$page++){

            $offset =  ($page - 1) * $page_size;
            $sql = sprintf("select * from %s limit %s,%s",$table,$offset,$page_size);

            error_log("\r\n $sql",3,'sql_access.log');

            $result = $conn->query($sql);
            $data = $result->fetch_all(MYSQLI_ASSOC);

            foreach($data as $item){

				$id = $item['id'];
                $item['outer_id'] = $id;
                unset($item['id']);
                $credit_sql = $base_credit_sql;

                foreach($common_fields as $field){
                    $val = '';
                    if(isset($item[$field])){
                        if($field == 'loan_username' || $field == 'loan_user_identity'){
                            $decode_item = json_decode($item[$field],true);

                            if(is_array($decode_item) && $decode_item)
                                $val = implode(',',array_filter($decode_item));
                        }else{
                            $val = $item[$field];
                        }
                        unset($item[$field]);
                    }
                    $credit_sql = $credit_sql."'".$val."',";
                }

                $credit_sql = trim($credit_sql,',').")";

                error_log("\r\n $credit_sql",3,'sql_access.log');

                $conn->begin_transaction();

                $resultat = $conn->query($credit_sql);
                if (!$resultat) {
                    $conn->rollback();
                    error_log("\r\n insert $table failed, error: ". $credit_sql,3,'sql_error.log');
                    continue;
                } else {
                    $last_id = $conn->insert_id; // function will now return the ID instead of true.
                }

				# insert into module_credit_extend table
                if(!empty($item)){
                    $extra = json_encode($item);

					$stmt = $conn->prepare($base_credit_extend_sql);
					$stmt->bind_param('ss', $last_id,$extra);

					/* execute prepared statement */
					$stmt->execute();

					if(!$stmt->affected_rows){
                	    $conn->rollback();
                        $log_data = [
                            'last_id' => $last_id,
                            'extra' => $extra
                        ];
                        error_log("\r\n insert module_credit_extend failed, params: ".var_export($log_data,true),3,'sql_error.log');
						$stmt->close();
						continue;
					}
					/* close statement and connection */
					$stmt->close();
                }

                # third months credit must update detail credit_id
                if($table == 'module_credit_third'){

                    $update_sql = sprintf("update module_credit_third_detail set credit_third_id = %s where credit_third_id = %s",$last_id,$id);
                    $conn->query($update_sql);
                    error_log("\r\n update sql: $update_sql ",3,'update_sql.log');
                }
                $conn->commit();
            }
        }
        echo $table . ":" . $row['rowcount'] . "\n";
	}
    $conn->close();
