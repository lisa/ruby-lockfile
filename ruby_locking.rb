require 'tmpdir'
require 'fileutils'
module RubyLocking
  RUBY_LOCK_TEMP_DIR = Dir.tmpdir
  class LockException < StandardError;end
  
  # Default to checking to see if a global lock has been put in place.
  def locked?(lock_name = "global", skip_global = false)
    File.exists?(File.join(RUBY_LOCK_TEMP_DIR,'ruby-lock',lock_name)) || 
      (!skip_global && File.exists?(File.join(RUBY_LOCK_TEMP_DIR,'ruby-lock',"global")))
  end
  
  def lock!(lock_name)
    unless File.exists?(File.join(RUBY_LOCK_TEMP_DIR,'ruby-lock'))
      FileUtils.mkdir_p(File.join(RUBY_LOCK_TEMP_DIR,'ruby-lock'), :mode => 0700) 
    end
    File.open(File.join(RUBY_LOCK_TEMP_DIR,'ruby-lock',lock_name),'w') { |f| f.print Process.pid.to_s }
  end
  def unlock!(lock_name)
    File.unlink(File.join(RUBY_LOCK_TEMP_DIR,'ruby-lock',lock_name)) rescue true
  end
  
  def achieve_global_lock!
    raise LockException.new("Already locked.") if locked?("global")
    lock!("global")      
  end
  
  def release_global_lock!(check_pid = true)
    return unless locked?("global") && File.exists?(File.join(RUBY_LOCK_TEMP_DIR,'ruby-lock'))
    locked_pid = File.read(File.join(RUBY_LOCK_TEMP_DIR,'ruby-lock',"global")).chomp
    my_pid = Process.pid.to_s
    if check_pid && (my_pid != locked_pid)
      raise LockException.new("Can't release lock, pid mismatch: locker #{locked_pid}, i am #{my_pid}")
    else
      unlock!("global")
    end
  end
  
  def do_lock(lock_name,&block)
    if ! locked?(lock_name) && block_given?
      lock_name == 'global' ? achieve_global_lock! : lock!(lock_name)
      begin
        yield
      rescue Exception => e
        lock_name == 'global' ? release_global_lock! : unlock!(lock_name)
        raise
      ensure
        lock_name == 'global' ? release_global_lock! : unlock!(lock_name)
      end
    end
  end
end