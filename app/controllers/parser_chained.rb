class ParserChained
	def initialize(*parsers)
		@parsers=*parsers
	end

	def parse(e)
		yield @parsers.reduce(e) {|m,c| c.parse(m)}
	end
end