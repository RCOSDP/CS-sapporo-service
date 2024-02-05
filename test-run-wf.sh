#!/usr/bin/env bash
set -euo pipefail

# set -x

# Define default values for SAPPORO_HOST and SAPPORO_PORT
SAPPORO_HOST=${SAPPORO_HOST:-127.0.0.1}
SAPPORO_PORT=${SAPPORO_PORT:-1122}

if [[ -z "${GRDM_TOKEN}" ]] || [[ -z "${PROJECT_ID}" ]]; then
    echo "Error: Both GRDM_TOKEN and PROJECT_ID must be set."
    echo "Usage: GRDM_TOKEN=... PROJECT_ID=... bash test-run-wf.sh"
    exit 1
fi

readonly workflow_url="./trimming_and_qc.cwl"
readonly workflow_params='{
  "fastq_1": {
    "class": "File",
    "path": "ERR034597_1.small.fq.gz"
  },
  "fastq_2": {
    "class": "File",
    "path": "ERR034597_2.small.fq.gz"
  }
}'
readonly workflow_attachment='[
  {
    "file_url": "ERR034597_1.small.fq.gz",
    "file_name": "ERR034597_1.small.fq.gz"
  },
  {
    "file_url": "ERR034597_2.small.fq.gz",
    "file_name": "ERR034597_2.small.fq.gz"
  },
  {
    "file_url": "trimming_and_qc.cwl",
    "file_name": "trimming_and_qc.cwl"
  },
  {
    "file_url": "fastqc.cwl",
    "file_name": "fastqc.cwl"
  },
  {
    "file_url": "trimmomatic_pe.cwl",
    "file_name": "trimmomatic_pe.cwl"
  }
]'
readonly tags=$(
    cat <<EOF
{
  "grdm_token": "${GRDM_TOKEN}",
  "project_id": "${PROJECT_ID}"
}
EOF
)

response=$(curl -fsSL -X POST \
    -H "Content-Type: multipart/form-data" \
    -F "workflow_params=${workflow_params}" \
    -F "workflow_type=CWL" \
    -F "workflow_type_version=v1.0" \
    -F "workflow_url=${workflow_url}" \
    -F "workflow_engine_name=cwltool" \
    -F "workflow_attachment=${workflow_attachment}" \
    -F "tags=${tags}" \
    http://${SAPPORO_HOST}:${SAPPORO_PORT}/runs)

if [[ $? -ne 0 ]]; then
    echo -e "Error: Failed to POST runs:\n${response}"
    exit 1
fi

run_id=$(echo "${response}" | jq -r '.run_id')

echo -e "POST /runs is succeeded:\n${response}\n"
echo -e "Please access to the following URL to get the run status:\n"
echo -e "curl -fsSL -X GET http://${SAPPORO_HOST}:${SAPPORO_PORT}/runs/${run_id}\n"
