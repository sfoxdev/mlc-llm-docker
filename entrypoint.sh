#!/bin/bash

set -e

if [ "$1" = "build" ]; then
  echo "Building MLC-LLM wheel"
  cd /src/mlc-llm/python
  python setup.py bdist_wheel
else
  exec "$@"
fi