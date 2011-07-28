require "open-uri"
require "fileutils"
require "logger"
require "erb"

class RubygemsProxy
  attr_reader :env

  def self.call(env)
    new(env).run
  end

  def initialize(env)
    @env = env
    logger.level = Logger::INFO
  end

  def run
    logger.info "#{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}"

    return update_specs if env["REQUEST_METHOD"] == "DELETE"

    case env["PATH_INFO"]
    when "/"
      [200, {"Content-Type" => "text/html"}, [erb(:index)]]
    else
      [200, {"Content-Type" => "application/octet-stream"}, [contents]]
    end
  rescue Exception
    [200, {"Content-Type" => "text/html"}, [erb(404)]]
  end

  private
  def erb(view)
    ERB.new(template(view)).result(binding)
  end

  def server_url
    env["rack.url_scheme"] + "://" + File.join(env["SERVER_NAME"], env["PATH_INFO"])
  end

  def rubygems_url(gemname)
    "http://rubygems.org/gems/%s" % Rack::Utils.escape(gemname)
  end

  def gem_url(name, version)
    File.join(server_url, "gems", Rack::Utils.escape("#{name}-#{version}.gem"))
  end

  def gem_list
    Dir["#{root_dir}/public/gems/**/*.gem"]
  end

  def grouped_gems
    gem_list.inject({}) do |buffer, file|
      basename = File.basename(file)
      parts = basename.gsub(/\.gem/, "").split("-")
      version = parts.pop
      name = parts.join("-")

      buffer[name] ||= []
      buffer[name] << version
      buffer
    end
  end

  def template(name)
    @templates ||= {}
    @templates[name] ||= File.read("#{root_dir}/app/views/#{name}.erb")
  end

  def root_dir
    File.expand_path "."
  end

  def logger
    @logger ||= Logger.new(STDOUT)
  end

  def cache_dir
    "#{root_dir}/public"
  end

  def contents
    if File.directory?(filepath)
      erb(404)
    elsif cached?
      logger.info "Read from cache: #{filepath}"
      open(filepath).read
    else
      logger.info "Read from interwebz: #{url}"
      open(url).read.tap {|content| save(content)}
    end
  rescue Exception => error
    # Just try to load from file if something goes wrong.
    # This includes HTTP timeout, or something.
    # If it fails again, we won't have any files anyway!
    logger.error "Error: #{error.class} => #{error.message}"
    open(filepath).read
  end

  def save(contents)
    FileUtils.mkdir_p File.dirname(filepath)
    File.open(filepath, "wb") {|handler| handler << contents}
  end

  def cached?
    File.file?(filepath)
  end

  def filepath
    File.join(cache_dir, env["PATH_INFO"])
  end

  def url
    File.join("http://rubygems.org", env["PATH_INFO"])
  end

  def update_specs
    dir = Dir["#{cache_dir}/*.gz", "#{cache_dir}/gems/**"]    
    dir.each {|file| File.unlink(file)}
    [200, {"Content-Type" => "text/plain"}, ["OK\n"]]
  end
end
