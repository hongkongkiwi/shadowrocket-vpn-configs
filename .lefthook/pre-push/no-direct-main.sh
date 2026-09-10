#!/bin/sh

while read -r local_ref local_sha remote_ref remote_sha; do
  case "$remote_ref" in
    refs/heads/main|refs/heads/master)
      echo "Direct pushes to main/master are blocked. Push a feature branch and open a PR."
      exit 1
      ;;
  esac
done
