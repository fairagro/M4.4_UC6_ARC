#! /bin/bash

if [ ! -d "../generator/.venv/" ]; then
python3.11 -m venv ../generator/.venv
fi
# activate venv
source ../generator/.venv/bin/activate
pip install -r ../generator/requirements.txt

for entry in `find -iname '*.R'`; do
    filename=$(basename ${entry%.*})
    mkdir ./$filename
    mv $entry ./$filename/$filename.R
    
    path=./$filename/$filename
    python ../generator/workflow_tools $path.R --docker Dockerfile:uc6_arc > $path.cwl
done