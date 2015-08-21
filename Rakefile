require 'bundler'
Bundler.require 

require 'sinatra/activerecord/rake'
require './models/listing'

ActiveRecord::Base.establish_connection({
  adapter: 'postgresql',
  database: 'easylistings'
})

namespace :db do

	desc "Add_Listing API"  	
		page_num = 1
		page = Nokogiri::HTML(RestClient.get("http://streeteasy.com/for-sale/brooklyn?page=#{page_num+1}"))
		arr = page.css('div.details-title').text 
		price = page.css("div.price-info span.price").text
		cprice = price.gsub! "$", " $"
		splrice = cprice.split(" ")
		array = arr.split("SAVE")

			array.each do |e|
				hash = {}
				hash[:address] = e
				

			Listing.create(hash)
		end		
	end
end