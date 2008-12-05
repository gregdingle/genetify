<?php

require('init.php');

function fetch_goals($domain, $page)
{
    global $mysqli;
    $sql = "SELECT DISTINCT goal.name FROM goal 
        JOIN pageview USING(pageview_xid) 
        JOIN page USING(page_id) 
        JOIN domain USING(domain_id) 
        WHERE domain.name = '$domain' AND page.name = '$page'";
        
    $result = $mysqli->query($sql);   
    $goals = array();
    while ($row = $result->fetch_assoc()) {
        $goals[] = $row['name'];
    }
    return $goals;
}

function fetch_genes($domain, $page)
{                 
    global $mysqli;
    $sql = "CALL get_improvement('$domain', '$page', NULL)";
        
    $mysqli->multi_query($sql);  
    $result = $mysqli->store_result();
    $mysqli->next_result(); //because first is always status message
    $genes = array();
    while ($row = $result->fetch_assoc()) {
        $geneDict[$row['gene_name']] = $row['improvement_factor'];
    }
    return $geneDict;
}

function main($geneDict)
{
    //TODO: fixme
    $baseURL = 'http://localhost.com/genetify';

    if (empty($geneDict)) {
        die('No genes to graph');
    }
    else {
        $graphURLs = array();
        foreach (array_keys($geneDict) as $gene) {
            foreach (array('strip', 'bar', 'share', 'prob') as $chart_type) {
                $queryParams = array(
                    'domain=' . $_GET['domain'],      
                    'page=' . urlencode($_GET['page']),
                    'gene=' . urlencode($gene),
                    'chart=' . $chart_type,
                    'rand=' . rand(0, 1000)
                );
                $graphURLs[$gene][$chart_type] = $baseURL . '/pygooglechart/graph.py?' . implode('&', $queryParams);
            }
        }                                                       
        return $graphURLs;
    }
}

$geneDict = fetch_genes($_GET['domain'], $_GET['page']);
$graphURLs = main($geneDict);     
$goals = fetch_goals($_GET['domain'], $_GET['page']);
if (empty($goals)) {
    die('No goals to graph');
}                            

?>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
	"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
	<title>Genetify &mdash; Graphs</title>	     
	<script type="text/javascript">
        GENETIFY_CONFIG = {
           NO_VARYING: true
       };
   </script>

    <?php include('test-sections/_head.html'); ?>
    <style type="text/css" media="screen">
        table td {
            padding: 0px 0px 0px 0px;
        }
        table .divider td {
            height: 1em;
            padding: 30px 0px 10px 0px;
        }               
        strong {
            font-weight: bold;
        }
    </style>
</head>

<body>							
	
	<h1>Genetify graphs</h1>  
	<h2>Results of <?=$_GET['domain'], $_GET['page']?> on <?=implode(', ', $goals)?></h2>
	
	<table border="0">
	    <?php foreach ($graphURLs as $gene => $gene_chart): ?>
        <tr class="divider"><td colspan="4"><strong><?=$gene?></strong>, <?=round($geneDict[$gene], 2)?>x improvement over original</td></tr>
		<tr>       
    	    <?php foreach ($gene_chart as $URL): ?>
			<td>   
                <img src="<?=$URL?>" alt=""/>
			</td>
            <?php endforeach ?>
		</tr>
        <?php endforeach ?>
    </table> 
    
</body>
</html>