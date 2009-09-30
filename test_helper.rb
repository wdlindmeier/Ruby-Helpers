module WDLTestHelper

  def deny(condition, message=nil)
    assert !condition, message
  end
  
  def assert_invalid(record, message=nil)
    assert !record.valid?, message 
  end

  def no_test
    flunk "Test hasn't been written yet." 
  end
  
  def setup_action_mailer
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []        
  end  
  
  def setup_controller(kind)
    @controller = kind.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end  

  # => assert_unique(Invite, :company)
  def assert_unique(klass, prop)
    klass.delete_all
    assert_difference "#{klass.name}.count" do
      thing = create_instance
    end
    assert_no_difference "#{klass.name}.count" do
      thing = create_instance
      assert thing.errors.on(prop)
    end
  end

  # => assert_length_in_bounds(Invite, :company)
  # => assert_length_in_bounds(Invite, :company, 3, 10)
  # => assert_length_in_bounds(Invite, :company, 3, 10, 'passes', 'this will fail')
  
  #assert_length_in_bounds(Recipe, :category, 1, 100, Recipe::CATEGORIES.first, newcategory)
  def assert_length_in_bounds(klass, prop, min, max, pass=nil, fail=nil)
    just_right_min = min - 1
    just_right_max = max - 1
    too_short = min - 2
    too_long = max

    klass.delete_all
    assert_difference "#{klass.name}.count" do
      if pass.nil?
        n = ''
        i=0
        for i in 0..just_right_min
          n << 'x'
        end
        thing = create_instance(prop=>n)
      else
        thing = create_instance(prop=>pass)
      end
    end

    klass.delete_all
    assert_difference "#{klass.name}.count" do
      if pass.nil?
        n = ''
        i=0
        for i in 0..just_right_max
          n << 'x'
        end
        thing = create_instance(prop=>n)
      else
        thing = create_instance(prop=>pass)
      end
    end

    klass.delete_all
    assert_no_difference "#{klass.name}.count" do
      if fail.nil?
        n = ''
        i=0
        for i in 0..too_short
          n << 'x'
        end
        thing = create_instance(prop=>n)
      else
        thing = create_instance(prop=>fail)
      end
      assert thing.errors.on(prop)
    end

    klass.delete_all
    assert_no_difference "#{klass.name}.count" do
      if fail.nil?
        n = ''
        i=0
        for i in 0..too_long
          n << 'x'
        end
        thing = create_instance(prop=>n)
      else
        thing = create_instance(prop=>fail)
      end
      assert thing.errors.on(prop)
    end
  end

  # => assert_format_passes(Invite, :company, 'this should pass')
  def assert_format_passes(klass, prop, pass)
    klass.delete_all
    assert_difference "#{klass.name}.count" do
      invite = create_instance(prop=>pass)
    end
  end

  # => assert_format_fails(Invite, :company, 'this should fail')
  def assert_format_fails(klass, prop, fail)
    klass.delete_all
    assert_difference "#{klass.name}.count" do
      invite = create_instance
    end
    klass.delete_all
    assert_no_difference "#{klass.name}.count" do
      invite = create_instance(prop=>fail)
      assert invite.errors.on(prop)
    end
  end


  # => assert_required(Invite, :company)
  def assert_required(klass, prop)
    klass.delete_all
    assert_difference "#{klass.name}.count" do
      invite = create_instance
    end
    klass.delete_all
    assert_no_difference "#{klass.name}.count" do
      invite = create_instance(prop=>nil)
      assert invite.errors.on(prop)
    end
  end

  # => assert_not_required(Invite, :company)
  def assert_not_required(klass, prop)
    klass.delete_all
    assert_difference "#{klass.name}.count" do
      thing = create_instance(prop=>nil)
    end
  end

  def logger
    RAILS_DEFAULT_LOGGER
  end
  
  def assert_mass_assignment_fails(klass, props={})
    instance = klass.new(props)
    props.keys.each do |meth|
      assert_not_equal instance.send(meth), props[meth]
    end
  end
  
  def assert_validates_associated(klass, prop, invalid)
    klass.delete_all
    assert_difference "#{klass.name}.count" do
      invite = create_instance
    end
    klass.delete_all
    assert_no_difference "#{klass.name}.count" do
      invite = create_instance(prop=>invalid)
      assert invite.errors.on(prop).include?('is invalid')
    end    
  end
  
  def assert_autogenerate(klass, prop)
    klass.delete_all
    obj = create_instance(prop => nil)
    assert_not_nil obj.send(prop)
  end
  
  def assert_empty(array)
    assert array.empty?
  end
  
  def assert_dependant_destroy(obj, *props)
    props.each do |prop|
      deny obj.send(prop).blank?, "#{obj.class.name} #{obj.id} #{prop} is empty"
    end
    obj.class.destroy(obj.id)
    props.each do |prop|
      assert_equal Kernel.const_get(prop.to_s.classify).count(:id, :conditions => "#{obj.class.name.foreign_key} = #{obj.id}"), 0, "#{obj.class.name} #{prop} are not destroyed when an instance is deleted"
    end    
  end
  
  def assert_valid_fixtures(*models)
    models.each do |model|
      records = model.find(:all)
      assert records.all?{|r| r.valid?}, "One or more pre-loaded #{model.name} is invalid:\n#{records.map{|r| r.valid? ? nil : 
                                                                 "#{r.id}: "+r.errors.full_messages.to_sentence }.compact.join("\n")}"
    end
  end
  
  def assert_raises_exception(e, &block)
    begin
      yield
    rescue Exception => err
      return assert(err.is_a?(e), "Raised #{err.class.name}, expected #{e.name}")
    end
    assert false, "Expected to raise #{e.name}"
  end
  
  def assert_asked_to_login
    assert_redirected_to new_session_path()
  end

  def assert_includes(obj, item, message=nil)
    assert obj.include?(item), message
  end
  
  def deny_includes(obj, item, message=nil)
    deny obj.include?(item), message
  end
  
  def assert_response_includes(string)
    assert @response.body.include?(string), "Response body does not include #{string}"
  end
  
  def assert_not_blank(collection)
    assert !collection.blank?
  end
  
  def assert_blank(thing)
    assert thing.blank?
  end
    
end