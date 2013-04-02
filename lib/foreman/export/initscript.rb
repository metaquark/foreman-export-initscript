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

    error("Must have a rvm version") unless ENV['RVM_VERSION']

    recent = nil
    version = ENV['RVM_VERSION']
    dir = "/usr/local/rvm/environments/"

    if version.match /^\d.\d.\d$/
      Dir.entries(dir).each do |file|
        match = file.match /^ruby-#{version}-p(\d{3})$/
        next unless match
        unless recent
          recent = match
          next
        end
        if Integer(recent[1]) < Integer(match[1])
          recent = match
        end
      end
      recent = File.join dir, recent[0]
    elsif version.match /^\d.\d.\d-p\d{3}$/
      recent = File.join dir, "ruby-#{version}"
    else
      error("No suitable version found in environment")
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
    FileUtils.chmod(755, "#{app}")
#    path = export_template name
#    write_template "initscript/master.erb", "#{app}", binding
   end

end

