listen "0.0.0.0:8080"
worker_processes 2
pid "app/tmp/pids/unicorn.pid"
stderr_path "app/log/unicorn.err"
stdout_path "app/log/unicorn.log"

before_fork do |server, worker|
   old_pid = "#{server.config[:pid]}.oldbin"
   if old_pid != server.pid
     begin
       sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
       Process.kill(sig, File.read(old_pid).to_i)
     rescue Errno::ENOENT, Errno::ESRCH
     end
   end
end