# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  
  include AuthenticatedSystem
  include ApplicationHelper
  include ExceptionNotifiable
  
  # Fuck it
  skip_before_filter :verify_authenticity_token  
  
  helper :all # include all helpers, all the time
  
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'fbfa7fc30f0240a4f35d88ee99503c41'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  filter_parameter_logging :password
  
  after_filter :store_flash_in_cookie
  before_filter :store_return_to
  before_filter :set_is_admin_page, :only => :admin
  
  protected
  
  def store_return_to
    session[:return_to] = params[:return_to] unless params[:return_to].blank?
  end
  
  def params_for_pagination(table_name='', keep_sort_params=true)
    params[:sort] ||= -1
    params[:order] ||= 'created_at'
    # auto adds the table name to the order param
    order = (params[:order] =~ /\./) ? params[:order] : [table_name, '.', params[:order]].join
    @items_per_page ||= params[:limit] || 50
    @sort_order = "#{order} #{params[:sort].to_i == 1 ? "ASC" : "DESC"}"
    @page = params[:page] && params[:page].to_i > 0 ? params[:page].to_i : 1
    @pagination_params = {:limit => @items_per_page, :offset => (@page-1)*@items_per_page.to_i,
                          :order => @sort_order}
    delete_pagination_params unless keep_sort_params
  end  
  
  def admin_required
    if login_required
      if current_user.is_admin?
        return true
      else
        respond_to do |format|
          format.html do
            flash[:error] = "Access Denied"
            return redirect_back_or_default(home_path)
          end
          format.js do
            return render(:json => false.to_json, :status => 401, :layout => false)
          end
          format.xml do
            return render(:xml => '<error status="401">permission denied</error>', :status => 401, :layout => false)
          end
        end
      end
    end
  end  
  
  def catch_records_not_found(redirect_path='/', message='Record not found.', &action)
    begin
      yield action
    rescue ActiveRecord::RecordNotFound => e
      respond_to do |format|
        format.html do
          flash[:error] = message
          return redirect_back_or_default(redirect_path)
        end
        format.js   { return render(:text => '', :status => 404, :layout => false) }
        format.xml  { return render(:text => '', :status => 404, :layout => false) }
      end      
    end    
  end
  
  alias_method :non_api_login_required, :login_required
  # TODO: Make this more robust
  def login_required
    if params[:api_key]
      self.current_user = User.find_by_api_key(params[:api_key])
    else
      non_api_login_required
    end
  end
  
  def store_flash_in_cookie
    unless flash.blank?
      cookies['flash'] ||= flash.to_json
      flash.clear
    end
  end
  
  def load_calendar_variables
    @calendar_vars = {}
    begin 
      month = Date.parse("#{Date::MONTHNAMES[params[:month].to_i]} #{params[:year]}") 
    rescue ArgumentError
      month = Date.today.start_of('month')
    end
    @calendar_vars[:month] = month
		@calendar_vars[:last_month] = month-1.month
		@calendar_vars[:next_month] = month+1.month
		@calendar_vars[:today] = Date.today
		
		# Add any extra days from previous and next months that make our first and last weeks complete.
		# This allows us to render the calendar as a perfect rectangle.
		start_day = month-(month.wday.days)
		end_day = (month+(1.month-1.day))
		end_day += (6-end_day.wday).days

		@calendar_vars[:range] = (start_day..end_day)
  end
  
  def load_all_missions_for_calendar
    missions = ApprovedMission.find(:all, :conditions => ["publish_on IS NOT NULL AND publish_on >= ? AND publish_on <= ?", 
		                                                      @calendar_vars[:range].first, @calendar_vars[:range].last])		
		add_missions_to_calendar_vars(missions)    
  end
  
  def load_published_missions_for_calendar
    missions = ApprovedMission.published.find(:all, :conditions => ["publish_on >= ? AND publish_on <= ?",
                                                                    @calendar_vars[:range].first, @calendar_vars[:range].last])		
		add_missions_to_calendar_vars(missions)    
  end
  
  def delete_pagination_params
    params.delete(:sort)
    params.delete(:order)    
  end  
  
  def set_logged_in_script_cookies
    cookies['_tweak_user_id'] = { :value => current_user.id.to_s, :expires => current_user.remember_token_expires_at }
    cookies['_tweak_user_login'] = { :value => current_user.login, :expires => current_user.remember_token_expires_at }
    cookies['_tweak_user_auth_token'] = { :value => authenticity_token_from_cookie_session, :expires => current_user.remember_token_expires_at }
    if current_user.is_admin?
      cookies['_tweak_append_scripts'] = { :value => 'admin_scripts', :expires => current_user.remember_token_expires_at }
      cookies['_tweak_append_css'] = { :value => 'admin', :expires => current_user.remember_token_expires_at }
    end
  end
  
  def destroy_logged_in_script_cookies
    cookies.delete('_tweak_user_id')
    cookies.delete('_tweak_user_login')
    cookies.delete('_tweak_user_auth_token')
    cookies.delete('_tweak_append_scripts')
    cookies.delete('_tweak_append_css')
  end  
  
  def set_mission_sort_params
    # Set the sort order in a cookie
    params['order'] ||= 'created_at'
    params['sort'] ||= '-1'
    params_for_pagination 'missions'
    @sort_order = @sort_order.sub('missions.score', '(votes_for - votes_against)').sub('missions.random', (ActiveRecord::Base.connection.adapter_name == 'SQLite' ? 'RANDOM()' : 'RAND()'))    
  end  
  
  def set_is_admin_page
    @is_admin_page = true
  end
  
  def rescue_action_in_public(exception)
    case exception
    when ::ActionController::RoutingError    
      return render(:file => RAILS_ROOT+'/public/404.html', :status => 404)
    else
      super
    end
  end
  
  private  
  
  def add_missions_to_calendar_vars(missions)
    @calendar_vars[:missions] = @calendar_vars[:range].inject({}){ |hash, date| 
                                    hash[date] = missions.detect{|m| m.publish_on == date}
                                    hash
                                }
  end
  
  # untested
  def load_recent_activity(omitted_mission=nil)
    omitted_mission_id = omitted_mission ? omitted_mission.id : 0
    actions = []
    actions << Submission.find(:all, :order => 'created_at DESC', :limit => 2, :include => {:user => :avatar},
                                     :conditions => ["submissions.mission_id != ?", omitted_mission_id])
    actions << Comment.find(:all, :order => 'created_at DESC', :limit => 2, :include => {:user => :avatar})
    actions << Mission.find(:all, :order => 'created_at DESC', :limit => 2, :include => {:user => :avatar})    
    @recent_activities = actions.flatten.compact.map{|act| 
      a = Activity.new(:action => act, :user => act.user, :action_name => 'CREATED')
      a.created_at = act.created_at
      a
    }.sort{|a,b| b.created_at <=> a.created_at }
  end
  
end