#!/bin/bash 
the_ip=`gcloud compute instances list --format json | jq '.[1]["networkInterfaces"][0]["accessConfigs"][0]["natIP"]' | sed 's/"//g'` 
echo "${the_ip}" | grep '^[0-9][0-9.]*[0-9]$' >> /dev/null 
if [ $? -ne 0 ]; then 
    echo "Unable to determine cluster NodeIP. Please ask for help." 
    exit 1 
fi 
echo "Cluster IP: ${the_ip}" 

# Scan the specified range of ports using nmap 
nmap_output=$(nmap -p 31300-31399 -sT -Pn $the_ip) 
# Initialize the array variable 
open_ports=() 
# Parse the nmap output to extract the open ports 
while read -r line; do 
     if [[ $line =~ ^[0-9]+\/tcp.*open ]]; then 
        port=$(echo $line | cut -d '/' -f 1) 
        open_ports+=($port) 
     fi 
done <<< "$nmap_output" 

# Display the results 
echo "Open ports: ${open_ports[@]}" 
echo -e "\nSummary : \n" 
cat <<EOF
Gr8 n3ws, Your kubernetes shell can be accessed @ http://${the_ip}:${open_ports[0]}/webshell or http://${the_ip}:${open_ports[1]}/webshell. have fun! 
EOF