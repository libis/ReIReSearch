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
require 'iso639'
require 'active_support/core_ext/hash'

######################################################################################
reiresConfJson = File.read(File.join(File.dirname(__FILE__), './src/config/config.cfg'))
reiresConf = JSON.parse(reiresConfJson)


######################### Dataset and Dataprovider Configuration ######################
ingestConfJson =  File.read(File.join(File.dirname(__FILE__), './src/config/LLTA.cfg'))
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

@records_dir = "#{RECORDS_DIR}/LLTA/"

source_dir = "/app/source_records/LLTA/"

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
source_file_name = "*.json"

log("SOURCE_RECORDS_DIR : #{ source_dir }")
log("source_file_name : #{ source_file_name }")


def parse_json_file( source_file:  )
    begin
        records = JSON.parse( File.read(source_file) )  
        puts "number of records:  #{records["SchemaItems"].size }"

        # if @type of isPartOf is ["Book","PublicationVolume"] make it "PublicationVolume" (from Array to String)
        records["SchemaItems"].map! { |record| 
            unless record["isPartOf"].nil?
                unless record["isPartOf"]["@type"].kind_of?(String)
                    if record["isPartOf"]["@type"].kind_of?(Array)
                        record["isPartOf"]["@type"].delete("Book")
                        if record["isPartOf"]["@type"].size == 1
                            record["isPartOf"]["@type"] = record["isPartOf"]["@type"][0]
                        end
                    end
                end
            end
            record
        }

        # if isPartOf contains an isPartOf, replace the first part of the name (CC SL, CC SL or CSEL) in the isPartOf with  
        # the full name from the nested isPartOf and remove this nested isPartOf
        records["SchemaItems"].map! { |record| 
            unless record["isPartOf"]["isPartOf"].nil?
                record["isPartOf"]["name"].gsub!(/^CC SL(,.*)$/,"#{record["isPartOf"]["isPartOf"]["name"]}, \1") 
                record["isPartOf"]["name"].gsub!(/^CC CM(,.*)$/) { |m| "#{ record["isPartOf"]["isPartOf"]["name"] }#{$1}" }
                record["isPartOf"]["name"].gsub!(/^CC SL(,.*)$/,"#{record["isPartOf"]["isPartOf"]["name"]}, \1") 
                record["isPartOf"].delete("isPartOf")
            end
            record
        }

=begin



        publisher = records["SchemaItems"].map { |record| record["isPartOf"]["publisher"] }.uniq
        publisher.compact!
        puts "publisher #{publisher}"

        isPartOf = records["SchemaItems"].map { |record| record["isPartOf"]["name"] }.sort.uniq
        #isPartOf = records["SchemaItems"].map { |record| record["isPartOf"]["name"].gsub(/, [pc]\. [\d\.a-z;, -]*(\(.*\))?$/,'') }.sort
        isPartOf.compact!
        puts "number of uniq partsOf:  #{isPartOf.size}"

        isPartOf = records["SchemaItems"].map { |record| record["isPartOf"]["name"].gsub(/, [pc]\. [\d\.a-z;, -]*(\(.*\))?$/,'') }.sort.uniq
        isPartOf.compact!
        puts "number of uniq partsOf with some stripped text:  #{isPartOf.size}"

        isPartOf = records["SchemaItems"].map { |record| 
            unless record["isPartOf"]["isPartOf"].nil?            
                record["isPartOf"]["name"]
                    .gsub(/^(CC SL).*?$/,'\1') 
                    .gsub(/^(CC CM).*?$/,'\1')
                    .gsub(/^(CSEL).*?$/,'\1')
            else
                ""
            end
        }.sort
        
        puts "number of records with partOf starting with CC SL : #{ (isPartOf.select{ |name| name == "CC SL" }).size }"
        puts "number of records with partOf starting with CC CM : #{ (isPartOf.select{ |name| name == "CC CM" }).size }"
        puts "number of records with partOf starting with CSEL : #{ (isPartOf.select{ |name| name == "CSEL" }).size }"
        puts "----------------"
        # puts isPartOf
        


        isPartOf = records["SchemaItems"].map { |record| record["isPartOf"]["isPartOf"]["name"] unless record["isPartOf"]["isPartOf"].nil? }.uniq

        puts "isPartOf.size #{isPartOf.size}"
        isPartOf.compact!
        puts isPartOf
=end

        records["SchemaItems"].each_with_index do |record, index|
            parse_record( record: record )
            #if index % 100 == 0
            #   parse_record( record: record )
            #end
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
    id = record["url"][/\?key=(.*)$/,1].gsub(/_$/,'')
    id = "#{@prefixid}_#{id}"
    #type = record["@type"]
    type = "PublicationIssue"

=begin
    puts "id : #{id }"

    id = "#{@prefixid}_#{id}"
    type = record["@type"] 
    puts "type: #{type}"

    type = record["isPartOf"]["@type"]
    puts "isPartOf type: #{type}"
    
    name = record["isPartOf"]["name"]
    puts "isPartOf name: #{name}"    
=end   
    
schema_out = schema_out_object(id: id, type: type, url: "#{@url_prefix}/#{id}",)

# @context
# "@type": ["Book","PublicationVolume"],

=begin
name
isPartOf
temporalCoverage
url
author
@context
@type
name
isPartOf
temporalCoverage
url
=end

    record["@context"]       = schema_out["@context"]
    record["@id"]            = schema_out["@id"]
    record["@type"]          = schema_out["@type"]
    record["additionalType"] = schema_out["additionalType"]

    if record["isPartOf"].has_key?("publisher") 
        if record["isPartOf"]["publisher"] == "Brepols"
            record["isPartOf"]["publisher"] = {
                "@id"           => "Brepols",
                "@type"         => "Organization",
                "name"          => "Brepols Publishers",
                "alternateName" => "Brepols"
            }
        else
            record["isPartOf"]["publisher"] = {
                "@type" => "Organization",
                "name" =>  record["isPartOf"]["publisher"]
            }
        end
    end

    language = record["inLanguage"] || "la"
    record["inLanguage"] =  Iso639[language].alpha3
    
    record["datePublished"] = record["isPartOf"]["datePublished"]
    record["pageStart"]    = record["isPartOf"]["pageStart"]
    record["pageEnd"]      = record["isPartOf"]["pageEnd"]

    record["isPartOf"].delete("pageStart")
    record["isPartOf"].delete("pageEnd")

    language = record["isPartOf"]["inLanguage"] || "la"
    record["isPartOf"]["inLanguage"] = Iso639[language].alpha3

    record["isBasedOn"]      = schema_out["isBasedOn"]
    record["sameAs"]         = record["url"]
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