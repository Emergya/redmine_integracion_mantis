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
	    end
	  end

	  module InstanceMethods
	  	# Devuelve un mensaje 403 si se está intentando modificar el estado de una petición a un estado no válido
	  	def update_issue_from_params_with_api_error
		    if params[:issue][:status_id].present? and !@issue.new_statuses_allowed_to(User.current).map(&:id).include?(params[:issue][:status_id].to_i)
		      return render_403
		    end
		    update_issue_from_params_without_api_error
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