#!/usr/bin/env bash

CLUSTER_NAMEPRFX=${CLUSTER_NAMEPRFX:-demo}
NUM_CLUSTERS=${NUM_CLUSTERS:-1}
GLOBAL_METALLB_PRFX=${GLOBAL_METALLB_PRFX:-250}

KIND_IMAGE=${KIND_IMAGE:-kindest/node:v1.24.7}


# we use a static additional loopback address. this ensires that we can use the same IP imdependednt of the instance
# and will allow to have the cluster pre-provisioned on any instance. Pleas uncomment the previous lines if this is not desired
K8S_API_ADDR="172.123.123.1"
K8S_API_PORT=6443


# create cluster
function create_cluster {
    local name=$1; shift
    if [[ $# > 1 ]]; then
        local apiaddr=$1; shift
        local portoffset=$1; shift
    fi

    apiport=$((${K8S_API_PORT} + ${portoffset}))

    cat <<EOF > kind_config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  apiServerAddress: "${apiaddr}"
  apiServerPort: ${apiport}
nodes:
- role: control-plane
  image: ${KIND_IMAGE}
- role: worker
  image: ${KIND_IMAGE}
- role: worker
  image: ${KIND_IMAGE}

EOF
    kind create cluster --name ${name} --config kind_config.yaml
    kind get kubeconfig --name ${name} > ~/.kube/${name}.kconf
}


for (( cur_cluster=0; cur_cluster < $NUM_CLUSTERS; cur_cluster++))
do
    cluster_name=${CLUSTER_NAMEPRFX}$((${cur_cluster} + 1))
    create_cluster $cluster_name ${K8S_API_ADDR} ${cur_cluster}
done


echo 'Waiting for matallb to be deployed...'


# Find the node's first 2 octets for use to create metallb IP ranges (assumes k3d docker networks are using /16 cidr):
kconf=~/.kube/${CLUSTER_NAMEPRFX}1.kconf
nodeAddrPrfx=$(kubectl get nodes --kubeconfig ${kconf} -o jsonpath="{.items[0].status.addresses[?(@.type=='InternalIP')].address}" | cut -d '.' -f 1,2)

echo 'Deploying metallb'
# Install metallb in all the clusters (use the later 3 octets of the docker bridge prefix)

for (( cur_cluster=0; cur_cluster < $NUM_CLUSTERS; cur_cluster++))
do
    cluster_name=${CLUSTER_NAMEPRFX}$((${cur_cluster} + 1))

    kconf=~/.kube/${cluster_name}.kconf
    kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.9/config/manifests/metallb-native.yaml --kubeconfig ${kconf}

    echo 'Waiting for metallb to be ready...'
    sleep 5 && kubectl wait pods --all=True -n metallb-system --for=condition=Ready --timeout=120s


    cat <<EOF | kubectl apply --kubeconfig ${kconf} -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: metallb-ippool
  namespace: metallb-system
spec:
  addresses:
  - ${nodeAddrPrfx}.${GLOBAL_METALLB_PRFX}.1-${nodeAddrPrfx}.${GLOBAL_METALLB_PRFX}.250
  autoAssign: true
  avoidBuggyIPs: false
EOF

    cat <<EOF | kubectl apply --kubeconfig ${kconf} -f -
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: metallb-l2-mode
  namespace: metallb-system
EOF

    GLOBAL_METALLB_PRFX=$((${GLOBAL_METALLB_PRFX} + 1))

done
