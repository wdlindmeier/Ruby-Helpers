# NOTE: Make ApplicationController a subclass of WDLApplicationController to get these methods

class WDLApplicationController < ActionController::Base
  
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
  
  def delete_pagination_params
    params.delete(:sort)
    params.delete(:order)    
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
  
  def store_flash_in_cookie
    unless flash.blank?
      cookies['flash'] ||= flash.to_json
      flash.clear
    end
  end
  
  def rescue_action_in_public(exception)
    case exception
    when ::ActionController::RoutingError    
      return render(:file => RAILS_ROOT+'/public/404.html', :status => 404)
    else
      super
    end
  end
    
end