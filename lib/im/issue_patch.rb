require_dependency 'issue'
require 'dispatcher' unless Rails::VERSION::MAJOR >= 3

module IM
  module IssuePatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      # Same as typing in the class
      base.class_eval do
        unloadable # Send unloadable so it will be reloaded in development
        require 'net/http'
        require 'uri'

        after_update :notification_note
        after_update :notification_change_status
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      # Metodo que envia a Mantis la nota al actualizar una petición.
    	def notification_note
        # =============================================================================
        # [PENDIENTE por definir parametros que se van a enviar a Mantis pero funciona]
        # =============================================================================

        # parameters = {"issue[project_id]" => '3', "issue[subject]" => 'EJEMPLO Creo3', "issue[tracker_id]" => '2', "issue[status_id]" => '13', "issue[priority_id]" => '1'}
        # parameters['key'] = "2d70d8e0f1837048350cd88b12c6614d2f26f404"

        # url = Setting.plugin_redmine_integracion_mantis[:mantis_url_notes]

        # self.send_to_mantis(url, parameters)
    	end

      # Metodo que envia a mantis el aviso del cambio de estado de una petición.
      def notification_change_status
        # =============================================================================
        # [PENDIENTE por definir parametros que se van a enviar a Mantis pero funciona]
        # =============================================================================

        # if self.status_id_changed?
        #   status = IssueStatus.find self.status_id
        #   if Setting.plugin_redmine_integracion_mantis[:mantis_url_statuses_notification].include? status.id
        #     parameters = { "status[name]" => status.name }
        #     parameters['key'] = "2d70d8e0f1837048350cd88b12c6614d2f26f404"

        #     url = Setting.plugin_redmine_integracion_mantis[:mantis_url_statuses]
            
        #     # self.send_to_mantis(url, parameters)
        #   end
        # end
      end

      def send_to_mantis(url, parameters)
        uri = URI.parse(url)
        req = Net::HTTP::Post.new(uri.path)
        req.set_form_data(parameters)

        res = Net::HTTP.start(uri.hostname, uri.port) do |http|
          http.request(req)
        end
      end
    end

  end
end
if Rails::VERSION::MAJOR >= 3
  ActionDispatch::Callbacks.to_prepare do
    # use require_dependency if you plan to utilize development mode
    Issue.send(:include, IM::IssuePatch)
  end
else
  Dispatcher.to_prepare do
    Issue.send(:include, IM::IssuePatch)
  end
end