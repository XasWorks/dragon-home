
require_relative 'ConversationOutput'

module XNM
    module Conversation
        def Conversation.to_convo(message, **opts)
            if(message.is_a? BaseConversation)
                return message
            elsif(message.is_a? String)
                text = message;
                message = Conversation::BaseConversation.new();
                message.respond text

                return message
            elsif(message.is_a? Hash)
                h = message
                message = Conversation::BaseConversation.new();
                message.level = h[:level] if h.include? :level
                message.respond h[:text], **h

                return message
            else
                raise ArgumentError, "Could not convert to conversation!"
            end
        end

        class BaseConversation
            attr_accessor :user
            attr_accessor :user_text
            attr_accessor :has_new_reply

            attr_accessor :tag

            attr_accessor :source_type

            attr_accessor :reply_data
            
            attr_accessor :inquiry_options

            attr_accessor :level
            attr_accessor :colour

            attr_reader   :target_output

            def initialize()
                @user = nil
                @user_text = nil
                @has_new_reply = false

                @tag = nil

                @source_type = nil

                @reply_text = nil

                @level = :INFO
                @colour = nil

                @target_output = nil 
                @assigned = false
            end

            # Set the target output for this conversation
            #
            # This will remove the conversation from the list of pending conversations from its 
            # original output, and move it to the newly set output - essentially transferring where
            # it will be spoken
            #
            # @param [Output, nil] new_target New target output
            def target_output=(new_target)
                unless((new_target.is_a? Output) || (new_target.nil?))
                    raise ArgumentError, 'Output must be a Conversation::Output' 
                end

                return if @assigned

                @target_output&.dequeue_conversation(self)
                @target_output = new_target

                @target_output&.queue_conversation(self)
            end

            # Mark this conversation as "assigned", i.e. an output has started the conversation.
            #
            # After this function was called, the conversation may no longer be reassigned, 
            # and it will also be removed from any pending queues.
            def assign!()
                return if @assigned
                @assigned = true

                @target_output&.dequeue_conversation(self)
                @user&.dequeue_conversation(self)
            end
            def assigned?
                return @assigned
            end

            # Update the conversation by setting the user's text.
            #
            # This shall be called once a new reply of the user to the
            # conversation was received. Afterwards, the conversation
            # should be run through the conversation processing pipeline
            # to select an appropriate response or inquiry.
            def set_user_answer(text, user: nil)
                @user ||= user;

                @user_text = text;
                @has_new_reply  = true;

                @inquiry_options = nil
            end

            # Set a response to the current conversation.
            #
            # This will simply set the text, other options, as well as the "has_new_reply" flag.
            # The conversation will not directly output the text - this is the job of the assigned
            # Output, which MUST react to the newly set flag!
            def respond(text, **opts)
                opts[:text] = text;
                @reply_data = opts;

                @has_new_reply = false
            end
            alias :reply :respond
            alias :say :respond

            # Set an inquiry.
            #
            # This will send a response text to the current conversation, as well as initiate a 
            # inquiry. This means that the assigned Output must give the user a way to respond to 
            # the conversation. 
            # The given options can be used to give a list of options (yes/no or similar).
            #
            # Note that the inquiry response does not have to happen immediately, and may be delayed by a few 
            # minutes (until the user responds)
            #
            # Also note that a conversation 'tag' may be assigned to properly handle the response as it gets 
            # fed back into the conversation handling loop.
            def inquire(text, **opts)
                respond(text)

                @reply_text = text;

                @inquiry_options = opts
            end

            def has_inquiry?
                return !@inquiry_options.nil?
            end

            def to_s
                @user_text.to_s
            end
        end
    end
end