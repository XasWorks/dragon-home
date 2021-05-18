
require_relative 'Hook'

module XNM
    module DragonHome
        class HookHandler
            attr_reader :scheduler

            def initialize()
                @event_queue = Queue.new()

                @scheduler = Rufus::Scheduler.new

                @hooks = {}
            end

            def define_hook(hook_name, &block)
                @hooks[hook_name]&.destroy!

                new_hook = Hook.new(self, hook_name);

                block.call(new_hook);

                @hooks[hook_name] = new_hook;
            end

            def send_event(tag, *extra_opts)
                @hooks.each { |_, h| h.feed_callback_data(tag, extra_opts) }
            end

            def send_conversation(conversation)
                total_tag = ("conversationReply" + (conversation.tag&.to_s&.capitalize || '')).to_sym

                @hooks.each do |_, h|
                    h.feed_callback_data(total_tag, conversation)

                    break unless conversation.has_new_reply
                end
            end
        end
    end
end