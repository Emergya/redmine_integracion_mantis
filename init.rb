require 'im/issue_patch'

Redmine::Plugin.register :redmine_integracion_mantis do
  name 'Redmine Integracion Mantis plugin'
  author 'jresinas, mabalos'
  description 'Plugin de Redmine que permite la integracion entre CSMe y Mantis.'
  version '0.1.0'
  author_url 'http://www.emergya.es'

  settings :default => {}, :partial => 'settings/redmine_integracion_mantis'
end
