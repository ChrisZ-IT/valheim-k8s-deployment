# Valheim kubernetes deployment dedicated server

## deployment

  1. Add the label `requiredCPU=high` to the worker node(s) you want allow this pod to go on `kubectl label nodes kubewrk01 kubewrk02 requiredCPU=high`
  2. Clone this project down and CD into that directory
  3. Make any necessary changes (examples: change configmap, pv and pvcs..etc )
  4. Deploy the server resources:
    - this block assumes you have `envsubst` installed.
        ```
          read -p "Enter Server name: " servername
          read -p "Enter World name: " worldname
          read -sp "Enter desired password : " svr_password
          export SERVER_NAME=$servername
          export WORLD_NAME=$worldname
          export SERVER_PASSWORD=$(echo -n $svr_password | base64)
          for file in *.yml; do
            # Check if files actually exist to avoid running on empty globs
            [ -e "$file" ] || continue
            echo "Applying $file..."
            envsubst < "$file" | sed 's/_DOLLAR_/\$/g' | kubectl apply -f -
          done
        ```
  5. Verify pod starts:
    - `k get pod -n valheim`
  6. Grab server's quick join code from the logs once the pod is running(Makes it easier to others to join)
    - `k logs -n valheim pods/valheim-66574f9b8c-tfj25 valheim-server`
  7. (optional) Add yourself and your friends to the adminlist.txt/permittedlist.txt (and your enemies to bannedlist.txt)
    - If you used nfs or some other persistent storage you can navigate to where you have it saving the data for the `valheim-saves-pv` mount.

    [Taken from](https://valheim.com/support/a-guide-to-dedicated-servers/) under `Administrating the server`:
      ```
        You can edit three separate text-files to set 1) who has admin privileges, 2) who is banned from your server, and 3) who is permitted on your server.

        These three files, located in the default save path, are called adminlist.txt, bannedlist.txt, and permittedlist.txt. Add one Platform User ID per line to set desired roles. The Platform User ID can be obtained from the Server log or from within the game using the F2 panel and follows the format [Platform]_[User ID] (case sensitive).

        Please note that adding a person on the permitted list will ban everyone else from the server.
      ```

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
