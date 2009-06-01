<?php
require_once('init.php');

// todo: change to POST only, check referrer
function main()
{       
    if (empty($_REQUEST['page'])) {
        errback('Page required.');
    }

    if ($_REQUEST['delete'] == true) {
        $count = delete($_REQUEST['domain'], $_REQUEST['page']);
        delete_cache($_REQUEST['domain'], $_REQUEST['page']);
        if (@$_REQUEST['return'] == 'text' || @$_REQUEST['callback']) {
            callback($count . ' deleted');
        }
        else {
            return_image($count > 0);
        }
    }       
    else {
        errback('Really?');
    }
}                                                  

function delete($domain_name, $page_name)
{                
    global $mysqli;                   
    $sql = 
        "DELETE page FROM page 
            JOIN domain USING(domain_id)
        WHERE page.name = '$page_name'
            AND domain.name = '$domain_name'";
    $mysqli->query($sql);
        
    $affected = $mysqli->affected_rows;
    return $affected;
} 

function delete_cache($domain, $page)
{
    $filepath = get_cache_pathname($domain, $page);
    if (file_exists($filepath)) {
        unlink($filepath);
    }
}

main();
$mysqli->close(); 
?>