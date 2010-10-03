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
      end      
    end    
  end
end

ActiveRecord::Base.send(:include, WDL::ActiveRecord::Extras)