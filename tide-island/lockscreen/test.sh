#!/bin/bash
# Runs the quickshell lockscreen in test window mode
export TEST_MODE=1
quickshell -p "$(dirname "$0")"
