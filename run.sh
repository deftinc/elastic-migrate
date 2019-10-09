#!/usr/bin/env bash
set -eo pipefail

./wait-for-it.sh $ELASTICSEARCH_HOST -t 60

case $1 in
  console)
    node -i --experimental-repl-await
    ;;
  ci)
    bash ./test/ci
    ;;
  *)
    exec "$@"
    ;;
esac
