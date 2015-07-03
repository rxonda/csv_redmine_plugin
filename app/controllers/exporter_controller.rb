class ExporterController < ApplicationController
  unloadable


  def export
	@inicio = !params[:dataInicio] || params[:dataInicio].strip
	@fim = !params[:dataTermino] || params[:dataTermino].strip
  	if @inicio || !@inicio.empty? then
  		if !@fim || @fim.empty?
  			flash[:error] = 'Você deve informar a Data de término'
  		elsif @inicio > @fim
  			flash[:error] = 'Data de início não pode maior que a Data de término!'
  		else
	  		@timeEntries = TimeEntry.where("spent_on >= :start_date and spent_on <= :end_date", 
	  			{start_date: params[:dataInicio], end_date: params[:dataTermino]})
  		end
  	elsif !@fim || @fim.empty?
  		flash[:error] = 'Você deve informar a Data de início'
  	else
    	@timeEntries = TimeEntry.all
  	end
  end
end
