require 'nokogiri'
require 'mechanize'
require 'json'
require 'csv'
require 'logger'
require 'parallel'

agent = Mechanize.new { |agent|
  agent.open_timeout   = 15
  agent.read_timeout   = 15
}
# agent.log = Logger.new(STDOUT)

root = "/tmp/results"
# root = "/Users/babak/Development/Source/smallmedia/tmp"

cities = []

begin
  cities_file = File.read("#{root}/tcicpo168_cities.json")
  puts "Loading Cities"
  cities = JSON.parse(cities_file, {:symbolize_names => true})
rescue
end

if cities.length == 0
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

  File.open("#{root}/tcicpo168_cities.json","w") do |f|
    f.write(cities.to_json)
  end
end

p cities

Parallel.each(cities, :in_processes => 10) do |city|
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

    CSV.open("#{root}/tcicpo168-#{city[:code]}.csv", "w") do |csv|
    	all.each {|elem| csv << elem.values }
    end

    if errors.length > 0
      CSV.open("#{root}/tcicpo168-#{city[:code]}.error.log", "w") do |csv|
      	errors.each {|elem| csv << elem.values }
      # end
  end
  rescue => ex
    CSV.open("#{root}/tcicpo168-#{city[:code]}.error.city.csv", "w") do |csv|
    	csv << [city[:code], ex.message]
    end
  end

end
