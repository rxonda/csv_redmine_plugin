class ExporterController < ApplicationController
  unloadable


  def export
  	if params[:filtro] then
  		@inicio = params[:filtro][:dataInicio]
  		@fim = params[:dataTermino]
  		@timeEntries = TimeEntry.where("spent_on >= :start_date and spent_on <= :end_date", 
  			{start_date: params[:filtro][:dataInicio], end_date: params[:dataTermino]})
  	else
    	@timeEntries = TimeEntry.all
  	end
  end
end
