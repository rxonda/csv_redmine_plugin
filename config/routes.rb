# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
get 'exporter/timesheet' => 'exporter#index', :as => 'exporter_timesheet'
get 'exporter/export' => 'exporter#export', :as => 'exporter_export'
