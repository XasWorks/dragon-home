
require_relative 'ConversationOutput.rb'

module XNM
    module Conversation
        class TelegramConversationEndpoint
            include Output

            def initialize(tg_handler, home_core, user)
                @telegram_chat = tg_handler
                @home_core = home_core
                @user = user

                @on_msg_reply = nil;

                # Maps message IDs to old conversations to properly reconstruct old conversations
                @msg_id_map = {}
                @convo_tag_id_map = {}

                init_conversation_output

                @conversation_thread = Thread.new do
                    convo_thread
                end
                @conversation_thread.abort_on_exception = true

                @telegram_chat.on_message do |msg|
                    conversation = nil

                    if(rid = msg.reply_to_id)
                        conversation = @msg_id_map[rid]
                        @msg_id_map.delete rid
                    end
                    
                    conversation ||= BaseConversation.new()
                    
                    conversation.set_user_answer(msg.to_s)
                    conversation.user = @user
                    
                    if(conversation.target_output.nil?)
                        conversation.target_output = self
                    else
                        queue_conversation conversation
                    end
                end
            end

            private def convo_thread
                loop do
                    @current_conversation = next_conversation(blocking: true)
                    
                    @home_core.send_conversation(@current_conversation) if(@current_conversation.has_new_reply)

                    text = @current_conversation.reply_data&.dig(:text)
                    msg = @telegram_chat.send_message text if text.is_a? String
                    
                    next if msg.nil?

                    if(@current_conversation.has_inquiry?() && !(@current_conversation.tag.nil?))
                        if(old_id = @convo_tag_id_map[@current_conversation.tag])
                            @msg_id_map.delete old_id
                        end

                        @convo_tag_id_map[@current_conversation.tag] = msg.message_id
                        @msg_id_map[msg.message_id] = @current_conversation
                    end
                    
                    @current_conversation.reply_data = nil
                end
            end

            def rate_conversation(convo)
                if(convo.user)
                    return 100 if !convo.user.awake?
                end

                return 0;
            end

            alias :send_message :queue_conversation

            def is_available?(convo)
                return true
            end
        end
    end
end