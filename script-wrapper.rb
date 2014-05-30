#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Copyright (C) 2014  Daniel Gröber <dxld ÄT darkboxed DOT org>
#
# This work is free software. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2, as
# published by Sam Hocevar. See the LICENSE.WTFPL file for more details.


file = File.expand_path('../@@SCRIPT@@', __FILE__)
script = IO.read file

bang = script.lines.first
if ! bang.match /^#![^[:space:]]+/ then
  exit 1
end

cmd = bang.match(/^#!([^[:space:]]+)/)[1]

p = spawn cmd, file, *ARGV
Process.wait p
exit $?.exitstatus
