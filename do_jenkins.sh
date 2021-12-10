#!/bin/bash

HTTP_PORT_NUMBER=8080

vm_activity_timeout()
{
	INCREMENT=30

	echo "VM activity timout set to $INCREMENT minutes"

	while [ "$INCREMENT" > "0" ]; then
		RET=$(virsh list | grep running)
		if [ -z "RET"]
			INCREMENT=$(($INCREMENT-1))
			echo "WST will be turned off after $INCREMENT minutes"
		fi

		sleep(60)
	done

	poweroff
}

vm_activity_timeout &

java -jar jenkins.war --httpPort=${HTTP_PORT_NUMBER}

