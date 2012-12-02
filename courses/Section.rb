class Section
	attr_accessor :section_num, :open_spots, :max, :crn, :instructor, :time, :location

	def initialize(section_num, open_spots, max_spots, crn, instructor, time, location)
		@section_num = section_num
		@open_spots = open_spots
		@max_spots = max_spots
		@crn = crn
		@instructor = instructor
		@time = time
		@location = location
	end

end