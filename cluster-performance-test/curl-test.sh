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

# Assign file as output to save test results
output=$1
echo "Iteration No.,Time Taken per-URL,,," > $output
echo ",${services_url[0]},${services_url[1]},${services_url[2]},${services_url[3]}" >> $output

# start accessing each public-facing services on the cluster
for i in {1..50}; do
    echo "Iteration no. $i"
    results=()
    j=0
    while [ $j -lt ${#services_url[@]} ]; do
        echo "curl to ${services_url[j]}"
        start=$(date +%s.%N)
        curl -s -o /dev/null --no-keepalive --max-time 5 ${services_url[j]}
        end=$(date +%s.%N)    
        duration=$(echo "$end - $start" | bc)
        echo "The request took $duration seconds"
        results+=($duration)
        ((j++))
        sleep 5
    done
    echo "$i,${results[0]},${results[1]},${results[2]},${results[3]}" >> $output
    sleep 10
done