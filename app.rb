require 'bundler'
Bundler.require

require './models/listing'

ActiveRecord::Base.establish_connection({
  adapter: 'postgresql',
  database: 'easylistings'
})

require 'nokogiri'
require 'mechanize'
require 'rsolr'
require 'json'
require 'pry'
require 'json'
require 'rsolr'
require 'httparty'
require 'net/http'

agent = Mechanize.new

url = 'http://streeteasy.com/for-sale/brooklyn'

begin
  page = agent.get(url)
rescue Exception => e
  page = e.page
end

another_page = true
page_num = 271   

while another_page == true

  listing = page.search('div.photo a').map do |link|
  page_url = link.attr('href')
  listing_page = agent.get("#{page_url}")
  # realtor = listing_page.search('div.subtitle.no_bottom_margin').text == nil ? "" : listing_page.search('div.subtitle.no_bottom_margin').text
  realtor = listing_page.search('div.subtitle.no_bottom_margin').text 
    int_realtor = realtor == nil ? "" : realtor.split(":")[1]
  broker = listing_page.search('div#agent-promo a') ? listing_page.search('div#agent-promo a')[1]: ""
  listing_type = listing_page.search('span.nobreak') ? listing_page.search('span.nobreak')[0].text : ""
  listing = listing_page.search('h1.building-title a').text
  footage = listing_page.search('div.details_info span').text
    int_footage = footage.match(/[a-zA-Z]|./) == nil ? "" : footage
  price = listing_page.search('div.price').text
    int_price = price == nil ? "" : price.split('f').map(&:strip)[0].split('$')[1]
  beds = listing_page.search('div.details_info span')[3].text.split(' ')[0] 
    int_beds = beds == nil ? "" : beds.split(' ')[0] 
  baths = listing_page.search('div.details_info span')[4] == nil ? "" : listing_page.search('div.details_info span')[4].text
  area = listing_page.search('div.details_info').search('a').last.text
  zipcode = listing_page.search('div.in_this_building.big_separator p').text
    int_zipcode  = zipcode == nil ? "" : zipcode.split(" ")[5]
  id = listing_page.search('div.actions-buttons a').map {|nd| nd['data-gtm-item-id']}[0] 
  {
    id: id,
    broker: int_realtor == nil ? "" : int_realtor.strip,
    agents: broker ? broker.text : "",
    full_street_address: listing,
    sq_ft: int_footage == nil ? "" : int_footage.split[0].gsub(/,/,'').to_i,
    price: int_price == nil ? "" : int_price.gsub(/[^0-9]/,''),
    city: 'Brooklyn',
    state: 'New-York',
    zip: int_zipcode.to_i,
    neighborhood: area,
    borough: 'Brooklyn',
    bedrooms: int_beds.to_i,
    baths: baths.to_i,
    listing_type: "Sale",
    property_category: listing_type == nil ? "" : listing_type,
    key: id,
    streeteasy_url: 'http://streeteasy.com' + page_url,
    } 
  end
  
    uri = URI('http://solr-dev.we3.com:8983/solr/streeteasy-listings/update?commit=true')
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Post.new(uri, initheader = {'Content-Type' =>'application/json'})
    req.body = listing.to_json
    res = http.request(req)
      puts "response #{res.body}" + "#{page_num}"

  if page_num == 283
    another_page = false # stops the loop from running again
  else
    page = agent.get("http://streeteasy.com/for-sale/brooklyn?page=#{page_num+1}")
  end
  page_num += 1
end

get '/solr' do
  solr = RSolr.connect :url => 'http://solr-dev.we3.com:8983/solr/streeteasy-listings/update?commit=true'
  solr.get 'select', :params => {:wt => :json}
end

get '/api/listings' do
    content_type :json
    listing.to_json
end

