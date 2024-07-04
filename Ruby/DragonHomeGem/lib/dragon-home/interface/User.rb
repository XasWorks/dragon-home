
require_relative '../hooks/HookHandler.rb'

require_relative '../misc/haversine.rb'

require_relative 'DB.rb'

module XNM
    module DragonHome
        class User
            attr_reader :id

            attr_reader :room
            attr_reader :regions

            attr_reader :awake

            attr_accessor :apikey

            attr_reader :location

            attr_accessor :conversation_outputs

            attr_reader :db_user

            def initialize(user_id, home_core)
                @id = user_id
                @name = nil

                @room = nil

                @awake = true

                @hook_data = {}
                @apikey = nil

                @location = {'lat' => 0, 'lon' => 0, 'vel' => 0}

                @home_core = home_core
                
                @conversation_queue   = [];
                @conversation_mutex   = Mutex.new
                @conversation_outputs = [];

                @db_user = DB::User.find_or_create_by(name: user_id) do |user|
                    user.hook_config = {}
                    user.save
                end

                @home_core << self
            end

            def awake=(state)
                state = (state) ? true : false;

                return if @db_user.hook_config[:awake] == state
                @db_user.hook_config[:awake] = state

                @db_user.save

                reassign_conversations
                @home_core.synchronous_event :userAwakeChanged, self
            end
            def awake?
                @db_user.hook_config[:awake]
            end

            def room=(room)
                unless( room.nil?() || room.is_a?(Room) )
                    raise ArgumentError, 'User room must be nil or room!'
                end

                return if room == @room

                old_room = @room
                @room = room

                reassign_conversations

                @home_core.send_event :userMovedRooms, self, old_room
            end

            def name=(new_name)
                return if new_name == @db_user.hook_config[:name]
                return unless (new_name.is_a?(String) || new_name.nil?)

                self.awake = false if new_name.nil?
                
                old_name = @db_user.hook_config[:name]
                @db_user.hook_config[:name] = new_name

                @db_user.save

                @home_core.synchronous_event :userSwitched, self, old_name
                self.awake = true unless new_name.nil?
            end
            def name
                return @id if @db_user.hook_config[:name].nil?
                return @db_user.hook_config[:name]
            end

            def location=(new_location)
                unless(new_location['lat'].is_a?(Numeric) && new_location['lon'].is_a?(Numeric) && new_location['vel'].is_a?(Numeric))
                    raise ArgumentError, "Location must include latitude, longitude and velocity!"
                end

                new_location['inregions'] ||= []

                old_location = @location
                @location = new_location

                distance = XNM.geo_distance(old_location, @location)

                DB::UserLocation.create(ts: Time.now(), user: @db_user, lat: new_location['lat'], lon: new_location['lon'], velocity: new_location['vel']);

                @home_core.send_event :userLocationChanged, self, distance, old_location
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
                
                convo.target_output = best_output;
            end

            def send_message(msg)
                msg = Conversation.to_convo(msg)
                msg.user = self

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

            def save
                @db_user.save
            end

            def hook_data
                @db_user.hook_config
            end

            def start_activity(name, color: nil, category: nil)
                at = DB::ActivityType.find_or_create_by(name: name) do |a|
                    a.color = color
                    a.category = category

                    a.save
                end

                DB::Activity.create(user: @db_user, activity_type: at, tstart: Time.now())
            end

            def close_activity(name, extra_details: nil, description: nil)
                search_opts = { tend: nil }

                if(! name.nil?)
                    at = nil
                    begin
                        at = DB::ActivityType.find_by(name: name);
                    rescue ActiveRecord::RecordNotFound
                        return nil
                    end
                
                    search_opts[:activity_type] = at
                end

                a = @db_user.activities.where(**search_opts).last

                return nil if a.nil?

                a.tend = Time.now()
                a.extra_flags = extra_details
                a.description = description

                a.save

                a
            end
        end
    end
end