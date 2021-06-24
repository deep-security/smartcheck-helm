#!/bin/bash
#
# A helper script to fetch Kubernetes settings and Deep Security Smart Check logs.
# Optionally, you can also collect malware-scan core dump files (if available) using this script.
#

unset CURRENT_NS
unset NAMESPACE

KUBECTL=kubectl
HELM=helm
RELEASE="deepsecurity-smartcheck"
NAMESPACE=""

# By default, no core dump files are collected.
# If collecting core dump is true, 2 core files are collected.
COLLECTDUMP=false
DUMPFILES=2
COREPATTERN="core"

NOW=$(date +%s)
RESULTDIR="/tmp/smartcheck-${NOW}"

help()
{
cat << EOF
Helper script to fetch Kubernetes setting and Deep Security Smart Check logs. 
Optionally, you can also collect malware-scan core dump files (if available) using this script.
Options:
-release          [Optional] Specifies the Deep Security Smart Check release name. The default is deepsecurity-smartcheck
-namespace        [Optional] Specifies the the namespace of Deep Security Smart Check deployment.
                             The default is the current namespace or default.
-collectdump      [Optional] Flag to enable collecting malware-scan core dump files.
                             The default number of core dump files is 2. You can change it by exporting environment variable - DUMPFILES.
                             Collecting core dump files takes longer time.
-corefilepattern  [Optional] S[ecifies the core dump file name prefix pattern. The default value is 'core'.
-resultdir        [Optional] Specifies the directory to save the logs.

Usage examples:
# Display this help
./collect-logs.sh -h | H

# Collect logs for the default release and namespace
./collect-logs.sh

# Collect logs for the named release and namespace
./collect-logs.sh -release deepsecurity-smartcheck -namespace trendmicro

# Collect logs with optional core dump files if available
./collect-logs.sh -collectdump

# Collect logs with core dump files if available, with optional core dump file pattern as 'core'.
./collect-logs.sh -collectdump -corefilepattern core

# Collect logs and core dump from named release and namespace
./collect-logs.sh -release deepsecurity-smartcheck -namespace trendmicro -resultdir /tmp/smartcheck-log -collectdump -corefilepattern core

# Change the number of core dump files to be collected
export MAX_DUMP_FILES 3
EOF
}

#####
# check prerequisites
#####
command_exists () {
  command -v "$1" >/dev/null 2>&1
}

if ! command_exists $KUBECTL; then
  echo "No kubectl command found, exiting..."
  echo "Use option -h for help."
  exit 1
fi

if ! command_exists $HELM; then
  echo "No helm command found, exiting..."
  echo "Use option -h for help."
  exit 1
fi

while [[ $# -gt 0 ]]
do
  key="$1"
  case $key in
    -h|-H)
      help
      exit 0
      ;;
    -release)
     RELEASE=$2
     shift
     shift
     ;;
    -namespace)
     NAMESPACE=$2
     shift
     shift
     ;;
    -resultdir)
     RESULTDIR=$2
     shift
     shift
     ;;
    -collectdump)
      COLLECTDUMP=true
      shift
      ;;
    -corefilepattern)
      COREPATTERN="$2"
      shift
      shift
      ;;
    *)
     echo "Unrecognized options are specified: $1"
     echo "Use option -h for help."
     exit 1
    ;;
  esac
done

CURRENT_NS=$($KUBECTL config view --minify --output 'jsonpath={..namespace}')
CURRENT_NS=${CURRENT_NS:-default}
NAMESPACE=${NAMESPACE:-$CURRENT_NS}
NAMESPACE_PARAM="--namespace=$NAMESPACE"

echo "Collect logs for application release $RELEASE from namespace $NAMESPACE"
if [ $COLLECTDUMP == true ]; then
  # check if environment variable - MAX_DUMP_FILES is specified
  if [ ! -z "$MAX_DUMP_FILES" ]; then
    # check if MAX_DUMP_FILES specifies a valid number
    if [ "$MAX_DUMP_FILES" -eq "$MAX_DUMP_FILES" ] 2>/dev/null; then
      if [ $MAX_DUMP_FILES -gt 0 ]; then
        DUMPFILES=$MAX_DUMP_FILES
      else
        echo "Invalid core dump file number is specified. It must be greater than 0. Default value $DUMPFILES is used."
      fi
    else
      echo "Invalid core dump file number is specified. It must be a number. Default value $DUMPFILES is used."
    fi 
  fi   

  echo "Collect $DUMPFILES core dump files if available"
fi

PODS=$($KUBECTL get pods "$NAMESPACE_PARAM" -o=jsonpath='{range .items[*]}{.metadata.name}{";"}{end}' -l release=$RELEASE)
if [ -z "${PODS}" ]; then
  echo "No Smart Check pods are found in release '$RELEASE' in namespace '$NAMESPACE'.  Do you specify correct Smart Check release and namespace? Use option -h for help."
  exit 1
fi

# Get Helm version since 'helm list' on Helm 3 does not display all namespaces unless specified. However, this flag does not exist in Helm 2
case X`helm version --template="{{.Version}}"` in
  Xv3.*)
    HELM_COMMAND="$HELM list --all-namespaces";;
  *)
    HELM_COMMAND="$HELM list";;
esac

# prepare the output folder
MASTER_DIR="${RESULTDIR}/master"
mkdir -p "$MASTER_DIR/apps"
echo "Results folder is: $RESULTDIR"

#####
# setting logs
#####
COMMANDS=( "version:$KUBECTL version"
           "components:$KUBECTL get componentstatuses"
           "events:$KUBECTL get events --all-namespaces"
           "storageclass:$KUBECTL describe storageclass"
           "helm:$HELM_COMMAND"
           "helm-status:$HELM status $RELEASE"
           "nodes:$KUBECTL describe nodes"
           "podlist:$KUBECTL get pods --all-namespaces"
           "smartcheck-get:$KUBECTL get all --all-namespaces -l release=$RELEASE"
           "smartcheck-desc:$KUBECTL describe all --all-namespaces -l release=$RELEASE"
           "smartcheck-desc-netpol:$KUBECTL describe networkpolicy --all-namespaces -l release=$RELEASE"
           "smartcheck-secrets:$KUBECTL get secrets --all-namespaces -l release=$RELEASE"
           "smartcheck-config:$KUBECTL describe configmap --all-namespaces -l release=$RELEASE")

echo "Fetching setting logs..."
for command in "${COMMANDS[@]}"; do
    KEY="${command%%:*}"
    VALUE="${command##*:}"
    echo "Command:" "$VALUE" > "$MASTER_DIR/$KEY.log"
    echo "====================================" >> "$MASTER_DIR/$KEY.log"
    $VALUE >> "$MASTER_DIR/$KEY.log" 2>&1
done

#####
# application logs
#####
for pod in $(echo "$PODS" | tr ";" "\n"); do
    CONTAINERS=$($KUBECTL get pods "$NAMESPACE_PARAM" "$pod" -o jsonpath='{.spec.initContainers[*].name}')
    for container in $CONTAINERS; do
        echo "Fetching Deep Security Smart Check logs... $pod - $container"
        $KUBECTL logs "$NAMESPACE_PARAM" "$pod" -c "$container" > "$MASTER_DIR/apps/$pod-$container.log"
        # check for any previous containers, this would indicate a crash
        PREV_LOGFILE="$MASTER_DIR/apps/$pod-$container-previous.log"
        if ! $KUBECTL logs "$NAMESPACE_PARAM" "$pod" -c "$container" -p > "$PREV_LOGFILE" 2>/dev/null; then
            rm -f "$PREV_LOGFILE"
        fi
    done

    # list containers in pod
    CONTAINERS=$($KUBECTL get pods "$NAMESPACE_PARAM" "$pod" -o jsonpath='{.spec.containers[*].name}')
    for container in $CONTAINERS; do
        echo "Fetching Deep Security Smart Check logs... $pod - $container"
        $KUBECTL logs "$NAMESPACE_PARAM" "$pod" -c "$container" > "$MASTER_DIR/apps/$pod-$container.log"
        # check for any previous containers, this would indicate a crash
        PREV_LOGFILE="$MASTER_DIR/apps/$pod-$container-previous.log"
        if ! $KUBECTL logs "$NAMESPACE_PARAM" "$pod" -c "$container" -p > "$PREV_LOGFILE" 2>/dev/null; then
            rm -f "$PREV_LOGFILE"
        fi
    done
done

####
# collect core dump files from malware-scan pods
####
if [ $COLLECTDUMP == true ]; then
  fetchcount=0
  for malware_scan_pod in $(echo "$PODS" | tr ";" "\n" | grep malware-scan); do
    COREFILES=$($KUBECTL exec "$malware_scan_pod" -- ls /tmp | grep "$COREPATTERN")
    if [ -z "$COREFILES" ]; then
      continue
    fi

    if [ ${#COREFILES[@]} -gt 0 ]; then
      mkdir -p "$MASTER_DIR/apps/$malware_scan_pod"
      for corefile in $COREFILES; do
        if [ $fetchcount -ge $DUMPFILES ]; then
          echo "Done fetching $fetchcount dump files"
          break 2
        fi
        echo "Fetching core dump file $corefile from $malware_scan_pod ..."
        $KUBECTL cp $malware_scan_pod:/tmp/$corefile "$MASTER_DIR/apps/$malware_scan_pod/$corefile"  > /dev/null
        ((fetchcount++))
      done
    fi
  done
fi

echo "Find collected logs at: $RESULTDIR"