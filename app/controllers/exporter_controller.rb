require 'csv'

class ExporterController < ApplicationController
  unloadable

  def initialize
    @timeEntries = []
    @consolidado = {}
    @porDataMatricula = {}
  end

  def export
  	if params[:dataInicio].blank? && params[:dataTermino].blank?
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

  	_inicio = Date.parse(params[:dataInicio])
  	_fim = Date.parse(params[:dataTermino])

  	if _inicio > _fim
  		flash[:error] = 'Data de início não pode ser maior que a Data de término!'
  		return
  	end

  	recuperaPorDatas(_inicio,_fim) {|t| pack t}

    @porDataMatricula.each do |chave, valor|
      if valor[:tipo] == 0.0 && valor[:total] > 8.0
        qtdExtra = valor[:total] - 8.0
        valor[:lancamentos].each do |l|
          razao = l[:qtd] / valor[:total]
          novaEntrada = l.clone
          l[:qtd] = razao * 8.0
          novaEntrada[:qtd] = razao * qtdExtra
          novaEntrada[:horaExtra] = 50.0
          @timeEntries << novaEntrada          
        end
      end
    end

  	if @timeEntries.empty?
  		flash[:warning] = 'Nenhum registro encontrado!'
  	else
  		respond_to do |format|
  			format.html
  			format.csv do
  				_agora = DateTime.now
  				filename = "TS_RCTI_#{_inicio.strftime('%Y%m%d')}I_#{_fim.strftime('%Y%m%d')}F_#{_agora.strftime('%Y%m%d')}G_#{_agora.strftime('%H%M%S')}G.CSV"
  				headers['Content-Disposition'] = "attachment; filename=#{filename}"
  				headers['content-Type'] ||= 'text/csv; charset=UTF-8; header=present'
  			end
  		end
  	end
  end

  private

  def recuperaPorDatas(dataInicio, dataTermino, &block)
    callback = block
  	TimeEntry.where("spent_on >= :start_date and spent_on <= :end_date", 
		{start_date: dataInicio, end_date: dataTermino}).each {|t| callback.call t}
  end

  def pack(e)
  	customFieldCentroCusto = CustomField.where(type: 'UserCustomField', name: 'Centro de Custo').first
  	customFieldMatricula = CustomField.where(type: 'UserCustomField', name: 'Matrícula').first
  	customFieldCargo = CustomField.where(type: 'UserCustomField', name: 'Cargo').first
  	customFieldObjetoCusto = CustomField.where(type: 'ProjectCustomField', name: 'Centro de Custo').first
    customFieldCodigoSAP = CustomField.where(type: "TimeEntryActivityCustomField", name: 'Código SAP').first

    _user = e.user
    _project = e.project
    _data = e.spent_on
    _matricula = _user.custom_value_for(customFieldMatricula).value
    _objetoCusto = _project.custom_value_for(customFieldObjetoCusto).value
    _atividade = e.activity.custom_value_for(customFieldCodigoSAP).value
    _qtdHoras = e.hours
    _horaExtra = calculateExtraTime(_data)

    _key = [
      _data,
      _matricula,
      _objetoCusto,
      _atividade
    ]

    _keyDataMatricula = [
      _data,
      _matricula
    ]

    (@porDataMatricula[_keyDataMatricula] ||= {
      :total => 0.0,
      :tipo => _horaExtra,
      :lancamentos => []
    })[:total] += _qtdHoras

    if !@consolidado[_key]
      _temp = {
        :objetoCusto => _objetoCusto,
        :centroCusto => _user.custom_value_for(customFieldCentroCusto).value.split(' - ').first,
        :matricula => _matricula,
        :cargo => _user.custom_value_for(customFieldCargo).value.split(' - ').first,
        :qtd => _qtdHoras,
        :atividade => _atividade,
        :horaExtra => _horaExtra
      }

      @timeEntries << _temp

      @porDataMatricula[_keyDataMatricula][:lancamentos] << _temp

      @consolidado[_key] = _temp
    else
      @consolidado[_key][:qtd]+=e.hours
    end

  end

  def calculateExtraTime(data)
    if data.sunday?
      return 100.0
    end
    if data.holiday?(Holidays::TIPOS_FERIADOS)
      return 100.0
    end
    if data.saturday?
      return 50.0
    end
    return 0.0
  end
end
