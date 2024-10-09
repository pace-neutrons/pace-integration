#!/bin/bash

args=()
for var; do
  [[ $var != '-batch' ]] && args+=("$var")
done

tmpmfile=mlscript_$(mktemp -u XXXXXXXX)
echo "${args[@]}" > ${tmpmfile}.m
runner_path=/home/runner/work/_actions/matlab-actions/run-command/v2/dist/bin/glnxa64/

${runner_path}/run-matlab-command "setenv('MW_ORIG_WORKING_FOLDER', cd('`pwd`'));${tmpmfile}"