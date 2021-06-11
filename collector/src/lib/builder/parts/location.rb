require 'pp'
require 'logger'

module Locations

    def locationCreated
        path = '$.datafield[?(@["_tag"] == "260" ||  @["_tag"] == "264" )].subfield[?(@["a"])]'
        marcf = JsonPath.on(@record, path)
        locations = marcf.map {|location|  parse_location(location) }

        path = '$.datafield[?(@["_tag"] == "710")].subfield[?(@["4"].include? "prt")]'
        marcf = JsonPath.on(@record, path)
        temp_locations = marcf.map {|location| location["a"] = location["c"]; location }
        temp_locations = temp_locations.map {|location|   parse_location(location)  }
        locations << temp_locations unless temp_locations.empty?
        return locations unless locations.empty?
        return nil
    end

end