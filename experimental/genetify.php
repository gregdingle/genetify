<?php

//TODO: test code

// require_once('genetify.php');               
// $g = new Genetify(1, '/genetify/');                   
// 
// $variants = array(
//  array('A', array('AAAAA', 'aaaaa')), 
//  array('B', array('BBBBBB', 'bbbbb')), 
//  array('C', array('CCCCC', 'ccccc'))
// );
// $preHTML = print_r($g->varyGene('preHTMLgene', 'preHTMLgene original', $variants), 1);      
  

//TODO: scope is conflicting with page
// $variants = array('A', 'B', 'C');
// $inline = $g->varyGene('inlinePHPgene', 'inlinePHPgene original', $variants);	 

//TODO: put all these examples in a test

// $asdf = 'o';
// $asdf_vA = 'a';
// extract($g->varyVars(get_defined_vars()));
// echo $asdf;					  

// $test_rows = array(
//	   array('name'=>'row', 'data'=>'aaaaaaaa'), 
//	   array('name'=>'row_vB', 'data'=>'bbbbb'), 
//	   array('name'=>'row_vC', 'data'=>'ccccccc') 
// );						   
// print_r($g->varyRows($test_rows, 'name'));

// $list = array(
//	  'A'=>'aaaaaaaa', 
//	  'B'=>'bbbbb', 
//	  'C'=>'ccccccc' 
// );
// 
// print_r($g->varyOrder($list));	



error_reporting(E_ALL);

//TODO: use http://us3.php.net/manual/en/ref.runkit.php

//TODO: test this conditional
if (!function_exists('json_decode')) {
    require_once('JSON.php');
}                   

if ( !function_exists('sys_get_temp_dir') )
{
    function sys_get_temp_dir()
    {
        // Try to get from environment variable
        if ( !empty($_ENV['TMP']) )
        {
            return realpath( $_ENV['TMP'] );
        }
        else if ( !empty($_ENV['TMPDIR']) )
        {
            return realpath( $_ENV['TMPDIR'] );
        }
        else if ( !empty($_ENV['TEMP']) )
        {
            return realpath( $_ENV['TEMP'] );
        }
        // Detect by creating a temporary file
        //TODO: is this too slow? it will check filesystem on every request
        else
        {
            $temp_file = tempnam( md5(uniqid(rand(), TRUE)), '' );
            if ( $temp_file )
            {
                $temp_dir = realpath( dirname($temp_file) );
                unlink( $temp_file );
                return $temp_dir;
            }
            else
            {
                return FALSE;
            }
        }
    }
}
                             
//TODO: replace this with something more robust like pear's cache-lite
function genetify_updateCache($URL, $localCachePath)
{
    $raw_results = file_get_contents($URL);
    file_put_contents($localCachePath, $raw_results);
}

class Genetify
{
    function Genetify($request_results=1, $path='')
    {          
        //TODO: good idea to keep compatible php4 and 5?                           
        $this->genome = array();
        $this->genomeOverride = array();
        $this->results = array();
        $this->domain = '';
        $this->cookieEnabled = 1;  
        $this->useLocalCache = 1;   
        $this->cacheUpdateFreq = 1;
        
        $this->remoteBaseURL = (!empty($_SERVER['HTTPS']) ? "https" : "http") . '://genetify.com';

        $this->systemNames = $this->_getSystemNames();
        
        if (isset($_COOKIE['genetify_use_cookie'])) {
            $this->cookieEnabled = $_COOKIE['genetify_use_cookie'] * 1;
        }

        if (!$path) {   
            $path = $_SERVER['PHP_SELF'];
        }               
        
        $this->_cookieInit($path);
        
        if ($_SERVER['SERVER_NAME'] == 'localhost') {
            //todo: provide sensible domain key for local testing
            $this->domain = 'localhost';
        }    
        else {                        
            //TODO: HTTP_HOST or SERVER_NAME??
            $this->domain = $_SERVER['SERVER_NAME'];            
        }                                                        
                                                
        if ($request_results){                                   
            $this->results = $this->_requestResults($path);
        }
    }       
    
    function _getSystemNames()
    {
        foreach ($GLOBALS as $key => $value) {
            $names[$key] = 1;
        }                                
        $names['systemNames'] = 1;
        return $names;
    }
     
    function _requestResults($path)
    {                                             
        $path = rawurlencode($path);
        $URL = $this->remoteBaseURL . "/reader.php?domain=$this->domain&path=$path";
        
        if ($this->useLocalCache) {
            //TODO: best name scheme for local cache?      
            $filename = $this->domain . '__' . $path . '__results.js';
            $localCachePath = sys_get_temp_dir() . '/' . $filename;     
            
            if (rand(1, round(1 / $this->cacheUpdateFreq)) == 1){
                if (!is_readable($localCachePath)) {
                    // on first, update cache immediately
                    genetify_updateCache($URL, $localCachePath);
                }    
                else {                                   
                    // on later, update cache at termination of script                   
                    //TODO: possible to call function as static method?
                    register_shutdown_function('genetify_updateCache', $URL, $localCachePath);
                }
            }                                  
            $raw_results = file_get_contents($localCachePath);
        }
        else {                                   
            $raw_results = file_get_contents($URL);
        }
        
        $raw_results = trim($raw_results, '()'); //for JSON parsers

        if (function_exists('json_decode')) {
            return json_decode($raw_results);
        }
        else {                   
            //TODO: create instance only once
            $json = new Services_JSON();
            return $json->decode($raw_results);
        }
    }       

    function varyOrder($array){ 
        for ($i=0; $i < count($array); $i++) { 
            $possible_positions[] = array('position_' . $i, $i);
        }
        foreach ($array as $key => $value) {
            $gene_name = $key . '_position';                             
            $selectedVariant = $this->_selectVariant($gene_name, $possible_positions);
            $this->genome[$gene_name] = $selectedVariant[0];
            $order[$key] = $selectedVariant[1];
        }                   
        asort($order);
        foreach ($order as $key => $value) {
            $newArray[$key] = $array[$key]; 
        }                                             
        $this->_save($this->genome);  
        return $newArray;
    }
    
    function varyRows($array, $key_field){
        foreach ($array as $key => $value) {
            $assoc[$value[$key_field]] = $value;
        }                   
        $switched = $this->varyVars($assoc);
        foreach ($switched as $key => $value) {
            $value[$key_field] = $key;
            $newArray[] = $value;
        }
        return $newArray;
    }

    function varyVars($defined_vars)
    {            
        return $this->_switchVars($this->_getVars($defined_vars));
    }                           

    function _getVars($defined_vars)
    {                                       
        $vars = array_diff_key($defined_vars, $this->systemNames);
        $pattern = '/(.*)_v([A-Z0-9_$][a-zA-Z0-9_$]*)/';
        
        foreach ($vars as $key => $value) {
            if (preg_match($pattern, $key, $matches)) {
                $geneDict[$matches[1]][] = array($matches[2], $value);
            }
        }                  
        foreach ($geneDict as $gene_name => $variants) {
            $geneDict[$gene_name][] = array('__original__', $vars[$gene_name]);
        }
        return $geneDict;
    }
    
    function _switchVars($geneDict)
    {                             
        foreach ($geneDict as $gene_name => $variants) {
            $selectedVariant = $this->_selectVariant($gene_name, $variants);    
            $newValues[$gene_name] = $selectedVariant[1];
            $this->genome[$gene_name] = $selectedVariant[0];
        }       
        $this->_save($this->genome);
        return $newValues;
    }   
    
    function varyGene($gene_name, $original, $variants)
    {                        
        if (!is_array($variants)){  
            $variants = array();
            for ($i = 2 ; $i < func_num_args(); $i++) {
                $variants[] = func_get_arg($i);
            }           
        }

        for ($j=0; $j < count($variants); $j++) { 
            if (!is_array($variants[$j])) {
                if (is_scalar($variants[$j])){
                    $variants[$j] = array($variants[$j], $variants[$j]);
                } 
                else {
                    die('Genetify: Non-scalar variants must be paired with a name.');
                }
            }
        }                    
        array_unshift($variants, array('__original__', $original));

        $selectedVariant = $this->_selectVariant($gene_name, $variants);    
        $this->genome[$gene_name] = $selectedVariant[0];
        $this->_save($this->genome);
        return $selectedVariant[1];
    }       
    
    function _cookieInit($path){
        if ($this->cookieEnabled  && isset($_COOKIE['genetify_genome_page'])) {
            // check results of path             
            if (substr($path, -1, 1) == '/') {
                $compare = strncmp($path, $_COOKIE['genetify_genome_page'], count($path));
            }                     
            else {
                $compare = strcmp($path, $_COOKIE['genetify_genome_page']);
            }
            if ($compare === 0) {         
                $this->genomeOverride = $this->_fragmentToGenome($_COOKIE['genetify_genome']);    
            }
        }
    }      
     
    function _getFixedVariant($gene_name, $variants)
    {
        for ($i=0; $i < count($variants); $i++) { 
            if ($variants[$i][0] == $this->genomeOverride[$gene_name]) {
                return $variants[$i];
            }
        }   
        die('Genetify: No variant of name ' . $this->genomeOverride[$gene_name] . ' in gene ' . $gene_name);
    }
    
    function _selectVariant($gene_name, $variants)
    {                                             
        if (isset($this->genomeOverride[$gene_name])) {
            return $this->_getFixedVariant($gene_name, $variants);
        }
        else if ($this->results){                
            $probs = $this->_getProbabilities($gene_name, $variants);
            return $this->_getVariantWithProbability($variants, $probs);
        }
        else {
            $rand = rand(0, count($variants) - 1);
            return $variants[$rand];
        }
    }       
                
    function _getProbabilities($gene_name, $variants)
    {
        $newProbs = array();
        for ($i=0; $i < count($variants); $i++) { 
            $key = $gene_name . '->' . $variants[$i][0];      
            $variant_results = @get_object_vars($this->results->$key);
            if ($variant_results['variant.weight']) {
                $probs[$i] = $variant_results['variant.weight'] * 1;
            }
            else {
                $probs[$i] = 'NaN';
                $newProbs[] = 1 / count($variants);
            }
        }                                           
        if (count($newProbs)) {
            $probs = $this->_adjustProbs($probs, $newProbs);
        }                

        // //TODO: what precision ?
        $sum = round(array_sum($probs) * 1000000) / 1000000;
        if ($sum != 1) {
            die('Genetify: Weights add up to ' . $sum);
        }
                  
        return $probs;
    }       
    
    function _adjustProbs($probs, $newProbs)
    {
        for ($i=0; $i < count($probs); $i++) { 
            $probs[$i] *= 1 - array_sum($newProbs);
        }                                         
        for ($j=0; $j < count($probs); $j++) { 
            if (!$probs[$j]){
                $probs[$j] = array_shift($newProbs);
            }
        }
        return $probs;
    }       
    
    function _getVariantWithProbability($variants, $probs)
    {
        $randomProb = $this->_getRandomFraction() * array_sum($probs); //because sum != 1 exactly
        $threshold = 0;
        for ($i=0; $i < count($variants); $i++) { 
            $threshold += array_shift($probs);
            if ($randomProb <= $threshold) {
                return $variants[$i];
            }
        }                            
        die('Genetify: No variant selected');
    }       
    
    function _getRandomFraction($precision=1000000)
    {
        return rand(0, $precision) / $precision;
    }
    
    function _fragmentToGenome($str){
        if (!$str) {
            return array();
        }
        else {
            $kvs = explode(',', $str);
            foreach($kvs as $kv){
                $gene = explode('=', $kv);
                $genes[$gene[0]] = $gene[1];
            }
            return $genes;
        }
    }                                     
    
    function _genomeToURLFragment($genome)
    {
        if (!$genome){
            die('Genetify: Genome empty');
        }
        foreach ($genome as $key => $value){
            $kv[] = $key . '=' . $value;  //setcookie does encoding
        }
        sort($kv);    
        return implode(',', $kv);
    }   
    
    function _save($genome)
    {                        
        //TODO: use pageview_xid !!!!
        if (headers_sent()) {
            $this->_writeToJavascript($this->genome);
        }              
        else {
            $this->_cookieSave($this->genome);  
        }           
    }
    
    function _cookieSave($genome){                         
        //TODO: keep same as JS lib
        $hoursToExpiry = 1;                        
        $expires = time() + $hoursToExpiry * 60 * 60;                     

        if (isset($_COOKIE['genetify_genome'])) {
            $oldGenome = $this->_fragmentToGenome($_COOKIE['genetify_genome']);
            $newGenome = array_merge($oldGenome, $genome);
        }
        else {
            $newGenome = $genome;            
        }

        //TODO: subdomains?
        $domain = '.' . $this->domain; //because document.cookie sets with prefix (.) !!!

        setcookie('genetify_genome', $this->_genomeToURLFragment($newGenome), $expires, '/', $domain);
        setcookie('genetify_genome_page', $_SERVER['PHP_SELF'], $expires, '/', $domain);
    }     
    
    function _writeToJavascript($genome)
    {
        if (function_exists('json_decode')) {
            $str = json_encode($genome);
        }
        else {   
            //TODO: create instance only once
            $json = new Services_JSON();
            $str = $json->encode($genome);
        }
        
        //TODO: could this get ugly with a lot of calls to vary?
        //TODO: what about contexts inside of tags, or non-HTML?
        echo '<script type="text/javascript">';
        echo "genetify.utils.update(genetify.genome, $str);";
        echo "genetify.cookie.save('".$_SERVER['PHP_SELF']."');";
        echo '</script>';
    }
    
    function printProbs(){
        if (!$this->results) {
            echo 'Genetify: No results';
            return;
        }
        foreach ($this->genome as $gene_name => $value) {
            echo '<br>';
            $key = $gene_name . '->' . $value;      
            $variant_results = @get_object_vars($this->results->$key);
            if ($variant_results['variant.weight']) {
                $prob = round($variant_results['variant.weight']*100)/100;
                if ($prob === 0){
                    echo "$key, p=undefined";
                }
                else {
                    echo "$key, p=$prob";
                }
            }
            else {
                echo "$key, results not found";
            }
        }
    }
    
    //TODO:     function results()
}
?>