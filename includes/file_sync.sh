echo "#######################################"
echo "##### Getting production files         "
echo "#######################################"

rsync -rltuDv --delete --exclude='application.ini' --exclude='public/tmp/' root@$productionip:$prodpath/shared/* $SHARE_DIR/

echo "#### Files are synced."
