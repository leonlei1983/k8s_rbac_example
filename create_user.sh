#!/bin/bash

CURRENT_PATH=$(cd $(dirname $0) && pwd)

K8S_USER=${1:-employee01}
K8S_GROUP=${2:-devops}
K8S_USER_EXPIRATION=${3:-60}

# K8S_CA_CERT=/etc/kubernetes/pki/ca.crt
# K8S_CA_KEY=/etc/kubernetes/pki/ca.key
K8S_CA_CERT=${CURRENT_PATH}/k8s/ca.crt
K8S_CA_KEY=${CURRENT_PATH}/k8s/ca.key
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

[ -f "${K8S_CA_CERT}" ] || func_error cannot find k8s ca.crt
[ -f "${K8S_CA_KEY}" ] || func_error cannot find k8s ca.key

mkdir -p ${CURRENT_PATH}/${K8S_USER}
pushd ${CURRENT_PATH}/${K8S_USER}
# create user ca
if [ ! -f "${K8S_USER}.key" ]; then
  func_cmd openssl genrsa -out ${K8S_USER}.key 2048
  func_cmd openssl req -new -key ${K8S_USER}.key \
  -out ${K8S_USER}.csr -subj "/CN=${K8S_USER}/O=${K8S_GROUP}"
  func_cmd openssl x509 -req -in ${K8S_USER}.csr \
  -CA ${K8S_CA_CERT} -CAkey ${K8S_CA_KEY} -CAcreateserial -out ${K8S_USER}.crt -days ${K8S_USER_EXPIRATION}
fi

# create k8s config
cat <<EOF > ${K8S_CONFIG}
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: $(cat ${K8S_CA_CERT} | base64)
    server: ${K8S_API_SERVER}
  name: ${K8S_CLUSTER}
EOF

# update k8s config in local
func_cmd kubectl config set-credentials ${K8S_USER} \
--client-certificate=${K8S_USER}.crt \
--client-key=${K8S_USER}.key \
--kubeconfig=${K8S_CONFIG}

func_cmd kubectl config set-context ${K8S_USER}-context \
--cluster=${K8S_CLUSTER} --namespace=${K8S_NAMESPACE} \
--user=${K8S_USER} --kubeconfig=${K8S_CONFIG}

func_cmd kubectl config use-context ${K8S_USER}-context \
--kubeconfig=${K8S_CONFIG}
popd
