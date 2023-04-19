// package kill_ilegal_pod
package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"time"

	secretmanager "cloud.google.com/go/secretmanager/apiv1"
	secretmanagerpb "cloud.google.com/go/secretmanager/apiv1/secretmanagerpb"
	metaV1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
)

// Alert falco data structure
type Alert struct {
	Output       string    `json:"output"`
	Priority     string    `json:"priority"`
	Rule         string    `json:"rule"`
	Time         time.Time `json:"time"`
	OutputFields struct {
		ContainerID              string      `json:"container.id"`
		ContainerImageRepository interface{} `json:"container.image.repository"`
		ContainerImageTag        interface{} `json:"container.image.tag"`
		EvtTime                  int64       `json:"evt.time"`
		FdName                   string      `json:"fd.name"`
		K8SNsName                string      `json:"k8s.ns.name"`
		K8SPodName               string      `json:"k8s.pod.name"`
		ProcCmdline              string      `json:"proc.cmdline"`
	} `json:"output_fields"`
}

var op Operation

type Operation struct {
	clientSet *kubernetes.Clientset
}

// init initializes new Kubernetes ClientSet with given config
func init() {
	// The resource name of the SECRET_ENV_VAR in the format
	// `projects/*/secrets/*/versions/*`
	os.Setenv("SECRET_ENV_VAR", "projects/river-enquiry-374506/secrets/pod-destroyer-secret/versions/latest")
	resource := os.Getenv("SECRET_ENV_VAR")
	if len(resource) == 0 {
		panic(fmt.Errorf("$SECRET_ENV_VAR env variable did not set"))
	}

	secret, err := GetSecret(resource)
	if err != nil {
		panic(fmt.Errorf("get secret: %q", err))
	}

	kubeCfg, err := clientcmd.NewClientConfigFromBytes(secret)
	if err != nil {
		panic(fmt.Errorf("new client config: %q", err))
	}

	restCfg, err := kubeCfg.ClientConfig()
	if err != nil {
		panic(fmt.Errorf("client config: %q", err))
	}

	cs, err := kubernetes.NewForConfig(restCfg)
	if err != nil {
		panic(fmt.Errorf("unable to initialize config: %q", err))
	}

	op = Operation{clientSet: cs}
}

// KillIlegalPod will be executed for each Falco event
func KillIlegalPod(w http.ResponseWriter, r *http.Request) {
	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, "cannot read body", http.StatusBadRequest)
		return
	}

	var event Alert

	err = json.Unmarshal(body, &event)
	if err != nil {
		http.Error(w, "cannot parse body", http.StatusBadRequest)
		return
	}

	fmt.Println("Pod name in request : %q", event.OutputFields.K8SPodName)
	if (event.OutputFields.K8SPodName != "" && event.OutputFields.K8SNsName != "") {
		err = op.PodDestroy(event.OutputFields.K8SPodName, event.OutputFields.K8SNsName)

		if err != nil {
			http.Error(w, fmt.Sprintf("cannot delete pod: %q", err), http.StatusInternalServerError)
			return
		}

		w.WriteHeader(http.StatusOK)
		io.WriteString(w, fmt.Sprintf("Pod %q at namespace %v has been deleted", event.OutputFields.K8SPodName, event.OutputFields.K8SNsName))
		return
	} else {
		w.WriteHeader(http.StatusBadRequest)
		fmt.Fprint(w, "Pod name or namespace is empty! Nothing will be removed!")
		return
	}
}

// PodDestroy destroys the given pod name in the given namespace
func (d *Operation) PodDestroy(name, namespace string) error {
	err := d.clientSet.CoreV1().Pods(namespace).Delete(context.TODO(), name, metaV1.DeleteOptions{})
	if err != nil {
		return fmt.Errorf("unable to delete pod %s: %q", name, err)
	}
	return nil
}

// GetSecret returns the secret data.
func GetSecret(name string) ([]byte, error) {
	ctx := context.Background()

	client, err := secretmanager.NewClient(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to create secretmanager client: %v", err)
	}
	defer client.Close()

	result, err := client.AccessSecretVersion(ctx, &secretmanagerpb.AccessSecretVersionRequest{
		Name: name,
	})

	if err != nil {
		return nil, fmt.Errorf("failed to access secret version: %q, %v", name, err)
	}

	return result.Payload.Data, nil
}
