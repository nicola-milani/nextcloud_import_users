#!/bin/bash
#Command line tool for import from csv

function check_req(){

    command -v pwgen >> /dev/null
    if [ $? = 1 ]; then
        echo "please install pwgen"
        exit 1
    fi
}

check_req

function do_run(){
    if [ ! -f $csv ]; then
        echo "file not exists"
        exit 1
    fi
    var_datum=$(date +"%Y%m%d")
    input=${csv}
    var_apache_user=${webuser}
    var_path_nextcloud=${nxt_path}
    var_result_file="${log_path}/${var_datum}_user_create.txt"

    i=1
    while read -r line
    do
        [ -z "$line" ] && continue
        test $i -eq 1 && ((i=i+1)) && continue

    #   echo "Rang: ${line}"
        var_password=$(pwgen 8 -c -n -N 1)
        set -e
        export OC_PASS=$var_password
    #   echo "${var_password} ${OC_PASS}"
        var_username=$(echo "${line}" | cut -d"," -f2)
        var_name=$(echo "${line}" | cut -d"," -f1)
        var_group1=$(echo "${line}" | cut -d"," -f3)
        var_group2=$(echo "${line}" | cut -d"," -f4)
        var_group3=$(echo "${line}" | cut -d"," -f5)
        var_group4=$(echo "${line}" | cut -d"," -f6)
        var_group5=$(echo "${line}" | cut -d"," -f7)
        var_email=$(echo "${line}" | cut -d"," -f8)
        var_quota=$(echo "${line}" | cut -d"," -f9)
        # echo $var_username " with pwd " $var_password " in groups " $var_group1 $var_group2 $var_group3 $var_group4 $var_group5 " with email" $var_email "with quota" $var_quota
        # if [ "${var_group5}" != "" ] ;then
        # echo     su -s /bin/sh ${var_apache_user} -c "php ${var_path_nextcloud}/occ user:add ${var_username} --password-from-env --group='${var_group1}' --group='${var_group2}' --group='${var_group3}' --group='${var_group4}' --group='${var_group5}' --display-name='${var_name}'"
        # if [ "${var_group4}" != "" ] ;then
        # echo     su -s /bin/sh ${var_apache_user} -c "php ${var_path_nextcloud}/occ user:add ${var_username} --password-from-env --group='${var_group1}' --group='${var_group2}' --group='${var_group3}' --group='${var_group4}' --display-name='${var_name}'"
        # elif [ "${var_group3}" != "" ] ;then
        #     su -s /bin/sh ${var_apache_user} -c "php ${var_path_nextcloud}/occ user:add ${var_username} --password-from-env --group='${var_group1}' --group='${var_group2}' --group='${var_group3}' --display-name='${var_name}'"
        # elif [ "${var_group2}" != "" ] ;then
        #     su -s /bin/sh ${var_apache_user} -c "php ${var_path_nextcloud}/occ user:add ${var_username} --password-from-env --group='${var_group1}' --group='${var_group2}' --display-name='${var_name}'"
        # fi
        # su -s /bin/sh ${var_apache_user} -c " php ${var_path_nextcloud}/occ user:setting ${var_username} settings email '${var_email}'"
        # su -s /bin/sh ${var_apache_user} -c " php ${var_path_nextcloud}/occ user:setting ${var_username} files quota '${var_quota}'"
        # echo "${var_username};${var_password}" >> "${var_result_file}"
    done < "$input"
exit 0
}

function do_help(){
    cat <<EOF

$0 --csv /path/of/users_csv --header [true|false] --sep ";" --debug [true|false] --nxt_path /path/nextcloud --log_path /path/output/log
--help: show this
--csv: path of csv with users
--sep: separator for csv ex ; or , etc.. 
--nxt_path: absolute path of nextcloud installation
--log_path: path for username and password output
--debug: enable verbose output
--default: print default value
--get_example: get csv example structure with number of user groups
EOF

}


function get_example(){

if [ -f $HOME/users_template.csv ]; then
    echo "file  $HOME/users_template.csv already exist"
    exit 1
fi
cat <<EOT >> ~/users_template.csv
Nome e Cognome,username,group1,group2,group3,group4,group5,E-mail,Quota

EOT

    if [ $? = 1 ]; then
        echo "chek permissions"
    else
        echo "example created in $HOME"
    fi
}
function print_default(){
    echo  "Print default options..."
    echo " "
    print_value
}
function print_value(){
    echo -e "csv path: $(pwd)/users.csv"
    echo -e "with header: " $header
    echo -e "separator file: " "\""$sep"\"" 
    echo -e "web user: "$webuser 
    echo -e "nextcloud path: " $nxt_path 
    echo -e "path of output:  "$log_path 
    echo -e "status of debug: "$debug
}

#default value
csv="$(pwd)/users.csv"
header="true"
sep=","
debug="false"
webuser="root"
nxt_path="/var/www"
log_path="/root/"

function do_import() {
    clear
    echo "Running options..."
    print_value
    do_run
    echo "done"
}
set +x
PROGNAME=${0##*/}
PROGVERSION=0.1.0
SHORTOPTS="hs:cr"

LONGOPTS="help,csv:,sep:,debug,header:,webuser:,nxt_path:,log_path:,default,get_example"

ARGS=$(getopt -s bash  --options $SHORTOPTS --longoptions $LONGOPTS --name $PROGNAME -- "$@" )

if [ $? -ne 0 ]; then
    # bad argument
    exit 1
fi
eval set -- "$ARGS"

while true; do

   case $1 in
    -h|--help)
        shift
        do_help
        exit 0
        ;;
    --csv)
        shift
        csv=$1
        ;;
    --header)
        shift
        header=$1
        ;;
    --sep)
        shift
        sep=$1
        ;;
    --webuser)
        shift
        webuser=$1
        ;;
    --nxt_path)
        shift
        nxt_path=$1
        ;;
    --log_path)
        shift
        log_path=$1
        ;;
    --debug)
        shift
        debug="true"
        #exit 0
        ;;
    --default)
        shift
        print_default
        exit 0
        ;;
    --get_example)
        shift
        get_example
        exit 0
        ;;
    *)
        shift
        break
        ;;
   esac
   shift
done

do_import