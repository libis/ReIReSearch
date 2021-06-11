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
ingestConfJson =  File.read(File.join(File.dirname(__FILE__), './src/config/Cyrillomethodiana.cfg'))
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

records_dir = "#{RECORDS_DIR}/Cyrillomethodiana/"

######################################################################################
@url_prefix = reiresConf["url_prefix"]
@prefixid =  "#{reiresConf["prefixid"]}_#{ @provider["@id"] }_#{ @dataset["@id"] }"

# @sdLicense = reiresConf["sdLicense"]
# @sdPublisher = reiresConf["sdPublisher"]
######################################################################################

def parse_persons(persons)
    persons.each.map do |p|
        unless p.nil?
            tmp_hash = {
                "@type" => "Person"
            }
            tmp_hash['name']       = script_checker(p, @unicode_script)
            tmp_hash.reject!{|k,v| v.nil?}
            tmp_hash
        end
    end
end  

def parse_publisher(publisher)
    publisher.each.map do |p|
        unless p.nil?
            tmp_hash = {
                "@type" => "Organization"
            }
            tmp_hash['name'] = p
            tmp_hash.reject!{|k,v| v.nil?}
            tmp_hash
        end
    end
end  

def code_to_language_strings (values, mapping)
    mapped = values.map do |value|
        mapping.map do |lang, obj|
            selected = obj.select { |code| code == "#{value}"  ? true : false }
            selected.map { |code,v| {"@value": "#{v}", "@language": "#{lang}"} }
        end
    end
end

def parse_record (record, id)
    begin 

        @counter  = 0
        person_counter = 0
        organization_counter = 0
        places_counter = 0
        creativework_counter = 0

        #output[:sameAs] =  header_id
        #output[:identifier] = urn_id
        #output[:identifier] = header_id
    
        type =  type_mapping( "book" )

        schema_out = schema_out_object(id: id, type: type, url: "#{@url_prefix}/#{id}",) 

        language = filter(record, '$.language').first || @metaLanguage
        ###################### ERROR in dataset ###########
        language = "Croatian" if language == "Croation"
        output[:language] = Iso639[language].alpha2
        schema_out["inLanguage"] =  Iso639[language].alpha3

        #puts JSON.pretty_generate(record)
        title =  filter(record, '$.title')
        output[:name] = title.map{ |t| script_checker(t, @unicode_script) }
        schema_out["name"] = output[:name] unless output[:name].nil?

        output[:author] = parse_persons(filter(record, '$.authors'))
        schema_out["author"] =  output[:author] unless output[:author].nil?

        output[:isbn] = filter(record, '$.isbn')
        schema_out["isbn"] = output[:isbn] unless output[:isbn].nil?

        output[:datePublished] = filter(record, '$.releaseDate')
        schema_out["datePublished"] = output[:datePublished] unless output[:datePublished].nil?

        output[:bookEdition] = filter(record, '$.edition')
        schema_out["bookEdition"] = output[:bookEdition] unless output[:bookEdition].nil?

        output[:publisher] = parse_publisher(filter(record, '$.manufacturer'))
        schema_out["publisher"] = output[:publisher] unless output[:publisher].nil?

        output[:numberOfPages] = filter(record, '$.numberOfPages').first
        schema_out["numberOfPages"] = output[:numberOfPages].to_i unless output[:numberOfPages].nil?

        output[:description] = filter(record, '$.comment')
        schema_out["description"] = output[:description].map { |html| Nokogiri::HTML(html).text } unless output[:description].nil?

        output[:ebookURL] = filter(record, '$.ebookURL')

        unless filter(record, '$.ebookURL').empty?
            # puts "digital_presentation : #{digital_presentation}" 
            associatedMedia = schema_out_object(id: "#{id}_Media", type: "MediaObject", url: filter(record, '$.ebookURL').map { |u| "#{@mediaUrlPrefix}#{u}"}) 

            associatedMedia["identifier"] = "#{id}_Media"
            associatedMedia["name"] = "ebook"        
            associatedMedia["contentUrl"] = filter(record, '$.ebookURL').map { |u| "#{@mediaUrlPrefix}#{u}"}    
            associatedMedia["thumbnailUrl"] = filter(record, '$.imageURL').map { |u| "#{@mediaUrlPrefix}#{u}"}        

            output[:associatedMedia] = associatedMedia
            schema_out["associatedMedia"]=output[:associatedMedia] unless output[:associatedMedia].nil?
        end
    
        categorie = filter(record, '$.categs.categ')
        # convert [<id>] to [ {"@value": "<value>", "@language": "<language>"},  {"@value": "<value>", "@language": "<language>"} ]
        c = code_to_language_strings(categorie, @category_mapping)
        output[:keywords] = code_to_language_strings(categorie, @category_mapping)
        schema_out["keywords"]=output[:keywords] if !output[:keywords].nil?

=begin
        date # Date that this record is added to the database ???
        langshow # always *
        url # always empty
        reviews # always empty
        published # heeft de waarde 0 of 1
=end

        schema_out

    rescue StandardError => msg  
        # display the system generated error message  
        puts "Error parsing record: #{msg}"
        puts record
    end
end  

source_file_name = 'Cyrillomethodiana_booklibrary_full_20190820.xml'
#source_file_name = 'Cyrillomethodiana_booklibrary_test.xml'
url = "file://#{SOURCE_RECORDS_DIR}/#{source_file_name}"

#options = {user: config[:user], password: config[:password]}
options = {user: 'nvt', password: 'nvt'}


######################################################################################
@category_mapping = JSON.parse( File.read(File.join(File.dirname(__FILE__), './src/config/Cyrillomethodiana/category.json')) )
######################################################################################

file_counter = 0
record_counter = 0

Dir.glob("#{records_dir}/*").each { |file| File.delete(file)}

while url
    log("Load URL : #{  url }")
    timing_start = Time.now

    data = input.from_uri(url, options)
    log("Data loaded in #{((Time.now - timing_start) * 1000).to_i} ms")

    filter(data, '$..data.books.book').each do |record|
       
        urn_id = filter(record, '$.bookid').first
        urn_id = urn_id.to_s.rjust(9, "0") # create a 9 digit long id
        id= "#{@prefixid}_#{urn_id}"
        log("ID: #{ id }")

        #######################################################################################
        # create raw_json file for this record
        #filename = "#{@dataset}_metsurl_#{id}.json"
        #    puts "write file to #{SOURCE_RECORDS_DIR}/#{provider["@id"]}/#{filename}"
        #    open("#{SOURCE_RECORDS_DIR}/#{provider["@id"]}/#{filename}", "w+") do |file|
        #    file.write(record.to_json)
        #end
        #######################################################################################

        output[:identifier] = urn_id

        #type = type_mapping( filter(record, '$.genre.$text')[0] )
        type = "book"

        schema_out = parse_record(record, id)

=begin
        schema_out["alternateName"] = output[:alternateName]  if !output[:alternateName].nil?
        schema_out["sameAs"] =  output[:sameAs]   if !output[:sameAs].nil?
        schema_out["identifier"] =  output[:identifier]   if !output[:identifier].nil?
        schema_out["sameAs"]=output[:sameAs] if !output[:sameAs].nil
=end

       #schema_out.reject!{|k,v| v.nil? || ( (!v.is_a? Integer) && v.empty? ) }
       cleanup_schema(schema_out)
       add_all_ids( data: schema_out, prefix:  "#{id}")
       schema_out = becompact(schema_out)

        if !schema_out.empty?
          output.to_jsonfile(schema_out.compact, id.gsub(/[.\/\\:\?\*|"<>]/, '-'), records_dir)
        end

        output.clear()
        schema_out = {}
    end
    url=nil
end

