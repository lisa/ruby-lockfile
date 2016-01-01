# Ruby Locking Module

## Introduction

This RubyLockfile module is mainly an internal (for my use) library that I'm moving to Github.

This is a fairly naive implementation, without using the `flock(2)` system call. So it's obviously not thread safe.


# Sample Code

If you'd like to use it here's a couple real-world sample cases:

    require 'ruby_locking'
    
    include RubyLocking
    
    [ 'long_task', 'short_task', 'one_should_run' ].each do |method_name|
      begin
        do_lock(method_name) do
          Rake::Task[method_name].invoke
        end
      rescue Application::Exception
        unlock!(method_name)
        next
      rescue Exception => e
        $stderr.puts "#{method_name}: Caught an unexpected xception: #{e.inspect}"
        unlock!(method_name)
        next
      end
    end