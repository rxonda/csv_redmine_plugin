class ParserChained
	def initialize(*parsers)
		@parsers=*parsers
	end

	def parse(e)
		result = e
		@parsers.each {|p|
			p.parse(result) {|x| result = x}
		}
		yield result
	end
end