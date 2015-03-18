module Rake::Hooks
  def before(*task_names, &new_task)
    options = task_names.last.is_a?(Hash) ? task_names.pop : {}
    ignore_exceptions = options.delete(:ignore_exceptions) || false
    arg_string = ""
    task_string = ""
    
    task_names.each do |task_name|  
      old_task = Rake.application.instance_variable_get('@tasks').delete(task_name.to_s)
      if old_task != nil
        # build invoke argument string
        old_task.arg_names.each do |arg|
          arg_string = arg_string + "args[:#{arg}],"
        end
        # build rake task with arguments
        if task_name.to_s.split(':').length > 1 #use namespaces
          task_string =
          "namespace :#{(task_name.to_s.split(':')[0]).to_s} do |namespace|
            desc \"#{old_task.full_comment}\"
            task :#{task_name.to_s.split(':')[task_name.to_s.split(':').length-1]}, [:#{old_task.arg_names.join(', :')}] => old_task.prerequisites do |t, args|
              new_task.call
              begin
                old_task.reenable
                old_task.invoke(#{arg_string[0..arg_string.length-2]})
                old_task.clear
              rescue
                raise unless ignore_exceptions
              end
            end
          end"
        else #no namespace
          task_string =
          "desc \"#{old_task.full_comment}\"
          task :#{task_name.to_s.split(':')[task_name.to_s.split(':').length-1]}, [:#{old_task.arg_names.join(', :')}] => old_task.prerequisites do |t, args|
            new_task.call
            begin
              old_task.reenable
              old_task.invoke(#{arg_string[0..arg_string.length-2]})
              old_task.clear
            rescue
              raise unless ignore_exceptions
            end
          end"
        end
        if old_task.arg_names.length == 0
          desc old_task.full_comment
          task task_name => old_task.prerequisites do
            new_task.call
            begin
              old_task.reenable
              old_task.invoke
              old_task.clear
            rescue
              raise unless ignore_exceptions
            end
          end
        else
          eval(task_string)
        end
      else
        puts "[ERROR] The task \"#{task_name.to_s}\" you want to hook does not exist!"
        abort
      end
    end
  end

  def after(*task_names, &new_task)
    options = task_names.last.is_a?(Hash) ? task_names.pop : {}
    ignore_exceptions = options.delete(:ignore_exceptions) || false
    arg_string = ""
    task_string = ""    
    
    task_names.each do |task_name|
      old_task = Rake.application.instance_variable_get('@tasks').delete(task_name.to_s)
      if old_task != nil
        # build invoke argument string
        old_task.arg_names.each do |arg|
          arg_string = arg_string + "args[:#{arg}],"
        end
        # build rake task with arguments
        if task_name.to_s.split(':').length > 1 #use namespaces
          task_string =
          "namespace :#{(task_name.to_s.split(':')[0]).to_s} do |namespace|
            desc \"#{old_task.full_comment}\"
            task :#{task_name.to_s.split(':')[task_name.to_s.split(':').length-1]}, [:#{old_task.arg_names.join(', :')}] => old_task.prerequisites do |t, args|
              begin
                old_task.reenable
                old_task.invoke(#{arg_string[0..arg_string.length-2]})
                old_task.clear
              rescue
                raise unless ignore_exceptions
              end
              new_task.call
            end
          end"
        else
          task_string =
          "desc \"#{old_task.full_comment}\"
          task :#{task_name.to_s.split(':')[task_name.to_s.split(':').length-1]}, [:#{old_task.arg_names.join(', :')}] => old_task.prerequisites do |t, args|
            begin
              old_task.reenable
              old_task.invoke(#{arg_string[0..arg_string.length-2]})
              old_task.clear
            rescue
              raise unless ignore_exceptions
            end
            new_task.call
          end"
        end
        if old_task.arg_names.length == 0
          desc old_task.full_comment
          task task_name => old_task.prerequisites do
            begin
              old_task.reenable
              old_task.invoke
              old_task.clear
            rescue
              raise unless ignore_exceptions
            end
            new_task.call
          end
        else
          eval(task_string)
        end
      else
        puts "[ERROR] The task you want to hook does not exist!"
        abort
      end
    end
  end
end

Rake::DSL.send(:include, Rake::Hooks) if defined?(Rake::DSL)
include Rake::Hooks unless self.class.included_modules.include?(Rake::Hooks)
