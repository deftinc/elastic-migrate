#!/usr/bin/env bats

load test_helper

setup() {
  setup_test_directory
}

teardown() {
  teardown_test_directory
}

@test "[elastic-migrate USAGE] should show help with no args" {
  run elastic-migrate
  assert_success
  assert_line "Usage: elastic-migrate [options] [command]"
  assert_line_count 10 # Bash throws out empty lines
}

@test "[elastic-migrate USAGE] should show help with long form help option" {
  run elastic-migrate --help
  assert_success
  assert_line "Usage: elastic-migrate [options] [command]"
}

@test "[elastic-migrate USAGE] should show help with short form help option" {
  run elastic-migrate -h
  assert_success
  assert_line "Usage: elastic-migrate [options] [command]"
}

@test "[elastic-migrate USAGE] should show help with help command" {
  run elastic-migrate help
  assert_success
  assert_line "Usage: elastic-migrate [options] [command]"
}

@test "[elastic-migrate USAGE] should show nothing with unknown command" {
  run elastic-migrate foo
  assert_success
  assert_output ""
}
