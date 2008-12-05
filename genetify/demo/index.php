<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
	"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>                                                                      
    <title>Genetify &mdash; A play-full walkthru</title>       
    
    <script type="text/javascript">
        GENETIFY_CONFIG = {
            USE_COOKIE: false,
            USE_RESULTS_CACHE: false,
            REMOTE_BASE_URL: '../'
        };
    </script>
    <?php 
        include('test-sections/_head.html'); 
        if (empty($_GET['p'])) {
            $_GET['p'] = 'intro';
        }
    ?>   
</head>

<body>                          
    
    <h1>Genetify</h1>   
    
    <table border="0" cellspacing="10">
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


<p style="font-size: 0.75em"><a href="genetify.txt">Full documentation</a></p>
</body>
</html>
