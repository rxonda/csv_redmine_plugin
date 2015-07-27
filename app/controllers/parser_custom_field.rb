class ParserCustomField
	def initialize(model,type,name,fnParser=lambda{|v| v})
		@model = model
		@customField = CustomField.where(:type => type, :name => name).first
		@fnDoParse = fnParser
	end

	def parse(e)
		_model = e.send(@model)
		if !_model.custom_value_for(@customField).blank? && !_model.custom_value_for(@customField).value.blank?
			yield @fnDoParse.call _model.custom_value_for(@customField).value
		end
	end
end