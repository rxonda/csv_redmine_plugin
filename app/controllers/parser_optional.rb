class ParserOptional
	def initialize(default,*parsers)
		@default=default
		@parsers=*parsers
	end

	def parse(e)
		resultado = nil
		@parsers.each do |x|
			x.parse(e) {|t| resultado||=t}
		end
		yield resultado||@default
	end
end