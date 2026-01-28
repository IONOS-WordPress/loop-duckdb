#!/usr/bin/env bash

# fail if any following command fails
set -eo pipefail

# link skills to gemini cli
rm -rf ./.gemini/skills && ln -sr ./docs/skills ./.gemini/skills