<?php
require_once('init.php');

function main()
{
    if (empty($_REQUEST['page'])) {
        die('Page required.');
    }

    //TODO: mysql-php field type mapping... keep ints as ints!

    // $start = microtime();
    // echo microtime() - $start;
    $results = get_results($_REQUEST['domain'], $_REQUEST['page']);

    if (!function_exists('json_encode')) {
        require_once('JSON.php');
        $json = new Services_JSON();
        $output = $json->encode($results);
    }
    else {
        $output = json_encode($results);
    }

    $callback = $_REQUEST['callback'] . "($output)";
    header('Content-type: text/javascript');
    print($callback);
}

function get_results($domain, $page){
    global $mysqli;

    $sql = "SELECT gene.name as gene_name, variant.name as variant_name, stats_by_variant.*
            FROM stats_by_variant
                JOIN variant USING(variant_id)
                JOIN gene USING(gene_id)
                JOIN page USING(page_id)
                JOIN domain USING(domain_id)
            WHERE domain.name = '$domain' AND page.name = '$page'
            ORDER BY gene_name, variant_name = '__original__' DESC, variant_name";

    $queryset = $mysqli->query($sql);
    $results = array();
    while ($row = $queryset->fetch_assoc()) {
        foreach ($row as $key => $value) {
            if (is_numeric($value) && !strstr($key, '_id')) {
                $results[$row['gene_name']][$row['variant_name']][$key] = $value * 1;
            }
        }
    }

    return $results;
}

main();
$mysqli->close();
?>
