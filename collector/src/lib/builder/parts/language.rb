require 'pp'

## Marc Tags 041 en 008 

#### https://w3c.github.io/json-ld-syntax/#string-internationalization

module Languages
    def languages
        path = '$.datafield[?(@["_tag"] == "041")].subfield[?(@["a"])]'
        marcf = JsonPath.on(@record, path)


        output_templ = '{#{a}}'
        subfields_config = {
            :a => {
                :transformation => Proc.new {  |s| s.to_s },
                :delimiter => ", "
            }
        }
        if ! marcf.empty?
                return parse_marcfields(marcf: marcf, output_templ: output_templ, subfields_config: subfields_config )
        else
            path = '$.controlfield[?(@["_tag"] == "008")].$text'
            marcf = JsonPath.on(@record, path)
            [ marcf.first.to_s.match(/.{35}(.{3})/).to_s[35,3] ]
        end
    end
end