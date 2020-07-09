# Deep Security Smart Check

## Getting started

### Getting an activation code

We recommend that you register for a 30-day trial license [code](https://go2.trendmicro.com/geoip/trial-168). Deep Security Smart Check will operate without an activation code; however, malware pattern updates will not be available and you will see a warning message in the administration console.

[Contact us](https://resources.trendmicro.com/Hybrid-Cloud-Security-Contact-Us.html) for full product licensing and pricing details.

### Installing Helm

Deep Security Smart Check uses the `helm` package manager for Kubernetes.

#### Helm 3

We recommend using Helm 3 (version 3.0.1 or later) to install Deep Security Smart Check if this is possible for you.

There is a handy [guide](https://helm.sh/docs/intro/install/) that will help you get started. In most cases installing Helm 3 involves running a single command.

If you have already installed Deep Security Smart Check using Helm 2, you will need to migrate your install. The Helm folks have a helpful [blog post](https://helm.sh/blog/migrate-from-helm-v2-to-helm-v3/) that details this process.

#### Helm 2

<details>
<summary>If you have to use Helm 2, you will need <code>helm</code> version <code>v2.14.1</code> or later. Expand this section for details.</summary>

There's a handy [quickstart](https://docs.helm.sh/using_helm/#quickstart) that will help you get started, or if you like living dangerously:

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

Use `helm version` to confirm that you have at least version `v2.14.1` of the client and server installed.

_Note: the commands above will give `tiller` full cluster administrator privileges. Review [Securing your Helm Installation](https://docs.helm.sh/using_helm/#securing-your-helm-installation) for help on what to consider when setting up Helm in your cluster._

</details>

### Installing Deep Security Smart Check

The Helm chart for Deep Security Smart Check is hosted in a public repository on Github.

To install the latest version of Deep Security Smart Check into the default Kubernetes namespace:

1. Create a file called `overrides.yaml` that will contain your site-specific settings.

   ```yaml
   ## activationCode is the product activation code.
   ##
   ## Default value: (none)
   activationCode: YOUR-CODE-HERE

   auth:
     ## secretSeed is used as part of the password generation process for
     ## all auto-generated internal passwords, ensuring that each installation of
     ## Deep Security Smart Check has different passwords.
     ##
     ## Default value: {must be provided by the installer}
     secretSeed: YOUR-SECRET-HERE
   ```

2. Use `helm` to install Deep Security Smart Check with your site-specific settings:

   ```sh
   helm install \
     --values overrides.yaml \
     deepsecurity-smartcheck \
     https://github.com/deep-security/smartcheck-helm/archive/master.tar.gz
   ```

_Experienced `helm` users will note that we are using `deepsecurity-smartcheck` as the `helm` release name in these examples. There is no requirement to use this release name._

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

### Uninstalling Deep Security Smart Check

You can delete all of the resources created for Deep Security Smart Check by running `helm delete`:

```sh
helm delete deepsecurity-smartcheck
```

Use the `helm list` command to list installed releases.

**`helm delete` is a destructive command and will delete all of the Deep Security Smart Check resources. If you are not using an external database, you will also lose all database contents without further confirmation.**

## Documentation

- [Deep Security Smart Check Deployment Guide](https://deep-security.github.io/smartcheck-docs/admin_docs/admin.html)
- [Useful procedures](https://github.com/deep-security/smartcheck-helm/wiki)
- [API reference](https://deep-security.github.io/smartcheck-docs/api/index.html)

## Advanced topics

### Installing a specific version of Deep Security Smart Check

If you want to install a specific version of Deep Security Smart Check, you can use the archive link for the tagged release. For example, to install Deep Security Smart Check 1.2.46, you can run:

```sh
helm install \
  --values overrides.yaml \
  deepsecurity-smartcheck \
  https://github.com/deep-security/smartcheck-helm/archive/1.2.46.tar.gz
```

### Using an alternate Kubernetes namespace

To install Deep Security Smart Check into an existing Kubernetes namespace that's different from the current namespace, use the `--namespace` parameter in the `helm install` command:

```sh
helm install \
  --namespace {namespace} \
  --values overrides.yaml \
  deepsecurity-smartcheck \
  https://github.com/deep-security/smartcheck-helm/archive/master.tar.gz
```

### Overriding configuration defaults

Helm uses a file called `values.yaml` to set configuration defaults. You can find detailed documentation for each of the configuration options in this file.

As described above, you can override the defaults in this file by creating an `overrides.yaml` file and providing the location of this file on the command line:

```sh
helm install \
  --values overrides.yaml \
  deepsecurity-smartcheck \
  https://github.com/deep-security/smartcheck-helm/archive/master.tar.gz
```

_If you create a file to override the values, make sure to copy the structure from the chart's `values.yaml` file. You only need to provide the values that you are overriding._

## Troubleshooting

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
  deepsecurity-smartcheck \
  https://github.com/deep-security/smartcheck-helm/archive/master.tar.gz
```

### Timeouts attempting to connect to registry

If you are attempting to add a registry that's running on a port other than the standard HTTPS port `443`, you will likely run into timeouts.

The `networkPolicy.additionalRegistryPorts` configuration item in the Helm chart allows you to open outbound network access from Deep Security Smart Check to the registry.

For example, if your registry is running on port 8443, you would update your `overrides.yaml` file to include the following and do a `helm upgrade` to apply the changed configuration:

```yaml
networkPolicy:
  additionalRegistryPorts:
    - 8443
```

If you continue to encounter timeouts, the network connectivity issue may be caused by a firewall or some other network issue.

### Built-in database pod failing to start on Bottlerocket

If you are installing Deep Security Smart Check with the built-in database on an Amazon Elastic Kubernetes Service (Amazon EKS) cluster running Bottlerocket, you may see errors with the `db` pod if the EKS EBS CSI driver is not installed:

```text
Warning  FailedMount             6m51s (x12 over 31m)  kubelet, ip-192-168-82-134.us-west-2.compute.internal  Unable to mount volumes for pod "db-74995d7886-rfl4g_default(6c9a66fd-5d7b-11ea-9306-0e4eadbaa154)": timeout expired waiting for volumes to attach or mount for pod "default"/"db-74995d7886-rfl4g". list of unmounted volumes=[data]. list of unattached volumes=[varrun tmp data]

Warning  FailedMount             2m38s (x23 over 33m)  kubelet, ip-192-168-82-134.us-west-2.compute.internal  MountVolume.MountDevice failed for volume "pvc-6c53aaaa-5d7b-11ea-ae3f-02de703f8790" : executable file not found in $PATH
```

For production, you should [use an external database](https://github.com/deep-security/smartcheck-helm/wiki/Use-an-external-database) instead of the internal database.

If you are doing a trial install and want to use the built-in database, you can install the required driver. See [EKS EBS CSI Driver](https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html) for more information and installation instructions.
