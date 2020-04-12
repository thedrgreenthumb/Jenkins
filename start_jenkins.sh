#!/bin/bash

HTTP_PORT_NUMBER=8080

java -jar jenkins.war --httpPort=${HTTP_PORT_NUMBER}

