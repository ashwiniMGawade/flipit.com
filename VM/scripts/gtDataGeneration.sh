#!/bin/bash

# Import variables.
source /var/scripts/variables.sh

# Deleting files first
function remove {
	rm -f /var/www/flipit_application/web/public/js/back_end/gtData.js /var/www/logs/cms \
	/var/www/logs/default 

	for locale  in "${locales[@]}"
	do
	    rm -f /var/www/flipit_application/web/public/$locale/js/back_end/gtData.js
	done
}

if [[ -n remove ]]; then
    remove
else
    echo "No permissions. Delete public/js/back_end/gtData.js, logs/cms & logs/default on the host."
fi

# Creating new files
mkdir -p /var/www/flipit_application/web/public/js/back_end
touch /var/www/flipit_application/web/public/js/back_end/gtData.js
chown vagrant:www-data /var/www/flipit_application/web/public/js/back_end/gtData.js

touch /var/www/logs/cms
touch /var/www/logs/default
chown vagrant:www-data /var/www/logs/cms
chown vagrant:www-data /var/www/logs/default

for locale  in "${locales[@]}"
do
    mkdir -p /var/www/flipit_application/web/public/$locale/js/back_end
    touch /var/www/flipit_application/web/public/$locale/js/back_end/gtData.js
    chown vagrant:www-data /var/www/flipit_application/web/public/$locale/js/back_end/gtData.js
done

echo '##############'
echo 'Generated log & GtData files'
echo '##############'
