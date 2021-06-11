require 'pp'
require 'logger'

module RelatedWorks

    def isPartOf
        path = '$.datafield[?(@["_tag"] == "490")].subfield[?(@["a"])]'
        marcf = JsonPath.on(@record, path)
        
        output_templ = '{#{a}}'
        subfields_config = {
            :a => {
                :transformation => Proc.new {  |s| s.to_s },
                :delimiter => ", "
            }
        }
        output = parse_marcfields(marcf: marcf, output_templ: output_templ, subfields_config: subfields_config )
        output.map! { |o| 
            creativework = { :name => o }
            parse_creative_work (creativework) 
        }
        return output unless output.empty?
    end   

    def translationOfWork
        path = '$.datafield[?(@["_tag"] == "775")].subfield[?(@["4"].include? "765")]'
        marcf = JsonPath.on(@record, path)

        output_templ = '{#{t}}'
        subfields_config = {
            :t => {
                :transformation => Proc.new {  |s| s.gsub(/[\/:;=.,]$/, "") },
                :delimiter => ", "
            }
        }

        output = parse_marcfields(marcf: marcf, output_templ: output_templ, subfields_config: subfields_config )
        output.map! { |o| 
            creativework = { :name => o }
            parse_creative_work (creativework) 
        }
        return output unless output.empty?
    end

end