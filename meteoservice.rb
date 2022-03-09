require 'uri'
require 'net/http'

require 'rexml/document'
require 'json'

require 'date'

CLOUDINESS = %w[Ясно Малооблачно Облачно Пасмурно].freeze
TIMES_OF_DAY = %w[Ночь Утро День Вечер].freeze

cities = JSON.parse(File.read("#{__dir__}/data/cities.json"))

puts 'Погоду для какого города Вы хотите узнать?'

cities.each.with_index(1) do |(city_name, _), index|
  puts "#{index}: #{city_name}"
end

user_input = STDIN.gets.to_i

until user_input.between?(1, cities.size)
  puts 'Введите соответствующий городу номер'
  user_input = STDIN.gets.to_i
end

city = cities.keys[user_input - 1]

# http://www.meteoservice.ru/content/export.html
uri = URI.parse("https://xml.meteoservice.ru/export/gismeteo/point/#{cities[city]}.xml")
response = Net::HTTP.get_response(uri)

doc = REXML::Document.new(response.body)

city_name = URI.decode_www_form_component(
  doc.root.elements['REPORT/TOWN'].attributes['sname']
)

puts
puts "* * * #{city_name} * * *"
puts

doc.root.elements.each('REPORT/TOWN/FORECAST') do |forecast|
  min_temp = forecast.elements['TEMPERATURE'].attributes['min'].to_i
  max_temp = forecast.elements['TEMPERATURE'].attributes['max'].to_i

  max_wind = forecast.elements['WIND'].attributes['max']

  clouds_index = forecast.elements['PHENOMENA'].attributes['cloudiness'].to_i
  clouds = CLOUDINESS[clouds_index]

  year = forecast['year']
  month = forecast['month']
  day = forecast['day']

  date = "#{year}-#{month}-#{day}" == Date.today.to_s ? 'Сегодня' : "#{day}.#{month}.#{year}"
  time_of_day_index = forecast['tod'].to_i
  time_of_day = TIMES_OF_DAY[time_of_day_index]

  min_range_value =
    min_temp.positive? ? "+#{min_temp}" : "#{min_temp}"

  max_range_value =
    max_temp.positive? ? "+#{max_temp}" : "#{max_temp}"

  temp_range = min_range_value..max_range_value

  puts "#{date}, #{time_of_day}"
  puts "#{temp_range}, ветер #{max_wind} м/с, #{clouds}"

  puts "Температура — от #{min_temp} до #{max_temp} С"
  puts "Ветер #{max_wind} м/с"
  puts clouds
  puts
end

puts '«Предоставлено Meteoservice.ru» сайт - https://www.meteoservice.ru'
