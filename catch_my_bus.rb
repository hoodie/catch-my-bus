#!/usr/bin/env ruby
# encoding: utf-8
# This file is distributed under the terms of the
# GNU General Public License 2.
# Please see the COPYING-GPL-2 file for details.

require 'yaml'
require 'net/http'
require 'json'
require 'notify'
require 'pp'

$SCRIPT_PATH = File.split(File.expand_path(__FILE__))[0]

@big_sleep    = 180
@little_sleep = 2

config_file = 'config.yml'
config      = YAML.load_file(config_file)

class TramStation
  def initialize name
    @name = name
    @destinations= {}
  end

  def show
    puts @name
    puts print
    puts
  end

  def print
    string = ""
    @destinations.each do |name,times|
      string << "#{name} in\n"
      times.each { |t| string << " #{t}min " }
      string << "\n"
    end
    return string
  end
  def notify
    Notify.notify @name, print(), {app:"Catch My Bus", :icon => (File.join$SCRIPT_PATH, "Bushaltestelle.png" )}
  end

  def parse_arrival(arrival)
    arrival[2] = 0 if arrival[2] == ""
    arrival[2] = arrival[2].to_i
    dest = "#{arrival[0]} #{arrival[1]}"
    @destinations[dest] = [] if @destinations[dest].nil?
    @destinations[dest] << arrival[2]
  end

  def update
    @destinations= {}
    uri = URI URI::encode "http://widgets.vvo-online.de/abfahrtsmonitor/Abfahrten.do?ort=Dresden&hst=#{@name}&vz=0"
    JSON.parse(Net::HTTP.get(uri)).each do |json|
      parse_arrival(json)
    end
  end
end

config['stations'].map!{ |station| TramStation.new station }

while true do
  config['stations'].each do |station|
    station.update
    station.notify
    station.show
    sleep @little_sleep
  end
  sleep @big_sleep
end


