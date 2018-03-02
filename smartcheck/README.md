# Deep Security Smart Check

## Getting started

Deep Security Smart Check uses the `helm` package manager for Kubernetes.

### Installing Helm

You will need `helm` installed and running. There's a handy [quickstart](https://docs.helm.sh/using_helm/#quickstart) that will help you get started.

#### Securing Helm

The Helm team have some helpful [guidelines for securing your Helm installation](https://docs.helm.sh/using_helm/#securing-your-helm-installation) as well as [an abbreviated list of best practices](https://docs.helm.sh/using_helm/#best-practices-for-securing-helm-and-tiller) for reference.

### Installing Deep Security Smart Check

The Helm chart for Deep Security Smart Check is hosted on Github; the latest version is `v0.0.2`.

To install Deep Security Smart Check into the default Kubernetes namespace:

```sh
helm upgrade --install \
  deepsecurity-smartcheck \
  https://github.com/deepsecurity/smartcheck/archive/v0.0.2.tgz
```

_Experienced `helm` users will note that we are using `deepsecurity-smartcheck` as the `helm` release name in these examples. There is no requirement to use this release name._

### Connecting to Deep Security Smart Check

The install process will display instructions for obtaining the initial username and password and for connecting to Deep Security Smart Check.

## Advanced topics

### Using an alternate Kubernetes namespace

To install Deep Security Smart Check into an existing Kubernetes namespace that's different from the current kube config namespace, use the `--namespace` parameter in the `helm upgrade` command:

```sh
helm upgrade --install \
  --namespace {namespace} \
  deepsecurity-smartcheck \
  https://github.com/deepsecurity/smartcheck/archive/v0.0.2.tgz
```

### Overriding configuration defaults

Helm uses a file called `values.yaml` to set configuration defaults.

You can override the defaults in this file by specifying a comma-separated list of key-value pairs on the command line:

```sh
helm upgrade --install \
  --set key1=value1,key2=value2,... \
  deepsecurity-smartcheck \
  https://github.com/deepsecurity/smartcheck/archive/v0.0.2.tgz
```

or by creating a <abbr title="YAML Ain't Markup Language">YAML</abbr> file with the specific values you want to override and providing the location of this file on the command line:

```sh
helm upgrade --install \
  --values overrides.yaml \
  deepsecurity-smartcheck \
  https://github.com/deepsecurity/smartcheck/archive/v0.0.2.tgz
```

_If you create a file to override the values, make sure to copy the structure from the chart's `values.yaml` file. You only need to provide the values that you are overriding._

#### Common configuration overrides

Refer to the `values.yaml` file in the chart for a full list of available values to override; some common keys are listed here:

<style type="text/css">
th { vertical-align: bottom; }
td { vertical-align: top; }
</style>

<table>
<thead>
<tr><th>Key</th><th>Default value</th><th>Description</th></tr>
</thead>
<tbody>
<tr><td><code>auth.userName</code></td><td><code>administrator</code></td><td>The name of the default administrator user that the system will create on startup.</td></tr>
<tr><td><code>auth.password</code></td><td><code>{a random 16-character alphanumeric string}</code></td><td>The default password assigned to the default administrator. <code>helm</code> will provide instructions for retrieving the initial password as part of the installation process.</td></tr>
<tr><td><code>certificate.commonName</code></td><td><code>example.com</code></td><td>The server name to use in the default self-signed certificate created for the service.</td></tr>
<tr><td><code>service.type</code></td><td><code>LoadBalancer</code></td><td>The Kubernetes service type to create. This must be one of <code>LoadBalancer</code>, <code>ClusterIP</code>, <code>NodePort</code>, or <code>ExternalName</code>.</td></tr>
<tr><td><code>persistence.enabled</code></td><td><code>true</code></td><td>Whether a persistent volume should be created for the Deep Security Smart Check databases. <strong>If no persistent volume claim is created, all database content will be lost when the database container restarts.</strong></td></tr>
<tr><td><code>networkPolicy.enabled</code></td><td><code>false</code></td><td><strong>EXPERIMENTAL:</strong> Whether Kubernetes <code>NetworkPolicy</code> resources should be created for the deployed pods.</td></tr>
</tbody>
</table>