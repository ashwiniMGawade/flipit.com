#!/bin/bash

# Import variables.
source /var/scripts/variables.sh

s3cmd sync s3://img.flipit.com/public/images/ /var/www/flipit_application/web/public/images

for locale in "${locales[@]}"
do
    s3cmd sync s3://img.flipit.com/public/$locale/ /var/www/flipit_application/web/public/$locale
done
