#!/bin/bash -eux

sed -i "s/$1/$2/g" lib/dyndnsd/version.rb

release_date=$(LC_ALL=en_US.utf8 date +"%B %-d, %Y")

if grep "## $2 (" CHANGELOG.md; then
    true
elif grep "## $2" CHANGELOG.md; then
    sed -i "s/## $2/## $2 ($release_date)/g" CHANGELOG.md
else
    echo "## $2 ($release_date)" >> CHANGELOG.md
fi
