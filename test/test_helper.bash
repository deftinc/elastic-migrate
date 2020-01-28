# guard against executing this block twice due to bats internals
if [ -z "$ELASTIC_MIGRATE_TEST_DIR" ]; then
  BATS_BASE_DIR=$(pwd)
  ELASTIC_MIGRATE_TEST_DIR="${BATS_TMPDIR}/elastic-migrate"
  ELASTIC_MIGRATE_TEST_DIR=$(mktemp -d "${ELASTIC_MIGRATE_TEST_DIR}.XXX") 2>/dev/null || exit 1
  export ELASTIC_MIGRATE_TEST_DIR
  export BATS_BASE_DIR
fi

debug() {
  >&2 echo $@
}

debug_output() {
  >&2 echo $output
}

refresh_index() {
  curl -s -X POST "$ELASTICSEARCH_HOST/_refresh" > /dev/null
}

setup_test_migrations() {
  mkdir -p "$ELASTIC_MIGRATE_TEST_DIR/migrations"
  cp $BATS_BASE_DIR/test/fixtures/* "$ELASTIC_MIGRATE_TEST_DIR/migrations"
}

setup_custom_test_migrations() {
  mkdir -p "$ELASTIC_MIGRATE_TEST_DIR/custom_migrations"
  cp $BATS_BASE_DIR/test/fixtures/* "$ELASTIC_MIGRATE_TEST_DIR/custom_migrations"
}

setup_test_directory() {
  mkdir -p "$ELASTIC_MIGRATE_TEST_DIR/elastic-migrate"
  cd "$ELASTIC_MIGRATE_TEST_DIR"
}

setup_elastic_migrate() {
  export ELASTIC_MIGRATE_MIGRATIONS_INDEX_NAME=test_elastic_migrate_migrations
  elastic-migrate setup
  npm install $BATS_BASE_DIR
}

teardown_elastic_migrate() {
  curl -s -X DELETE $ELASTICSEARCH_HOST/foo > /dev/null
  curl -s -X DELETE $ELASTICSEARCH_HOST/bar > /dev/null
  curl -s -X DELETE $ELASTICSEARCH_HOST/baz > /dev/null
  curl -s -X DELETE $ELASTICSEARCH_HOST/$ELASTIC_MIGRATE_MIGRATIONS_INDEX_NAME > /dev/null
  refresh_index
  unset ELASTIC_MIGRATE_MIGRATIONS_INDEX_NAME
}

teardown_test_directory() {
  rm -rf "$ELASTIC_MIGRATE_TEST_DIR"
}

flunk() {
  { if [ "$#" -eq 0 ]; then cat -
    else echo "$@"
    fi
  }
  return 1;
}

assert_success() {
  if [ "$status" -ne 0 ]; then
    flunk "command failed with exit status $status"
  elif [ "$#" -gt 0 ]; then
    assert_output "$1"
  fi
}

assert_failure() {
  if [ "$status" -eq 0 ]; then
    flunk "expected failed exit status"
  elif [ "$#" -gt 0 ]; then
    assert_output "$1"
  fi
}

assert_equal() {
  if [ "$1" != "$2" ]; then
    { echo "expected: $1"
      echo "actual:   $2"
    } | flunk
  fi
}

assert_output() {
  local expected
  if [ $# -eq 0 ]; then expected="$(cat -)"
  else expected="$1"
  fi
  assert_equal "$expected" "$output"
}

assert_line() {
  if [ "$1" -ge 0 ] 2>/dev/null; then
    assert_equal "$2" "${lines[$1]}"
  else
    local line
    for line in "${lines[@]}"; do
      if [ "$line" = "$1" ]; then return 0; fi
    done
    debug_output
    flunk "expected line \`$1'"
  fi
}

assert_line_count() {
  if [ "$1" -ge 0 ] 2>/dev/null; then
    local num_lines="${#lines[@]}"
    if [ "$1" != "$num_lines" ]; then
      {
        echo "expected $1 lines"
        echo "actually $num_lines lines"
      } | flunk
    else return 0;
    fi
  else flunk "Must expect zero or more lines"
  fi
}

refute_line() {
  if [ "$1" -ge 0 ] 2>/dev/null; then
    local num_lines="${#lines[@]}"
    if [ "$1" -lt "$num_lines" ]; then

      flunk "output has $num_lines lines"
    fi
  else
    local line
    for line in "${lines[@]}"; do
      if [ "$line" = "$1" ]; then

        flunk "expected to not find line \`$line'"
      fi
    done
  fi
}

assert() {
  if ! "$@"; then
    flunk "failed: $@"
  fi
}
