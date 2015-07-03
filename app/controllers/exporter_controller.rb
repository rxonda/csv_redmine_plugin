class ExporterController < ApplicationController
  unloadable


  def export
  	if params[:dataInicio] then
  		@inicio = params[:dataInicio]
  		@fim = params[:dataTermino]
  		if !@fim
  			flash[:error] = 'Você deve informar a Data de término'
  		elsif @inicio > @fim
  			flash[:error] = 'Data de início não pode maior que a Data de término!'
  		else
	  		@timeEntries = TimeEntry.where("spent_on >= :start_date and spent_on <= :end_date", 
	  			{start_date: params[:dataInicio], end_date: params[:dataTermino]})
  		end
  	elsif params[:dataTermino]
  		flash[:error] = 'Você deve informar a Data de início'
  	else
    	@timeEntries = TimeEntry.all
  	end
  end
end
