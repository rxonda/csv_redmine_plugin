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
	@inicio = Date.parse(params[:dataInicio])
	@fim = Date.parse(params[:dataTermino])
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
				agora = Date.now
				filename = "TS_RCTI_#{@inicio.strftime('%Y%m%d')}I_#{@fim.strftime('%Y%m%d')}F_#{agora.strftime('%Y%m%d')}G_#{agora.strftime('%H%M%S')}G.CSV"
				headers['Content-Disposition'] = "attachment; filename=#{filename}"
				headers['content-Type'] ||= 'text/csv; charset=UTF-8; header=present'
				@headers = ['Nome','Data','Qtd','Comentario']
				# render :template => 'exporter/export.csv.erb'
			end
		end
	end
  end
end
