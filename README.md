# Valheim kubernetes deployment dedicated server
A project for deploying a Valheim server into a kubernestes cluster.

Note:
  - I am using an NFS share off my synology for storing game files & Saves. Because of this my base container is using the uid & gid of my non admin account just so I don't have to modify any permissions. This makes it easy to be able to quickly edit the Admin/Permitted/banned.txt files with out doing any code changes or pod restarts.

## deployment

  1. Add the label `requiredCPU=high` to the worker node(s) you want allow this pod to go on `kubectl label nodes kubewrk01 kubewrk02 requiredCPU=high`
  2. Clone this project down and CD into that directory
  3. Make any necessary changes (examples: change configmap, pv and pvcs..etc )
  4. Deploy the server resources:
    - this block assumes you have `envsubst` installed.
      - note 1: Not setting a password prevents your server from showing up in the server browser(people will need your IP/join code).
      - note 2: Passwords are required for public servers. This deployment current defaults to a public server if you set a password.
      - note 3: `-crossplay` is also enabled by default(Registers your server with PlayFab, this enables crossplay (steam, epic and consoles) & generates a join code). Remove that line from the config map if only want to allow steam users to be able to join.
      - note 4: You will need to manually add `-public 0 -password $4` to your config map if you don't want a public server and you want a password. Im not really accounting for that in the deploy script below. Just noting it is a possible config and I might add it later.
        ```
          read -p "Enter Server name(My Server): " servername
          servername=${servername:-My Server}
          read -p "Enter World name(${servername}): " worldname
          read -sp "Enter server password(none): " svr_password
          svr_password=${svr_password:-none}
          echo ""

          export SERVER_NAME=$servername
          if [[ -z "$worldname" ]]; then
            export WORLD_NAME="$servername"
          else
            export WORLD_NAME="$worldname"
          fi
          export SERVER_PASSWORD=$(echo -n $svr_password | base64)

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
        ```
  5. Verify pod starts:
    - `k get pod -n valheim`
  6. Grab server's quick join code from the logs once the pod is running(Makes it easier to others to join)
    - `k logs -n valheim pods/valheim-66574f9b8c-tfj25 valheim-server`
  7. (optional) Add yourself and your friends to the adminlist.txt/permittedlist.txt (and your enemies to bannedlist.txt)
    - If you used nfs or some other persistent storage you can navigate to where you have it saving the data for the `valheim-saves-pv` mount.

[Taken from](https://valheim.com/support/a-guide-to-dedicated-servers/) under `Administrating the server` :

```
You can edit three separate text-files to set 1) who has admin privileges, 2) who is banned from your server, and 3) who is permitted on your server.

These three files, located in the default save path, are called adminlist.txt, bannedlist.txt, and permittedlist.txt. Add one Platform User ID per line to set desired roles. The Platform User ID can be obtained from the Server log or from within the game using the F2 panel and follows the format [Platform]_[User ID] (case sensitive).

Please note that adding a person on the permitted list will ban everyone else from the server.
```

Note: To patch server just restart the pod.

## Troubleshooting
  - Verify the pod:
    - `k get pod -n valheim`
    - `k describe pod -n valheim`
      - review the events on the pod

  - Review pods app logs
    - Review init container logs: `k logs -n valheim pods/valheim-66574f9b8c-tfj25 init-steamcmd --follow`
      - is it having issues downloading the game files?
    - Review main container logs: `k logs -n valheim pods/valheim-66574f9b8c-tfj25 valheim-server --follow`
      - Is it having issues starting the server?

  - Verify storage is bound:
    - `k get pv -n valheim`
    - `k get pvc -n valheim`

  - Verify the service has an endpoint
    - `k describe svc -n valheim valheim-svc`

## TO DO
  - Setup network policies
  - Maybe capture the access .txt configs in the config map.
    Still not 100% on this since it would require a pod restart to apply it.
