require 'nokogiri'
require 'mechanize'
require 'json'
require 'csv'

agent = Mechanize.new


# osts = [3,4,24,10,32,16,18,23,14,30,9,29,6,19,20,11,7,26,25,27,2,15,1,28,22,13,21,12,8,5,17]
osts = [32]

page = agent.get('http://avab.behdasht.gov.ir/hospital/')
form = page.form('form1')
c = form.field_with(:id => 'popOstId').options.count

all = []
for i in 1..(c - 1) do
	form = page.form('form1')
	s = form.field_with(:id => 'popOstId').options[i]
	puts s.text

	s.select
	page = agent.submit(form)

	doc = Nokogiri::HTML(page.body)
	doc.encoding = 'utf-8'
	rows = doc.xpath('//table[@id="dgHospital"]/tr')

	# remove header
	rows.shift

	details = rows.collect do |row, index|
		  detail = {}
	    [
				[:name, 'td[3]/font/text()'],
				[:city, 'td[4]/font/text()'],
				[:address, 'td[5]/font/text()'],
				[:tel, 'td[6]/font/text()'],
	    ].each do |name, xpath|
		    detail[name] = row.at_xpath(xpath).to_s.strip
		  end
	    detail
	end

	all += details
end

CSV.open("/tmp/results/mhmellih16.csv", "wb") do |csv|
	all.each {|elem| csv << elem.values }
end

# File.open("/tmp/results/mhmellih16.json","w") do |f|
#   f.write(JSON.pretty_generate(details))
# end
