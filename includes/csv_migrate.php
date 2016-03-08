<?php 
	// create po nd mo files
$locales = array(
'ar' => 'es_AR',
'at' => 'de_AT',
'au' => 'en_AU',
'be' => 'nl_BE',
'br' => 'pt_BR',
'ca' => 'en_CA',
'ch' => 'de_CH',
'cl' => 'es_CL',
'cn' => 'zh_CN',
'de' => 'de_DE',
'dk' => 'da_DK',
'es' => 'es_ES',
'fi' => 'fi_FI',
'fr' => 'fr_FR',
'hk' => 'zh_HK',
'id' => 'id_ID',
'ie' => 'en_IE',
'in' => 'en_IN',
'it' => 'it_IT',
'jp' => 'ja_JP',
'kr' => 'ko_KR',
'mx' => 'es_MX',
'my' => 'ms_MY',
'no' => 'nn_NO',
'nz' => 'en_NZ',
'pl' => 'pl_PL',
'pt' => 'pt_PT',
'ru' => 'ru_RU',
'se' => 'sv_SE',
'sg' => 'en_SG',
'sk' => 'sk_SK',
'tr' => 'tr_TR',
'uk' => 'uk_UA',
'us' => 'en_US',
'za' => 'en_ZA',
);

$path = '/Users/danielbakker/Sites/flipit.com/flipit_application/public/';

	foreach ($locales as $locale => $lang) {

		// new po files
		$poFile = $path.$locale.'/language/form_'.strtoupper($locale).'.po';
		shell_exec('xgettext --force-po -f /dev/null -o' .$poFile);

		$moCreate = 'msgfmt '.$poFile.' --output-file '.$path.$locale.'/language/form_'.strtoupper($locale).'.mo';
		shell_exec($moCreate);

		$poFile = $path.$locale.'/language/email_'.strtoupper($locale).'.po';
		shell_exec('xgettext --force-po -f /dev/null -o' .$poFile);

		$moCreate = 'msgfmt '.$poFile.' --output-file '.$path.$locale.'/language/email_'.strtoupper($locale).'.mo';
		shell_exec($moCreate);

		// fallback dir, and copy frontend php
		$structure = $path.$locale.'/language/fallback';
		if (!mkdir($structure, 0775, true)) {
	    	echo('Failed to create folder or folder exists...');
		}

		$file = $path.$locale.'/language/frontend_php_'.strtoupper($locale).'.po';
		$newfile = $path.$locale.'/language/fallback/frontend_php_'.strtoupper($locale).'.po';
		if (!copy($file, $newfile)) {
		    echo "failed to copy $file...\n";
		}

		$file = $path.$locale.'/language/frontend_php_'.strtoupper($locale).'.mo';
		$newfile = $path.$locale.'/language/fallback/frontend_php_'.strtoupper($locale).'.mo';
		if (!copy($file, $newfile)) {
		    echo "failed to copy $file...\n";
		}

		// the csv
		$current = file_get_contents('translations.csv');
		$csvFolder = $path.$locale.'/language/'.$lang;
		if (!mkdir($csvFolder, 0775, true)) {
	    	echo('Failed to create CSV folder or folder exists...');
		}
		file_put_contents($csvFolder.'/translations.csv', '"";""');
	}
?>