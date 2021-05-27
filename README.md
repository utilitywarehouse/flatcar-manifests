# flatcar-manifests

A Kustomize base for managing [Flatcar Container Linux](https://www.flatcar-linux.org/).

## Components

Includes:

- [flatcar-linux-update-operator](https://github.com/kinvolk/flatcar-linux-update-operator)
- And, optionally, [Nebraska](https://github.com/kinvolk/nebraska)

## Usage

```
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
bases:
  - github.com/utilitywarehouse/flatcar-manifests//base/cluster?ref=master
  - github.com/utilitywarehouse/flatcar-manifests//base/namespaced?ref=master
  - github.com/utilitywarehouse/flatcar-manifests//base/nebraska?ref=master
```

Refer to the [example](example/).
