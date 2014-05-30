require "bundler/gem_tasks"
require 'rake/clean'

task :default => [:build]
task :build => ['bin/travis-run']

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

#task :rubify do
#  FileUtils.mkdir_p BINDIR if !Dir.exist? BINDIR
#
#  ['travis-run'].each do |file|
#    if File.executable? file and shellscript? file then
#      rubify file
#    end
#  end
#end
