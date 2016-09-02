<?PHP
    $str = urldecode($_REQUEST['jsonData']);
    $name = $_REQUEST['fileName'];

    if ($str && $name)
    {
        $fp = fopen('./generatedJSON/'.$name.'.json', 'w');
        fwrite($fp, $str);
        fclose($fp);
        echo "complete generate : ".$name;
        exit;
    }
    
    echo "error";
?>