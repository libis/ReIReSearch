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

Encoding::default_external = Encoding::UTF_8

######################################################################################
reiresConfJson = File.read(File.join(File.dirname(__FILE__), './src/config/config.cfg'))
reiresConf = JSON.parse(reiresConfJson)

######################### Dataset and Dataprovider Configuration ######################
ingestConfJson =  File.read(File.join(File.dirname(__FILE__), './src/config/KlerusDatenbank.cfg'))
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
@isBasedOn = build_isBasedOn(ingestdata).deep_symbolize_keys

records_dir = "#{RECORDS_DIR}/Klerus_Datenbank/"

######################################################################################
@url_prefix = reiresConf["url_prefix"]
@prefixid =  "#{reiresConf["prefixid"]}_#{ @provider["@id"] }_#{ @dataset["@id"] }"

# @sdLicense = reiresConf["sdLicense"]
# @sdPublisher = reiresConf["sdPublisher"]
######################################################################################

log("Read csv-files")

source_file_name = 'klerus_template_mixed_2021-04-28.csv'
source_file_name = 'test.csv'
data = input.csv_file_to_hash("#{SOURCE_RECORDS_DIR}/JGUKlerusDatenbank/#{source_file_name}", ";")

file_counter = 0
record_counter = 0

def parse_date(date)
    date.gsub(/^(\d)\.(\d{3})(\d{2})(\d{2}).*/,'\1\2-\3-\4')
        .gsub(/^(\d{4})-00-00$/,'\1-01-01')
        .gsub(/^(\d{4})-\d{2}-00$/,'\1-01-01')
        .gsub(/^(\d{4})-00-\d{2}$/,'\1-01-01')
        .gsub(/^(\d{4})-[2-9]\d-\d{2}$/,'\1-01-01')
        .gsub(/^(\d{4})-1[3-9]-\d{2}$/,'\1-01-01')
        .gsub(/^(\d{4})-\d{2}-[4-9]\d$/,'\1-01-01')
end

def create_weihe(id:, startDate:, ort:, kirche:, description:, name:)                               
    startDate = parse_date( startDate ) unless startDate.nil?

    location = nil
    unless kirche.nil?
        location =  {
            :@type => "Place",
            :name => kirche,
            :address => ort
        } 
    end

    output =   {   
        :@type => "Event",
        :@id   => id,
        :name  => name,
        :description => description,
        :location => location,  
        :startDate   => startDate
    } 

    output
end
  

Dir.glob("#{records_dir}/*").each { |file| File.delete(file)}

log("Create Records from csv-files")
@records = data.flat_map do | doc_row |
    doc = doc_row.to_h
    output.clear()

    if doc["schema.org[:@id]"].nil? || doc["schema.org[:@id]"].empty?
        return
    end
    urn_id = doc["schema.org[:@id]"]
    urn_id = urn_id.to_s.rjust(9, "0") # create a 9 digit long id
    id = "#{@prefixid}_#{urn_id}"

    puts id

    type = "Person"
    schema_out_object(id: id, type: type, url: "#{@url_prefix}/#{id}")

    output[:familyName] = doc["schema.org[:familyName]"]
    output[:givenName]  = doc["schema.org[:givenName]"]
    output[:name]       = "#{  doc["schema.org[:familyName]"]  }, #{ doc["schema.org[:givenName]"]}"
    
    output[:birthDate]  = parse_date( doc["schema.org[:birthDate]"] ) unless doc["schema.org[:birthDate]"].nil?

    output[:birthPlace] = {            
            :@type => "Place", 
            :name => doc["schema.org[:birthPlace]"] 
        } unless doc["schema.org[:birthPlace]"] .nil?

    output[:deathDate]  = parse_date(doc["schema.org[:deathDate]"]) unless doc["schema.org[:deathDate]"].nil?
    output[:deathPlace] = {            
            :@type => "Place", 
            :name => doc["schema.org[:deathPlace]"]
        } unless doc["schema.org[:deathPlace]"].nil?

    output[:description]  = doc["schema.org[:description]"]

    unless [
        doc["schema.org[:subjectOf][:subdiakonat][:startDate]"],
        doc["schema.org[:subjectOf][:subdiakonat][:location][:location]"],
        doc["schema.org[:subjectOf][:subdiakonat][:location][:name]"],
        doc["schema.org[:subjectOf][:subdiakonat][:description]"]
    ].all?{ |x| x.nil? || x.empty? }
        startDate   = doc["schema.org[:subjectOf][:subdiakonat][:startDate]"]
        ort         = doc["schema.org[:subjectOf][:subdiakonat][:location][:location]"]
        kirche      = doc["schema.org[:subjectOf][:subdiakonat][:location][:name]"]
        description = doc["schema.org[:subjectOf][:subdiakonat][:description]"]
        name        = "Subdiakonat"

        output[:subjectOf] = create_weihe(id: "#{id}_EVENT_ORDINATION_1", startDate: startDate, ort: ort, kirche: kirche, description: description, name: name)                               

    end
    
    unless [
        doc["schema.org[:subjectOf][:diakonat][:startDate]"],
        doc["schema.org[:subjectOf][:diakonat][:location][:location]"],
        doc["schema.org[:subjectOf][:diakonat][:location][:name]"],
        doc["schema.org[:subjectOf][:diakonat][:description]"]
    ].all?{ |x| x.nil? || x.empty? }
        startDate   = doc["schema.org[:subjectOf][:diakonat][:startDate]"]
        ort         = doc["schema.org[:subjectOf][:diakonat][:location][:location]"]
        kirche      = doc["schema.org[:subjectOf][:diakonat][:location][:name]"]
        description = doc["schema.org[:subjectOf][:diakonat][:description]"]
        name        = "Diakonat"

        output[:subjectOf] = create_weihe(id: "#{id}_EVENT_ORDINATION_2", startDate: startDate, ort: ort, kirche: kirche, description: description, name: name)                               

    end

    unless [
        doc["schema.org[:subjectOf][:priesterweihe][:startDate]"],
        doc["schema.org[:subjectOf][:priesterweihe][:location][:location]"],
        doc["schema.org[:subjectOf][:priesterweihe][:location][:name]"],
        doc["schema.org[:subjectOf][:priesterweihe][:description]"]
    ].all?{ |x| x.nil? || x.empty? }
        startDate   = doc["schema.org[:subjectOf][:priesterweihe][:startDate]"]
        ort         = doc["schema.org[:subjectOf][:priesterweihe][:location][:location]"]
        kirche      = doc["schema.org[:subjectOf][:priesterweihe][:location][:name]"]
        description = doc["schema.org[:subjectOf][:priesterweihe][:description]"]
        name        = "Priesterweihe"

        output[:subjectOf] = create_weihe(id: "#{id}_EVENT_ORDINATION_3", startDate: startDate, ort: ort, kirche: kirche, description: description, name: name)                               

    end

    unless doc["schema.org[:subjectOf][:name]"].nil?
        output[:subjectOf] =                 
            {   
                :@type => "CreativeWork",
                :@id   => "#{id}_CREATIVEWORK_LITERATUR_1",
                :name  => doc["schema.org[:subjectOf][:name]"]
            }
    end

    #puts output.raw

    output.clean()
    output.add_all_ids(prefix: id)

    output.to_json(id.gsub(/[.\/\\:\?\*|"<>]/, '-'), records_dir)
    output.clear()
    
end
