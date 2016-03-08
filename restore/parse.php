<?php
function csv_to_array($locale = '', $dir)
{
	 
	$delimiter = ',' ;

	echo $cp  = $dir . '/data.csv';

    if(!file_exists($cp) || !is_readable($cp))
    {
        echo 'fiel not found';
    	return ; 
    }

    $header = NULL;
    $data = array();
    if (($handle = fopen($cp, 'r')) !== FALSE)
    {
        while (($row = fgetcsv($handle, 1000, $delimiter)) !== FALSE)
        {
            if(!$header)
                $header = $row;
            else
                $data[] = $row ;
        }
        fclose($handle);
    }

	
    if(count($data) > 0 )
    {


		
		$str = '' ;
    	foreach ($data as $value) {
		 # please avoid to format below template
		$str.= <<<EOD
UPDATE `flipit_$locale`.`offer` SET `authorId`='$value[0]' , `authorName`='$value[1]' where `id`='$value[2]'; \n
EOD;
		
    	}
	 
			$file = $dir  ."/backup_data.sql"; 
			$Handle = fopen($file, 'w');
			$Data = "Jane Doe\n"; 
			fwrite($Handle, $str.PHP_EOL); 
			
			fclose($Handle); 
    } 
    
}

$locale = isset($argv[1]) ? $argv[1] : ''; //br' ;

$path = isset($argv[2]) ? $argv[2] : ''; // data/br/' ;

csv_to_array($locale,$path);

?>