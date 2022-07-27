# Deploy a Stack
Using fleet we're going to deploy an entire stack, clusters and apps/services.

## Prereqs
* kubectl
* running `Rancher Server`
* patched default `ClusterGroup` in `fleet-local` namespace (see below for how)

### Patching ClusterGroup
There's a bug in fleet right now that has yet to be fixed. It prevents us from deploying applications to our local cluster. This is an easy permanent fix, just run:
```console
kubectl patch ClusterGroup -n fleet-local default --type=json -p='[{"op": "remove", "path": "/spec/selector/matchLabels/name"}]'
```

## HowTo
Easy mode for deploying is using Carvel's `ytt` and `kapp` applications. `ytt` is both a yaml template and overlay tool as well as a yaml aggregator, we can use it to recursively grab all yaml files in a directory and feed over to `kubectl` or `kapp`. `kapp` does similar to kubectl but will create the objects in order, and allow you to aggregate/track the deployment with an `app` name. This allows for a higher level view.