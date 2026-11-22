prompt_var() {
    local var_name="$1" default="$2" prompt="$3" mode="$4"
    local input flags="-rp"

    [[ "$mode" == "secret" ]] && flags="-rsp"
    read $flags "$prompt (Default: '${default:-none}'): " input
    [[ "$mode" == "secret" ]] && echo ""

    input="${input:-$default}"

    if [[ "$mode" == "list" && -n "$input" ]]; then
        input=$(tr ',' '\n' <<< "$input" | xargs -n1 | sed '2,$s/^/    /')
    fi

    export "$var_name=$input"
    echo ""
}

prompt_var SERVER_NAME       "My Server"     "Enter Server name (Default: 'My Server')"
prompt_var WORLD_NAME        "$SERVER_NAME"  $'Enter World Name (Default: '"$SERVER_NAME"')'
prompt_var SERVER_PASSWORD   ""              $'Enter server password (Default: none)' secret
prompt_var ADMIN_LIST        ""              $"Enter Comma separated list of Numeric Steam IDs for admin access (Default: 'none')" list
export SERVER_PASSWORD=$(printf '%s' "$SERVER_PASSWORD" | base64)

if [ -f "namespace.yml" ]; then
    echo "Applying namespace.yml..."
    kubectl apply -f namespace.yml
fi
for file in *.yml; do
    [ -e "$file" ] || continue
    echo "Applying $file..."
    if [[ "$file" == "configmap.yml" && "$svr_password" == "none" ]]; then
        envsubst < "$file" | \
        sed -E 's/-password\s+"[^"]+"/-public 0/g' | \
        sed 's/_DOLLAR_/\$/g' | kubectl apply -f -
    else
        envsubst < "$file" | sed 's/_DOLLAR_/\$/g' | kubectl apply -f -
    fi
done
