require "rake"
require "fileutils"

namespace :rubygems do
	namespace :proxy do	
	  desc "configure rubygems_proxy"
		task "configure" do
      FileUtils.mkdir_p "app/tmp/pids"
      FileUtils.mkdir_p "app/log"
		end
		
		desc "start rubygems_proxy"
		task "start" do
      system("bundle exec unicorn -c app/config/unicorn.rb -D")
		end

		desc "restart rubygems_proxy"
		task "restart" do
      pid = File.read("app/tmp/pids/unicorn.pid").to_i
      Process.kill(:USR2, pid)
		end
		
		desc "stop rubygems_proxy"
		task "stop" do
      pid = File.read("app/tmp/pids/unicorn.pid").to_i
      Process.kill(:TERM, pid)
		end

		desc "remove all cached files"
		task "clean" do
      # peding
		end		
	end
end