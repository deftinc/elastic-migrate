#!/usr/bin/env bats

load test_helper

setup() {
  setup_test_directory
}

teardown() {
  teardown_test_directory
}


@test "[elastic-migrate SETUP] should show help with the short-form help option" {
  run elastic-migrate setup -h
  assert_success
  assert_line "Usage: elastic-migrate-setup [options]"
}

@test "[elastic-migrate SETUP] should show help with the long-form help option" {
  run elastic-migrate setup --help
  assert_success
  assert_line "Usage: elastic-migrate-setup [options]"
}

@test "[elastic-migrate SETUP] should give error when missing host" {
  export ELASTICSEARCH_HOST_BAK=$ELASTICSEARCH_HOST
  unset ELASTICSEARCH_HOST
  run elastic-migrate setup
  assert_failure
  assert_line "Error: Must provide host"
  export ELASTICSEARCH_HOST=$ELASTICSEARCH_HOST_BAK
  unset ELASTICSEARCH_HOST_BAK
}

@test "[elastic-migrate SETUP] should give error when given a bad hostname" {
  export ELASTICSEARCH_HOST_BAK=$ELASTICSEARCH_HOST
  export ELASTICSEARCH_HOST=badhost:9200
  run elastic-migrate setup
  assert_failure
  assert_line "Error connecting to host"
  export ELASTICSEARCH_HOST=$ELASTICSEARCH_HOST_BAK
  unset ELASTICSEARCH_HOST_BAK
}

@test "[elastic-migrate SETUP] should be able to connect to elasticsearch" {
  OUTPUT=$(curl -s $ELASTICSEARCH_HOST | jq '.version.number' | tr -d '"')
  assert_equal 7.4.0 $OUTPUT
}

@test "[elastic-migrate SETUP] should show the usage prompt when given the short form help option" {
  run elastic-migrate setup -h
  assert_success
  assert_line "Usage: elastic-migrate-setup [options]"
}

@test "[elastic-migrate SETUP] should show the usage prompt when given the long form help option" {
  run elastic-migrate setup --help
  assert_success
  assert_line "Usage: elastic-migrate-setup [options]"
}

@test "[elastic-migrate SETUP] should complete successfully when setup has not run" {
  export ELASTIC_MIGRATE_MIGRATIONS_INDEX_NAME=test_elastic_migrate_migrations
  run elastic-migrate setup
  assert_success
  assert_output "Done."
  teardown_elastic_migrate
}

@test "[elastic-migrate SETUP] should complete successfully when setup has run" {
  export ELASTIC_MIGRATE_MIGRATIONS_INDEX_NAME=test_elastic_migrate_migrations
  elastic-migrate setup
  run elastic-migrate setup
  assert_success
  assert_output "Already ran setup. Exiting."
  teardown_elastic_migrate
}

@test "[elastic-migrate SETUP] should have created an elasticsearch index when setup runs" {
  export ELASTIC_MIGRATE_MIGRATIONS_INDEX_NAME=test_elastic_migrate_migrations
  run elastic-migrate setup
  assert_success
  OUTPUT=$(curl -s -X GET $ELASTICSEARCH_HOST/$ELASTIC_MIGRATE_MIGRATIONS_INDEX_NAME/_mapping | jq ".$ELASTIC_MIGRATE_MIGRATIONS_INDEX_NAME.mappings.properties.description.type" | tr -d '"')
  assert_equal text $OUTPUT
  teardown_elastic_migrate
}

@test "[elastic-migrate SETUP] should create the migrations directory if it does not exist" {
  export ELASTIC_MIGRATE_MIGRATIONS_INDEX_NAME=test_elastic_migrate_migrations
  run elastic-migrate setup
  assert_success
  OUTPUT=$(ls . | grep migrations | wc -l)
  assert_equal 1 $OUTPUT
  teardown_elastic_migrate
}

@test "[elastic-migrate SETUP] should not error if the migrations directory already exists" {
  export ELASTIC_MIGRATE_MIGRATIONS_INDEX_NAME=test_elastic_migrate_migrations
  run mkdir ./migrations
  OUTPUT=$(ls . | grep migrations | wc -l)
  assert_equal 1 $OUTPUT
  run elastic-migrate setup
  assert_success
  teardown_elastic_migrate
}
