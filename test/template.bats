#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

setup() {
  load helpers
  setup_test_dir
}

@test "template: lists available templates with no args" {
  run threads template
  [ "$status" -eq 0 ]
  [[ "$output" == *"HUMAN"* ]]
  [[ "$output" == *"Available templates"* ]]
}

@test "template: outputs named template body to stdout" {
  run threads template HUMAN
  [ "$status" -eq 0 ]
  [[ "$output" == *"# HUMAN"* ]]
  [[ "$output" == *"[!info]"* ]]
}

@test "template: strips frontmatter from output" {
  run threads template HUMAN
  [ "$status" -eq 0 ]
  [[ "$output" != *"description:"* ]]
}

@test "template: unknown template exits non-zero" {
  run threads template nonexistent
  [ "$status" -ne 0 ]
  [[ "$output" == *"Unknown template"* ]]
}

@test "template: output can initialize a file" {
  threads template HUMAN > "$THREADS_PATH"
  [ -f "$THREADS_PATH" ]
  grep -q "# HUMAN" "$THREADS_PATH"
  grep -q "\[!info\]" "$THREADS_PATH"
}
