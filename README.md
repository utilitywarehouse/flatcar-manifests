# flatcar-manifests

A Kustomize base for managing [Flatcar Container Linux](https://www.flatcar-linux.org/).

## Components

Includes:

- [flatcar-linux-update-operator](https://github.com/kinvolk/flatcar-linux-update-operator)
- [A DaemonSet](base/namespaced/flatcar-update-ctl.yaml) that controls when nodes are rebooted
  into newer release versions

## Usage

There are bases for `aws`, `gcp` and `merit` providers.

```
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
bases:
  - github.com/utilitywarehouse/flatcar-manifests//aws/cluster?ref=master
  - github.com/utilitywarehouse/flatcar-manifests//aws/namespaced?ref=master
```

```
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
bases:
  - github.com/utilitywarehouse/flatcar-manifests//gcp/cluster?ref=master
  - github.com/utilitywarehouse/flatcar-manifests//gcp/namespaced?ref=master
```

```
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
bases:
  - github.com/utilitywarehouse/flatcar-manifests//merit/cluster?ref=master
  - github.com/utilitywarehouse/flatcar-manifests//merit/namespaced?ref=master
```


Refer to the [example](example/).
