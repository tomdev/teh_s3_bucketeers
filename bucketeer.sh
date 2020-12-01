#!/bin/bash

echo ""
echo "  _       _            _____   _                _        _                 "
echo " | |     | |          |____ | | |              | |      | |                "
echo " | |_ ___| |__    ___     / / | |__  _   _  ___| | _____| |_ ___  ___ _ __ "
echo " | __/ _ \ '_ \  / __|    \ \ | '_ \| | | |/ __| |/ / _ \ __/ _ \/ _ \ '__|"
echo " | ||  __/ | | | \__ \.___/ / | |_) | |_| | (__|   <  __/ ||  __/  __/ |   "
echo "  \__\___|_| |_| |___/\____/  |_.__/ \__,_|\___|_|\_\___|\__\___|\___|_|   "
echo ""

if [[ -z $@ ]]; then
  echo "Error: no targets specified."
  echo ""
  echo "Usage: ./bucketeer.sh <target> <target>"
  exit 1
fi

AWS_CREDENTIALS_SETUP_DOCUMENTATION_URL="https://docs.aws.amazon.com/sdk-for-java/v1/developer-guide/setup-credentials.html#setup-credentials-setting"
AWS_CREDENTIALS_FILE=~/.aws/credentials
THREADS=20
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
NORMAL=$(tput sgr0)

ensure_aws_credentials() {
  if [[ ! -e ${AWS_CREDENTIALS_FILE} ]]; then
    echo "Warning: Required AWS credential file ${AWS_CREDENTIALS_FILE} not found."
    echo ""
    echo "Documentation on how to set up these credentials can be found here:"
    echo ${AWS_CREDENTIALS_SETUP_DOCUMENTATION_URL}
    exit 1
  fi
}

ensure_dependency_installed() {
  dependency=${1}

  command -v ${dependency} >/dev/null

  if [[ "$?" -ne 0 ]]; then
    echo "Required dependency \"${dependency}\" not installed. Please install and retry."
    exit 1
  fi
}

test_bucket() {
  bucket_name="${1}"

  #echo "testing $bucket_name"

  result=$(curl -m 5 -s -X 'GET' -o/dev/null -w '%{http_code}' -I http://${bucket_name}.s3.amazonaws.com/?max-keys=1)

  if [[ ${result} == "403" || ${result} == "404" ]]; then
    aws s3 ls s3://${bucket_name} &> aws.txt;
    if [[ $? == 0 ]]; then
        echo "[${GREEN}FOUND${NORMAL}] https://${bucket_name}.s3.amazonaws.com";
        echo "https://${bucket_name}.s3.amazonaws.com" >> ${RESULT_FILE}
    else
        cat aws.txt | grep -E -q "AccessDenied|AllAccessDisabled";
        if [[ $? == 0 ]]; then
            echo "[${RED}FOUND${NORMAL}] https://${bucket_name}.s3.amazonaws.com";
        fi
    fi
  elif [[ $result == "200" ]]; then
    echo "[${GREEN}FOUND${NORMAL}] https://${bucket_name}.s3.amazonaws.com"
    echo "https://${bucket_name}.s3.amazonaws.com" >> ${RESULT_FILE}
  fi
}

check_prefix() {
  local bucket_part="${1}"

  # from @nahamsec's lazys3
  ENVIRONMENTS=(backup dev development stage s3 staging prod production test)

  # simple
  test_bucket "${NAME}-${bucket_part}"
  test_bucket "${NAME}.${bucket_part}"
  test_bucket "${NAME}${bucket_part}"

  test_bucket "${bucket_part}-${NAME}"
  test_bucket "${bucket_part}.${NAME}"
  test_bucket "${bucket_part}${NAME}"

  for ENV in ${ENVIRONMENTS[@]}; do
    test_bucket "${NAME}-${bucket_part}-${ENV}"
    test_bucket "${NAME}-${bucket_part}.${ENV}"
    test_bucket "${NAME}-${bucket_part}${ENV}"
    test_bucket "${NAME}.${bucket_part}-${ENV}"
    test_bucket "${NAME}.${bucket_part}.${ENV}"

    test_bucket "${NAME}-${ENV}-${bucket_part}"
    test_bucket "${NAME}-${ENV}.${bucket_part}"
    test_bucket "${NAME}-${ENV}${bucket_part}"
    test_bucket "${NAME}.${ENV}-${bucket_part}"
    test_bucket "${NAME}.${ENV}.${bucket_part}"

    test_bucket "${bucket_part}-${NAME}-${ENV}"
    test_bucket "${bucket_part}-${NAME}.${ENV}"
    test_bucket "${bucket_part}-${NAME}${ENV}"
    test_bucket "${bucket_part}.${NAME}-${ENV}"
    test_bucket "${bucket_part}.${NAME}.${ENV}"

    test_bucket "${bucket_part}-${ENV}-${NAME}"
    test_bucket "${bucket_part}-${ENV}.${NAME}"
    test_bucket "${bucket_part}-${ENV}${NAME}"
    test_bucket "${bucket_part}.${ENV}-${NAME}"
    test_bucket "${bucket_part}.${ENV}.${NAME}"

    test_bucket "${ENV}-${NAME}-${bucket_part}"
    test_bucket "${ENV}-${NAME}.${bucket_part}"
    test_bucket "${ENV}-${NAME}${bucket_part}"
    test_bucket "${ENV}.${NAME}-${bucket_part}"
    test_bucket "${ENV}.${NAME}.${bucket_part}"

    test_bucket "${ENV}-${bucket_part}-${NAME}"
    test_bucket "${ENV}-${bucket_part}.${NAME}"
    test_bucket "${ENV}-${bucket_part}${NAME}"
    test_bucket "${ENV}.${bucket_part}-${NAME}"
    test_bucket "${ENV}.${bucket_part}.${NAME}"
  done
}

print_results() {
  if [[ -s ${RESULT_FILE} ]]; then
    NR_OF_RESULTS=$(wc -l ${RESULT_FILE} | awk '{print $1}')
  else
    NR_OF_RESULTS=0
  fi

  echo ""
  echo "Scanning done. Found ${NR_OF_RESULTS} results."
}

open_sem() {
  mkfifo pipe-$$
  exec 3<>pipe-$$
  rm -f pipe-$$
  local i=$1
  for ((; i > 0; i--)); do
      printf %s 000 >&3
  done
}

run_with_lock() {
    local x
    read -u 3 -n 3 x && ((0==x)) || exit $x
    (
      "$@"
      printf '%.3d' $? >&3
    )&
}

ensure_dependency_installed aws
ensure_aws_credentials

for NAME in ${@}
do
  RESULT_FILE="results-${NAME}-$(date +%Y-%m-%d_%H:%M).txt"
  test_bucket ${NAME}

  open_sem ${THREADS}
  while read line; do
    run_with_lock check_prefix ${line}
  done < ./common_bucket_prefixes.txt
  print_results
done
