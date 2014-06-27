# Copyright (C) 2014  Daniel Gröber <dxld ÄT darkboxed DOT org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# This script will be sourced by travis-run

if [ ! -e .travis.yml ]; then
    echo "Error: .travis.yml does not exist.">&2
    exit 1
fi

cfgs=$(backend_run_script "$OPT_VM_NAME" < .travis.yml)

id=0
printf '%s\n' "$cfgs" | while IFS=$(printf '\n') read -r line; do
    unset label; unset cfg
    eval $(printf '%s' "$line")

    [ ! "$label" ] && continue

    echo "$id: \"$label\""
    id=$(($id + 1))
done
