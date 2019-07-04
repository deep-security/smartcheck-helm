# Deep Security Smart Check

## Getting started

### Getting an activation code

We recommend that you register for a 30-day trial license [code](https://go2.trendmicro.com/geoip/trial-168). Deep Security Smart Check will operate without an activation code; however, malware pattern updates will not be available and you will see a warning message in the administration console.

### Installing Helm

Deep Security Smart Check uses the `helm` package manager for Kubernetes.

You will need `helm` version `v2.14.1` or later. There's a handy [quickstart](https://docs.helm.sh/using_helm/#quickstart) that will help you get started, or if you like living dangerously:

```sh
curl -L https://git.io/get_helm.sh | bash
```

Helm has a cluster-side component called `tiller` that needs to be installed as well.

Make sure that your `kubectl` context is set correctly to point to your cluster:

```sh
kubectl config current-context
```

_If your `kubectl` context is not pointing to your cluster, use `kubectl config get-contexts` and `kubectl config use-context` to set it, or if you are using Google Cloud Platform follow the instructions in the **Connect to the cluster** dialog available by clicking the **Connect** button beside your cluster information in the console._

Configure a service account for `tiller` and install:

```sh
kubectl create serviceaccount \
  --namespace kube-system \
  tiller

kubectl create clusterrolebinding tiller-cluster-role \
  --clusterrole=cluster-admin \
  --serviceaccount=kube-system:tiller

helm init --service-account tiller
```

Use `helm version` to confirm that you have at least version `v2.8.0` of the client and server installed.

_Note: the commands above will give `tiller` full cluster administrator privileges. Review [Securing your Helm Installation](https://docs.helm.sh/using_helm/#securing-your-helm-installation) for help on what to consider when setting up Helm in your cluster._

### Installing Deep Security Smart Check

The Helm chart for Deep Security Smart Check is hosted in a public repository on Github.

To install the latest version of Deep Security Smart Check into the default Kubernetes namespace:

```sh
helm install \
  --set auth.masterPassword={password} \
  --set activationCode={activation code} \
  --name deepsecurity-smartcheck \
  https://github.com/deep-security/smartcheck-helm/archive/master.tar.gz
```

_Experienced `helm` users will note that we are using `deepsecurity-smartcheck` as the `helm` release name in these examples. There is no requirement to use this release name._

**Note:** If you do not have an activation code then omit the `--set activationCode={activation code}` line.

**Note:** This installs Deep Security Smart Check with an in-cluster database, which requires a persistent volume. Your cluster must support creating persistent volumes to work with the in-cluster database. See [Use an external database](https://github.com/deep-security/smartcheck-helm/wiki/Use-an-external-database) to learn how to use an external database with Deep Security Smart Check.

### Connecting to Deep Security Smart Check

The install process will display instructions for obtaining the initial username and password and for connecting to Deep Security Smart Check.

### Upgrading Deep Security Smart Check

To upgrade an existing installation of Deep Security Smart Check in the default Kubernetes namespace to the latest version:

```sh
helm upgrade \
  --values overrides.yaml \
  deepsecurity-smartcheck \
  https://github.com/deep-security/smartcheck-helm/archive/master.tar.gz
```

This assumes that you have put any local overrides (for example the activation code and the master password) into a file called `overrides.yaml` in the current directory as described in [Overriding configuration defaults](#overriding-configuration-defaults).

### Uninstalling Deep Security Smart Check

You can delete all of the resources created for Deep Security Smart Check by running `helm delete`:

```sh
helm delete --purge deepsecurity-smartcheck
```

Use the `helm list` command to list installed releases.

**This is a destructive command and will delete all of the Deep Security Smart Check resources, including database contents, without further confirmation.**

## Documentation

Our [docs page](https://deep-security.github.io/smartcheck-docs/) provides links to the Deep Security Smart Check Deployment Guide and full API documentation.

## Advanced topics

### Installing a specific version of Deep Security Smart Check

If you want to install a specific version of Deep Security Smart Check, you can use the archive link for the tagged release rather than for `master`. For example, to install Deep Security Smart Check 1.2.12, you can run:

```sh
helm install \
  --set auth.masterPassword={password} \
  --set activationCode={activation code} \
  --name deepsecurity-smartcheck \
  https://github.com/deep-security/smartcheck-helm/archive/1.2.12.tar.gz
```

### Using an alternate Kubernetes namespace

To install Deep Security Smart Check into an existing Kubernetes namespace that's different from the current kube config namespace, use the `--namespace` parameter in the `helm install` command:

```sh
helm install \
  --namespace {namespace} \
  --set auth.masterPassword={password} \
  --name deepsecurity-smartcheck \
  https://github.com/deep-security/smartcheck-helm/archive/master.tar.gz
```

### Overriding configuration defaults

Helm uses a file called `values.yaml` to set configuration defaults.

You can override the defaults in this file by specifying a comma-separated list of key-value pairs on the command line:

```sh
helm install \
  --set key1=value1,key2=value2,... \
  --name deepsecurity-smartcheck \
  https://github.com/deep-security/smartcheck-helm/archive/master.tar.gz
```

or by creating a [YAML](http://yaml.org "YAML Ain't Markup Language") file with the specific values you want to override and providing the location of this file on the command line:

```sh
helm install \
  --values overrides.yaml \
  --name deepsecurity-smartcheck \
  https://github.com/deep-security/smartcheck-helm/archive/master.tar.gz
```

_If you create a file to override the values, make sure to copy the structure from the chart's `values.yaml` file. You only need to provide the values that you are overriding._

#### Common configuration overrides

Refer to the `values.yaml` file for a full list of available values to override; some common keys are listed here:

| Key                                          | Default value                                 | Description                                                                                                                                                                                                                                                                 |
| -------------------------------------------- | --------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `activationCode`                             | None                                          | The activation code to use. The activation code is required if you wish to receive updated malware patterns.                                                                                                                                                                |
| `auth.masterPassword`                        | None                                          | The master password to use when generating passwords within the system, ensuring that each installation of Deep Security Smart Check has different passwords.                                                                                                               |
| `auth.userName`                              | `administrator`                               | The name of the default administrator user that the system will create on startup.                                                                                                                                                                                          |
| `auth.password`                              | `{a random 16-character alphanumeric string}` | The default password assigned to the default administrator. `helm` will provide instructions for retrieving the initial password as part of the installation process.                                                                                                       |
| `certificate.commonName`                     | `example.com`                                 | The server name to use in the default self-signed certificate created for the service.                                                                                                                                                                                      |
| `service.type`                               | `LoadBalancer`                                | The Kubernetes service type to create. This must be one of `LoadBalancer`, `ClusterIP`, or `NodePort`.                                                                                                                                                                      |
| `persistence.enabled`                        | `true`                                        | Whether a persistent volume should be created for the Deep Security Smart Check databases. **If no persistent volume claim is created, all database content will be lost when the database container restarts.**                                                            |
| `persistence.storageClassName`               | None                                          | If set, will be used as the storage class for the persistent volume claim that is created for the Deep Security Smart Check databases.                                                                                                                                      |
| `networkPolicy.enabled`                      | `true`                                        | Whether Kubernetes `NetworkPolicy` resources should be created for the deployed pods.                                                                                                                                                                                       |
| `networkPolicy.additionalWebhookTargetPorts` | None                                          | If set, will be used as a list of destination port numbers that are allowed for web hook targets.                                                                                                                                                                           |
| `networkPolicy.additionalRegistryPorts`      | None                                          | If set, will be used as a list of destination port numbers that are allowed for connections to registries.                                                                                                                                                                  |
| `proxy.httpProxy`                            |                                               | If set, will be used as the proxy for HTTP traffic from Deep Security Smart Check. The value may be either a complete URL or a `host[:port]`, in which case the `http` scheme is assumed.                                                                                   |
| `proxy.httpsProxy`                           |                                               | If set, will be used as the proxy for HTTPS traffic from Deep Security Smart Check. If `httpsProxy` is not set, `httpProxy` is also checked and will be used if set. The value may be either a complete URL or a `host[:port]`, in which case the `http` scheme is assumed. |
| `proxy.noProxy`                              |                                               | If set, is a list of hosts or `host:port` combinations which should not be accessed through the proxy.                                                                                                                                                                      |
| `proxy.username`                             |                                               | If set, is the user name to use to authenticate requests sent through the proxy.                                                                                                                                                                                            |
| `proxy.password`                             |                                               | If set, is the password to use to authenticate requests sent through the proxy.                                                                                                                                                                                             |
| `scan.malwareCache.enabled`                  | `true`                                        | If set, cache mechanism will be used to improve scanning performance.                                                                                                                                                                                                       |

</tbody>
</table>

### Replacing the service certificate

See the wiki page [Replace the service certificate](https://github.com/deep-security/smartcheck-helm/wiki/Replace-the-service-certificate).

### Securing Helm

The Helm team have some helpful [guidelines for securing your Helm installation](https://docs.helm.sh/using_helm/#securing-your-helm-installation) as well as [an abbreviated list of best practices](https://docs.helm.sh/using_helm/#best-practices-for-securing-helm-and-tiller) for reference.

## Database backup and restore

Deep Security Smart Check stores its data in a `postgres` database.

### Backing up the application database

The following example command will perform a full database dump, compressing the output and writing it to the file `db.gz` in the current directory. You can then archive the `db.gz` file according to your needs.

```sh
kubectl exec $(kubectl get pods -l service=db -o jsonpath='{.items[0].metadata.name}') -- \
  sh -c 'pg_dumpall -U $POSTGRES_USER | gzip -' \
  > db.gz
```

_Note: If you are running Deep Security Smart Check in a namespace other than the `default` namespace and your `kubectl` context is not set to use that namespace, you will need to add the `--namespace NAMESPACE` parameter to both `kubectl` commands in this example._

_Important: While Deep Security Smart Check encrypts credentials stored in the database, the database backup file contains other information that you may consider sensitive, such as registry locations, names, and scan results. Ensure that you store your backups safely with appropriate access controls to prevent misuse or accidental disclosure._

### Restoring the application database from a backup

The following example command will perform a database restore from the compressed database dump created in the previous procedure.

```sh
kubectl exec -i \
  $(kubectl get pods -l service=db -o jsonpath='{.items[0].metadata.name}') -- \
  sh -c 'gunzip -f -c - | psql -U $POSTGRES_USER' \
  < db.gz
```

_Note: If you are running Deep Security Smart Check in a namespace other than the `default` namespace and your `kubectl` context is not set to use that namespace, you will need to add the `--namespace NAMESPACE` parameter to both `kubectl` commands in this example._

## Troubleshooting

### Failed to pull image ... certificate signed by unknown authority

If you are using `minikube` and an insecure registry, you will need to tell `minikube` that the registry is insecure. To do this, you will need to first delete and then restart your `minikube` VM:

```sh
minikube delete
minikube start --insecure-registry {registry address}
```

### Failed to pull image ... Please enable or contact project owners to enable the Google Container Registry API

#### Step 1: Check that you have the right repository names in your `overrides.yaml`

If you have copied the Deep Security Smart Check images from their default location to the Google Container Registry and pods are failing to start with an error message that looks like the following:

```text
Failed to pull image "us.gcr.io/deepsecurity/auth:latest": rpc error: code = 2 desc = Error response from daemon: {"message":"Get https://gcr.io/v2/deepsecurity/auth/manifests/latest: denied: Please enable or contact project owners to enable the Google Container Registry API in Cloud Console at https://console.cloud.google.com/apis/api/containerregistry.googleapis.com/overview?project=deepsecurity before performing this operation."}
```

with the `deepsecurity` project name, then check to make sure that you have the right project name override in your `overrides.yaml` file. For example, if your project is `amazing-minbari` and your registry endpoint is `gcr.io`, you should have the following in your `overrides.yaml`:

```yaml
images:
  defaults:
    registry: gcr.io
    project: amazing-minbari
```

#### Step 2: Ensure that the Google Container Registry API is enabled

If you have confirmed that the project name is set correctly and you are seeing it in the error message, follow the instructions and the link in the error to enable the Google Container Registry API, then delete and re-install the release:

```sh
helm delete --purge deepsecurity-smartcheck
helm install \
  --values overrides.yaml \
  --name deepsecurity-smartcheck \
  https://github.com/deep-security/smartcheck-helm/archive/master.tar.gz
```

### Failed to pull image ... pull access denied ... repository does not exist or may require 'docker login'

If the images are stored in a private registry, you will need to use `ImagePullSecrets` to allow your Kubernetes cluster to pull the images from the registry.

#### Creating a Secret with a Docker Config

Run the following command to create a Docker secret, replacing the upper-case values with your values:

```sh
kubectl create secret docker-registry myregistrykey \
  --docker-server=DOCKER_REGISTRY_SERVER \
  --docker-username=DOCKER_USER \
  --docker-password=DOCKER_PASSWORD \
  --docker-email=DOCKER_EMAIL
```

**IMPORTANT:** Make sure you enter your credentials correctly! If you get the values wrong, Docker Hub will lock out your account when it sees repeated failed attempts to download the images.

Then, provide the secret key (`myregistrykey` in the example) to the install process, either on the command line:

```sh
helm delete --purge deepsecurity-smartcheck
helm install \
  --set images.defaults.imagePullSecret=myregistrykey \
  --values overrides.yaml \
  --name deepsecurity-smartcheck \
  https://github.com/deep-security/smartcheck-helm/archive/master.tar.gz
```

or by editing your `overrides.yaml` file to set the `images.defaults.imagePullSecret` attribute and re-installing:

```sh
helm delete --purge deepsecurity-smartcheck
helm install \
  --values overrides.yaml \
  --name deepsecurity-smartcheck \
  https://github.com/deep-security/smartcheck-helm/archive/master.tar.gz
```

### What role does my Google Cloud Platform service account need in order for Deep Security Smart Check to work with Google Container Registry?

The service account must have at least the `StorageObjectViewer` role.

### Internal network failures

If you are see errors from the `auth` service like:

```text
request canceled while waiting for connection
```

the issue may be caused by a common [Kubernetes installation issue](https://github.com/kubernetes/kubernetes/issues/61593#issuecomment-376405711) where pods cannot talk to themselves using a Kubernetes service.

If you are using Google Kubernetes Engine, first ensure that network policy is enabled on your cluster.

If you are not using Google Kubernetes Engine, try the following command on _all_ worker nodes in your cluster. If you are using `minikube`, use `minikube ssh` to access the worker node.

Depending on your installation, the network interface in the next step may be `cni0` or `docker0`; if trying `cni0` results in an error message, try `docker0`.

```sh
sudo ip link set cni0 promisc on
```

### Pod has unbound PersistentVolumeClaims on Amazon EKS

If you are using `Amazon EKS` and see errors like:

```text
pod has unbound PersistentVolumeClaims
```

You likely have not defined a storage class. Since Amazon EKS does not create a default storage class you will have to create one [as described here](https://docs.aws.amazon.com/eks/latest/userguide/storage-classes.html) , then specify the storage class name when installing Deep Security Smart Check:

```sh
helm install \
  --set persistence.storageClassName={storage class name} \
  --values overrides.yaml \
  --name deepsecurity-smartcheck \
  https://github.com/deep-security/smartcheck-helm/archive/master.tar.gz
```
