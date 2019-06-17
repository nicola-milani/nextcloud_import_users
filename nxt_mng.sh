#!/bin/bash
#Command line tool for import from csv
#author nicola milani info@nicolamilani.it
#gpl

. /etc/nxt_mng/config

function check_req(){
    
    command -v pwgen >> /dev/null
    if [ $? = 1 ]; then
        echo "please install pwgen"
        exit 1
    fi
}

check_req

#main program
function do_run(){
    #check if file exists
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
    #set -x
    while read -r line
    do
        [ -z "$line" ] && continue
        test $i -eq 1 && ((i=i+1)) && continue
        #   echo "Rang: ${line}"
        var_password=$(pwgen 8 -c -n -N 1)
#        set -e
        export OC_PASS=$var_password+
        #   echo "${var_password} ${OC_PASS}"
        var_name=$(echo "${line}" | cut -d"," -f1)
        var_username=$(echo "${line}" | cut -d"," -f2)
        var_email=$(echo "${line}" | cut -d"," -f3)
        var_quota=$(echo "${line}" | cut -d"," -f4)
        var_group1=$(echo "${line}" | cut -d"," -f5)
        var_group2=$(echo "${line}" | cut -d"," -f6)
        var_group3=$(echo "${line}" | cut -d"," -f7)
        var_group4=$(echo "${line}" | cut -d"," -f8)
        var_group5=$(echo "${line}" | cut -d"," -f9)
        groups=""
        if [ ! -z "${var_group1}" ]; then
            group=$group" --group"${var_group1}
        fi
        if [ ! -z "${var_group2}" ]; then
            group=$group" --group"${var_group2}
        fi
        if [ ! -z "${var_group3}" ]; then
            group=$group" --group"${var_group3}
        fi
        if [ ! -z "${var_group4}" ]; then
            group=$group" --group"${var_group4}
        fi
        if [ ! -z "${var_group5}" ]; then
            group=$group" --group"${var_group5}
        fi
        if [ ! -z "${group}" ]; then
            
            sudo -u ${var_apache_user} php ${var_path_nextcloud}/occ user:add ${var_username} --password-from-env ${groups} --display-name='${var_name}'
        else
            su -s /bin/bash ${var_apache_user} -c "php ${var_path_nextcloud}/occ user:add ${var_username} --password-from-env --display-name='${var_name}'"
        fi
        su -s /bin/bash ${var_apache_user} -c "php ${var_path_nextcloud}/occ user:setting ${var_username} settings email '${var_email}'"
        su -s /bin/bash ${var_apache_user} -c "php ${var_path_nextcloud}/occ user:setting ${var_username} files quota '${var_quota}'"
        echo "${var_username};${var_password}" >> "${var_result_file}"
    done < "$input"
    exit 0
}

function add_to_group(){
    var_apache_user=${webuser}
    var_path_nextcloud=${nxt_path}

    group=$2
    input=$1
    echo $group $input
    i=1
    while read -r line
    do
        [ -z "$line" ] && continue
        test $i -eq 1 && ((i=i+1)) && continue
        var_username=$(echo "${line}" | cut -d"," -f2)
        su -s /bin/bash ${var_apache_user} -c "php ${var_path_nextcloud}/occ group:adduser ${group} ${var_username}" 
	echo $var_username $group
    done < "$input"
}

function do_help(){
    cat <<EOF

--csv /path/of/users_csv --header [true|false] --sep "," --debug [true|false] --nxt_path /path/nextcloud --log_path /path/output/log
--help: show this
--add-grp: add all users in csv file in to group
--grp-report : show report of all users by group
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
    
    if [ -f $(pwd)/users_template.csv ]; then
        echo "file  $(pwd)/users_template.csv already exist"
        exit 1
    fi
cat <<EOT >> $(pwd)/users_template.csv
Name,username,email,quota,group1,group2,group3,group4,group5
Mario Rossi,m.rossi,m.rossi@example.com,2GB,,,,,

EOT
    
    if [ $? = 1 ]; then
        echo "chek permissions"
    else
        echo "example created in $(pwd)"
    fi
}
function print_default(){
    echo  "Print default options..."
    echo " "
    print_value
}
function print_value(){
    echo -e "csv path:" $csv
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
webuser="www-data"
nxt_path="/var/www/html/nextcloud"
log_path="/var/log/nxt_tools/"
mkdir -p $log_path &> /dev/null
if [ $? -eq 1 ]; then
    echo "can't write in $log_path"
fi

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

LONGOPTS="help,add-grp,grp-report,csv:,sep:,debug,header:,webuser:,nxt_path:,log_path:,default,get_example"

ARGS=$(getopt -s bash  --options $SHORTOPTS --longoptions $LONGOPTS --name $PROGNAME -- "$@" )

if [ $? -ne 0 ]; then
    # bad argument
    exit 1
fi
eval set -- "$ARGS"

while true; do
    
    case $1 in
        --add-grp)
	    shift
            shift
	    add_to_group $1 $2
            exit 0
        ;;
        --grp-report)
            sudo -u www-data php /var/www/html/nextcloud/occ group:list
            exit 0
        ;;
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
