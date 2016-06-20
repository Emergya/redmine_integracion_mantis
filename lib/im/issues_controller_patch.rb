require_dependency 'issues_controller'
require 'dispatcher' unless Rails::VERSION::MAJOR >= 3

module IM
	module IssuesControllerPatch
	  def self.included(base) # :nodoc:
	    base.extend(ClassMethods)
	    base.send(:include, InstanceMethods)
	    base.class_eval do
	      unloadable  # Send unloadable so it will be reloaded in development
	      alias_method_chain :update_issue_from_params, :api_error
	      alias_method_chain :update, :journal_created_on
	    end
	  end

	  module InstanceMethods
	  	# Devuelve un mensaje 403 si se está intentando modificar el estado de una petición a un estado no válido
	  	def update_issue_from_params_with_api_error
		    if params[:issue][:status_id].present? and !@issue.new_statuses_allowed_to(User.current).map(&:id).include?(params[:issue][:status_id].to_i)
     		  render :text => '{"errors":["No se puede pasar al estado solicitado"]}', :status => '422'
     		  return false
		    end
		    update_issue_from_params_without_api_error
	   	end

	   	def update_with_journal_created_on
		    return unless update_issue_from_params
		    @issue.save_attachments(params[:attachments] || (params[:issue] && params[:issue][:uploads]))
		    saved = false
		    # Formato fecha: Thu, 16 Jun 2016 10:44:44 UTC +00:00
		    if request.format.json? && params[:issue][:created_on_notes].present?
		    	@issue.current_journal.created_on = params[:issue][:created_on_notes].to_datetime
		    end

		    begin
		      saved = save_issue_with_child_records
		    rescue ActiveRecord::StaleObjectError
		      @conflict = true
		      if params[:last_journal_id]
		        @conflict_journals = @issue.journals_after(params[:last_journal_id]).all
		        @conflict_journals.reject!(&:private_notes?) unless User.current.allowed_to?(:view_private_notes, @issue.project)
		      end
		    end

		    if saved
		      render_attachment_warning_if_needed(@issue)
		      flash[:notice] = l(:notice_successful_update) unless @issue.current_journal.new_record?

		      respond_to do |format|
		        format.html { redirect_back_or_default issue_path(@issue) }
		        format.api  { render_api_ok }
		      end
		    else
		      respond_to do |format|
		        format.html { render :action => 'edit' }
		        format.api  { render_validation_errors(@issue) }
		      end
		    end
		end
	  end

	  module ClassMethods
	  end
	end
end
if Rails::VERSION::MAJOR >= 3
  ActionDispatch::Callbacks.to_prepare do
    IssuesController.send(:include, IM::IssuesControllerPatch)
  end
else
  Dispatcher.to_prepare do
    IssuesController.send(:include, IM::IssuesControllerPatch)
  end
end