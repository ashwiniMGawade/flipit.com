#!/bin/bash

includes_path=includes

# Import variables.
source $includes_path/variables.sh

shopt -s dotglob

cd flipit_application/public/

mkdir language
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
