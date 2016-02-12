require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList['test/**/*_test.rb']
end

task :default => [:test, :docu]

require "docu/rake/task"

Docu::Rake::Task.new do |task|
  task.file = "README.md.docu"
end
