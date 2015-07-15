require 'csv'

class ExporterController < ApplicationController
  unloadable

  def index
    render :template => 'exporter/export.html.erb'
  end

  def export
    execute(params[:dataInicio], params[:dataTermino], lambda{|_inicio,_fim|
      respond_to do |format|
        format.html
        format.csv do
          _agora = DateTime.now
          filename = "TS_RCTI_#{_inicio.strftime('%Y%m%d')}I_#{_fim.strftime('%Y%m%d')}F_#{_agora.strftime('%Y%m%d')}G_#{_agora.strftime('%H%M%S')}G.CSV"
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
          headers['content-Type'] ||= 'text/csv; charset=UTF-8; header=present'
        end
      end}, lambda{|msg|
        flash[:error] = msg
        redirect_to exporter_timesheet_path
        })
  end

  private

  def execute(dataInicio, dataTermino, fnSuccess, fnFail)
    if dataInicio.blank? && dataTermino.blank?
      fnFail.call('Você deve informar a Data de início e a Data de término')
      return
    end
    if dataInicio.blank?
      fnFail.call('Você deve informar a Data de início')
      return
    end
    if dataTermino.blank?
      fnFail.call('Você deve informar a Data de término')
      return
    end

    _inicio = Date.strptime(dataInicio,'%d/%m/%Y')
    _fim = Date.strptime(dataTermino,'%d/%m/%Y')

    if _inicio > _fim
      fnFail.call('Data de início não pode ser maior que a Data de término!')
      return
    end

    @timeEntries = []
    @porDataMatricula = {}

    TimeEntry.where(:spent_on=>(_inicio.._fim)).each do |t| 
      pack(t) {|v|
        normaliza(v) {|z|
          consolida(z) {|e| @timeEntries << e}
        }
      }
    end

    @porDataMatricula.each do |chave, valor|
      verifyExtraTime(chave[0], lambda {
          if valor[:total] > 8.0
            qtdExtra = valor[:total] - 8.0
            valor[:lancamentos].each do |k,v|
              razao = v[:qtd] / valor[:total]
              novaEntrada = v.clone
              v[:qtd] = razao * 8.0
              v[:horaExtra] = 0.0
              novaEntrada[:qtd] = razao * qtdExtra
              novaEntrada[:horaExtra] = 50.0
              @timeEntries << novaEntrada          
            end
          else
            valor[:lancamentos].each do |k,v|
              v[:horaExtra] = 0.0
            end
          end
          }, lambda {
          valor[:lancamentos].each do |k,v|
            v[:horaExtra] = 50.0
          end
          }, lambda {
          valor[:lancamentos].each do |k,v|
            v[:horaExtra] = 100.0
          end
          })
    end

    if @timeEntries.empty?
      fnFail.call('Nenhum registro encontrado!')
    else
      fnSuccess.call(_inicio, _fim)
    end
  end

  def pack(e, &block)
    retorno = {:data => e.spent_on,
      :qtd => e.hours
    }
    getCustomFieldValue(e.project,'ProjectCustomField', 'Centro de Custo') {|v| retorno[:objetoCusto]=v}
    getCustomFieldValue(e.user,'UserCustomField','Centro de Custo') {|v| retorno[:centroCusto]=v.split(' - ').first}
    getCustomFieldValue(e.user,'UserCustomField','Matrícula') {|v| retorno[:matricula]=v}
    getCustomFieldValue(e.user,'UserCustomField','Cargo'){|v| retorno[:cargo] = v.split(' - ').first}
    getCustomFieldValue(e.activity,'TimeEntryActivityCustomField','Código SAP'){|v| retorno[:atividade]=v}
    callback = block
    callback.call(retorno)
  end

  def normaliza(e, &block)
    e[:centroCusto]||='N/A'
    e[:matricula]||='N/A'
    e[:cargo]||='N/A'
    e[:atividade]||='N/A'
    e[:objetoCusto]||=e[:centroCusto]
    callback=block
    callback.call e
  end

  def getCustomFieldValue(_model,_type,_name,&block)
    callback = block
    CustomField.where(:type => _type, :name => _name).take(1).each do |customField|
      callback.call(_model.custom_value_for(customField).value)
    end
  end

  def consolida(entry, &block)
    _keyDataMatricula = [
      entry[:data],
      entry[:matricula]
    ]

    (@porDataMatricula[_keyDataMatricula] ||= {
      :total => 0.0,
      :lancamentos => {}
    })[:total] += entry[:qtd]

    _key = [
      entry[:objetoCusto],
      entry[:atividade]
    ]

    if !@porDataMatricula[_keyDataMatricula][:lancamentos][_key]
      @porDataMatricula[_keyDataMatricula][:lancamentos][_key] = entry
      callback = block
      callback.call entry
    else
      @porDataMatricula[_keyDataMatricula][:lancamentos][_key][:qtd]+=entry[:qtd]
    end
  end

  def verifyExtraTime(data, fnNormal, fnHalf, fnFull)
    if data.sunday?
      fnFull.call
    elsif data.holiday?(Holidays::TIPOS_FERIADOS)
      fnFull.call
    elsif data.saturday?
      fnHalf.call
    else
      fnNormal.call
    end
  end
end
