#!/usr/bin/env ruby
 
require 'rubygems'
require 'mechanize'
require 'yaml'
require 'awesome_print'
require 'nokogiri'
require 'open-uri'
require 'highline/import'
require 'webrick'
require 'json'

class Department
	attr_accessor :deptname, :deptkey, :courses

	def initialize(dept, key)
		@deptname = dept
		@deptkey = key
		@courses = Array.new
	end

	def add(value)
		@courses.push(value)
	end

	def courses
		@courses
	end

	def getSubject(agent, subject)
		#subj_form.field_with(:name=>"SUBJ").options.first.unselect
		
		page_form = agent.get('https://was.nd.edu/reg/srch/ClassSearchServlet').form()
		select = page_form.field_with(:name => "SUBJ")
		
		select.select_none()

		pp subject

		#pp select.
		select.options_with(:value => "#{subject}").each do |field|
			field.select
		end
		 
		response = agent.submit(page_form)
		#pp page.body
		results = response.body
		 
		doc = Nokogiri::HTML(results, 'UTF-8')

		parseHTML(doc, subject)
	end

	def parseHTML(doc, subject)
		#Find nodes by XPATH
		rows = doc.xpath('//table[@id="resulttable"]/tbody/tr')
		#cells = rows.css('td')
		details = rows.collect do |row|
		        detail = {}
		        [
		        		[:subject, subject],
		                [:course, 'td[1]/a[1]'],
		                [:section, 'td[1]/a[1]'],
		                [:title, 'td[2]'],
		                [:credits, 'td[3]'],
		                [:status, 'td[4]'],
		                [:max_spots, 'td[5]'],
		                [:open_spots, 'td[6]'],
		                [:xlst, 'td[7]'],
		                [:crn, 'td[8]'],
		                [:syl, 'td[9]'],
		                [:instructor, 'td[10]/a'],
		                [:when, 'td[11]'],
		                [:begin, 'td[12]'],
		                [:end, 'td[13]'],
		                [:location, 'td[14]'],
		        ].each do |name, xpath|
		        		# Want to loop through each cell/detail, then perform actions accordingly
		        		if name == :course
		                	detail[name] = row.xpath(xpath).text.strip.split('-').first.strip
		                	#pp detail[name]
		            	elsif name == :section
		                	detail[name] = row.xpath(xpath).text.strip.split('-').last.strip
		                	#pp detail[name]
		                elsif name == :subject
		                	detail[name] = subject
		            	else
		                	detail[name] = row.xpath(xpath).text.strip
		                	#pp detail[name]          		
		            	end       	
		        end
		        detail
		end
		 
		#pp details
		# Let's build our Courses array!

		prev = ''
		#c = Course.new(nil, nil, nil)
		details.each do |d|
			#temp = Course.new(d[:title], d[:course], d[:credits])

			#pp prev
			#unless @courses.empty?
			#Check if the course number already exists in the array
			if d[:course] == prev
					#loc = @courses.find_index{|course| course.name == d[:title]}
				s = Section.new(d[:section], d[:open_spots], d[:max_spots], d[:crn], d[:instructor], d[:when], d[:location])
					#c.add(s)
				@courses.last.add(s)

			else
				c = Course.new( d[:title], d[:course], d[:credits])
				s = Section.new(d[:section], d[:open_spots], d[:max_spots], d[:crn], d[:instructor], d[:when], d[:location])
				c.add(s)
				add(c)
			end

			unless d[:course] == nil
				prev = d[:course]
			end

		end
		#exportHash(subject, @courses)
		#exportJSON(subject, @courses)

		#@courses.each do |co|
		#	pp co
		#end
	end

	def exportHash(subject, courselist)
		File.open("courses/#{subject}.yml", File::WRONLY|File::CREAT) do |file|
			file.write courselist.to_yaml
		end
	end

	def exportJSON(subject, courselist)
		File.open("courses/#{subject}.json", File::WRONLY|File::CREAT) do |file|
			file.write courselist.to_json
		end
	end

end

class Course
	attr_accessor :title, :credits,:course_no, :sections

	def initialize(name, coursenum, credit)
		@title = name
		@credits = credit
		@course_no = coursenum
		@sections = Array.new
	end

	def add(value)
		@sections.push(value)
	end

	def coursenum
		@coursenum
	end

	def title
		@title
	end

	def credits
		@credits
	end
end

class Section
	attr_accessor :section_num, :open_spots, :max_spots, :crn, :instructor, :time, :location

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

def exportHashDept(departments)
	File.open("courses/departments.yml", File::WRONLY|File::CREAT) do |file|
		file.write departments.to_yaml
	end
end

def exportHashJSON(departments)
	File.open("courses/departments.json", File::WRONLY|File::CREAT) do |file|
		file.write departments.to_json
	end
end

departments = []
a = Mechanize.new
page = a.get('https://was.nd.edu/reg/srch/ClassSearchServlet')

value = nil
subj_form = page.form()
	 
options = subj_form.field_with(:name=>"SUBJ").options

options.each { |op|
	dept = Department.new(op.text.strip, op.value.strip)
	dept.getSubject(a, dept.deptkey)
	departments.push(dept)
	#pp op.text.strip
	#getSubject(a, op)
}
	exportHashJSON(departments)
	exportHashDept(departments)

