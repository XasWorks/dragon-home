
require 'active_record'

module XNM 
	module DragonHome
		module DB
			class JSONDeserializer
				def self.dump(hash)
				  hash
				end
	  
				def self.parse_layer(layer)
					if(layer.is_a? Array)
						layer.map! { |i| parse_layer(i) }
					end
					
					return layer unless layer.is_a? Hash
					
					if layer.include? "json_class"
						klass = JSON.deep_const_get layer["json_class"]
						
						if(klass and klass.json_creatable?)
							return klass.json_create(layer)
						end
					end
					
					layer.transform_keys!(&:to_sym)

					layer.transform_values! { |l| parse_layer(l) }
				end

				def self.load(hash)
				  parse_layer((hash.is_a?(Hash) ? hash : {}))
				end
	  		end

			class ActivityType < ActiveRecord::Base
				has_many :activities
			end

			class Activity < ActiveRecord::Base
				belongs_to :user
				belongs_to :activity_type

				serialize :extra_details, JSONDeserializer
			end

			class User < ActiveRecord::Base
				has_many :activities
				has_many :user_locations

				serialize :hook_config, JSONDeserializer
			end

			class UserLocation < ActiveRecord::Base
				belongs_to :user
			end
		end
	end
end