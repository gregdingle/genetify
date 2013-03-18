<?php
require_once('init.php');

// because brower may close connection before all data inserted
//TODO: check this is working
ignore_user_abort(1);


$base_url = 'http://' . $_SERVER['SERVER_NAME'] . rtrim(dirname($_SERVER['PHP_SELF']), '/');

//TODO: where to put this test function that tests all three HTTP API calls?
function test()
{
    //TODO: this does not test referrers and visitors, which can span across pages
    global $base_url;

    $tests = array();

    $tests['pageview']['observed'] = file_get_contents($base_url . '/recorder.php?return=text&domain=test.com&page=/test.html&genome=main=Elements,mygene=C,myothergene=__original__&pageview_xid=0&load_time=7&init_time=7&results_time=14&idle_time=86&vary_time=17&vary_call=elements');

    //prevent false alarm on first run after install
    $tests['pageview']['observed'] = str_replace('visitor: 1 inserted', '', $tests['pageview']['observed']);

    $tests['pageview']['expected'] = '
page: 1 inserted
genome: 1 inserted
stats_by_genome: 1 inserted
pageview: 1 inserted
gene: 3 inserted
variant: 3 inserted
genome_variant_link: 3 inserted
stats_by_variant: 3 inserted';

    $tests['goal']['observed'] = file_get_contents($base_url . '/recorder.php?goal=test&value=100&pageview_xid=0&return=text');
    $tests['goal']['expected'] = 'goal: 1 inserted
stats_by_genome: 2 inserted
stats_by_variant: 6 inserted';

    $tests['results']['observed'] = file_get_contents($base_url . '/reader.php?callback=genetify.handleResults&domain=test.com&page=/test.html');
    $tests['results']['expected'] = 'genetify.handleResults({"main":{"Elements":{"count":1,"nonzero":1,"sum":100,"avg":100,"sumsq":10000,"wavg":10}},"mygene":{"C":{"count":1,"nonzero":1,"sum":100,"avg":100,"sumsq":10000,"wavg":10}},"myothergene":{"__original__":{"count":1,"nonzero":1,"sum":100,"avg":100,"sumsq":10000,"wavg":10}}})';

    $tests['delete']['observed'] = file_get_contents($base_url . '/delete.php?domain=test.com&page=/test.html&delete=true&return=text');
    $tests['delete']['expected'] = '1 deleted';

    $test_result = 'PASSED';
    foreach ($tests as $key => $value) {
        if (trim($value['observed']) != trim($value['expected'])) {
            $test_result = 'FAILED';
            header('Content-type: text/plain');
            print_r($value);
            break;
        }
    }
    return $test_result;
}

function main()
{
    //TODO: dispatcher function
    if (@$_REQUEST['test']) {
        die(test());
    }

    if (@$_REQUEST['error'] && stristr($_REQUEST['error'], 'genetify')) {
        //TODO: is this any better than getting user agent server-side?
        die(record_error($_REQUEST['error'], $_REQUEST['line_number'], $_REQUEST['domain'], $_REQUEST['page']));
    }

    if (@$_REQUEST['goal']) {
        die(record_goal($_REQUEST['pageview_xid'], $_REQUEST['goal'], $_REQUEST['value']));
    }

    //TODO: try benchmarking query instead of prepared statement inserts
    if (@$_REQUEST['benchmark']) {
        $_REQUEST['pageview_xid'] = rand(1,1000000);
        $_REQUEST['genome'] = rand(1,4) . '=' . rand(1,4);
    }

    //TODO: better check of all required parameters
    //TODO: record rand part of query string and check for dups
    //TODO: referrer check from legitimate domain
    if (@$_REQUEST['genome']) {

        $visitor_id = insert_new_visitor($_SERVER['REMOTE_ADDR']);

        if (@$_REQUEST['referrer']) {
            $referrer_id = insert_new_referrer(parse_genome($_REQUEST['referrer']));
        }
        else {
            $referrer_id = 'NULL';
        }

        $domain_id = insert_new_domain('name', $_REQUEST['domain']);
        $page_id = insert_new_page('name', $_REQUEST['page'], $domain_id);

        $genome_id = insert_new('genome', 'hash', md5($_REQUEST['genome']), $page_id);
        update_stats('genome', $genome_id, 1, 0);

        // because these times are not always calculable
        $results_time = $_REQUEST['results_time'] != 'NaN' ? $_REQUEST['results_time'] : 'NULL';
        $idle_time = $_REQUEST['idle_time'] != 'NaN' ? $_REQUEST['idle_time'] : 'NULL';
        $vary_time = $_REQUEST['vary_time'] != 'NaN' ? $_REQUEST['vary_time'] : 'NULL';

        //TODO: mysql escape *all* $_REQUEST variables
        insert_pageview($genome_id, $page_id, $visitor_id, $referrer_id, $_REQUEST['pageview_xid'], $_REQUEST['vary_call'], $_REQUEST['load_time'], $_REQUEST['init_time'], $results_time, $idle_time, $vary_time);

        $genes = parse_genome($_REQUEST['genome']);
        foreach ($genes as $gene => $variant) {
            $gene_id = insert_new('gene', 'name', $gene, $page_id);
            $variant_id = insert_new_variant($variant, $gene_id);
            insert_new_genome_variant_link($genome_id, $variant_id);
            update_stats('variant', $variant_id, 1, 0);
        }

        if (@$_REQUEST['benchmark'] && rand(1, 1/$_REQUEST['benchmark']) == 1) {
            record_goal($_REQUEST['pageview_xid'], 'benchgoal', rand(1,1000000));
        }

        render_status('pageview');
    }


}

//TODO: double check
function record_error($message, $line_number, $domain, $page)
{
    $domain_id = insert_new_domain('name', $domain);
    $page_id = insert_new_page('name', $page, $domain_id);
    $visitor_id = insert_new_visitor($_SERVER['REMOTE_ADDR']);
    insert_error($message, $line_number, $page_id, $visitor_id);

    return render_status('error');
}

function render_status($table)
{
    global $start_time;

    if (@$_REQUEST['return'] == 'text' || @$_REQUEST['callback']) {
        foreach ($GLOBALS['affected_tables'] as $t => $value) {
            $lines[] = "$t: $value inserted";
        }
        //TODO: suppress only for auto test
        if (!@$_REQUEST['return'] == 'text') {
            $lines[] = round(1000 * (microtime(1) - $start_time)) . 'ms';
        }
        callback(@$_REQUEST['callback'] ? implode(', ', $lines) : implode("\n", $lines));
    }
    else {
        return_image(count($GLOBALS['affected_tables'][$table]) > 0);
    }
}

function _get_pageview_info($pageview_xid, $try=1)
{
    global $mysqli;
    $sql =
        "SELECT
            domain.name as 'domain_name',
            page.name as 'page_name',
            genome_id,
            variant_id
        FROM pageview
            INNER JOIN page USING(page_id)
            INNER JOIN domain USING(domain_id)
            INNER JOIN genome using(genome_id)
            INNER JOIN genome_variant_link using(genome_id)
        WHERE pageview.pageview_xid = $pageview_xid";

    $result = $mysqli->query($sql);
    if ($result->num_rows > 0) {
        while ($row = $result->fetch_assoc()) {
            $rows[] = $row;
        }
        return $rows;
    }
    // because pageview may be inserted slightly later than goal
    else if ($try <= 3) {
        sleep(1);
        return _get_pageview_info($pageview_xid, ++$try);
    }
    else {
        errback('Goal: No pageview in database');
    }
}

function record_goal($pageview_xid, $name, $value, $set_cache=1)
{
    // this line must come first
    $rows = _get_pageview_info($pageview_xid);
    $domain = $rows[0]['domain_name'];
    $page = $rows[0]['page_name'];

    insert_goal($pageview_xid, $name, $value);

    update_stats('genome', $rows[0]['genome_id'], 0, $value);
    foreach ($rows as $row) {
        update_stats('variant', $row['variant_id'], 0, $value);
    }

    //TODO: check against a cache frequency to reduce load
    if ($set_cache) {
        set_cache($domain, $page);
    }

    return render_status('goal');
}

function set_cache($domain, $page)
{
    global $base_url;
    $callback = 'genetify.handleResults';
    //TODO: is this slow?
    $reader_response = file_get_contents("$base_url/reader.php?callback=$callback&domain=$domain&page=$page");
    if (!strstr($reader_response, $callback)) {
        errback('Read failure: ' . $reader_response);
    }

    $filepath = get_cache_pathname($domain, $page);
    //TODO: atomic file replace
    $fh = fopen($filepath, 'w');
    $success = fwrite($fh, $reader_response);
    fclose($fh);
    if (!$success) {
        errback('Write failure: ' . $filepath);
    }
}

function parse_genome($genome){
    $kvs = explode(',', $genome);
    foreach($kvs as $kv){
        $gene = explode('=', $kv);
        $genes[$gene[0]] = $gene[1];
    }
    return $genes;
}

function _get_unique_row_id($table, $sql){
    global $mysqli;
    $result = $mysqli->query($sql);
    if ($result->num_rows > 0) {
        $row = $result->fetch_assoc();
        return $row[$table.'_id'];
    }
    else {
        return 0;
    }
}

function _execute_and_return_id($table, $stmt)
{
    global $mysqli;
    $stmt->execute();
    if ($mysqli->error) {
        errback($table . ': '. $mysqli->error);
    }
    @$GLOBALS['affected_tables'][$table] += $stmt->affected_rows;
    $stmt->close();
    return $mysqli->insert_id;
}

//TODO: refactor all these insert functions!

function insert_new($table, $key_field, $key_value, $page_id)
{
    global $mysqli;
    $sql = "SELECT * FROM $table INNER JOIN page USING(page_id)
            WHERE $table.$key_field = '$key_value'
                AND page.page_id = '$page_id'";
    $id = _get_unique_row_id($table, $sql);
    if ($id == 0) {
        $stmt = $mysqli->prepare("INSERT INTO $table($key_field, page_id) VALUES(?, ?)");
        $stmt->bind_param('si', $key_value, $page_id);
        $id = _execute_and_return_id($table, $stmt);
    }
    return $id;
}

function insert_new_domain($key_field, $key_value)
{
    global $mysqli;
    $sql = "SELECT * FROM domain where domain.$key_field = '$key_value'";
    $id = _get_unique_row_id('domain', $sql);
    if ($id == 0) {
        $stmt = $mysqli->prepare("INSERT INTO domain($key_field) VALUES(?)");
        $stmt->bind_param('s', $key_value);
        $id = _execute_and_return_id('domain', $stmt);
    }
    return $id;
}

function update_stats($key, $id, $count, $value)
{
    global $mysqli;
    $field = $key . '_id';
    $sql = "INSERT INTO stats_by_$key($field, count, nonzero, sum, avg, sumsq, wavg)
        VALUES($id, 1, 0, 0, 0, 0, 0)
        ON DUPLICATE KEY UPDATE
            count = count + $count,
            nonzero = nonzero + ($value>0),
            sum = sum + $value,
            avg = sum / (count + $count),
            sumsq = sumsq + ($value * $value),
            wavg = 0.9 * wavg + 0.1 * $value";
    $stmt = $mysqli->prepare($sql);
    _execute_and_return_id('stats_by_' . $key, $stmt);
}

function insert_new_variant($key_value, $gene_id)
{
    global $mysqli;
    $sql = "SELECT * FROM gene
        INNER JOIN variant USING(gene_id)
        WHERE gene.gene_id = $gene_id
            AND variant.name = '$key_value'";
    $id = _get_unique_row_id('variant', $sql);
    if ($id == 0) {
        $stmt = $mysqli->prepare("INSERT INTO variant(name, gene_id) VALUES(?, ?)");
        $stmt->bind_param('si', $key_value, $gene_id);
        $id = _execute_and_return_id('variant', $stmt);
    }
    return $id;
}

function insert_new_page($key_field, $key_value, $domain_id)
{
    global $mysqli;
    $sql = "SELECT * FROM domain INNER JOIN page USING(domain_id)
        WHERE domain.domain_id = $domain_id AND page.$key_field = '$key_value'";
    $id = _get_unique_row_id('page', $sql);
    if ($id == 0) {
        $stmt = $mysqli->prepare("INSERT INTO page($key_field, domain_id) VALUES(?, ?)");
        $stmt->bind_param('si', $key_value, $domain_id);
        $id = _execute_and_return_id('page', $stmt);
    }
    return $id;
}

function insert_new_genome_variant_link($genome_id, $variant_id){
    global $mysqli;
    $sql = "SELECT * FROM genome_variant_link
        WHERE genome_id = $genome_id AND variant_id = $variant_id";
    $id = _get_unique_row_id('genome_variant_link', $sql);
    if ($id == 0) {
        $stmt = $mysqli->prepare("INSERT INTO genome_variant_link(genome_id, variant_id) VALUES(?, ?)");
        $stmt->bind_param('ii', $genome_id, $variant_id);
        $id = _execute_and_return_id('genome_variant_link', $stmt);
    }
    return $id;
}

//TODO: add category field
function insert_goal($pageview_xid, $name, $value){
    global $mysqli;
    $sql = "INSERT INTO goal(pageview_xid, name, value) VALUES(?, ?, ?)";
    $stmt = $mysqli->prepare($sql);
    $stmt->bind_param('dsi', $pageview_xid, $name, $value);
    return _execute_and_return_id('goal', $stmt);
}

function insert_pageview($genome_id, $page_id, $visitor_id, $referrer_id, $pageview_xid, $vary_call, $load_time, $init_time, $results_time, $idle_time, $vary_time){
    global $mysqli;
    $sql = "INSERT INTO pageview(genome_id, page_id, visitor_id, referrer_id, pageview_xid, vary_call, load_time, init_time, results_time, idle_time, vary_time) VALUES($genome_id, $page_id, $visitor_id, $referrer_id, $pageview_xid, '$vary_call', $load_time, $init_time, $results_time, $idle_time, $vary_time)";
    $stmt = $mysqli->prepare($sql);
    return _execute_and_return_id('pageview', $stmt);
}

function insert_error($message, $line_number, $page_id, $visitor_id){
    global $mysqli;
    $stmt = $mysqli->prepare("INSERT INTO error(message, line_number, page_id, visitor_id) VALUES(?, ?, ?, ?)");
    $stmt->bind_param('siii', $message, $line_number, $page_id, $visitor_id);
    return _execute_and_return_id('error', $stmt);
}

function insert_new_visitor($ip_address)
{
    global $mysqli;


    $visitor = array('ip_address' => $ip_address);
    // TODO: best delimiter?
    $visitor['hash'] = md5(implode('', $visitor));

   if (isset($CONFIG['browscap']) && $CONFIG['browscap']) {

        //TODO: make optional
        require_once('Browscap/Browscap.php');
        $bc = new Browscap('cache');
        //TODO: make this configurable
        $bc->doAutoUpdate = 0;
        foreach ($bc->getBrowser() as $key => $value) {
        //  filter out raw fields
            if (!strstr($key, 'browser_name')) {
                $visitor[$key] = $value;
            }
        }

        //TODO: convert database column names
        // $visitor = _camel_to_underscore($visitor);
    }

    $sql = "SELECT * FROM visitor WHERE visitor.hash = '" . $visitor['hash'] . "'";
    $id = _get_unique_row_id('visitor', $sql);
    if ($id == 0) {
        $sql = "INSERT INTO visitor(" . implode(', ', array_keys($visitor)) . ") VALUES('" . implode("', '", $visitor) . "')";
        $stmt = $mysqli->prepare($sql);
        $id = _execute_and_return_id('visitor', $stmt);
    }
    return $id;
}

function insert_new_referrer($referrer)
{
    global $mysqli;

    $referrer = _camel_to_underscore($referrer);

    $referrer['hash'] = md5(implode('', $referrer));
    //TODO: add indexes to database
    $sql = "SELECT * FROM referrer WHERE referrer.hash = '" . $referrer['hash'] . "'";
    $id = _get_unique_row_id('referrer', $sql);
    if ($id == 0) {
        $sql = "INSERT INTO referrer(" . implode(', ', array_keys($referrer)) . ") VALUES('" . implode("', '", $referrer) . "')";
        $stmt = $mysqli->prepare($sql);
        $id = _execute_and_return_id('referrer', $stmt);
    }
    return $id;
}

function _explode_case($string, $lower = true)
{
    $array = preg_split('/([A-Z][^A-Z]+)/', $string, -1, PREG_SPLIT_NO_EMPTY | PREG_SPLIT_DELIM_CAPTURE);

    if ($lower) {
      $array = array_map('strtolower', $array);
    }

    return $array;
}

function _camel_to_underscore($array)
{
    foreach ($array as $key => $value) {
        unset($array[$key]);
        $new_key = implode('_', _explode_case($key));
        $array[$new_key] = $value;
    }
    return $array;
}

main();
$mysqli->close();
?>
