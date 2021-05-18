
require_relative '../hooks/HookHandler.rb'

module XNM
    module DragonHome
        class User
            attr_reader :id

            attr_reader :room
            attr_reader :awake

            attr_accessor :conversation_outputs

            def initialize(user_id, home_core)
                @id = user_id
                @name = nil

                @awake = true

                @home_core = home_core
                
                @conversation_queue   = [];
                @conversation_mutex   = Mutex.new
                @conversation_outputs = [];

                @home_core << self
            end

            def set_name(name)
                return if @name == name
                old_name = @name
                @name = name

                @home_core.send_event :userNameChanged, self, old_name
            end

            def awake=(state)
                state = (state) ? true : false;

                return if @awake == state

                reassign_conversations

                @home_core.send_event :userAwakeChanged, self
            end

            def room=(room)
                unless( room.nil?() || room.is_a?(Room) )
                    raise ArgumentError, 'User room must be nil or room!'
                end

                old_room = room
                @room = room

                reassign_conversations

                @home_core.send_event :userMovedRooms, self, old_room
            end

            def name=(new_name)
                @name = new_name
            end
            def name
                return @user_id if @name.nil?
                return @name
            end

            private def reassign_conversations
                convo_clone = nil;
                @conversation_mutex.synchronize do
                    convo_clone = @conversation_queue.clone
                end

                convo_clone.each { |c| 
                    assign_conversation(c) 
                }
            end

            private def assign_conversation(convo)
                if(!@awake)
                    convo.target_output = nil;
                    return
                end

                best = nil;
                best_output = nil;

                [@conversation_outputs, @room].flatten.each do |r|
                    next if r.nil?

                    current_rating = r.rate_conversation(convo)
                    next if current_rating.nil?

                    if (best.nil?) || (current_rating > best)
                        best = current_rating
                        best_output = r;
                    end
                end

                puts "Assigning Conversation to output #{best_output}"
                convo.target_output = best_output;
            end

            def send_message(msg)
                msg = Conversation.to_convo(msg)

                assign_conversation(msg)

                return if msg.assigned?

                @conversation_mutex.synchronize do
                    @conversation_queue << msg
                    @conversation_queue.sort_by! { |c| Conversation::LEVELS[c.level] || 0 }
                end
            end
            def dequeue_conversation(convo)
                @conversation_mutex.synchronize do
                    @conversation_queue.delete convo
                end
            end
        end
    end
end