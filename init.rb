Holidays::TIPOS_FERIADOS = [:br,:observed,:informal]

Redmine::Plugin.register :csv_redmine_plugin do
  name 'Csv Teste plugin'
  author 'Raphael R. Costa'
  description 'Plugin para gerar arquivo CSV de lancamentos de timesheet'
  version '0.0.1'
  url 'https://github.com/rxonda/csv_redmine_plugin'
  author_url 'https://github.com/rxonda'

  menu :application_menu, :exporter, { :controller => 'exporter', :action => 'export' }, :caption => 'Exportação'
end
