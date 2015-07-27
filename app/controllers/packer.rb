class Packer
	def initialize(fields)
		@fields=fields
	end

	def pack(e)
		retorno = {}
		@fields.each do |k,v|
			v.parse(e) {|x| retorno[k] = x}
		end
		retorno
	end
end