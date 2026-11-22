# Valheim dedicated server kubernetes deployment


## deployment

  1. Clone this project down and CD into that directory
  3. Make any necessary changes (examples: change configmap(Other server settings), pv and pvcs..etc)
  4. Deploy the server resources(This assumes you have `envsubst` installed):
      - Run `./deploy.sh` within the valheim directory within this project.
  5. Verify pod starts:
    - `k get pod -n valheim`

Note: To patch server just restart the pod.

## Troubleshooting
  - Verify the pod:
    - `k get pod -n valheim`
    - `k describe pod -n valheim`
      - review the events on the pod

  - Review pods app logs
    - Review init container logs: `k logs -n valheim pods/valheim-66574f9b8c-tfj25 init-downloader --follow`
      - is it having issues downloading the game files?
    - Review main container logs: `k logs -n valheim pods/valheim-66574f9b8c-tfj25 valheim-server --follow`
      - Is it having issues starting the server?

  - Verify storage is bound:
    - `k get pv -n valheim`
    - `k get pvc -n valheim`

  - Verify storage permissions:
    - If pod wont start or you are getting `permission denied` errors and you are using nfs as your persistent storage.
      - validate 1026:100 has permissions to your nfs mounts. You may have to exec into the pod or set it from the storage side.

  - Verify the service has an endpoint
    - `k describe svc -n valheim valheim-svc`
