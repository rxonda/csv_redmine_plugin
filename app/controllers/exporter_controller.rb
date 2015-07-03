require 'csv'

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
		flash[:error] = 'Data de início não pode ser maior que a Data de término!'
		return
	end
	@timeEntries = TimeEntry.where("spent_on >= :start_date and spent_on <= :end_date", 
		{start_date: params[:dataInicio], end_date: params[:dataTermino]})
	if @timeEntries.empty?
		flash[:warning] = 'Nenhum registro encontrado!'
	else
		respond_to do |format|
			format.html
			format.csv do
				headers['Content-Disposition'] = 'attachment; filename=\"user-list\"'
				headers['content-Type'] ||= 'text/csv'
			end
		end
	end
  end
end
