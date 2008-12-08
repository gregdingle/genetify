<?php
require_once('CONFIG.php');

$mysqli = new mysqli($DB['host'], $DB['user'], $DB['password'], $DB['database']);

if (mysqli_connect_errno()) {
   errback("Can't connect to MySQL Server. Errorcode: " . mysqli_connect_error());
}

function errback($message)
{
    if (@$_REQUEST['errback']) {
        header('Content-type: text/javascript');
        $message = $_REQUEST['errback'] . '("Genetify: ' . $message . '");';
    }
    else {
        $message = 'ERROR: ' . $message;
    }
    //TODO: record errors from here?
    die($message);
}

function callback($message)
{
    if (@$_REQUEST['callback']) {
        header('Content-type: text/javascript');
        $message = $_REQUEST['callback'] . '("Genetify: ' . $message . '");';
    }
    die($message);
}

//TODO: needed anymore?
function return_image($boolean)
{
    if (function_exists('imagecreate')) {
        $im = imagecreate(1, 1);
        if ($boolean) {
            imagecolorallocate($im, 0, 255, 0);
        }
        else {
            imagecolorallocate($im, 255, 0, 0);
        }
        header("Content-type: image/gif");
        imagegif($im);
        imagedestroy($im);
    }
    //TODO: find better method when no GD
    else {
        $grape_gif='
        R0lGODlhIAAgALMAAAAAAAAAgHCAkC6LV76+vvXeswD/ANzc3DLNMubm+v/6zS9PT6Ai8P8A////
        /////yH5BAEAAAkALAAAAAAgACAAAAS00MlJq7046803AF3ofAYYfh8GIEvpoUZcmtOKAO5rLMva
        0rYVKqX5IEq3XDAZo1GGiOhw5rtJc09cVGo7orYwYtYo3d4+DBxJWuSCAQ30+vNTGcxnOIARj3eT
        YhJDQ3woDGl7foNiKBV7aYeEkHEignKFkk4ciYaImJqbkZ+PjZUjaJOElKanqJyRrJyZgSKkokOs
        NYa2q7mcirC5I5FofsK6hcHHgsSgx4a9yzXK0rrV19gRADs=
        ';

        $php_rules = 'iVBORw0KGgoAAAANSUhEUgAAABwAAAASCAMAAAB/2U7WAAAABl'
               . 'BMVEUAAAD///+l2Z/dAAAASUlEQVR4XqWQUQoAIAxC2/0vXZDr'
               . 'EX4IJTRkb7lobNUStXsB0jIXIAMSsQnWlsV+wULF4Avk9fLq2r'
               . '8a5HSE35Q3eO2XP1A1wQkZSgETvDtKdQAAAABJRU5ErkJggg==';

       if ($boolean) {
           $data = base64_decode($grape_gif);
           header("Content-type: image/gif");
       }
       else {
           $data = base64_decode($php_rules);
           header("Content-type: image/png");
       }
       echo $data;
   }
}

function get_cache_pathname($domain, $page)
{
    return 'cache/' . $domain . '__' . rawurlencode(rawurldecode($page)) . '__results.js';
}

?>
