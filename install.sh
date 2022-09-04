#!/usr/bin/env bash
cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" || exit 1
for script in install/*; do
	. "$script"
done
