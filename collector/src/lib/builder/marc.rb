require 'lib/builder/marc_utils'
require 'lib/builder/parts/person'
require 'lib/builder/parts/title'
require 'lib/builder/parts/organization'
require 'lib/builder/parts/date'
require 'lib/builder/parts/location'
require 'lib/builder/parts/identifier'
require 'lib/builder/parts/description'
require 'lib/builder/parts/about'
require 'lib/builder/parts/keyword'
require 'lib/builder/parts/related_work'
require 'lib/builder/parts/media_object'
require 'lib/builder/parts/language'
require 'lib/builder/parts/issue'
require 'lib/builder/parts/edition'

require 'pp'
require 'logger'

module Builder
  attr_reader :record, :themes, :provider

  class MARC
    include Utils
    include Titles
    include Languages    
    include Persons
    include Organizations
    include Dates
    include Locations
    include Identifiers
    include Descriptions
    include Abouts
    include Keywords
    include RelatedWorks
    include Issues
    include Edition
    include MediaObject

### 336 337 338 RDA Info Niet nodig
### 510 Citation/references note
### TODO 542  ?????
### TODO 546 Language Node 
### TODO 580 Linking complexity note
### TDOO 581 Niet beschreven in LIBISnet datamodel
### TODO 699 Local uniform/collective title (soms ook Herkomstcollectie)
### TODO 787 Niet beschreven in LIBISnet datamodel => gerelateerd aan Alma collections ???
### TODO 900 BIB record status in LIBISnet
### TODO 950 Illustration details 
### TODO 98x Administative Tags 
### TODO 991 Aleph ??
### TOOO 996 Data for scope and acquisition lists
### TODO 998 Source reference Aleph (SRC)


    def initialize(record)
      Encoding.default_external = "UTF-8"
      @logger = Logger.new(STDOUT)
      @record = record
      create_subfields
    end

    def create_subfields 
      #puts @record
      #####################################################
      # jsonPath doesn't work with integers in the keys 
      # "_ind1", "_ind2", "4" are not
      #####################################################
      
      #h = {}
      #@record['controlfield'].each { |c|  ( h[c["_tag"].to_s] ||= '' ) << c["$text"] }
      #@record['controlfield'] = h
      @record['datafield'].each do |d|
        h = {}
        # make it an array
        d['subfield'] = [ d['subfield'] ].flatten(1)
        d['subfield'].each { |s| ( h[s["_code"].to_s] ||= [] ) << s["$text"] }
        d['subfield'] = h
      end
    end

    def id
      marcfields(record:@record, field:"001")
    end

    def type_detection
      fmt = retrieveFMT (marcfields(record:@record, field:"ldr") )
      case fmt
        when "BK"
          "Book"
        when "SE"
          "CreativeWorkSeries"
        else
          nil
      end
    end


    def rare_book_detection
      output = []
      path = '$.datafield[?(@["_tag"] == "653" )].subfield[?(@["a"])]'
      marcf = JsonPath.on(@record, path)
      output_templ = '{#{a}}'
      subfields_config = {
          :v => {
              :transformation => Proc.new {  |i|  i.to_s } ,
              :delimiter => ", "
          }
      }
      output << parse_marcfields(marcf: marcf, output_templ: output_templ, subfields_config: subfields_config ) 
      output.reject! { |o| o.empty? }
      output.flatten! unless output.empty?
      if output.include? 'Books before 1840'
        return true
      else
        return false
      end
    end

    def themes
      output = Output.new
      output[:themes] = @themes.compact.sort.uniq if @themes.count > 0

      output[:themes]
    end

    def backlink
      "http://limo.libis.be/VLP:ALL_CONTENT:" + id
    end
  end
end