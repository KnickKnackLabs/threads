#!/usr/bin/env bash

setup_suite() {
  REPO_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export REPO_DIR

  # Load this repo's mise env even when tests are invoked directly via bats.
  eval "$(cd "$REPO_DIR" && mise env)"
}
