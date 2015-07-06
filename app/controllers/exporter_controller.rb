require 'csv'

class ExporterController < ApplicationController
  unloadable


  def export
  	if params[:dataInicio].blank? && params[:dataTermino].blank?
    	@timeEntries = recuperaTodos
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
  	@timeEntries = recuperaPorDatas params[:dataInicio], params[:dataTermino]
  	if @timeEntries.empty?
  		flash[:warning] = 'Nenhum registro encontrado!'
  	else
  		respond_to do |format|
  			format.html
  			format.csv do
  				agora = DateTime.now
  				filename = "TS_RCTI_#{@inicio.strftime('%Y%m%d')}I_#{@fim.strftime('%Y%m%d')}F_#{agora.strftime('%Y%m%d')}G_#{agora.strftime('%H%M%S')}G.CSV"
  				headers['Content-Disposition'] = "attachment; filename=#{filename}"
  				headers['content-Type'] ||= 'text/csv; charset=UTF-8; header=present'
  				@headers = ['Centro de Custo','Matrícula','Cargo', 'Atividade','Qtd. Horas', '% Adicional', 'Objeto de Custo']
  				# render :template => 'exporter/export.csv.erb'
  			end
  		end
  	end
  end

  def recuperaPorDatas(dataInicio, dataTermino)
  	pack(TimeEntry.where("spent_on >= :start_date and spent_on <= :end_date", 
		{start_date: dataInicio, end_date: dataTermino}))
  end

  def recuperaTodos
  	pack(TimeEntry.all)
  end

  def pack(colecao)
  	_encontrados = []
  	customFieldCentroCusto = CustomField.where(type: 'UserCustomField', name: 'Centro de Custo').first
  	customFieldMatricula = CustomField.where(type: 'UserCustomField', name: 'Matrícula').first
  	customFieldCargo = CustomField.where(type: 'UserCustomField', name: 'Cargo').first
  	customFieldObjetoCusto = CustomField.where(type: 'ProjectCustomField', name: 'Centro de Custo').first
  	colecao.each do |e|
  		_temp = {}
  		_user = e.user
  		_project = e.project
  		_temp[:objetoCusto] = _project.custom_value_for(customFieldObjetoCusto)
  		_temp[:centroCusto] = _user.custom_value_for(customFieldCentroCusto).split(' - ').first
  		_temp[:matricula] = _user.custom_value_for(customFieldMatricula)
  		_temp[:cargo] = _user.custom_value_for(customFieldCargo).split(' - ').first
  		_temp[:qtd] = e.hours
  		_temp[:atividade] = e.activity.name
      _temp[:horaExtra] = calculateExtraTime(e.spent_on)
  		_encontrados.push(_temp)
  	end
  	_encontrados
  end

  def calculateExtraTime(data) {
    if(e.sunday?) {
      return 1.0
    }
    if(e.holiday?(Holidays::TIPOS_FERIADOS)) {
      return 1.0
    }
    if(e.saturday?) {
      return 0.5
    }
    return 0.0
  }
end
