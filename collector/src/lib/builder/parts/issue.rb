require 'pp'

module Issues

    def pagination
        path = '$.datafield[?(@["_tag"] == "300" )].subfield[?(@["a"])]'
        marcf = JsonPath.on(@record, path)

        output_templ = '{#{a}}'
        subfields_config = {
            :a => {
                :transformation => Proc.new {  |i|  i.to_s  } ,
                :delimiter => ", "
            }
        }
        parse_marcfields(marcf: marcf, output_templ: output_templ, subfields_config: subfields_config ) 
    end

    def volumeNumber
      output = []
      path = '$.datafield[?(@["_tag"] == "490" )].subfield[?(@["v"])]'
      marcf = JsonPath.on(@record, path)

      output_templ = '{#{v}}'
      subfields_config = {
          :v => {
              :transformation => Proc.new {  |i|  i.to_s } ,
              :delimiter => ", "
          }
      }
      output << parse_marcfields(marcf: marcf, output_templ: output_templ, subfields_config: subfields_config ) 

      path = '$.datafield[?(@["_tag"] == "773" )].subfield[?(@["g"])]'
      marcf = JsonPath.on(@record, path)

      output_templ = '{#{g}}'
      subfields_config = {
          :g => {
              :transformation => Proc.new {  |i|  i.to_s } ,
              :delimiter => ", "
          }
      }
      output << parse_marcfields(marcf: marcf, output_templ: output_templ, subfields_config: subfields_config ) 
      
      output.reject! { |o| o.empty? }
      output.flatten(1) unless output.empty?
    end


end