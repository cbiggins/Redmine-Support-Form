require 'redmine'

Redmine::Plugin.register :redmine_support_form do
  name 'Redmine Support Form plugin'
  author 'Christian Biggins'
  description 'Creates a simple step-based support form for creating issues'
  version '0.0.1'
  author_url 'http://previousnext.com.au'

  project_module :support_form do
      permission :view_support_form, :support_form => :index
      permission :support_form, { :support_form => [:index, :view] }, :public => true
  end

  menu :project_menu, :support_form, { :controller => 'support_form', :action => 'index' }, :caption => 'New Issue', :after => :issues, :param => :project_id

  # Remove the existing support menu
  delete_menu_item :project_menu, :new_issue  

end
