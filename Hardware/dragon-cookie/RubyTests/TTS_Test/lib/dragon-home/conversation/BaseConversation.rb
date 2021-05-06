

module XNM
    module DragonHome
        class ConversationClosedError < StandardError
        end

        class BaseConversation

            attr_reader :user;
            attr_reader :closed;

            def initialize(config)
                @config = config;

                @closed = false;

                @conversation_thread = Thread.new() do
                    run_conversation_thread();
                end

                @conversation_thread.abort_on_exception = true;
            end


            private def run_conversation_thread()
                begin
                    @config[:conversation_block]&.call(self);
                rescue ConversationClosedError
                end
            end

            # Send a message back to the user for a given channel
            #
            # @param [String] message Message to send to the user.
            # @note This function is part of the blocking message interface, as some conversation endpoints
            #   need a certain time to speak out a message (such as a text to speech interface).
            def reply(message)
            end

            # Wait for the user to reply to the conversation.
            #
            # @param [Numeric, nil] timeout Optional timeout to retrieve user input.
            # @param [Array<String>, nil] options Optional answering options for the user. Can be used to 
            #   provide an answering template/answering buttons or a custom speech recognition JSGF file.
            # @return [String, nil] Will return either nil if the user did not reply in time or a timeout occured, or will return
            #   a string containing the user's input.
            def get_user_input(text = '', timeout: nil, options: nil)
            end

            # Will close this conversation.
            #
            # Closing this conversation disables the reply and user input options, and 
            # frees up the occupied conversation channel for more input. Will automatically be 
            # called at the end of the conversation thread.
            #
            # If this is called from outside the conversation thread, this shall cause the reply and user 
            # input functions to raise the ConversationClosedError to break out of the conversation thread
            # and abort it.
            def close!()
                @closed = true;
                @conversation_thread.run();

                raise ConversationClosedError if Thread.current() == @conversation_thread
            end
        
            def running?
                return !@closed
            end
        end
    end
end