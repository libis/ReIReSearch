require 'pp'
require 'logger'

module Abouts
    def about
        path = '$.datafield[?(@["_tag"] == "600" ||  @["_tag"] == "610" ||  @["_tag"] == "630" ||  @["_tag"] == "648" ||  @["_tag"] == "650" ||  @["_tag"] == "651")].subfield'
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
        ############# Retruns 1 string ##########
        ( parse_marcfields(marcf: marcf, output_templ: output_templ, subfields_config: subfields_config ) ).join("\n'")

    end
end
