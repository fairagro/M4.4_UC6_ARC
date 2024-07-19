#! /bin/bash

if [ ! -d "./generator/.venv/" ]; then
python3.12 -m venv ./generator/.venv
fi
# activate venv
source ./generator/.venv/bin/activate
pip install -r ./generator/requirements.txt


for entry in `ls scripts`; do
    if [[ $entry == *.R ]]; then
        python ./generator/workflow_tools ./scripts/$entry --docker Dockerfile:uc6_arc > ${entry%.*}.cwl
    fi
done