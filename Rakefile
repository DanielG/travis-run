require "bundler/gem_tasks"
require 'rake/clean'
require 'fileutils'

task :default => [:build]
task :build => 'bin/travis-run'
task :install => :travis_deps

DESTDIR = ENV['DESTDIR'] || '.'
BINDIR = File.join DESTDIR, "bin"

CLEAN << 'bin/travis-run'
file "bin/travis-run" => ["travis-run"] do |t|
  rubify t.prerequisites[0], t.name
end

$script_template = IO.read("script-wrapper.rb")

def rel_to path
  dir = File.dirname(path)

  depth = Pathname.new(dir).each_filename.to_a.length
  return ('../' * depth) + File.basename(path)
end

def rubify file, out
  s = File.stat(file)

  p = $script_template.partition "@@SCRIPT@@"
  p[1] = rel_to out

  IO.write out, p.join("")
  File.chmod s.mode, out
end

task :travis_deps do
  FileUtils.mkdir_p "deps" if ! File.directory? "deps"
  Dir.chdir "deps"

  ["build", "core", "support", "sidekiqs"].each do |repo|
    name = "travis-#{repo}"
    system "git clone https://github.com/travis-ci/travis-#{repo} #{name} || ( cd #{name} && git pull )"
    Dir.chdir name
    system "rm *.gem >/dev/null 2>&1 || true"
    system "gem build #{name}.gemspec"
    system "gem install #{name}"
    Dir.chdir ".."
  end
  Dir.chdir ".."
end

#task :rubify do
#  FileUtils.mkdir_p BINDIR if !Dir.exist? BINDIR
#
#  ['travis-run'].each do |file|
#    if File.executable? file and shellscript? file then
#      rubify file
#    end
#  end
#end
