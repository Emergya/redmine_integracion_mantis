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

        after_update :notification_get_parameters
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      # Metodo que envia a Mantis la notificacion de cambio de estado y/o la nota al actualizar una petición.
      def notification_get_parameters
        # URL que usará para llamar a la API de Mantis
        url = Setting.plugin_redmine_integracion_mantis[:mantis_url]
        
        # Se obtiene el valor de la ID de Mantis
        sds_mantis = self.custom_values.where('custom_field_id = ?', Setting.plugin_redmine_integracion_mantis[:mantis_field_id]).first.value

        if sds_mantis.present?
          # API Key que se enviará en cualquier caso.
          parameters = {}
          parameters['apiAccessKey'] = Setting.plugin_redmine_integracion_mantis[:mantis_api_key]
          
          # Se recoge los cambios de estados que se deben de tener en cuenta para la notificación a Mantis
          statuses_to_send = Setting.plugin_redmine_integracion_mantis[:mantis_url_statuses_notification]

          # Comprobamos si el estado de la petición ha cambiado
          if self.status_id_changed? && statuses_to_send.include?(self.status_id.to_s)
            req_type = "put"
            status = IssueStatus.find self.status_id
            parameters["data"] = { "bug_id" => sds_mantis, "estado" => status.name, "observaciones" => self.notes, "visible" => self.private_notes ? 'no' : 'si'}
          else # Si no ha cambiado el estado, unicamente enviaremos la nota
            req_type = "post"
            parameters["data"] = { "bug_id" => sds_mantis, "estado" => '', "observaciones" => self.notes, "visible" => self.private_notes ? 'no' : 'si' }
          end 

          # Llamada al metodo que enviará la información a Mantis
          # self.send_to_mantis(url_with_id_mantis, parameters, req_type)
        end
      end

      def send_to_mantis(url, parameters, type)
        uri = URI.parse(url)
        req = type == "post" ? Net::HTTP::Post.new(uri.path) : Net::HTTP::Put.new(uri.path)
        req.set_form_data(parameters)

        res = Net::HTTP.start(uri.hostname, uri.port) do |http|
          http.request(req)
        end

        self.show_flash_error_mantis(JSON.parse(res.body)) if res.code.to_i > 400
      end

      def show_flash_error_mantis(params)
        errors.add :base, params["message"]

        raise ActiveRecord::Rollback
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