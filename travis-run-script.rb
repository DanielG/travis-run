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

require 'rubygems'
require 'bundler/setup' if File.exist? File.expand_path('../Gemfile', __FILE__)


require 'travis/support'
Travis.logger = Logger.new(StringIO.new)

require 'travis'
require 'travis/build'
require 'travis/model/build/config'
require 'travis/testing/factories'
require 'factory_girl/factory'
require 'yaml'
require 'active_support/core_ext/hash'

#### From rails >= 4.0, activesupport/lib/active_support/core_ext/hash/keys.rb
# Copyright (c) 2005-2013 David Heinemeier Hansson
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
class Hash
  # Destructively convert all keys to strings.
  # This includes the keys from the root hash and from all
  # nested hashes.
  def deep_stringify_keys!
    deep_transform_keys!{ |key| key.to_s }
  end

  # Destructively convert all keys to symbols, as long as they respond
  # to +to_sym+. This includes the keys from the root hash and from all
  # nested hashes.
  def deep_symbolize_keys!
    deep_transform_keys!{ |key| key.to_sym rescue key }
  end

  # Destructively convert all keys by using the block operation.
  # This includes the keys from the root hash and from all
  # nested hashes.
  def deep_transform_keys!(&block)
    keys.each do |key|
      value = delete(key)
      self[yield(key)] = value.is_a?(Hash) ? value.deep_transform_keys!(&block) : value
    end
    self
  end
end

def configs dir
  config = travis_config(dir)
  normalized_cfg = Build::Config.new(config, multi_os: false).normalize

  builds = Build::Config::Matrix.new(normalized_cfg, multi_os: false).expand

  str = ""
  builds.each do |cfg|
    str += YAML.dump(cfg).gsub("\n", "\\\\n") + "\n"
  end

  str
end

def script(dir, config)
  build = {
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
    :config => YAML.load(config.gsub("\\n", "\n"))
  }

  Travis::Build.script(build).compile
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

if ARGV.length == 1 then
  puts configs(ARGV[0])
elsif ARGV.length == 2 && ARGV[1] == "--build" then
  puts script(ARGV[0], STDIN.read)
else
  puts "Usage: travis-run-script DIR [--build]"
  exit 1
end
