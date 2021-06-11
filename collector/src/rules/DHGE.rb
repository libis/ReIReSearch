#encoding: UTF-8
$LOAD_PATH << '.' << './lib'
require 'oai'
require 'http'
require 'open-uri'
require 'nokogiri'
require 'json'
require 'nori'
require 'uri'
require 'logger'
require 'cgi'
require 'mime/types'
require 'active_support/core_ext/hash'

######################################################################################
reiresConfJson = File.read(File.join(File.dirname(__FILE__), './src/config/config.cfg'))
reiresConf = JSON.parse(reiresConfJson)

######################### Dataset and Dataprovider Configuration ######################
ingestConfJson =  File.read(File.join(File.dirname(__FILE__), './src/config/DHGE.cfg'))
ingestConf = JSON.parse(ingestConfJson)

@dataset = ingestConf["dataset"]
@provider = ingestConf["provider"]
@license = ingestConf["license"]

@mediaUrlPrefix = ingestConf["mediaUrlPrefix"]

@metaLanguage = ingestConf["metaLanguage"]
@unicode_script = ingestConf["unicode_script"]
@recordLanguage = ingestConf["recordLanguage"]
@genericRecordDesc = ingestConf["genericRecordDesc"]

ingestdata = {
    "provider" => @provider,
    "dataset" => @dataset,
    "license" => @license,
    "name" => @genericRecordDesc
}
@isBasedOn = build_isBasedOn(ingestdata)

@records_dir = "#{RECORDS_DIR}/DHGE/"

source_dir = "/app/source_records/DHGE/"

######################################################################################
@url_prefix = reiresConf["url_prefix"]
@prefixid =  "#{reiresConf["prefixid"]}_#{ @provider["@id"] }_#{ @dataset["@id"] }"

# @sdLicense = reiresConf["sdLicense"]
# @sdPublisher = reiresConf["sdPublisher"] 
######################################################################################

file_counter = 0
record_counter = 0

## Delete records 
Dir.glob("#{@records_dir}/*").each { |file| File.delete(file)}

source_dir = source_dir || SOURCE_RECORDS_DIR
source_file_name = "*Bishops_*.json"
source_file_name = "*.json"

log("SOURCE_RECORDS_DIR : #{ source_dir }")
log("source_file_name : #{ source_file_name }")

def parse_json_file( source_file:  )
    begin
        records = JSON.parse( File.read(source_file) )  
        puts records["SchemaItems"].size

        isPartOf = records["SchemaItems"].map { |record| record["isPartOf"] }

        if isPartOf.uniq.size != 1
            raise "ERROR: Multiple isPartOf-values in this file #{ source_file } !!!"
        end

        recordIsPartOf = isPartOf.uniq[0]

# the keys are case sensitive        
        recordIsPartOf = recordIsPartOf.map { |k, v| [k.camelize(:lower), v] }.to_h

        @metaLanguage  = recordIsPartOf["inLanguage"] || @metaLanguage 
        recordIsPartOf["@context"] = build_context
        
        recordIsPartOf["name"] = "#{ recordIsPartOf["name"]} - volnr. #{recordIsPartOf["volumeNumber"]}"
        
        id = "#{@prefixid}_#{File.basename(source_file,".*").tr(" ","_")}"
        recordIsPartOf["@id"] = id

        if recordIsPartOf.has_key?("volumeNumber")
            recordIsPartOf["@type"] = recordIsPartOf["@type"]
            recordIsPartOf["additionalType"] = "PublicationVolume"
        end
        if recordIsPartOf.has_key?("publisher")
            recordIsPartOf["publisher"] = {
                    "@type" => "Organization",
                    "@id" => "#{  recordIsPartOf["@id"] }_ORGANIZATION_1",
                    "name" =>  recordIsPartOf["publisher"]
                }
            if recordIsPartOf.has_key?("location") 
                recordIsPartOf["publisher"]["location"] = {
                    "@type" => "Place",
                    "name" => recordIsPartOf["location"],
                    "@id" => "#{ recordIsPartOf["@id"] }_PLACE_0"
                }
            end
            recordIsPartOf.delete("location")
        end

        records["SchemaItems"].map! { |record| record["isPartOf"] = recordIsPartOf; record}

        isPartOf = records["SchemaItems"].map { |record| record["isPartOf"] }
       
        records["SchemaItems"].each_with_index do |record, index|
            parse_record( record: record )
            #if index % 100 == 0
            #   parse_record( record: record )
            #end
        end


        schema_out = schema_out_object(id: recordIsPartOf["@id"], type: recordIsPartOf["@type"], url: "#{@url_prefix}/#{id}",)
        schema_out.merge!(recordIsPartOf) 

        cleanup_schema(schema_out)
        add_all_ids( data: schema_out, prefix:  "#{id}")
        schema_out = becompact(schema_out)

        if !schema_out.empty?
            output.to_jsonfile(schema_out.compact, id.gsub(/[.\/\\:\?\*|"<>]/, '-'), @records_dir)
        end   

        output.clear()
        schema_out = {}

    rescue StandardError => msg  
        # display the system generated error message  
        puts "Error parse_json_file: #{msg}"
        record = {}
        puts "====> Error parse_json_file #{source_file}"
        return {}
    end
end

def parse_record( record:  )
    id = "#{@prefixid}_#{record["identifier"]}"
    @metaLanguage  = record["inLanguage"] 

    type = record["@type"]
#    if record.has_key?("pagination")
#        type = type_mapping( "PublicationIssue" )
#    end

    schema_out = schema_out_object(id: id, type: type, url: "#{@url_prefix}/#{id}",)

    record["@context"]       = schema_out["@context"]
    record["@id"]            = schema_out["@id"]
    record["@type"]          = schema_out["@type"]
    record["additionalType"] = schema_out["additionalType"]

    language = record["inLanguage"]
    record["inLanguage"] =  Iso639[language].alpha3
    

    record["datePublished"]  =record["isPartOf"]["datePublished"]

    record["isBasedOn"]      = schema_out["isBasedOn"]
    record["sameAs"]         = record["url"]

    record["description"] = record["abstract"]
    
    record.delete("abstract")
    record.delete("url")
    
    schema_out = record

    cleanup_schema(schema_out)
    add_all_ids( data: schema_out, prefix:  "#{id}")
    schema_out = becompact(schema_out)

    if !schema_out.empty?
        output.to_jsonfile(schema_out.compact, id.gsub(/[.\/\\:\?\*|"<>]/, '-'), @records_dir)
    end   

    output.clear()
    schema_out = {}
end

Dir["#{source_dir}/#{source_file_name}"].each_with_index do |source_file, index| 
    log(" parsing #{source_file}")
    parse_json_file( source_file: source_file ) 
end