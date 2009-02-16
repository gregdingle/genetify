<?php
require_once('init.php');

function main()
{
    if (empty($_REQUEST['domain']) || empty($_REQUEST['page'])) {
        die('Domain and page required.');
    }

    //TODO: mysql-php field type mapping... keep ints as ints!

    // $start = microtime();
    // echo microtime() - $start;
    $rows = get_results($_REQUEST['domain'], $_REQUEST['page']);

    if (!function_exists('json_encode')) {
        require_once('JSON.php');
        $json = new Services_JSON();
        $output = $json->encode($rows);
    }
    else {
        $output = json_encode($rows);
    }

    $callback = $_REQUEST['callback'] . "($output)";
    header('Content-type: text/javascript');
    print($callback);
}

function get_results($domain, $page){
    global $mysqli;

    $sql = "SELECT * FROM result
        WHERE domain_name = '$domain' AND page_name = '$page'
        ORDER BY gene_name, variant_weight DESC, variant_name = '__original__' DESC, variant_name";

    $result = $mysqli->query($sql);
    $rows = array();
    while ($row = $result->fetch_assoc()) {
        foreach ($row as $key => $value) {
            if (is_numeric($value)) {
                $value = $value * 1;
            }
            if (strstr($key, 'variant') && $key != 'variant_name' && $key != 'variant_id') {
                $rows[$row['gene_name']][$row['variant_name']][str_replace('variant_', '', $key)] = $value;
            }
        }
    }
    return $rows;
}

main();
$mysqli->close();
?>
