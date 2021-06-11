require 'pp'

module Dates

    def dates
        path = '$.datafield[?(@["_tag"] == "260" || ( @["_tag"] == "264" && @["_ind2"] == "1" ) ||  @["_tag"] == "953")].subfield[?(@["c"])]'
        marcf = JsonPath.on(@record, path)

        output_templ = '{#{c}}'
        subfields_config = {
            :c => {
                :transformation => Proc.new {  |i| ( i == 's.d.' ? i.to_s :  i.gsub(/[\/:;=.,]$/, "") ) } ,
                :delimiter => ", "
            }
        }
        
        if marcf.empty?
            path = '$.datafield[?(@["_tag"] == "953")].subfield[?(@["b"])]'
            marcf = JsonPath.on(@record, path)
            output_templ = '{#{b}}'
            subfields_config = {
                :c => {
                    :transformation => Proc.new {  |i| ( i == 's.d.' ? i.to_s :  i.gsub(/[\/:;=.,]$/, "") ) } ,
                    :delimiter => ", "
                }
            }
        end 

        if marcf.empty?
            path = '$.datafield[?(@["_tag"] == "953")].subfield[?(@["a"])]'
            marcf = JsonPath.on(@record, path)
            output_templ = '{#{a}}'
            subfields_config = {
                :c => {
                    :transformation => Proc.new {  |i| ( i == 's.d.' ? i.to_s :  i.gsub(/[\/:;=.,]$/, "") ) } ,
                    :delimiter => ", "
                }
            }
        end         

        if ! marcf.empty?
            return parse_marcfields(marcf: marcf, output_templ: output_templ, subfields_config: subfields_config )
        end
        
        path = '$.controlfield[?(@["_tag"] == "008")].$text'
        marcf = JsonPath.on(@record, path)
        marcf = marcf.first.to_s.downcase
        if checkcharonposition(marcf, "6@@n") && checkcharonposition(marcf, "7@@uuuuuuuu")
            return ["s.d."]
        end
        
        if !checkcharonposition(marcf, "6@@n") && !checkcharonposition(marcf, "6@@c") && !checkcharonposition(marcf, "7@@uuuuuuuu")
            fieldoutput = marcf.match(/.{7}([0123456789].{3})(.{4})/).to_s.gsub(/.{7}([0123456789].{3})(.{4})/,'\1 \2')
                        .gsub(/[#u]/, "?").to_s
                        .gsub(" ", "-").to_s
                        .gsub(/9999$/, "").to_s
             return [fieldoutput]
        end

        if checkcharonposition(marcf, "6@@n")
            fieldoutput = marcf.match(/.{7}([0123456789].{3})(.{4})/).to_s.gsub(/.{7}([0123456789].{3})(.{4})/,'\1 \2')
                    .gsub(/[#u]/, "?").to_s
                    .gsub(" ", "-").to_s
                    .gsub(/9999$/, "").to_s
            return [fieldoutput]
        end

        return nil
    end
  
    def datePublished
       dates
    end

    def dateCreated
        dates
    end


end