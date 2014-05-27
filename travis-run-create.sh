#!/bin/sh
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

## Create travis build VM on the current machine

if [ ! -e .travis.yml ]; then
    echo "Error: .travis.yml does not exist.">&2
    echo "You probably don't want to create the VM here, some backends store">&2
    echo "per-project state needed to run the build in the current directory."
    exit 1
fi

backend_create $OPT_VM_NAME
