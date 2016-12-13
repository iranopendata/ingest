require 'nokogiri'
require 'mechanize'
require 'json'
require 'csv'
require 'logger'

agent = Mechanize.new
# agent.log = Logger.new(STDOUT)

# retirive city codes
search_page = agent.get('http://www.tebyan-masajed.ir/')

search_form = search_page.form('f1')
c = search_form.field_with(:id => 'ParentID').options.count

cities = []

for i in 1..(c - 1) do
  state_select = search_form.field_with(:id => 'ParentID').options[i]

  state_select.select
  puts state_select.text

  page = agent.submit(search_form)
  form = page.form('f1')

  cc = form.field_with(:id => 'ParentID1').options

  cc.each {|c| p c.text}

  cc.each {|c| cities << {state: state_select.text, city: c.text, code: c.value} unless c.value == '0'}

end

all = []
cities.each do |city|
  city_page = agent.get("http://www.tebyan-masajed.ir/Modules/ShowmasajedInCity.aspx?CityId=#{city[:code]}")

  doc = Nokogiri::HTML(city_page.body)
  doc.encoding = 'utf-8'
  rows = doc.xpath('//table[@dir="rtl"]/tr/td/a')

  rows.each do |row|
    mosque_page = agent.get("http://www.tebyan-masajed.ir/Modules/#{row.to_h['href']}")
    mosque_page.encoding = 'utf-8'

    name = mosque_page.title.gsub('پورتال', '').strip

    detail = {state: city[:state], city: city[:city], name: name, code: row.to_h['href'].gsub('index.aspx?RegionId=', '')}

    all << detail

  end

end

p all

CSV.open("/tmp/results/tcicpo168.csv", "wb") do |csv|
	all.each {|elem| csv << elem.values }
end
