#!/bin/bash

# Import variables.
source /var/scripts/variables.sh
cd /var/www/flipit_application/web/public/

mkdir -p language
cd language
s3cmd get --recursive --force s3://languagefiles/language/
cd ..

for locale in "${locales[@]}"
do
    mkdir -p $locale/language/
    cd $locale/language/
    s3cmd get --recursive --force s3://languagefiles/$locale/language/
    cd ../..
done
