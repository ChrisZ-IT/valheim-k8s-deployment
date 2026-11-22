prompt_var() {
    local var_name="$1" default="$2" prompt="$3" mode="$4"
    local input val

    if [[ "$mode" == "secret" ]]; then
        read -rsp "$prompt: " input
        echo ""
    else
        read -rp "$prompt: " input
    fi

    val="${input:-$default}"

    export "$var_name"="$val"
    echo ""
}

prompt_var SERVER_NAME       "My Server"       "Enter Server name (Default: 'My Server')"
prompt_var WORLD_NAME        "$SERVER_NAME"    $'Enter World Name (Default: '"$SERVER_NAME"')'
prompt_var SERVER_PASSWORD   ""           $'Enter server password (Default: none)' secret
export SERVER_PASSWORD=$(echo -n $SERVER_PASSWORD | base64)

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
