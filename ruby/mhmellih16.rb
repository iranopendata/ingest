require 'nokogiri'
require 'mechanize'
require 'json'
require 'csv'

agent = Mechanize.new

main_page = agent.get('http://avab.behdasht.gov.ir/hospital/')
main_form = main_page.form('form1')
c = main_form.field_with(:id => 'popOstId').options.count

all = []
for i in 1..(c - 1) do
	ost_select = main_form.field_with(:id => 'popOstId').options[i]
	ost_select.select
	puts ost_select.text

	page = agent.submit(main_form)
	form = page.form('form1')

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

			inner_button_name = row.at_xpath('td[1]/font/input/@name').to_s.strip

			page = agent.submit(main_form)
			form = page.form('form1')
			button = form.button_with(:name => inner_button_name)
			inner_page = agent.click(button)

			inner_form = inner_page.form('form1')
			inner_doc = Nokogiri::HTML(inner_page.body)
			inner_doc.encoding = 'utf-8'

			[
				[:soc_id, "//*[@id='lblSocId']/text()"],
				[:hsp_type, "//*[@id='lblHspType']/text()"],
				[:bed_count, "//*[@id='lblBedCount']/text()"],
				[:spc_type, "//*[@id='lblSpcType']/text()"],
				[:ward1, "//*[@id='lblWard1']/text()"],
				[:ward2, "//*[@id='lblWard2']/text()"],
				[:ward3, "//*[@id='lblWard3']/text()"],
				[:ward4, "//*[@id='lblWard3']/text()"],
				[:email, "//*[@id='hlWebSite']/text()"],
			].each do |name, xpath|
				detail[name] = inner_doc.at_xpath(xpath).to_s.strip
			end
			puts detail[:name]

	    detail
	end

	all += details
end

CSV.open("/tmp/results/mhmellih16.csv", "wb") do |csv|
	all.each {|elem| csv << elem.values }
end
