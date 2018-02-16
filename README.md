# Helm charts for Deep Security Smart Check

## Getting started

You will need `[helm](https://helm.sh)` installed and running. There's a handy [quickstart](https://docs.helm.sh/using_helm/#quickstart) that will help you get `helm` up and running.

### Securing Helm

The Helm team have some helpful [guidelines for securing your Helm installation](https://docs.helm.sh/using_helm/#securing-your-helm-installation) as well as [an abbreviated list of best practices](https://docs.helm.sh/using_helm/#best-practices-for-securing-helm-and-tiller) for reference.

### Installing Deep Security Smart Check

The Helm chart for Deep Security Smart Check is hosted on Github; the latest version is `v0.0.2`.

```sh
helm upgrade --install \
  --values {values file} \
  {release name} \
  https://github.com/deepsecurity/smartcheck/archive/v0.0.2.tgz
```

To install into an existing namespace that's different from the current kube config namespace, use the `--namespace` parameter for `helm upgrade`:

```sh
helm upgrade --install \
  --namespace {namespace} \
  --values {values file} \
  {release name} \
  https://github.com/deepsecurity/smartcheck/archive/v0.0.2.tgz
```

### Setting configuration values on the command line

It's significantly better to use a version-controlled `values.yaml` file, but if you're experimenting you can set configuration values on the `helm` command line using `--set`:

```sh
helm upgrade --install \
  --set k=v,... \
  {release name}
  https://github.com/deepsecurity/smartcheck/archive/v0.0.2.tgz
```

For example, to install using the defaults but expose the service as a `ClusterIP` instead of using a `LoadBalancer` and to disable persistent volumes, use:

```sh
helm upgrade --install \
  --set persistence.enabled=false,service.type=ClusterIP \
  {release name}
  https://github.com/deepsecurity/smartcheck/archive/v0.0.2.tgz
```

## Contributing

### Getting started as a contributor

You will need [helm](https://helm.sh), of course. There's a handy [quickstart](https://docs.helm.sh/using_helm/#quickstart) that will help you get up and running.

### Checking the chart for errors

**IMPORTANT:** This will only check the chart for `helm` errors and YAML / JSON syntax errors -- it will not catch semantic errors or schema violations in your Kubernetes resource definitions.

```sh
helm lint
```

### Packaging the chart for distribution

```sh
helm package smartcheck
```

### Installing the chart

```sh
helm install smartcheck
```
