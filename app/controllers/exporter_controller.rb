class ExporterController < ApplicationController
  unloadable


  def export
  	if params[:dataInicio].blank? && params[:dataTermino].blank?
    	@timeEntries = TimeEntry.all
    	return
  	end
  	if params[:dataInicio].blank?
  		flash[:error] = 'Você deve informar a Data de início'
  		return
  	end
  	if params[:dataTermino].blank?
		flash[:error] = 'Você deve informar a Data de término'
		return
	end
	@inicio = params[:dataInicio]
	@fim = params[:dataTermino]
	if @inicio > @fim
		flash[:error] = 'Data de início não pode maior que a Data de término!'
		return
	end
	@timeEntries = TimeEntry.where("spent_on >= :start_date and spent_on <= :end_date", 
		{start_date: params[:dataInicio], end_date: params[:dataTermino]})
	if @timeEntries.size == 0
		flash[:warning] = 'Nenhum registro encontrado!'
	end
  end
end
