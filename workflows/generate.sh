#! /bin/bash

# activate venv
source ./generator/.venv/bin/activate

for entry in `ls scripts`; do
    if [[ $entry == *.R ]]; then
        python ./generator/workflow_tools ./scripts/$entry --docker Dockerfile:uc6_arc > ${entry%.*}.cwl
    fi
done