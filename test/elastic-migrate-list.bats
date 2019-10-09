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


@test "[elastic-migrate LIST] should show help with the short-form help option" {
  run elastic-migrate list -h
  assert_success
  assert_line "Usage: elastic-migrate-list [options]"
}

@test "[elastic-migrate LIST] should show help with the long-form help option" {
  run elastic-migrate list --help
  assert_success
  assert_line "Usage: elastic-migrate-list [options]"
}

@test "[elastic-migrate LIST] should give error when missing host" {
  export ELASTICSEARCH_HOST_BAK=$ELASTICSEARCH_HOST
  unset ELASTICSEARCH_HOST
  run elastic-migrate list
  assert_failure
  assert_line "Error: Must provide host"
  export ELASTICSEARCH_HOST=$ELASTICSEARCH_HOST_BAK
  unset ELASTICSEARCH_HOST_BAK
}

@test "[elastic-migrate LIST] should give error when given a bad hostname" {
  export ELASTICSEARCH_HOST_BAK=$ELASTICSEARCH_HOST
  export ELASTICSEARCH_HOST=badhost:9200
  run elastic-migrate list
  assert_failure
  assert_line "Error connecting to host"
  export ELASTICSEARCH_HOST=$ELASTICSEARCH_HOST_BAK
  unset ELASTICSEARCH_HOST_BAK
}

@test "[elastic-migrate LIST] should output no local migration files when there are no files" {
  run elastic-migrate list
  assert_success
  assert_line "No local migrations files"
}

@test "[elastic-migrate LIST] should list a line for each migration locally" {
  setup_test_migrations
  run elastic-migrate list
  assert_success
  assert_line_count 4
}

@test "[elastic-migrate LIST] should format a non-migrated migration on the host as '[ ] version description'" {
  setup_test_migrations
  run elastic-migrate list
  assert_success
  assert_line '[ ] 20181013140148 create_foo_bar'
}

@test "[elastic-migrate LIST] should format a migrated migration on the host as '[*] version description'" {
  setup_test_migrations
  curl -s -X PUT "$ELASTICSEARCH_HOST/$ELASTIC_MIGRATE_MIGRATIONS_INDEX_NAME/migration/1" -H 'Content-Type: application/json' -d'
  {
      "version" : "20181013140148",
      "description" : "create_foo_bar",
      "migratedAt" : "20181017125213"
  }
  '
  refresh_index
  run elastic-migrate list
  assert_success
  assert_line '[*] 20181013140148 create_foo_bar'
}
