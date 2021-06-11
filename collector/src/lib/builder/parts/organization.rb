require 'pp'

module Organizations

    def publisher
        path = '$.datafield[?(@["_tag"] == "260" ||  @["_tag"] == "264" )].subfield[?(@["b"])]'
        marcf = JsonPath.on(@record, path)
        organizations = marcf.map {|organization|  parse_organization (organization) }
        return organizations
    end

end