require 'csv'

class ExporterController < ApplicationController
  unloadable

  def index
    render :template => 'exporter/export.html.erb'
  end

  def export
    if params[:dataInicio].blank? && params[:dataTermino].blank?
      redirect_to(exporter_path,
        :error => ['Você deve informar a Data de início', 'Você deve informar a Data de término'])
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

    @timeEntries = []
    @porDataMatricula = {}

    recuperaPorDatas(_inicio,_fim) {|t| 
      pack(t) {|v|
        consolida(v) {|e| @timeEntries << e}
      }
    }

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
    {:start_date => dataInicio, :end_date => dataTermino}).each {|t| 
      callback.call(t)
    }
  end

  def pack(e, &block)
    customFieldCentroCusto = CustomField.where(:type => 'UserCustomField', :name => 'Centro de Custo').first
    customFieldMatricula = CustomField.where(:type => 'UserCustomField', :name => 'Matrícula').first
    customFieldCargo = CustomField.where(:type => 'UserCustomField', :name => 'Cargo').first
    customFieldObjetoCusto = CustomField.where(:type => 'ProjectCustomField', :name => 'Centro de Custo').first
    customFieldCodigoSAP = CustomField.where(:type => "TimeEntryActivityCustomField", :name => 'Código SAP').first

    _user = e.user

    callback = block
    callback.call({
      :data => e.spent_on,
      :objetoCusto => e.project.custom_value_for(customFieldObjetoCusto).value,
      :centroCusto => _user.custom_value_for(customFieldCentroCusto).value.split(' - ').first,
      :matricula => _user.custom_value_for(customFieldMatricula).value,
      :cargo => _user.custom_value_for(customFieldCargo).value.split(' - ').first,
      :qtd => e.hours,
      :atividade => e.activity.custom_value_for(customFieldCodigoSAP).value
    })
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
