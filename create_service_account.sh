#!/bin/bash

CURRENT_PATH=$(cd $(dirname $0) && pwd)

K8S_USER=${1:-employee99}
K8S_CLUSTER=kubernetes
K8S_NAMESPACE=example
K8S_CONFIG=${K8S_USER}.conf
K8S_API_SERVER=https://192.168.216.194:6443

func_cmd()
{
  echo "cmd: $*"
  eval "$*"
  echo
}

func_error()
{
  echo "[Error] $*"
  exit 1
}

mkdir -p ${CURRENT_PATH}/${K8S_USER}
pushd ${CURRENT_PATH}/${K8S_USER}
# create user ca
kubectl -n ${K8S_NAMESPACE} create sa ${K8S_USER} --dry-run -o yaml | kubectl apply -f -
USER_SECRET=$(kubectl -n ${K8S_NAMESPACE} get sa ${K8S_USER} -o go-template='{{range .secrets}}{{.name}}{{end}}')
K8S_CA_CERT=$(kubectl -n ${K8S_NAMESPACE} get secret ${USER_SECRET} -o yaml | awk '/ca.crt:/{print $2}')

# create k8s config
cat <<EOF > ${K8S_CONFIG}
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: ${K8S_CA_CERT}
    server: ${K8S_API_SERVER}
  name: ${K8S_CLUSTER}
EOF

# create user in k8s
USER_TOKEN=$(kubectl -n ${K8S_NAMESPACE} get secret ${USER_SECRET} -o go-template='{{.data.token}}' | base64 -D)
func_cmd kubectl config set-credentials ${K8S_USER} \
--token=${USER_TOKEN} --kubeconfig=${K8S_CONFIG}

func_cmd kubectl config set-context ${K8S_USER}-context \
--cluster=${K8S_CLUSTER} --namespace=${K8S_NAMESPACE} \
--user=${K8S_USER} --kubeconfig=${K8S_CONFIG}

func_cmd kubectl config use-context ${K8S_USER}-context \
--kubeconfig=${K8S_CONFIG}
popd
