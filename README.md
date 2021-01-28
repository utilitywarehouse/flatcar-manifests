# flatcar-manifests

A Kustomize base for managing [Flatcar Container Linux](https://www.flatcar-linux.org/).

## Components

Includes:

- [flatcar-linux-update-operator](https://github.com/kinvolk/flatcar-linux-update-operator)

## Usage

```
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
bases:
  - github.com/utilitywarehouse/flatcar-manifests//base/cluster?ref=master
  - github.com/utilitywarehouse/flatcar-manifests//base/namespaced?ref=master
```

Refer to the [example](example/).
