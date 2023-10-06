#!/usr/bin/env ruby

require "net/http"
require "uri"

url = 'https://people.math.sc.edu/Burkardt/data/wav/thermo.wav'

uri = URI.parse(url)
response = Net::HTTP.get_response(uri)
puts response.body.size
