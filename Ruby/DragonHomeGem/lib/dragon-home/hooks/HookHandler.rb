
require_relative 'Hook'
require 'rufus-scheduler'

module XNM
    module DragonHome
        class HookHandler
            attr_reader :scheduler

            def initialize()
                @event_queue = Queue.new()

                @scheduler = Rufus::Scheduler.new

                @hook_mutex = Mutex.new
                @hooks = {}

                @event_queue = Queue.new
                @event_thread = Thread.new do 
                    loop do
                        evt = @event_queue.pop

                        if(evt.is_a? Array)
                            @hook_mutex.synchronize do
                                @hooks.each { |_, h| h.feed_callback_data(evt[0], evt[1]) }
                            end

                            evt[2]&.call();
                        elsif(evt.is_a? Proc)
                            evt.call();
                        end
                    end
                end

                @event_thread.abort_on_exception = true
            end

            def define_hook(hook_name, &block)
                @hooks[hook_name]&.destroy!

                new_hook = Hook.new(self, hook_name);

                new_hook.instance_eval(&block)

                @hook_mutex.synchronize do
                    @hooks[hook_name] = new_hook;
                end

                new_hook.feed_callback_data(:setup, []);
            end

            def send_event(tag, *extra_opts, &block)
                if(Thread.current == @event_thread)
                    synchronous_event(tag, *extra_opts)
                else
                    @event_queue << [tag, extra_opts, block];
                end
            end

            def synchronous_event(tag, *extra_opts)
                had_owned_mutex = @hook_mutex.owned?
                @hook_mutex.lock unless had_owned_mutex

                @hooks.each { |_, h| h.feed_callback_data(tag, extra_opts) }
            ensure
                @hook_mutex.unlock unless had_owned_mutex
            end

            def send_conversation(conversation)
                total_tag = ("conversationReply" + (conversation.tag&.to_s&.capitalize || '')).to_sym

                @hook_mutex.synchronize do
                    @hooks.each do |_, h|
                        h.feed_callback_data(total_tag, conversation)

                        break unless conversation.has_new_reply
                    end
                end
            end
        end
    end
end