#!/bin/bash

includes_path=includes

# Import variables.
source $includes_path/variables.sh

cd $includes_path

shopt -s dotglob


sudo find flipit_application/public/language -type f -name "*.csv" -exec mv '{}' 'flipit_application/public/language/' \;

for locale  in "${locales[@]}"
do
    #echo "Set gtData for $locale"
    execute="sudo find flipit_application/public/$locale/language -type f -name '*.csv' -exec mv '{}' 'flipit_application/public/${locale}/language/' \;"
    
    echo $execute
done
