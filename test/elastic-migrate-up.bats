#!/usr/bin/env bats

load test_helper

setup() {
  setup_test_directory
  setup_elastic_migrate
}

teardown() {
  teardown_test_directory
  teardown_elastic_migrate
}


@test "[elastic-migrate UP] should show help with the short-form help option" {
  run elastic-migrate up -h
  assert_success
  assert_line "Usage: elastic-migrate-up [options] [version]"
}

@test "[elastic-migrate UP] should show help with the long-form help option" {
  run elastic-migrate up --help
  assert_success
  assert_line "Usage: elastic-migrate-up [options] [version]"
}

@test "[elastic-migrate UP] should give error when missing host" {
  export ELASTICSEARCH_HOST_BAK=$ELASTICSEARCH_HOST
  unset ELASTICSEARCH_HOST
  run elastic-migrate up
  assert_failure
  assert_line "Error: Must provide host"
  export ELASTICSEARCH_HOST=$ELASTICSEARCH_HOST_BAK
  unset ELASTICSEARCH_HOST_BAK
}

@test "[elastic-migrate UP] should give error when given a bad hostname" {
  export ELASTICSEARCH_HOST_BAK=$ELASTICSEARCH_HOST
  export ELASTICSEARCH_HOST=badhost:9200
  run elastic-migrate up
  assert_failure
  assert_line "Error connecting to host"
  export ELASTICSEARCH_HOST=$ELASTICSEARCH_HOST_BAK
  unset ELASTICSEARCH_HOST_BAK
}

@test "[elastic-migrate UP] should output nothing to do when no migrations are present" {
  run elastic-migrate up
  assert_success
  assert_line "Nothing to do."
}

@test "[elastic-migrate UP] should output a target version when given" {
  setup_test_migrations
  run elastic-migrate up 20181013140201
  assert_success
  assert_line "Migrating version=20181013140148 create_foo_bar"
  assert_line "Migrating version=20181013140201 create_baz"
  refute_line "Migrating version=20181013140207 remove_bar"
}

@test "[elastic-migrate UP] should output the default target version when missing" {
  setup_test_migrations
  run elastic-migrate up
  assert_success
  assert_line "Migrating version=20181013140224 remove_foo"
}

@test "[elastic-migrate UP] with env MIGRATIONS_PATH should output the default target version when missing" {
  export ELASTIC_MIGRATE_MIGRATIONS_PATH_BAK=$ELASTIC_MIGRATE_MIGRATIONS_PATH
  export ELASTIC_MIGRATE_MIGRATIONS_PATH=./custom_migrations
  setup_custom_test_migrations
  run elastic-migrate up
  assert_success
  assert_line "Migrating version=20181013140224 remove_foo"
  export ELASTIC_MIGRATE_MIGRATIONS_PATH=$ELASTIC_MIGRATE_MIGRATIONS_PATH_BAK
  unset ELASTICSEARCH_HOST_BAK
}

@test "[elastic-migrate UP] should output nothing to do if already on the latest version" {
  setup_test_migrations
  elastic-migrate up
  refresh_index
  run elastic-migrate up
  assert_success
  assert_line "Nothing to do."
}

@test "[elastic-migrate UP] should migrate to the target versions when given" {
  setup_test_migrations
  MIGRATED_COUNT=$(curl -s -X GET $ELASTICSEARCH_HOST/$ELASTIC_MIGRATE_MIGRATIONS_INDEX_NAME/_count\?q=\* | jq '.count')
  assert_equal 0 $MIGRATED_COUNT
  run elastic-migrate up 20181013140207
  refresh_index
  NEW_MIGRATED_COUNT=$(curl -s -X GET $ELASTICSEARCH_HOST/$ELASTIC_MIGRATE_MIGRATIONS_INDEX_NAME/_count\?q=\* | jq '.count')
  assert_equal 3 $NEW_MIGRATED_COUNT
  assert_success
}

@test "[elastic-migrate UP] should migrate to the latest version when version is not given" {
  setup_test_migrations
  MIGRATED_COUNT=$(curl -s -X GET $ELASTICSEARCH_HOST/$ELASTIC_MIGRATE_MIGRATIONS_INDEX_NAME/_count\?q=\* | jq '.count')
  assert_equal 0 $MIGRATED_COUNT
  run elastic-migrate up
  refresh_index
  NEW_MIGRATED_COUNT=$(curl -s -X GET $ELASTICSEARCH_HOST/$ELASTIC_MIGRATE_MIGRATIONS_INDEX_NAME/_count\?q=\* | jq '.count')
  assert_equal 4 $NEW_MIGRATED_COUNT
  assert_success
}
