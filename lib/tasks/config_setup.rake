# https://gist.github.com/masaki/1108410

namespace :setup do
  def copy_config(options = {})
    Dir[File.join(Rails.root, "config", "*.sample")].each do |source|
      target = source.sub(/\.(ex|s)ample$/, "")
      if options[:force] or not File.exist?(target)
        require "fileutils"
        puts "Create config file \"#{target}\" from \"#{source}\""
        FileUtils.copy_file source, target
      end
    end
  end

  def copy_config!
    copy_config(:force => true)
  end

  desc "Create config file from *.sample"
  task :config do |t|
    copy_config
  end

  namespace :config do
    desc "Create config file forcibly from *.sample"
    task :force do |t|
      copy_config!
    end
  end
end
