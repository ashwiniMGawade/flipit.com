#!/bin/bash

includes_path=includes

# Import variables.
source $includes_path/variables.sh

cd $includes_path

touch ../flipit_application/public/js/back_end/gtData.js
sudo chown _www:staff ../flipit_application/public/js/back_end/gtData.js

for locale  in "${locales[@]}"
do
    echo "Set gtData for $locale"
    touch ../flipit_application/public/$locale/js/back_end/gtData.js
    sudo chown _www:staff ../flipit_application/public/$locale/js/back_end/gtData.js
done
