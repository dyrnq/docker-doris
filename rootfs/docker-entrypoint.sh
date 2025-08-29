#!/usr/bin/env bash
set -eo pipefail



conf_arrow_flight_sql_port(){
    file="$1"
    value="$2"
    set_config_options "${file}" arrow_flight_sql_port "${value}"
}

conf_priority_networks(){
    file="$1"
    value="$2"
    set_config_options "${file}" priority_networks "${value}"
}

conf_enable_fqdn_mode(){

    if [[ "${DORIS_VERSION}" < "2.0.0" ]]; then return 0; fi

    file="$1"
    value="$2"
    set_config_options "${file}" enable_fqdn_mode "${value}"

}



process_doris_properties() {
    local doris_config_file=$1
    local doris_properties_content=$2
    # local config_options=()

    ## check if file is writable
    if [ -w "${doris_config_file}" ]; then
        local OLD_IFS="$IFS"
        IFS=$'\n'
        for prop in $doris_properties_content; do
            prop=$(echo $prop | tr -d '[:space:]')

            if [ -z "$prop" ]; then
                continue
            fi

            IFS=':' read -r key value <<< "$prop"

            # value=$(echo $value | envsubst)

            # config_options+=("$key" "$value")
            set_config_options "${doris_config_file}" "${key}" "${value}"
        done
        IFS="$OLD_IFS"

        # if [ ${#config_options[@]} -ne 0 ]; then
        #     set_config_options "${doris_config_file}" "${config_options[@]}"
        # fi
    else
        echo "${doris_config_file} NOT writable, skip process properties."
    fi
}

set_config_options() {
    local file="$1"
    local key="$2"
    local value="$3"
    if [ -w "$file" ]; then
        exist=$(grep -v "^#" < "${file}" | yq -p=props -o=yaml | yq "has(\"${key}\")")

        if [ "true" = "$exist" ]; then
            ## modify if existed
            sed -i "s/^${key}.*/${key} = ${value}/g" "$file"
        else
            echo "${key} = ${value}" >> "$file" ## append
        fi
    fi

}


_main() {
    if [ -n "$TZ" ]; then
        ( ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime && echo "$TZ" > /etc/timezone ) || true
    fi
    ulimit -n "${ULIMIT_NOFILE:-1000000}" || true
    ulimit -a || true
    swapoff -a || true

    conf_arrow_flight_sql_port "/opt/apache-doris/fe/conf/fe.conf" "${FE_ARROW_FLIGHT_SQL_PORT}"
    conf_arrow_flight_sql_port "/opt/apache-doris/be/conf/be.conf" "${BE_ARROW_FLIGHT_SQL_PORT}"
    conf_enable_fqdn_mode "/opt/apache-doris/fe/conf/fe.conf" "${ENABLE_FQDN_MODE}"
    if [ -n "${FE_PRIORITY_NETWORKS}" ]; then conf_priority_networks "/opt/apache-doris/fe/conf/fe.conf" "${FE_PRIORITY_NETWORKS}"; fi
    if [ -n "${BE_PRIORITY_NETWORKS}" ]; then conf_priority_networks "/opt/apache-doris/be/conf/be.conf" "${BE_PRIORITY_NETWORKS}"; fi

    if [ -n "${DORIS_FE_PROPERTIES}" ]; then
        process_doris_properties /opt/apache-doris/fe/conf/fe.conf "${DORIS_FE_PROPERTIES}"
    fi

    if [ -n "${DORIS_BE_PROPERTIES}" ]; then
        process_doris_properties /opt/apache-doris/be/conf/be.conf "${DORIS_BE_PROPERTIES}"
    fi
    if [ -n "${DORIS_MS_PROPERTIES}" ]; then
        process_doris_properties /opt/apache-doris/ms/conf/doris_cloud.conf "${DORIS_MS_PROPERTIES}"
    fi


    if grep -q -i "stand" <<< "${RUN_MODE}"; then
        touch /etc/s6-overlay/s6-rc.d/user/contents.d/be
        touch /etc/s6-overlay/s6-rc.d/user/contents.d/fe
        touch /etc/s6-overlay/s6-rc.d/user/contents.d/cluster
    elif grep -q -i "fe" <<< "${RUN_MODE}"; then
        touch /etc/s6-overlay/s6-rc.d/user/contents.d/fe
        touch /etc/s6-overlay/s6-rc.d/user/contents.d/cluster
    elif grep -q -i "be" <<< "${RUN_MODE}"; then
        touch /etc/s6-overlay/s6-rc.d/user/contents.d/be
        touch /etc/s6-overlay/s6-rc.d/user/contents.d/cluster
    elif grep -q -i "ms" <<< "${RUN_MODE}"; then
        if [ -e /opt/apache-doris/ms/bin/ ]; then touch /etc/s6-overlay/s6-rc.d/user/contents.d/ms; fi
    fi



    exec /init
}

_main "$@"
