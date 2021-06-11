require 'pp'
require 'logger'

module Edition

    def edition
        path = '$.datafield[?(@["_tag"] == "250")].subfield'
        marcf = JsonPath.on(@record, path)

        output_templ = '{#{a}}{ #{b}}'
        subfields_config = {
            :a => {
                :transformation => Proc.new {  |s| s.to_s },
                :delimiter => ", "
            },
            :b => {
                :transformation => Proc.new {  |s| s.to_s },
                :delimiter => ", "
            }
        }
        ( parse_marcfields(marcf: marcf, output_templ: output_templ, subfields_config: subfields_config ) ).join("\n'")
    end

end