# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
get 'exporter/timesheet' => 'exporter#export', :as => 'exporter_timesheet'
