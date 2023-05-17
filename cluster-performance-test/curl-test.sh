#!/bin/bash
cluster_ip=`gcloud compute instances list --format json | jq '.[1]["networkInterfaces"][0]["accessConfigs"][0]["natIP"]' | sed 's/"//g'` 
echo "${cluster_ip}" | grep '^[0-9][0-9.]*[0-9]$' >> /dev/null 
if [ $? -ne 0 ]; then 
    echo "Unable to determine cluster NodeIP. Please ask for help." 
    exit 1 
fi 
echo "Cluster IP: ${cluster_ip}" 

# Scan the specified range of ports using nmap 
nmap_output=$(nmap -p 31300-31399 -sT -Pn $cluster_ip) 
# Initialize the array variable 
services_ports=()
services_url=() 
# Parse the nmap output to extract the open ports for services url 
while read -r line; do 
    if [[ $line =~ ^[0-9]+\/tcp.*open ]]; then 
       port=$(echo $line | cut -d '/' -f 1)
       services_ports+=($port)
       url="http://${cluster_ip}:${port}" 
       services_url+=($url) 
    fi 
done <<< "$nmap_output"

echo "Services ports: ${services_ports[@]}"

# start accessing each public-facing services on the cluster
i=0
while [ $i -lt ${#services_url[@]} ]; do
    echo "curl to ${services_url[i]}"
    start=$(date +%s.%N)
    curl -s -o /dev/null ${services_url[i]}
    end=$(date +%s.%N)    
    duration=$(echo "$end - $start" | bc)
    echo "The request took $duration seconds"
    ((i++))
done