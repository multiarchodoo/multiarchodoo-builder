#!/bin/bash



test -e /etc/odoo/odoo.conf || echo "using default config for /etc/odoo/odoo.conf"
test -e /etc/odoo/odoo.conf || cp /odoo.conf.init /etc/odoo/odoo.conf
chown odoo /etc/odoo/odoo.conf
set -e

# set the postgres database host, port, user and password according to the environment
# and pass them as arguments to the odoo process if not present in the config file
: ${HOST:=${DB_PORT_5432_TCP_ADDR:='db'}}
: ${PORT:=${DB_PORT_5432_TCP_PORT:=5432}}
: ${USER:=${DB_ENV_POSTGRES_USER:=${POSTGRES_USER:='odoo'}}}
: ${PASSWORD:=${DB_ENV_POSTGRES_PASSWORD:=${POSTGRES_PASSWORD:='odoo'}}}

DB_ARGS=()
function check_config() {
    param="$1"
    value="$2"
    if ! grep -q -E "^\s*\b${param}\b\s*=" "$ODOO_RC" ; then
        DB_ARGS+=("--${param}")
        DB_ARGS+=("${value}")
   fi;
}
check_config "db_host" "$HOST"
check_config "db_port" "$PORT"
check_config "db_user" "$USER"
check_config "db_password" "$PASSWORD"

#apk add inotify-tools
test -e /var/lib/odoo/filestore/.seeded || { echo "seeding";
sleep 5
#pip3 install inotify &
#fails:
#web_1   |   File "/usr/lib/python3.8/site-packages/inotify/calls.py", line 34, in _check_nonnegative
#web_1   |     raise InotifyError("Call failed (should not be -1): (%d)" %
#web_1   | inotify.calls.InotifyError: Call failed (should not be -1): (-1) ERRNO=(0)

time  /usr/bin/odoo --db_host $HOST --db_port 5432 --db_user $USER --db_password $PASSWORD -d $USER --dev=reload -i base,hr,purchase_stock,stock_account,hr_expense,stock,project,portal_rating,hr_org_chart,hr_maintenance,hr_holidays,note,point_of_sale,sales,crm,fleet,billing,mrp,lunch,sale_management,repair,website_hr_recruitment,hr_attendance,board,warehouse,expenses,purchase,project-management,tpm-maintainance-software,manufacturing  --load-language de_DE --stop-after-init
touch /var/lib/odoo/filestore/.seeded
 echo -n ;  } ;
echo launching


case "$1" in
    -- | odoo)
        shift
        if [[ "$1" == "scaffold" ]] ; then
            exec odoo "$@"
        else
            exec odoo "$@" "${DB_ARGS[@]}"
        fi
        ;;
    -*)
        exec odoo "$@" "${DB_ARGS[@]}"
        ;;
    *)
        exec "$@"
esac

exit 1
