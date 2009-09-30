class Object
  # The hidden singleton lurks behind everyone
  def metaclass; class << self; self; end; end
  def meta_eval &blk; metaclass.instance_eval &blk; end

  # Adds methods to a metaclass
  def meta_def name, &blk
    meta_eval { define_method name, &blk }
  end

  # Defines an instance method within a class
  def class_def name, &blk
    class_eval { define_method name, &blk }
  end
end

module Kernel
  # Wrap this block around methods that create warnings that you want to ignore
  def silence_warnings
    old_verbose, $VERBOSE = $VERBOSE, nil
    yield
  ensure
    $VERBOSE = old_verbose
  end
end

class ActiveRecord::Base

  after_destroy :set_deleted_at
  
  def set_deleted_at
    changed_attributes[:deleted_at] = Time.now
  end
  
  def error_messages
    self.errors.full_messages.to_sentence
  end
  
  def associations
    single_assocs = methods.sort.grep(/loaded_(.*)\?/){ |m| m.sub(/^loaded_/, '').sub(/\?$/, '') }
    multi_assocs  = methods.grep(/_ids\=$/){ |m| m.sub(/_ids\=$/, '').pluralize }
    single_assocs + multi_assocs
  end
    
end

class ActionController::Caching::Sweeper

  def expire_paginated_page(options={})
    expire_ordered_page('page', options)
  end

  def expire_sorted_page(options={})
    expire_ordered_page('sort', options)
  end
  
  def expire_ordered_page(order, options={})
    cache_path = Rails.configuration.action_controller.page_cache_directory
    if pagination_path = url_for(options.merge(:only_path => true, :skip_relative_url_root => true))
      pagination_directory = File.join(cache_path, pagination_path, order)
      FileUtils.rm_rf(pagination_directory) if File.directory?(pagination_directory)
    end
    expire_page(options)
  end  
end

class Array
  def tally(&block)
    self.inject(0){|s,i| yield(i) ? s+1 : s }
  end
  def map_with_index(&block)
    array = []
    index = 0
    self.each do |a|
      array << yield(a, index)
      index += 1
    end
    array
  end
end

class String
  alias :to_integer :to_i 

  def human_titleize
    self.underscore.humanize.titleize
  end
  
  def url_path
    self.sub(/^\w+:\/\/[^\/]+/, '')
  end
  
end

module Boolean
  REPRESENTATIONS = {'1' => true, 'true' => true, '0' => false, 'false' => false}
  def self.parse(statement)
    statement.downcase! if statement.is_a? String
    if REPRESENTATIONS.keys.include? statement
      return REPRESENTATIONS[statement.to_s.downcase]
    else
      return !!statement
    end
  end
end

class ActiveRecord::Errors
  def delete(key)
    @errors.delete(key.to_s)
  end
end

module ActionView
  module Helpers
    module FormOptionsHelper
      STATES = ["Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado", "Connecticut", "Delaware", "Florida", "Georgia", "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland", "Massachusetts", "Michigan", "Minnesota", "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire", "New Jersey", "New Mexico", "New York", "North Carolina", "North Dakota", "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island", "South Carolina", "South Dakota", "Tennessee", "Texas", "Utah", "Vermont", "Virginia", "Washington", "Washington D.C.", "West Virginia", "Wisconsin", "Wyoming"]
    end
  end
  
  class Base
    @@field_error_proc = Proc.new{ |html_tag, instance| "<span class=\"fieldWithErrors\">#{html_tag}</span>" }
  end
end

class Time
  def human_format
    self.strftime("%b %d, %Y %H:%M")
  end
end

class Date
  def human_format(cachable=true)
    if cachable
      self.strftime('%b %d, %Y')
    else
      # We can add some extra gloss w/ human readable today / yesterday
      self == Date.today ? "Today" : (self == Date.yesterday ? "Yesterday" : self.strftime('%b %d, %Y'))
    end    
  end
  
  def start_of(interval)
    case interval
    when 'week'    
      (self - self.wday.days).to_date
    when 'month'
      (self - (self.mday - 1).days).to_date
    when 'year'
      (self - (self.yday - 1).days).to_date
    else
      self
    end    
  end
end

class Hash
  
  def -(key)
    h = self.dup
    h.delete(key)
    h
  end
  
  def select_from_range(range)
    a = ActiveSupport::OrderedHash.new
    range.each do |r|
      a[r] = self[r]
    end
    a
  end
  
  def map_keys
    h = {}
    self.each_key do |key|
      h[yield(key)] = self[key]
    end
    h    
  end
  
end