#!/usr/bin/env ruby

require "rubygems"
require "nokogiri"
require "open-uri"
require "colorize"
require "digest/sha1"

#
# Parse for finding a flat in Berlin because it's nuts!
#
class Geuscht

	attr_accessor :match

	NUM_ITERATIONS_FOR_BLINK = 20

	def initialize()    

		@protcol = "http://"
		@baseurl = "www.wg-gesucht.de"
		@language = "/en/"		
		@results_hashed = []
		@first_run = true
   	end

   	def monitor()

   		while true
   			parse()	   		
   		 	sleep 30
   		end
   	end

   	def parse()
				
		parse_url = @protcol + @baseurl + @language + "wohnungen-in-Berlin.8.2.0.0.html"
		doc = Nokogiri::HTML(open(parse_url))

		puts "Parsing details from ... " + parse_url + " \n"		
		rows = doc.xpath("//*[@id='table-compact-list']/tbody/tr")

		puts "\n## WG Gesucht Results ##\n".colorize(:blue)
		puts "Rooms\tListed\t\tAmount\tSize\tFrom\t\tTo\t\tLocation"

		rows.collect do |r|
			rooms = r.xpath("td[2]/a/span").text.strip
			date_listed = r.xpath("td[3]/a/span").text.strip
			rent = r.xpath("td[4]/a/span").text.strip
			link = ""
			r.xpath("td[4]/a").map { |l| 
				link = l['href']
			}
			size = r.xpath("td[5]/a/span").text.strip
			district = r.xpath("td[6]/a/span").text.strip
			from_date = r.xpath("td[7]/a/span").text.strip rescue ''
			until_date = r.xpath("td[8]/a/span").text.strip rescue ''

			if until_date.empty?
				until_date = "LongTerm"
			end

			if !district.include? "Airbnb" and !district.include? "ImmobilienScout24"			

				listing_link = "#{@baseurl}#{@language}#{link}"
				entry = "[#{rooms}]\t#{date_listed}\t#{rent}\t#{size}\t#{from_date}\t#{until_date}\t#{district} [#{listing_link}]"
				hashed_val = Digest::SHA1.hexdigest(entry)
				if should_highlight_cause_rules_match(rooms.to_i, rent.to_i)

					if @first_run == false and should_blink(hashed_val)
						puts entry.colorize(:green).blink
					else
						puts entry.colorize(:green)
					end
				else
					puts entry
				end				
				@results_hashed << hashed_val							
				@first_run = false
			end
		end
	end	

	def should_blink(hashed_val)
		
		if @results_hashed.include? hashed_val
			return false
		else
			return true
		end		
	end

	def should_highlight_cause_rules_match(rooms, rent)

		return true if 
			rooms > 1 and 
			rooms <= 3 and 
			rent < 850
	end
end

gesucht = Geuscht.new()
gesucht.monitor()