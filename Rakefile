desc 'Run all tests by default'
task :default => :rspec

def projects
  Dir['*/Gemfile'].map do |gemfile|
    File.basename File.expand_path '..', gemfile
  end
end

def execute_for_all_projects(command)
  failed = projects.reject {|it| system "cd #{it} && #{command}" }
  raise "Errors in #{failed.join(', ')}" unless failed.empty?
end

desc 'Run rspec for all projects'
task :rspec do
  execute_for_all_projects 'bundle exec rspec'
end

desc 'Bundle all projects'
task :bundle do
  execute_for_all_projects 'bundle install'
end
