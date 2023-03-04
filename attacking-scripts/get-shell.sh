#! /bin/sh
the_ip=`gcloud compute instances list --format json | jq '.[1]["networkInterfaces"][0]["accessConfigs"][0]["natIP"]' | sed 's/"//g'`

echo "${the_ip}" | grep '^[0-9][0-9.]*[0-9]$' >> /dev/null
if [ $? -ne 0 ]; then
	echo "Unable to determine cluster NodeIP. Please ask for help."
	exit 1
fi

cat <<EOF
Gr8 n3ws,

Your kubernetes shell can be accessed @ http://${the_ip}:31337/webshell. have fun!
EOF
