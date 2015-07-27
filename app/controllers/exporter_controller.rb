require 'csv'
require 'date'

class ExporterController < ApplicationController
  unloadable

  def index
    render :template => 'exporter/export.html.erb'
  end

  def export
    valida(params[:dataInicio], params[:dataTermino],
      lambda{|inicio, fim|
        execute(inicio, fim, lambda{|resultado|
          _agora = DateTime.now
          filename = "TS_RCTI_#{inicio.strftime('%Y%m%d')}I_#{fim.strftime('%Y%m%d')}F_#{_agora.strftime('%Y%m%d')}G_#{_agora.strftime('%H%M%S')}G"
          if params[:commit] == 'Excel'
            headers['Content-Disposition'] = "attachment; filename=#{filename}.XLS"
            headers['content-Type'] ||= 'application/xls; charset=UTF-8; header=present'
            @acumulaByProjeto=[]
            soma(resultado.group_by {|t| [t[:objetoCusto],t[:centroCusto],t[:horaExtra]]}) {|x| @acumulaByProjeto << x}
            @acumulaByAtividade=[]
            soma(resultado.group_by {|t| [t[:objetoCusto], t[:codigoSAP],t[:centroCusto],t[:horaExtra]]}) {|x| @acumulaByAtividade << x}
            render :template => 'exporter/export.xls.erb', :layout => false
          end
          if params[:commit] == 'CSV'
            headers['Content-Disposition'] = "attachment; filename=#{filename}.CSV"
            headers['content-Type'] ||= 'text/csv; charset=UTF-8; header=present'
            @timeEntries = resultado
            render :template => 'exporter/export.csv.erb', :layout => false
          end}, lambda{|msg|
            flash[:error] = msg
            redirect_to exporter_timesheet_path
          })
    }, lambda{|msg|
      flash[:error] = msg
      redirect_to exporter_timesheet_path
    })
  end

  private
  def valida(dataInicio, dataTermino, fnSuccess, fnFail)
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
    fnSuccess.call _inicio, _fim
  end

  def execute(inicio, fim, fnSuccess, fnFail)
    parserSplit=ParserLambda.new(lambda{|v| v.split(' - ').first})
    parserSplitLast=ParserLambda.new(lambda{|v| v.split(' - ').last})
    parserUser=Parser.new('user')
    parserProject=Parser.new('project')
    parserActivity=Parser.new('activity')
    parserCFCC = ParserCustomField.new('UserCustomField','Centro de Custo')
    parserCentroCusto = ParserChained.new(parserUser, parserCFCC, parserSplit)
    parserCentroCustoDescricao = ParserChained.new(paserUser, parserCFCC, parserSplitLast)
    parserObjetoCusto = ParserChained.new(parserProject, ParserCustomField.new('ProjectCustomField', 'Centro de Custo do Projeto'))
    parserCodigoSAP = ParserChained.new(parserActivity, ParserCustomField.new('TimeEntryActivityCustomField','Código SAP'))
    parserMatricula = ParserChained.new(parserUser, ParserCustomField.new('UserCustomField','Número de Matrícula'))
    parserCFCargo = ParserCustomField.new('UserCustomField','Cargo')
    parserCargo = ParserChained.new(parserUser, parserCFCargo, parserSplit)
    parserCargoDescr = ParserChained.new(parserUser, parserCFCargo, parserSplitLast)
    packer = Packer.new({:data=> Parser.new('spent_on'),
      :qtd=> Parser.new('hours'),
      :nomeFuncionario=> Parser.new('user.name'),
      :projeto=> Parser.new('project.name'),
      :atividade=> Parser.new('activity.name'),
      :objetoCusto=> ParserOptional.new('N/A', parserObjetoCusto, parserCentroCusto),
      :codigoSAP=> ParserOptional.new('N/A', parserCodigoSAP),
      :matricula=> ParserOptional.new('N/A', parserMatricula),
      :centroCusto=> ParserOptional.new('N/A', parserCentroCusto),
      :centroCustoDescricao=> ParserOptional.new('N/A', parserCentroCustoDescricao),
      :cargo=> ParserOptional.new('N/A', parserCargo),
      :cargoDescricao=> parserCargoDescr

    resultado = TimeEntry.where(:spent_on=>(inicio..fim))
    .map {|t|
      packer.pack(t)
    }.group_by {|entry|
      [entry[:data], entry[:matricula], entry[:objetoCusto], entry[:codigoSAP]]
    }.flat_map {|k,v|
      v.reduce {|m,c|
        m[:qtd]+=c[:qtd]
        m
      }
    }.group_by {|entry| [entry[:data], entry[:matricula]]}
    .flat_map {|k,v|
      _total = v.reduce(0.0) {|m,e| m+=e[:qtd] }
      v.flat_map do |t|
        _resultado=[]
        _resultado << t
        verifyExtraTime(k[0], lambda {
          if _total > 8.0
            qtdExtra = _total - 8.0
            razao = t[:qtd] / _total
            novaEntrada = t.clone
            t[:qtd] = razao * 8.0
            t[:horaExtra] = 0.0
            novaEntrada[:qtd] = razao * qtdExtra
            novaEntrada[:horaExtra] = 50.0
            _resultado << novaEntrada
          else
            t[:horaExtra] = 0.0
          end
          }, lambda {
            t[:horaExtra] = 50.0
          }, lambda {
            t[:horaExtra] = 100.0
          })
        _resultado
      end
    }

    if resultado.empty?
      fnFail.call 'Nenhum registro encontrado!'
    else
      fnSuccess.call resultado
    end
  end

  def soma(listagem)
    listagem.each do |k,v|
      _temp=v.first.clone
      _temp[:qtd]=0.0
      yield v.reduce(_temp) {|acumulado, entry| 
        acumulado[:qtd]+=entry[:qtd]
        acumulado
      }
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
