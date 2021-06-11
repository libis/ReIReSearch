require 'pp'
require 'logger'

module Descriptions

    def description
        description = []

        path = '$.datafield[?(@["_tag"] == "245")].subfield[?(@["c"])]'
        marcf = JsonPath.on(@record, path)
        
        output_templ = '{#{c}}'
        subfields_config = {
            :c => {
                :transformation => Proc.new {  |s| s.to_s },
                :delimiter => ", "
            }
        }
        ############# Retruns 1 string ##########
        description << ( parse_marcfields(marcf: marcf, output_templ: output_templ, subfields_config: subfields_config ) ).join("\n'")

        path = '$.datafield[?(@["_tag"] == "500")].subfield[?(@["a"])]'
        marcf = JsonPath.on(@record, path)
        
        output_templ = '{#{a}}'
        subfields_config = {
            :a => {
                :transformation => Proc.new {  |s| s.to_s },
                :delimiter => ", "
            }
        }
        ############# Retruns 1 string ##########
        description << ( parse_marcfields(marcf: marcf, output_templ: output_templ, subfields_config: subfields_config ) ).join("\n'")

        path = '$.datafield[?(@["_tag"] == "505")].subfield'
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
        description << ( parse_marcfields(marcf: marcf, output_templ: output_templ, subfields_config: subfields_config ) ).join("\n'")

        path = '$.datafield[?(@["_tag"] == "953")].subfield[?(@["a"])]'
        marcf = JsonPath.on(@record, path)
        
        output_templ = '{Period of publication :  #{a}}'
        subfields_config = {
            :a => {
                :transformation => Proc.new {  |s| s.to_s },
                :delimiter => ", "
            }
        }
        ############# Retruns 1 string ##########
        description << ( parse_marcfields(marcf: marcf, output_templ: output_templ, subfields_config: subfields_config ) ).join("\n'")

        description.reject! { |d| d.empty? }
        description.flatten(1)  unless description.empty?
    end
    
end
