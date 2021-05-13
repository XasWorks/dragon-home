

module XNM
    module Conversation
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

            def initialize()
                @user = nil
                @user_text = nil
                @has_new_reply = false

                @tag = nil

                @source_type = nil

                @reply_text = nil

                @level = :INFO
                @colour = nil
            end

            # TODO Set/Update the user here
            def set_user_answer(text)
                @user_text = text;
                @has_new_reply  = true;

                if(@on_reply_proc)
                    p = @on_reply_proc;
                    @on_reply_proc = nil;

                    p.call(self);

                    @has_new_reply = false
                end
            end

            def respond(text, **opts)
                opts[:text] = text;
                @reply_data = opts;

                @has_new_reply = false
            end
            alias :reply :respond
            alias :say :respond

            def inquire(text, **opts, &block)
                respond(text)

                @reply_text = text;
                @on_reply_proc = block;

                @inquiry_options = opts
            end

            def has_inquiry?
                return !@on_reply_proc.nil?
            end

            def to_s
                @user_text.to_s
            end
        end
    end
end