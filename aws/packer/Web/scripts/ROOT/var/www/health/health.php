<?php

ob_start();
$failure_count = 0;
$ch = curl_init();

/*
 * Define tests below...
 */

function Login_should_give_a_200() {
  $http = curl_init("http://localhost/login");
  curl_setopt($http, CURLOPT_RETURNTRANSFER, true);
  curl_exec($http);
  $http_status = curl_getinfo($http, CURLINFO_HTTP_CODE);
  curl_close($http);
  return $http_status === 200;
}

function S3FS_Image_filesystem_is_mounted() {
  exec('mountpoint /var/www/flipit.com/shared', $output, $return_value);
  return $return_value === 0;
}

function S3FS_Languagefiles_filesystem_is_mounted() {
  exec('mountpoint /var/www/flipit.com/language', $output, $return_value);
  return $return_value === 0;
}

function Root_filesystem_has_free_space() {
  return disk_free_space('/') > 10485760;
}

function Run_filesystem_has_free_space() {
  return disk_free_space('/') > 10485760;
}

function test($test_function) {
  global $failure_count;

  echo '<li>';
  echo '<b>' . str_replace('_', ' ', $test_function) . ':</b> ';
  $result = call_user_func($test_function);
  if ($result) {
    echo '<span style="color: green;">OK</span>';
  } else {
    echo '<span style="color: red;">FAILED</span>';
    $failure_count += 1;
  }
  echo "</li>\n";
}


/*
 * Perform the tests...
 */

echo '<ul>';

test('S3FS_Image_filesystem_is_mounted');
test('S3FS_Languagefiles_filesystem_is_mounted');
test('Root_filesystem_has_free_space');
test('Run_filesystem_has_free_space');
test('Login_should_give_a_200');

echo '</ul>';

/*
 * Handle test outcome...
 */

echo '<p>';

if ($failure_count == 0) {
  echo '<strong style="color: green;">Health Check Passed</strong>';
  header('HTTP/1.0 200 OK');
} else {
  echo '<strong style="color: red;">Health Check Failed</strong>';
  echo "<br/>We observed $failure_count failed test" . ($failure_count == 1 ? '' : 's' ) . "!";
  header('HTTP/1.0 503 Health Check Fails');
}

echo '</p>';

header('Cache-Control: no-cache, no-store, must-revalidate');
header('Pragma: no-cache');
header('Expires: 0');
ob_end_flush();
