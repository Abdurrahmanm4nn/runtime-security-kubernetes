export FALCO_NAMESPACE=falco
FUNCTION_NAME=KillPwnedPod

kubectl create namespace $FALCO_NAMESPACE

helm upgrade --install falco falcosecurity/falco \
--namespace $FALCO_NAMESPACE \
--set ebpf.enabled=true \
--set falcosidekick.enabled=true \
--set falcosidekick.config.gcp.cloudfunctions.name=${CLOUD_FUNCTION_NAME} \
--set falcosidekick.webui.enabled=true