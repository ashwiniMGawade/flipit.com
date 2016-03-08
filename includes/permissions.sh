echo "######################################"
echo "##### Setting permissions share dir   "
echo "######################################"

cd $SHARE_DIR

for folder in "${writable_dirs[@]}"
do
    echo "sudo chown -R $webuser $folder"
    sudo chown -R $webuser public/$folder
    echo "sudo chmod -R 775 $folder"
    sudo chmod -R 777 public/$folder

    for locale  in "${locales[@]}"
    do
        echo "sudo chown -R $webuser $locale/$folder"
        sudo chown -R $webuser $locale/$folder
        echo "sudo chmod -R 775 $locale/$folder"
        sudo chmod -R 777 $locale/$folder
    done
done

for folder in "${writable_files[@]}"
do
    echo "sudo chown -R $webuser $folder"
    sudo chown -R $webuser public/$folder
    echo "sudo chmod -R 775 $folder"
    sudo chmod -R 777 public/$folder

    for locale  in "${locales[@]}"
    do
        echo "sudo chown -R $webuser $locale/$folder"
        sudo chown -R $webuser $locale/$folder
        echo "sudo chmod -R 775 $locale/$folder"
        sudo chmod -R 777 $locale/$folder
    done
done

echo "#### Permissions are reset."