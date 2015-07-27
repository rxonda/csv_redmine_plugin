class ParserCustomField
	def initialize(type,name)
		@customField = CustomField.where(:type => type, :name => name).first
	end

	def parse(e)
		if !e.custom_value_for(@customField).blank? && !e.custom_value_for(@customField).value.blank?
			yield e.custom_value_for(@customField).value
		end
	end
end