# encoding: UTF-8
require_dependency 'journal'
require 'dispatcher' unless Rails::VERSION::MAJOR >= 3

module IM
  module JournalPatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      # Same as typing in the class
      base.class_eval do
        unloadable # Send unloadable so it will be reloaded in development
        
        alias_method_chain :send_notification, :integracion_mantis
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      def send_notification_with_integracion_mantis
        # Id del usuario para la migración
        migration_user_id = Setting.plugin_redmine_integracion_mantis[:migration_user_id]

        if migration_user_id.empty? or migration_user_id != User.current.id.to_s
          send_notification_without_integracion_mantis
        end
      end
    end

  end
end
if Rails::VERSION::MAJOR >= 3
  ActionDispatch::Callbacks.to_prepare do
    # use require_dependency if you plan to utilize development mode
    Journal.send(:include, IM::JournalPatch)
  end
else
  Dispatcher.to_prepare do
    Journal.send(:include, IM::JournalPatch)
  end
end