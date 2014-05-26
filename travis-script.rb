#!/usr/bin/ruby
# -*- coding: utf-8 -*-
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

puts File.expand_path('../Gemfile', __FILE__)

require 'rubygems'
require 'bundler/setup' if File.exist? File.expand_path('../Gemfile', __FILE__)

require 'travis/build'
require 'yaml'


def script dir
  config = {
    :build => {
      :id => 42,
      :number => 43
    },
    :repository => {
      :slug => File.basename(dir || "")
    },
    :job => {
      :branch => "master"
    },
    :config => travis_config(dir)
  }

  Travis::Build.script(config).compile
end

def travis_config(dir)
  @travis_config ||= begin
                       payload = YAML.load_file(travis_yaml dir)
                       payload.respond_to?(:to_hash) ? payload.to_hash : {}
                     end
end

def travis_yaml(dir = Dir.pwd)
  path = File.expand_path('.travis.yml', dir)
  if File.exist? path
    path
  else
    parent = File.expand_path('..', dir)
    throw "no .travis.yml found in #{dir}" if parent == dir
    puts "no .travis.yml found in #{dir}"
    travis_yaml(parent)
  end
end

# I feel dirty writing this but I don't want the resulting script to do a
# checkout as we copy the directory into the vm ourselfs
s = Travis::Build::Script::STAGES[:builtin]
s.delete_at(s.index(:checkout))

puts script(ARGV[0])
