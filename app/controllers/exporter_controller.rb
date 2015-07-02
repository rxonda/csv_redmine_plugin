class ExporterController < ApplicationController
  unloadable


  def export
  	if params[:dataInicio] then
  		@inicio = params[:dataInicio]
  		@fim = params[:dataTermino]
  		@timeEntries = TimeEntry.where("spent_on >= :start_date and spent_on <= :end_date", 
  			{start_date: params[:dataInicio], end_date: params[:dataTermino]})
  	else
    	@timeEntries = TimeEntry.all
  	end
  end
end
