########################################
# Data Gathering

while true; do
	read -rp "Desired Webshell Password: " PASSWORD
	read -rp "Password (again): " secondpassword
	if [ -n "${PASSWORD}" -a "${secondpassword}" = "${PASSWORD}" ]; then
		unset secondpassword
		break
	else
		echo "Passwords do not match."
	fi
done

K8SPASSWORD=$(echo -n "${PASSWORD}" | base64)
K8SUSER=$(echo -n "${USER}" | base64)

########################################
# Create a Cluster
echo
echo "Deploying cluster..."
echo

gcloud container clusters create target-cluster --zone "us-west1-a" --no-enable-basic-auth --release-channel "stable" --machine-type "n1-standard-2" --preemptible --disk-type "pd-standard" --disk-size "20" --metadata disable-legacy-endpoints=true --scopes "https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append" --enable-stackdriver-kubernetes --enable-ip-alias --default-max-pods-per-node "110" --addons HorizontalPodAutoscaling,HttpLoadBalancing --enable-autoupgrade --enable-autorepair --cluster-version=1.22 --image-type "COS" --tags=kube-target
# let us access its NodePorts
gcloud compute firewall-rules create allow-vanity-ports --allow tcp:31300-31399 --target-tags=kube-target

# Fetch the first cluster location
LOCATION="$(gcloud container clusters list --format='value(location)')"

# Fetch a valid kubeconfig
gcloud container clusters get-credentials --zone="${LOCATION}" target-cluster

########################################
# Apply the k8s config
kubectl apply -f services.yml
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: dashboard-secret
  namespace: dev
type: Opaque
data:
  username: $K8SUSER
  password: $K8SPASSWORD
---
apiVersion: v1
kind: Secret
metadata:
  name: dashboard-secret
  namespace: prd
type: Opaque
data:
  username: $K8SUSER
  password: $K8SPASSWORD
EOF
