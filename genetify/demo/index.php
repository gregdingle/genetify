<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
	"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
    <title>Genetify &mdash; A play-full walkthru</title>

    <script type="text/javascript">
        //TODO: why is this needed?
        console.log('Firebug is working');

        GENETIFY_CONFIG = {
            USE_COOKIE: false,
            USE_RESULTS_CACHE: false,
            REMOTE_BASE_URL: '..',
            NAMESPACE: window.location.pathname + window.location.search
        };
    </script>
    <?php
        include('test-sections/_head.html');
        if (empty($_GET['p'])) {
            $_GET['p'] = 'intro';
        }
    ?>

    <style type="text/css" media="screen">
        /* override controls.css */
        #genetify_results_table {
            position: static;
            width: 200px;
        }
        #genetify_results_table .genetify_gene_row {
            display: none;
        }
        #genetify_results_table .genetify_col_sum,
        #genetify_results_table .genetify_col_stddev,
        #genetify_results_table .genetify_col_share {
            display: none;
        }
        #genetify_results_table td {
            height: auto;
        }
    </style>

</head>

<body>

    <h1>Genetify</h1>

    <table id="demo_table" border="0" cellspacing="10">
        <?php include('test-sections/' . $_GET['p'] . '.html'); ?>
    </table>

    <script type="text/javascript" charset="utf-8">
        if (navigator.userAgent.indexOf("Firefox") == -1){
            alert('This demo was designed for use with Firefox.');
        }

        genetify.vary('all');

        var results = document.getElementById('results');
        if (results){
            var out = genetify.printProbs();
            results.innerHTML = out.replace(/\n/g, '<br/>');
        }

    </script>


<p><a style="font-size:0.75em" href="http://github.com/gregdingle/genetify/wikis">Project homepage</a></p>
</body>
</html>
