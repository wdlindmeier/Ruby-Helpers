module WDL
  module ActiveRecord 
    module Extras
      
      def self.included(base)
        base.send(:extend, ClassMethods)
        base.send(:include, InstanceMethods)
      end
      
      module ClassMethods
      end
      
      module InstanceMethods

        # Override in subclass to tweak the options show in to_json
        def to_json_options(options={})
          # Just return the default w/ symbolized keys
          options.symbolize_keys!
        end        
        
      end      
    end    
  end
end

ActiveRecord::Base.send(:include, WDL::ActiveRecord::Extras)

# Allows us to override the serialization options
# NOTE: Put this in ActiveRecord::Serialization::Serializer to override ALL serialization 

class ActiveRecord::Serialization::JsonSerializer

  def initialize(record, options = {})
    super
    @options = @record.to_json_options(@options)
  end
  
end