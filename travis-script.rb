#!/usr/bin/ruby

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
