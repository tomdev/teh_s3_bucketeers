#!/bin/bash

echo ""
echo "  _       _            _____   _                _        _                 "
echo " | |     | |          |____ | | |              | |      | |                "
echo " | |_ ___| |__    ___     / / | |__  _   _  ___| | _____| |_ ___  ___ _ __ "
echo " | __/ _ \ '_ \  / __|    \ \ | '_ \| | | |/ __| |/ / _ \ __/ _ \/ _ \ '__|"
echo " | ||  __/ | | | \__ \.___/ / | |_) | |_| | (__|   <  __/ ||  __/  __/ |   "
echo "  \__\___|_| |_| |___/\____/  |_.__/ \__,_|\___|_|\_\___|\__\___|\___|_|   "
echo ""

NAME=$1

if [[ -z $NAME ]]; then
  echo "Error: no company specified."
  echo ""
  echo "Usage: ./bucketeer.sh <company_name>"
  exit 1
fi

RESULT_FILE=results.txt

test_bucket() {
  bucket_name=$1

  echo "testing $bucket_name"

  result=$(curl -I $bucket_name.s3.amazonaws.com 2>/dev/null | head -n 1 | cut -d$' ' -f2)

  if [[ $result == "403" ]]; then
    echo "403: Unauthorized. Testing with authenticated user:"
    echo "aws s3 ls s3://$bucket_name"

    aws s3 ls s3://$bucket_name

    if [[ $? == 0 ]]; then
        # Yay, we can list the bucket as unauthenticated user!
        echo $bucket_name >> $RESULT_FILE
    fi
    echo ""
  elif [[ $result == "200" ]]; then
    echo "aws s3 ls s3://$bucket_name"

    aws s3 ls s3://$bucket_name

    if [[ $? == 0 ]]; then
        # Yay, we can access the bucket as authenticated user!
        echo $bucket_name >> $RESULT_FILE
    fi
    echo ""
  fi
}

check_prefix() {
  local bucket_part="$1"

  test_bucket "$NAME"
  test_bucket "$NAME-$bucket_part"
  test_bucket "$NAME-s3-$bucket_part"
  test_bucket "$bucket_part-$NAME"
  test_bucket "$NAME.$bucket_part"
  test_bucket "$bucket_part.$NAME"
  test_bucket "$NAME$bucket_part"
  test_bucket "$bucket_part$NAME"
  test_bucket "$bucket_part.$NAME.com"
  test_bucket "$bucket_part-s3-$NAME"
  test_bucket "$NAME-s3-$bucket_part"
  test_bucket "$bucket_part-production.$NAME.com"
}

main() {
  while read line ; do check_prefix $line ; done < ./common_bucket_prefixes.txt
}

main
