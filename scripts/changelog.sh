#!/bin/bash

repository_url="https://github.com/thetredev/steamcmd"

first_tag=$(git tag --sort=-version:refname | head -n 2 | tail -1)
second_tag=$(git tag --sort=-version:refname | head -n 1)

mkdir -p public

echo "## What's Changed" > public/changelog.md

echo >> public/changelog.md
git log ${first_tag}..${second_tag} --pretty=format:"- %s (%h)" >> public/changelog.md
echo >> public/changelog.md
echo >> public/changelog.md

echo "**Full Changelog**: [\`${first_tag}..${second_tag}\`](${repository_url}/compare/${first_tag}..${second_tag})" >> public/changelog.md
