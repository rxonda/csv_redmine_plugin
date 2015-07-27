class ParserLambda
def initialize(fnParser=lambda{|v| v})
		@fnDoParse = fnParser
	end

	def parse(e)
		yield @fnDoParse.call e
	end
end