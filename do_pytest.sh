#!/bin/bash

export JOB_NAME="TestPythonJenkinsJob"

pytest -x -s ./Job/test_python_jenkins_job.py
