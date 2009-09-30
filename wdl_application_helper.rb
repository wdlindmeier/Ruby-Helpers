# Methods added to this helper will be available to all templates in the application.
module WDLApplicationHelper

  def flash_messages
    content_tag(:div, flash.map{|k,v| content_tag(:p, v, :class => k)}.join("\n"), :id => 'flash_messages')
  end
  
  def button_tag(title, options={})
    options.stringify_keys!
    options = {'type' => 'submit', 'class' => 'submit_button'}.merge(options)
    "<button #{options.map{|k,v| "#{k}=\"#{v}\""}.join(' ')}><span>#{title}</span></button>"
  end
  
  def authenticity_token
    controller.send(:authenticity_token_from_cookie_session) unless RAILS_ENV=='test'
  end
  
  # Creates a bunch of <th> tags w/ a name and a default sort. 
  def sortable_column_links_for(headers=[], tag=:th)

    request_params = (RAILS_ENV == 'test') ? Hash.new([]).update(params) : params
    
    headers.inject('') do |html, columns|      
      href_params = params.dup.update(:order => columns[0].to_s, :sort => -1, :page => 1)      
      if request_params['order'] == columns[0].to_s
        if request_params['sort'] == '-1'
          class_name = 'current desc'
          href_params = params.dup.update(:order => columns[0].to_s, :sort => 1, :page => 1)
        else
          class_name = 'current asc'          
        end
      else
        class_name = 'unselected'
      end
      tag_contents = link_to(columns[1], href_params)
      html << content_tag(tag, tag_contents, :class => class_name)
    end
    
  end
    
  def cookie_flash_messages
    <<-HTML
    <div id="flash_messages">
      <script>
        var flash = readCookie('flash');
        if(!! flash){
          eval("var flashObj = "+unescape(flash).replace(/\\+/g, ' '));
          var output = [];
          for(var key in flashObj){
            output.push('<p class="'+key+'">'+flashObj[key]+'</p>');
          }
          document.write(output.join());
        }
        destroyCookie('flash');
      </script>
    </div>
HTML
  end
  
end
