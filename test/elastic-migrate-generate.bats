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

@test "[elastic-migrate GENERATE] should show help with the short-form help option" {
  run elastic-migrate generate -h
  assert_success
  assert_line "Usage: elastic-migrate-generate [options] <description>"
}

@test "[elastic-migrate GENERATE] should show help with the long-form help option" {
  run elastic-migrate generate --help
  assert_success
  assert_line "Usage: elastic-migrate-generate [options] <description>"
}

@test "[elastic-migrate GENERATE] should tell you about the file it generated" {
  run elastic-migrate generate create_index_foo
  assert_success
  assert_line "Migration class was generated:"
  assert_line_count 2
}

@test "[elastic-migrate GENERATE] should generate a new migration file" {
  OUTPUT=$(ls migrations/ | wc -l)
  assert_equal 0 $OUTPUT
  run elastic-migrate generate create_index_foo
  assert_success
  OUTPUT=$(ls migrations/ | wc -l)
  assert_equal 1 $OUTPUT
}

@test "[elastic-migrate GENERATE] should return failure if missing description" {
  run elastic-migrate generate
  assert_failure
  assert_line "Error: Must provide a description"
}

@test "[elastic-migrate GENERATE] should generate filename with description" {
  run elastic-migrate generate create_index_foo
  assert_success
  MATCHING_FILENAME=$(ls -l migrations/ | awk '{print $9}' | grep create_index_foo.js | cut -c 16-)
  assert_equal "create_index_foo.js" $MATCHING_FILENAME
}

@test "[elastic-migrate GENERATE] should generate filename with date prefix" {
  DATE_NOW=$(date -u +%Y%m%d%H%M)
  run elastic-migrate generate create_index_foo
  assert_success
  MATCHING_TIMESTAMP=$(ls -l migrations/ | awk '{print $9}' | grep create_index_foo.js | cut -c 1-12)
  assert_equal $DATE_NOW $MATCHING_TIMESTAMP
}

@test "[elastic-migrate GENERATE] should generate filename with correct length (date + description)" {
  run elastic-migrate generate foo
  assert_success
  FILENAME_LENGTH=$(ls -l migrations/ | awk '{print $9}' | wc -c)
  assert_equal 23 $FILENAME_LENGTH
}