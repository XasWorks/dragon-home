

module XNM
    module Conversation
        class TelegramConversationEndpoint
            def initialize(tg_handler)
                @telegram_chat = tg_handler

                @on_msg_reply = nil;

                # Maps message IDs to old conversations to properly reconstruct old conversations
                @msg_id_map = {}
                @convo_tag_id_map = {}

                @conversation_queue = Queue.new

                @conversation_thread = Thread.new do
                    convo_thread
                end
                @conversation_thread.abort_on_exception = true

                @telegram_chat.on_message do |msg|
                    puts "Message replies to #{msg.reply_to_id}"

                    if(rid = msg.reply_to_id)
                        puts "Message was replied to #{rid}"

                        conversation = @msg_id_map[rid]
                        @msg_id_map.delete rid
                    end
                    
                    conversation ||= BaseConversation.new() 

                    conversation.set_user_answer(msg.to_s)

                    @conversation_queue << conversation
                end
            end

            private def convo_thread
                loop do
                    @current_conversation = @conversation_queue.pop()
                    
                    if(@current_conversation.has_new_reply)
                        @on_msg_reply&.call(@current_conversation)
                    end

                    text = @current_conversation.reply_data.dig(:text)
                    msg = @telegram_chat.send_message text, inline_keyboard: {'Yes!' => 'Yes :>'} if text.is_a? String
                    
                    if(@current_conversation.has_inquiry? && @current_conversation.tag)
                        if(old_id = @convo_tag_id_map[@current_conversation.tag])
                            @msg_id_map.delete old_id
                        end

                        @convo_tag_id_map[@current_conversation.tag] = msg.message_id
                        
                        puts "MSG #{msg.message_id} associated with conversation tag #{@current_conversation.tag}"
                        @msg_id_map[msg.message_id] = @current_conversation
                    end
                    
                    @current_conversation.reply_data = nil
                end
            end

            def on_convo_reply(&block)
                @on_msg_reply = block;
            end
            def send_message(message)
                if(message.is_a? String)
                    text = message;
                    message = Conversation::BaseConversation.new();
                    message.respond text
                elsif(message.is_a? Hash)
                    h = message
                    message = Conversation::BaseConversation.new();
                    message.level = h[:level] if h.include? :level
                    message.respond h[:text], **h
                end

                @conversation_queue << message;
            end
        end
    end
end