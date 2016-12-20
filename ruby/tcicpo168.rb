require 'nokogiri'
require 'mechanize'
require 'json'
require 'csv'
require 'logger'

agent = Mechanize.new { |agent|
  agent.open_timeout   = 15
  agent.read_timeout   = 15
}
# agent.log = Logger.new(STDOUT)

# root = "/tmp/results"
root = "/Users/babak/Development/Source/smallmedia/tmp"

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


  cc.each {|c| cities << {state: state_select.text, city: c.text, code: c.value} unless c.value == '0'}

end


cities.each do |city|
  begin
    all = []
    errors =[]

    puts "---------------------------------------------"
    puts city[:city]
    puts
    city_page = agent.get("http://www.tebyan-masajed.ir/Modules/ShowmasajedInCity.aspx?CityId=#{city[:code]}")

    doc = Nokogiri::HTML(city_page.body)
    doc.encoding = 'utf-8'
    rows = doc.xpath('//table[@dir="rtl"]/tr/td/a')

    rows.each do |row|
      begin
        mosque_page = agent.get("http://www.tebyan-masajed.ir/Modules/#{row.to_h['href']}")
        mosque_page.encoding = 'utf-8'

        name = mosque_page.title.gsub('پورتال', '').strip

        detail = {state: city[:state], city: city[:city], name: name, code: row.to_h['href'].gsub('index.aspx?RegionId=', '')}

        puts detail[:name]

        all << detail
      rescue
        errors << row.to_h['href']
        next
      end
    end

    CSV.open("#{root}/tcicpo168.csv", "a+") do |csv|
    	all.each {|elem| csv << elem.values }
    end

    CSV.open("#{root}/tcicpo168.error.log", "a+") do |csv|
    	errors.each {|elem| csv << elem.values }
    end
  rescue => ex
    CSV.open("#{root}/tcicpo168.error.city.csv", "a+") do |csv|
    	csv << [city[:code], ex.message]
    end
  end
end
