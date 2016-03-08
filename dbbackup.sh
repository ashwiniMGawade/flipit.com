#!/bin/bash
includes_path=includes

# Import variables.
source $includes_path/variables.sh

# What type of backup we should run

function createVisitorInsertStatement()
{
    count=1
    visitorInsertStatement='INSERT INTO visitor VALUES'
    while read -a row
    do
        if [ $count -gt 1 ]
            then
            visitorInsertStatement="$visitorInsertStatement (${row[0]},'Visitor${row[0]}','lname','visitor${row[0]}@flipit.com', NULL,'5f4dcc3b5aa765d61d8327deb882cf99', NULL,${row[1]},${row[2]},${row[3]},CURDATE() + INTERVAL -20 YEAR,NULL,${row[4]},${row[5]},${row[6]},${row[7]},${row[8]},${row[9]},CURDATE(),CURDATE(),CURDATE(),CURDATE(),NULL, NULL, NULL,${row[10]},${row[11]},CURDATE(),${row[12]},${row[13]},${row[14]},${row[15]},NULL,CURDATE()),"
        fi
        let count=count+1
    done < <(echo "SELECT id,status,imageid,gender,weeklynewsletter,fashionnewsletter,travelnewsletter,codealert,createdby,deleted,active,changepasswordrequest,mailClickCount,mailOpenCount,mailHardBounceCount,mailSoftBounceCount FROM visitor LIMIT ${2},1000" | mysql ${1} -u ${db_user} -p"${db_user_pass}" --raw)
}

function createFlipitAdminUsers()
{
    createSuperAdministrator="INSERT INTO user VALUES (NULL, 'Super', 'Admin', 'sa@web-flight.nl', '5f4dcc3b5aa765d61d8327deb882cf99', '1', NULL, NULL, NULL, NULL, NULL, '', '1', NULL, NULL, '0', '', '', '', '', NULL, NULL, '0', NULL, '2013-12-12 12:50:20', NULL, NULL);"
    echo $createSuperAdministrator >> $backupPathType/backup_user_$timeStempBackup.sql
    createAdministrator="INSERT INTO user VALUES (NULL, 'Admin', 'User', 'a@web-flight.nl', '5f4dcc3b5aa765d61d8327deb882cf99', '1', NULL, NULL, NULL, NULL, NULL, '', '2', NULL, NULL, '0', '', '', '', '', NULL, NULL, '0', NULL, '2013-12-12 12:50:20', NULL, NULL);"
    echo $createAdministrator >> $backupPathType/backup_user_$timeStempBackup.sql
    createEditor="INSERT INTO user VALUES (NULL, 'Editor', 'User', 'e@web-flight.nl', '5f4dcc3b5aa765d61d8327deb882cf99', '1', NULL, NULL, NULL, NULL, NULL, '', '4', NULL, NULL, '0', '', '', '', '', NULL, NULL, '0', NULL, '2013-12-12 12:50:20', NULL, NULL);"
    echo $createEditor >> $backupPathType/backup_user_$timeStempBackup.sql
}

function createLocaleSpecificDbBackup()
{
    echo "Started backup for ${2} DB"
    mysqldump -u ${db_user} -p"${db_user_pass}" -h ${db_host} --ignore-table=${2}.view_count --ignore-table=${2}.conversions --ignore-table=${2}.visitor ${2} > $backupPathType/backup_site_${3}_$timeStempBackup.sql
    if [ $1 = 'testing' ]
        then
        mysqldump -u ${db_user} -p"${db_user_pass}" -h ${db_host} --where="DATE(created_at)>CURDATE()-INTERVAL 1 YEAR" ${2} view_count >> $backupPathType/backup_site_${3}_$timeStempBackup.sql
        mysqldump -u ${db_user} -p"${db_user_pass}" -h ${db_host} --where="DATE(created_at)>CURDATE()-INTERVAL 1 YEAR" ${2} conversions >> $backupPathType/backup_site_${3}_$timeStempBackup.sql
        mysqldump -u ${db_user} -p"${db_user_pass}" -h ${db_host} --no-data ${2} visitor >> $backupPathType/backup_site_${3}_$timeStempBackup.sql
    else
        mysqldump -u ${db_user} -p"${db_user_pass}" -h ${db_host} --no-data ${2} view_count conversions visitor >> $backupPathType/backup_site_${3}_$timeStempBackup.sql
    fi

    count=$(mysql -u ${db_user} -p"${db_user_pass}" -h ${db_host} ${2} -s --execute="SELECT count(1) as count FROM visitor")
    limit=0
    while [  $count -gt 0 ]
        do
        createVisitorInsertStatement ${2} $limit
        echo "${visitorInsertStatement%?};" >> $backupPathType/backup_site_${3}_$timeStempBackup.sql
        let count=count-1000
        let limit=limit+1000
    done
    echo "Completed backup of ${2} DB"
}

function dumpDatabasesForDevelopmentAndTesting()
{
    createLocaleSpecificDbBackup $1 'kortingscode_site' 'kc'

    echo "Started backup for kortingscode_user DB"
    mysqldump -u ${db_user} -p"${db_user_pass}" -h ${db_host} kortingscode_user > $backupPathType/backup_user_$timeStempBackup.sql
    createFlipitAdminUsers
    echo "Completed backup of kortingscode_user DB"

    for locale in "${locales[@]}"
        do
        createLocaleSpecificDbBackup $1 flipit_${locale,,} ${locale,,}
    done

}

function dumpDatabasesForBackup()
{
    mysqldump -u ${db_user} -p"${db_user_pass}" -h ${db_host} kortingscode_site > $backupPathType/backup_site_kc_$timeStempBackup.sql
    mysqldump -u ${db_user} -p"${db_user_pass}" -h ${db_host} kortingscode_user > $backupPathType/backup_user_$timeStempBackup.sql

    for locale in "${locales[@]}"
        do
        mysqldump -u ${db_user} -p"${db_user_pass}" -h ${db_host} flipit_${locale,,} > $backupPathType/backup_site_${locale,,}_$timeStempBackup.sql
    done
}

function compressForBackup()
{
    cd $backupPathType
    tar -zcf backup_site_kc_$timeStempBackup.tar.gz backup_site_kc_$timeStempBackup.sql
    rm -rf $backupPathType/backup_site_kc_$timeStempBackup.sql

    tar -zcf backup_user_$timeStempBackup.tar.gz backup_user_$timeStempBackup.sql
    rm -rf $backupPathType/backup_user_$timeStempBackup.sql

    for locale in "${locales[@]}"
        do
        tar -zcf backup_site_${locale,,}_$timeStempBackup.tar.gz backup_site_${locale,,}_$timeStempBackup.sql
        rm -rf $backupPathType/backup_site_${locale,,}_$timeStempBackup.sql
    done
}

function compressForDevelopmentAndTesting()
{
    mv $backupPathType/backup_site_kc_$timeStempBackup.sql $backupPathType/backup_site_kc.sql
    mv $backupPathType/backup_user_$timeStempBackup.sql $backupPathType/backup_user.sql

    for locale in "${locales[@]}"
        do
	    mv $backupPathType/backup_site_${locale,,}_$timeStempBackup.sql $backupPathType/backup_site_${locale,,}.sql
    done

    cd $backupPathType
    tar -zcf ../devDbBackup.tar.gz ./*
    rm -rf $backupPathType/*
    mv $backupPath/devDbBackup.tar.gz $backupPathType/
}

function deleteDatabaseDumpsInPath()
{
    files=$(ls $backupPathType/*.*  2> /dev/null | wc -l)
    if [ $files -gt 0 ]
        then
        rm -r $backupPathType/*
    fi
}

function deleteDatabaseDumpsOncreatedDate()
{
    filesToBeDeleted=$(find $backupPathType/* -mtime +${1} 2> /dev/null | wc -l)
    if [ $filesToBeDeleted -gt 0 ]
        then
        echo "Deleting backups more than ${1} days old"
        find $backupPathType/* -mtime +${1} -exec rm -r {} \;
    fi
}

case $1 in
    dev)
        backupPathType=$backupPath/dev
        mkdir -p $backupPathType
        message=$(echo "Created backups for dev")
        deleteDatabaseDumpsInPath
        dumpDatabasesForDevelopmentAndTesting $1
        compressForDevelopmentAndTesting
    ;;
    testing)
        backupPathType=$backupPath/testing
        mkdir -p $backupPathType
        message=$(echo "Created backups for testing")
        deleteDatabaseDumpsInPath
        dumpDatabasesForDevelopmentAndTesting $1
        compressForDevelopmentAndTesting
    ;;
    month)
        backupPathType=$backupPath/monthly
        mkdir -p $backupPathType
	    message=$(echo "Created monthly backup")
	    dumpDatabasesForBackup
	    compressForBackup
    ;;
    *)
        backupPathType=$backupPath/hourly
        mkdir -p $backupPathType
        message=$(echo "Created hourly backup")
        deleteDatabaseDumpsOncreatedDate 5
        dumpDatabasesForBackup
        compressForBackup
    ;;
esac

echo $message
