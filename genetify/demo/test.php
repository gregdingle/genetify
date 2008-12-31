<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
	"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
	<title>Genetify &mdash; Test page</title>
	<script type="text/javascript">
        GENETIFY_CONFIG = {
            // REQUEST_RESULTS: false,
            USE_RESULTS_CACHE: true,
            LOAD_CONTROLS: true,
            NAMESPACE: '/genetify/',
            //TODO: change on server
            REMOTE_BASE_URL: '..'
            // REMOTE_BASE_URL: window.location.pathname.split('/').slice(0, window.location.pathname.split('/').length-2).join('/')
        };

	</script>

    <?php for ($i=0; $i < 100; $i++) {
        // add 1000 rules for benchmarking
        // echo '<link rel="stylesheet" href="demo.css?rand='.$i.'" type="text/css" media="screen" title="no title" charset="utf-8">';
    } ?>

    <?php include('test-sections/_head.html'); ?>

    <!-- large JS library for benchmarking -->
    <!-- <script src="http://snipshot.com/media/base/MochiKit.js" type="text/javascript"></script>
    <script type="text/javascript">
       //TODO: why is Safari and IE finding different number of objects?
       MochiKit; //for IE
    </script> -->

	<style type="text/css" media="screen">
		/* CSS rules test */
		.mygene { background-color: white;}
		.mygene_vA { background-color: purple;}
		.mygene_vB { background-color: yellow;}

		/* Additive rules test */
        .myothergene { background-color: white;}
		.myothergene.vA { background-color: blue;}
		.myothergene.vB { background-color: red;}
		.myothergene.vC { background-color: green;}

	</style>

	<script type="text/javascript" charset="utf-8">
		// javascript test
		var mm = {};
		mm.zz = {};
		mm.zz.main = function(){
			genetify.vary('elements');
		};
		mm.zz.main_vAdditiveCSSRules = function(){
			genetify.vary('additiveCSSRules');
		};
		mm.zz.main_vElements = function(){
			genetify.vary('CSSRules');
		};
		mm.zz.circular = mm;
	</script>

	<style type="text/css" media="screen">
        /* for safari*/
/*      #genetify_controls {
            bottom: 200px !important;
        }*/
     .chart { max-width: 100%; }
	</style>

</head>

<body>

    <h1>Genetify test page</h1>

	<?php for ($i=0; $i < 1000; $i++) {
        // increase DOM size for benchmarking
        // echo '<div style="display:none" class="non"><p class="pas">wewe</p></div>';
    } ?>

	<table id="demo_table" border="0" cellspacing="10">
        <!-- <tr>
            <td>
                <img class="chart" id="stripchart" src="">
            </td>
            <td>
                <img class="chart" id="barchart" src="">
            </td>
        </tr> -->
		<tr>
			<td>
				<div class="container">

					<div class="mygene">mygene original</div>
					<div class="mygene v A">mygene A</div>
					<div class="mygene v B">mygene B</div>
					<div class="mygene v C">mygene C</div>
					<div class="corner top left">&nbsp;</div>
					<div class="corner top right">&nbsp;</div>
					<div class="corner bottom right">&nbsp;</div>
					<div class="corner bottom left">&nbsp;</div>
				</div>
			</td>
			<td>
				<div class="container">

					<div class="myothergene">myothergene original</div>
					<div class="myothergene v A">myothergene A</div>
					<div class="myothergene v B">myothergene B</div>
					<div class="myothergene v C">myothergene C</div>

					<div class="corner top left">&nbsp;</div>
					<div class="corner top right">&nbsp;</div>
					<div class="corner bottom right">&nbsp;</div>
					<div class="corner bottom left">&nbsp;</div>
				</div>
			</td>
		</tr>
		<tr>
			<td>
				<div class="container">

					<div class="mygene">mygene original</div>
					<div class="mygene v A">mygene A</div>
					<div class="mygene v B">mygene B</div>
					<div class="mygene v C">mygene C</div>

					<div class="corner top left">&nbsp;</div>
					<div class="corner top right">&nbsp;</div>
					<div class="corner bottom right">&nbsp;</div>
					<div class="corner bottom left">&nbsp;</div>
				</div>
			</td>
			<td>
				<div class="container">

					<div class="myothergene">myothergene original</div>
					<div class="myothergene v A">myothergene A</div>
					<div class="myothergene v B">myothergene B</div>
					<div class="myothergene v C">myothergene C</div>

					<div class="corner top left">&nbsp;</div>
					<div class="corner top right">&nbsp;</div>
					<div class="corner bottom right">&nbsp;</div>
					<div class="corner bottom left">&nbsp;</div>
				</div>
			</td>
		</tr>
	</table>

	<script type="text/javascript" charset="utf-8">
        // genetify.vary('elements');
        // genetify.test.printProbs();

        // genetify.controls.requestGraph('stripchart', 'mygene', 'strip');
        // genetify.controls.requestGraph('barchart', 'mygene', 'prob');

		// console.log(genetify.genomeOverride);
		// console.log(genetify.genome);
		// console.log(genetify.cookie.read('genetify_genome_page'));
		// console.log(genetify.cookie.read('genetify_genome'));

        self = genetify.test;
        // self.variants('mygene', ['A', 'B', 'C']);
        // self.variants('.mygene', ['A', 'B']);
        // self.variants('.myothergene', ['A', 'B', 'C']);
        // self.variants('main', ['AdditiveCSSRules', 'Elements']);

        // self.results('mygene', ['A', 'B', 'C']);

        genetify.controls.showResults();
	</script>

    <!-- <a href="#" onclick="genetify.record.goal('adfs',-1); return false;">test error</a>
    <a href="#" onclick="genetify.record.goal('adfs',-1); return false;">test error</a> -->

</body>
</html>
