require 'rubygems'
require 'mechanize'
require "active_support"
require "active_support/core_ext/object"

def perform_netflix_login(mechanize_object)
	login_successful = false
	mechanize_object.get('https://www.netflix.com/login/') do |page|
		puts "Enter your Netflix username or email: "
		my_username = gets
		puts "Enter your Netflix password:"
		my_password = gets

		login_form = page.forms.first
		login_form.fields.select{ |i| i.name == "userLoginId" }.first.value = my_username.chomp
		login_form.fields.select{ |i| i.name == "password" }.first.value = my_password.chomp
		sleep(0.5)
		new_page = login_form.submit
		sleep(0.5)
		
		profile_link_text = new_page.links.map{ |i| i.text.strip }
		allowed_page_links = profile_link_text.select{ |i| !(["add profile", "manage profiles"].include?(i.downcase)) }
		
		if allowed_page_links.empty? || allowed_page_links.first.downcase.chomp == "netflix"
			puts "No profiles associated with login info."
		else
			puts "Profiles available: "
			allowed_page_links.each do |i|
				puts i
			end
			puts "Enter profile to use: "
	 		my_profile = gets
	 		selected_profile_links = new_page.links.select{ |i| i.text.strip.downcase == my_profile.chomp.downcase }
	 		if selected_profile_links.any?
	 			selected_profile_links.first.click
	 			login_successful = true
	 		else
	 			puts "Profile not found."
	 		end
		end
	end
	login_successful
end

def prompt_for_search(mechanize_object)
	user_input = ""
	while user_input != "0"
		puts "Enter a title to search for or 0 to quit."
		user_input = gets
		user_input = user_input.chomp.gsub(' ', '%20')
		if user_input != "0"
			perform_search(mechanize_object, user_input)
		else
			puts "Bye!"
			perform_logout(mechanize_object)
		end
	end
end

def perform_search(mechanize_object, user_input)
	search_url = "https://www.netflix.com/search?q=" + user_input
	mechanize_object.get(search_url) do |page|
		begin
			if page.parser.xpath('//*[@id="title-card-0-0"]/div[1]/a').first.attributes["aria-label"].present?
				puts "Here is the first search result: "
				puts page.parser.xpath('//*[@id="title-card-0-0"]/div[1]/a').first.attributes["aria-label"].value.to_s
			else
				puts "Could not find a result for #{user_input.inspect}"
			end
		rescue
			puts "Hit error performing search for #{user_input.inspect}"
		end
	end
end

def perform_logout(mechanize_object) 
	mechanize_object.get('https://www.netflix.com/logout') do |page|
		sleep(0.2)
		new_page = page.links.select{ |i| i.text.strip.downcase == "go now" }.first.click
	end
end

this_webpage = Mechanize.new
if perform_netflix_login(this_webpage)
	prompt_for_search(this_webpage)
end


