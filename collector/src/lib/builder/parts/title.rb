require 'pp'
require 'logger'
## Marc Tags 130, 210, 242, 245, 246

module Titles
    
    def title_same_as
        path = '$.datafield[?(@["_tag"] == "130" || @["_tag"] == "245" ||  @["_tag"] == "242" ||  @["_tag"] == "246")].subfield'
        marcf = JsonPath.on(@record, path)

        output_templ = '{#{0}}'
        subfields_config = {
            :"#{0}" => {
                :transformation => Proc.new {  |s| s.gsub(/^\((uri|URI)\)[\s]*/, '') },
                :delimiter => ","
            }
        }
        parse_marcfields(marcf: marcf, output_templ: output_templ, subfields_config: subfields_config).map { |s| s.split(",") } .flatten
    end

    def uniform_title
        path = '$.datafield[?(@["_tag"] == "130" || @["_tag"] == "240") ].subfield[?(@["9"].include? "Y" || !@["9"])] || $.datafield[?(@["_tag"] == "830" ||'
        marcf = JsonPath.on(@record, path)

        output_templ = '{#{a}}{, #{b}}{ (#{f})}{ (#{g})}{ [#{l}]}{ #{m}}{ , #{o}}{ , #{p}}{ , #{r}}{ , #{s}}'
        subfields_config = {
            :a => {
                :transformation => Proc.new {  |s| s.gsub(/[\/:;=.,]$/, "") },
                :delimiter => ", "
            },
            :b => {
                :transformation => Proc.new {  |s| s.gsub(/[\/:;=.,]$/, "") },
                :delimiter => " "
            },
            :f => {
                :transformation => Proc.new {  |s| s.gsub(/[\/:;=.,]$/, "") },
                :delimiter => " "
            },
            :g => {
                :transformation => Proc.new {  |s| s.gsub(/[\/:;=.,]$/, "") },
                :delimiter => " "
            },
            :l => {
                :transformation => Proc.new {  |s| s.gsub(/[\/:;=.,]$/, "") },
                :delimiter => " "
            },
            :m => {
                :transformation => Proc.new {  |s| s.gsub(/[\/:;=.,]$/, "") },
                :delimiter => " "
            },
            :o => {
                :transformation => Proc.new {  |s| s.gsub(/[\/:;=.,]$/, "") },
                :delimiter => " "
            },
            :p => {
                :transformation => Proc.new {  |s| s.gsub(/[\/:;=.,]$/, "") },
                :delimiter => " "
            },
            :r => {
                :transformation => Proc.new {  |s| s.gsub(/[\/:;=.,]$/, "") },
                :delimiter => " "
            },
            :s => {
                :transformation => Proc.new {  |s| s.gsub(/[\/:;=.,]$/, "") },
                :delimiter => " "
            }
        }

        parse_marcfields(marcf: marcf, output_templ: output_templ, subfields_config: subfields_config )
    end

    def abbreviated_title
        path = '$.datafield[?(@["_tag"] == "210")].subfield[?(@["9"].include? "Y" || !@["9"])]'
        marcf = JsonPath.on(@record, path)
        output_templ = '{#{a}}'
        subfields_config = {
            :a => {
                :transformation => Proc.new {  |s| s.gsub(/[\/:;=.,]$/, "") },
                :delimiter => ", "
            }
        }
        parse_marcfields(marcf: marcf, output_templ: output_templ, subfields_config: subfields_config )
    end

    def translated_title
        path = '$.datafield[?(@["_tag"] == "242")].subfield[?(@["9"].include? "Y" || !@["9"])]'
        marcf = JsonPath.on(@record, path)
        
        output_templ = '{#{a}}{ #{b}}'
        subfields_config = {
            :a => {
                :transformation => Proc.new {  |s| s.gsub(/[\/:;=.,]$/, "") },
                :delimiter => ", "
            },
            :b => {
                :transformation => Proc.new {  |s| s.gsub(/[\/:;=.,]$/, "") },
                :delimiter => " "
            }
        }
        parse_marcfields(marcf: marcf, output_templ: output_templ, subfields_config: subfields_config )
    end

    def other_title
        path = '$.datafield[?(@["_tag"] == "246")].subfield[?(@["9"].include? "Y" || !@["9"])]'
        marcf = JsonPath.on(@record, path)

        output_templ = '{#{a}}{, #{b}}{ (#{f})}{ (#{g})}{ [#{l}]}{ #{m}}{ , #{o}}{ , #{p}}{ , #{r}}{ , #{s}}'
        subfields_config = {
            :a => {
                :transformation => Proc.new {  |s| s.gsub(/[\/:;=.,]$/, "") },
                :delimiter => ", "
            },
            :b => {
                :transformation => Proc.new {  |s| s.gsub(/[\/:;=.,]$/, "") },
                :delimiter => " "
            },
            :f => {
                :transformation => Proc.new {  |s| s.gsub(/[\/:;=.,]$/, "") },
                :delimiter => " "
            },
            :g => {
                :transformation => Proc.new {  |s| s.gsub(/[\/:;=.,]$/, "") },
                :delimiter => " "
            },
            :l => {
                :transformation => Proc.new {  |s| s.gsub(/[\/:;=.,]$/, "") },
                :delimiter => " "
            },
            :m => {
                :transformation => Proc.new {  |s| s.gsub(/[\/:;=.,]$/, "") },
                :delimiter => " "
            },
            :o => {
                :transformation => Proc.new {  |s| s.gsub(/[\/:;=.,]$/, "") },
                :delimiter => " "
            },
            :p => {
                :transformation => Proc.new {  |s| s.gsub(/[\/:;=.,]$/, "") },
                :delimiter => " "
            },
            :r => {
                :transformation => Proc.new {  |s| s.gsub(/[\/:;=.,]$/, "") },
                :delimiter => " "
            },
            :s => {
                :transformation => Proc.new {  |s| s.gsub(/[\/:;=.,]$/, "") },
                :delimiter => " "
            }
        }
        parse_marcfields(marcf: marcf, output_templ: output_templ, subfields_config: subfields_config )
    end

    def title()
        path = '$.datafield[?(@["_tag"] == "245)].subfield'
        marcf = JsonPath.on(@record, path)

        output_templ = '{#{a}}{, #{b}}{ #{n} }{ #{p}}'
        subfields_config = {
            :a => {
                :transformation => Proc.new {  |s| s.gsub(/[\/:;=.,]$/, "") },
                :delimiter => " - "
            },
            :b => {
                :transformation => Proc.new { |s| s.gsub(/[\/:;=.,]$/, "").to_s.match(/^<{0,2}([^>]{2})>{0,2}(.*)/).to_s.gsub(/(^..)\s/, "") },
                :delimiter => " "
            },
            :n => {
                :transformation => Proc.new {  |s| s.gsub(/[\/:;=.,]$/, "") },
                :delimiter => " "
            },
            :p => {
                :transformation => Proc.new {  |s| s.gsub(/[\/:;=.,]$/, "") },
                :delimiter => ", "
            }
        }
        parse_marcfields(marcf: marcf, output_templ: output_templ, subfields_config: subfields_config )
    end

end