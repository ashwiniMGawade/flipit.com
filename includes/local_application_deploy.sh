# Deploying on local development machine
cd $rootpath/flipit_application && git pull

echo "######################################"
echo "##### Starting deploy                 "
echo "######################################"

echo "##### Checking out files to new release directory ..."
cd $rootpath/flipit_application && git read-tree $1 && git checkout-index -a -f --prefix=$CUR_RLS_DIR/
rm -rf $rootpath/flipit_application/public/tmp/

echo "######################################"
echo "##### DB migrations                   "
echo "######################################"

php $rootpath/flipit_application/application/migration/migrations_site.php
php $rootpath/flipit_application/application/migration/migrations_user.php