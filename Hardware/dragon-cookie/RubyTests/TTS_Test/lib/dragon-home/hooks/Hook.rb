
require 'rufus-scheduler'

require_relative 'HookCallback'

module XNM
    module DragonHome
        class Hook
            def initialize(handler, hook_id)
                @handler = handler
                @hook_id = hook_id

                # This Hash will store information on the different callbacks used
                # in this hook. Among the callback itself, stored information includes
                # call count, call frequency, execution time, and error count.
                @callbacks = {}

                @scheduled_jobs = []

                @paused = false
                @destroyed = false
            end

            def feed_callback_data(callback_tag, args)
                return if @paused

                @callbacks[callback_tag]&.each { |cb| cb.execute!(args) }
            end

            def destroy!
                return if @destroyed

                @destroyed = true
                @scheduled_jobs.each(&:unschedule)
            end
            def destroyed?
                return @destroyed
            end

            def pause
                return if @paused
                @paused = true

                @scheduled_jobs.each &:pause
            end
            def paused?
                return @paused
            end
            def unpause
                return unless @paused
                @paused = false

                @scheduled_jobs.each &:unpause
            end


            def on(callback_tag, &block) 
                @callbacks[callback_tag] ||= Array.new();
                @callbacks[callback_tag] <<  HookCallback.new(callback_tag, block);
            end

            def cron(time_str, &block)
                callback = HookCallback.new(time_str, block)

                new_job = @handler.scheduler.schedule_cron(time_str, callback);

                @scheduled_jobs.filter!(&:scheduled?)
                @scheduled_jobs << new_job

                return new_job
            end
            def every(time_str, &block)
                callback = HookCallback.new(time_str, block);

                new_job = @handler.scheduler.schedule_every(time_str, callback);

                @scheduled_jobs.filter!(&:scheduled?)
                @scheduled_jobs << new_job

                return new_job
            end
        end
    end
end