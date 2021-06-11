require 'pp'
require 'logger'

## Marc Tags 020 022 024 en 028

module Identifiers

    def identifiers_same_as
        path = '$.datafield[?(@["_tag"] == "020" || @["_tag"] == "022" ||  @["_tag"] == "024" ||  @["_tag"] == "028")].subfield'
        marcf = JsonPath.on(@record, path)

        output_templ = '{#{0}}'
        subfields_config = {
            :"#{0}" => {
                :transformation => Proc.new {  |s| s.to_s.gsub(/^\((uri|URI)\)[\s]*/, '') },
                :delimiter => ", "
            }
        }
        parse_marcfields(marcf: marcf, output_templ: output_templ, subfields_config: subfields_config )
    end


    def identifiers_isbn
        path = '$.datafield[?(@["_tag"] == "020")].subfield'
        marcf = JsonPath.on(@record, path)
        
        output_templ = '{#{a}}{ #{c}}{ #{z}}'
        subfields_config = {
            :a => {
                :transformation => Proc.new {  |s| s.to_s },
                :delimiter => ", "
            },
            :c => {
                :transformation => Proc.new {  |s| s.to_s },
                :delimiter => ", "
            },
            :z => {
                :transformation => Proc.new {  |s| s.to_s },
                :delimiter => ", "
            }
        }
        parse_marcfields(marcf: marcf, output_templ: output_templ, subfields_config: subfields_config )
    end

    def identifiers_issn
        path = '$.datafield[?(@["_tag"] == "022")].subfield'
        marcf = JsonPath.on(@record, path)
        
        output_templ = '{#{a}}{ #{2}}'
        subfields_config = {
            :a => {
                :transformation => Proc.new {  |s| s.gsub(/^\((uri|URI)\)[\s]*/, '') },
                :delimiter => ", "
            }
        }
        parse_marcfields(marcf: marcf, output_templ: output_templ, subfields_config: subfields_config )
    end

    def identifiers_ismn
        path = '$.datafield[?(@["_tag"] == "024" && @["_ind1"] == "2")].subfield'
        marcf = JsonPath.on(@record, path)
        output_templ = '{#{a}}'
        parse_marcfields(marcf: marcf, output_templ: output_templ)
    end

    def identifiers_ean
        path = '$.datafield[?(@["_tag"] == "024" && @["_ind1"] == "3")].subfield'
        marcf = JsonPath.on(@record, path)
        output_templ = '{#{a}}'
        parse_marcfields(marcf: marcf, output_templ: output_templ)
    end

    def identifiers_oth_id
        path = '$.datafield[?(@["_tag"] == "028" && @["_ind2"] == "0")].subfield'
        marcf = JsonPath.on(@record, path)
        
        output_templ = '{#{a}}{ (#{b}}{ #{q})}'
        subfields_config = {
            :a => {
                :transformation => Proc.new {  |s| s.to_s },
                :delimiter => ", "
            },
            :b => {
                :transformation => Proc.new {  |s| s.to_s },
                :delimiter => ", "
            },
            :q => {
                :transformation => Proc.new {  |s| s.to_s },
                :delimiter => ", "
            }
        }
        parse_marcfields(marcf: marcf, output_templ: output_templ, subfields_config: subfields_config )
    end
    
    def identifiers
        identifiers = {}
        
        identifiers["ISBN"] = identifiers_isbn

        identifiers["ISSN"] = identifiers_issn

        identifiers["ISMN"] = identifiers_ismn

        identifiers["EAN"] = identifiers_ean

        identifiers["Other identifier"] = identifiers_oth_id
                
        ######### Remove if array if empty ""
        identifiers.delete_if { |k, v| v.empty? }
        identifiers unless identifiers.empty?
    end
end
