class Parser
	def initialize(name)
		@name = name
	end

	def parse(e)
		yield @name.split('.').reduce(e) {|r,c| r.send(c)}
	end
end