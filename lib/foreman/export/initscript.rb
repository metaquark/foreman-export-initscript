require "erb"
require "foreman/export"

class Foreman::Export::Initscript < Foreman::Export::Base

  def export

    #super
    error("Must specify a location") unless location
    FileUtils.mkdir_p(location) rescue error("Could not create: #{location}")
    FileUtils.mkdir_p(log) rescue error("Could not create: #{log}")
#    begin
#      FileUtils.chown(user, nil, log)
#    rescue Exception => e
#      error("Could not chown #{log} to #{user} - #{e.message}")
#    end

    if rvm_version = ENV['RVM_VERSION']
      rvm_path = nil
      rvm_base_dir = "/usr/local/rvm/environments/"

      if rvm_version.match /^\d.\d.\d$/
        Dir.entries(rvm_base_dir).each do |file|
          match = file.match /^ruby-#{rvm_version}-p(\d{3})$/
          next unless match
          unless rvm_path
            rvm_path = match
            next
          end
          if Integer(rvm_path[1]) < Integer(match[1])
            rvm_path = match
          end
        end
        rvm_path = File.join rvm_base_dir, rvm_path[0]
      elsif rvm_version.match /^\d.\d.\d-p\d{3}$/
        rvm_path = File.join rvm_base_dir, "ruby-#{rvm_version}"
      else
        error("No suitable rvm version found in environment")
      end
    end

    name = "initscript/master.erb"
    name_without_first = name.split("/")[1..-1].join("/")
    matchers = []
    matchers << File.join(options[:template], name_without_first) if options[:template]
    matchers << File.expand_path("~/.foreman/templates/#{name}")
    matchers << File.expand_path("../../../../data/export/#{name}", __FILE__)
    path = File.read(matchers.detect { |m| File.exists?(m) })
    compiled = ERB.new(path).result(binding)
    write_file "#{app}", compiled
    chmod 0755, app
#    path = export_template name
#    write_template "initscript/master.erb", "#{app}", binding
  end

end

