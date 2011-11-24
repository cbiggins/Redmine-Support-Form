class SupportFormController < ApplicationController
  unloadable

  before_filter :require_login

  def index
      
      # Find the enabled modules ... 
      # @modules = Project.find(params[:project_id]).enabled_module_names
      
      # Get the priority list for the form
      @priorities = IssuePriority.all

      @project_id = params[:project_id]
  end
  
  def handle_post

     @descdata = params[:Issue]

      subject = @descdata[:subject]
      @project = Project.find(@descdata[:project_id])

      description_html = "<p><strong>" + l(:label_support_form_system) + "</strong><br/>" + @descdata[:system] + "</p>"
      description_html+= "<p><strong>" + l(:label_support_form_description) + "</strong><br/>" + @descdata[:description] + "</p>"
      description_html+= "<p><strong>" + l(:label_support_form_expectation) + "</strong><br/>" + @descdata[:expectation] + "</p>"
      description_html+= "<p><strong>" + l(:label_support_form_leadup) + "</strong><br/>" + @descdata[:leadup] + "</p>"
      description_html+= "<p><strong>" + l(:label_support_form_occurrence) + "</strong><br/>" + @descdata[:occurrence] + "</p>"
      description_html+= "<p><strong>" + l(:label_support_form_comments) + "</strong><br/>" + @descdata[:comments] + "</p>"

      description_wiki = "*" + l(:label_support_form_system) + "*\n" + @descdata[:system] + "\n\n"
      description_wiki+= "*" + l(:label_support_form_description) + "*\n" + @descdata[:description] + "\n\n"
      description_wiki+= "*" + l(:label_support_form_expectation) + "*\n" + @descdata[:expectation] + "\n\n"
      description_wiki+= "*" + l(:label_support_form_leadup) + "*\n" + @descdata[:leadup] + "\n\n"
      description_wiki+= "*" + l(:label_support_form_occurrence) + "*\n" + @descdata[:occurrence] + "\n\n"
      description_wiki+= "*" + l(:label_support_form_comments) + "*\n" + @descdata[:comments] + "\n\n"

      # Default to the Support tracker
      tracker = Tracker.find(:first, :conditions => { :name => 'Support' });

      # Add the support team as watchers...
      @role = Role.find(:first, :conditions => {:name => 'Support Team'} )

      # Now, lets get the users in the Support role for this Project ...
      members = Member.find(:all, :joins => :member_roles, :conditions => { :project_id => @project , :member_roles => { :role_id => @role }} )

      # new issue
      issue = Issue.new

      # We'll populate a user array so we can loop over them for the notifications
      members.each do |member|
            issue.add_watcher(User.find(member.user_id))
      end

      # We create a new issue with the params ...
      issue.author            = User.current
      issue.tracker_id        = tracker.id
      issue.project_id        = @project.id
      issue.status_id         = 1
      issue.priority_id       = @descdata[:priority_id].to_i
      issue.subject           = subject
      issue.description       = description_wiki
      issue.start_date        ||= Date.today


      if (issue.save) 
            redirect_to issue
      else
            flash.now[:error] = l('An error occurred.')
      end

      # Shoot the user an email with the issue details
      mail = SupportNotifier.create_support_notification(User.current, issue, description_html)
      SupportNotifier.deliver(mail)
  end

end

class SupportNotifier < ActionMailer::Base
   def support_notification(recipient, issue, description)
     recipients     recipient.mail
     from           "redmine@previousnext.com.au"
     subject        "Thank you for your support issue: " + issue.to_s
     body           :issue => issue, :description => description
     content_type   "text/html"
   end
end