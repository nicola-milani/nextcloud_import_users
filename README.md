# nextcloud_import_users
import users from csv


import.sh --csv /path/of/users_csv --header [true|false] --sep ";" --debug [true|false] --nxt_path /path/nextcloud --log_path
/path/output/log

--help: show this

--csv: path of csv with users

--sep: separator for csv ex ; or , etc.. 

--nxt_path: absolute path of nextcloud installation

--log_path: path for username and password output

--debug: enable verbose output

--default: print default value

--get_example: get csv example structure with number of user groups
