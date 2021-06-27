
require_relative 'Conversation'

module XNM
    module Conversation
        LEVELS = {
            INFO: 1,
            WORKING: 2,
            WARN: 3,
            ERROR: 4,
            ALERT: 5
        };

        # Output Mix-In
        #
        # The functions in this mix-in provide the necessary API
        # to be part of the conversation handling environment of 
        # dragon-home. Any system that wants to be able to output conversations,
        # it must include this mix-in.
        module Output
            def init_conversation_output()
                @conversation_queue = []
                @conversation_mutex = Mutex.new
            end
            
            # Returns the next conversation to output
            #
            # This function will either block until a conversation is available
            # (if 'blocking' is true), or return nil if none is available.
            #
            # This function shall be used in the internal processing thread of the 
            # output.
            private def next_conversation(blocking: false)
                if(blocking)
                    @conversation_thread_waiting = Thread.current()
                    Thread.stop while @conversation_queue.empty?
                    @conversation_thread_waiting = nil;
                end
                
                convo = nil;
                @conversation_mutex.synchronize do
                    convo = @conversation_queue.shift
                end

                return nil if convo.nil?

                convo.assign!
                return convo
            end

            # Queue a conversation to this output.
            #
            # This will insert the conversation into the output queue. 
            # Once the endpoint becomes available the conversation will be output.
            #
            # Note that the conversations are queued by output level, with
            # "ALERT" being the highest-priority level
            def queue_conversation(convo)
                convo = Conversation.to_convo convo

                raise ArgumentError, 'Message must be a BaseConversation' unless convo.is_a? BaseConversation

                return if(convo.assigned?() && (convo.target_output != self))

                @conversation_mutex.synchronize do
                    @conversation_queue << convo
                    @conversation_queue.uniq!
                    @conversation_queue.sort_by! { |m| LEVELS[m.level] || 0 }
                end

                @conversation_thread_waiting&.run
            end

            # Remove a conversation from this output queue
            #
            # This will try to remove the conversation from this output queue.
            # Note that if the conversation has already been spoken, this will not
            # do anything.
            #
            # @warn This should *only* be called from the Conversation. If you 
            #  want to change the output of a conversation, do so by using 
            #  {BaseConversation#target_output=}
            def dequeue_conversation(convo)
                @conversation_mutex.synchronize do
                    @conversation_queue.delete convo
                end
            end

            # Rate the compatibility of this conversation to this Output.
            #
            # This function shall return how suitable this endpoint is for outputting the message.
            # For example, a Telegram Bot could always return 0 (it can always send the message but is
            # not the best choice), whereas a Room could return a higher or lower number depending on how
            # suited it is.
            #
            # Returning nil means that this endpoint is not capable/suitable for outputting this 
            # message.
            def rate_conversation(convo)
                nil
            end

            def is_speaking?
                return false
            end
        end
    end
end