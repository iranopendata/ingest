require 'nokogiri'
require 'mechanize'
require 'json'

agent = Mechanize.new

page = agent.get('http://avab.behdasht.gov.ir/hospital/')

ost_id = 10

form = page.form('form1')
form.field_with(:id => 'popOstId').options[ost_id].select
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

File.open("/tmp/results/mhmellih16.json","w") do |f|
  f.write(JSON.pretty_generate(details))
end
