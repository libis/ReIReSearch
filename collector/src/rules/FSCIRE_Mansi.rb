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
require 'csv'
require 'pp'
require 'mime/types'
require 'active_support/core_ext/hash'

def cleanup(s)
    if s.is_a?(String)
        if s == "''"
            s = ""
        end
        s
    elsif s.is_a?(Array)
        s.each { |v| v = cleanup(v) } 
    elsif s.is_a?(Hash)
        s.each { |k, v| s[k] = cleanup(v) } 
    end
end
######################################################################################
reiresConfJson = File.read(File.join(File.dirname(__FILE__), './src/config/config.cfg'))
reiresConf = JSON.parse(reiresConfJson)

######################### Dataset and Dataprovider Configuration ######################
ingestConfJson =  File.read(File.join(File.dirname(__FILE__), './src/config/FSCIRE_Mansi.cfg'))
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

@records_dir = "#{RECORDS_DIR}/FSCIRE_Mansi/"

log("Read csv-files")

######################################################################################
@url_prefix = reiresConf["url_prefix"]
@prefixid =  "#{reiresConf["prefixid"]}_#{ @provider["@id"] }_#{ @dataset["@id"] }"

# @sdLicense = reiresConf["sdLicense"]
# @sdPublisher = reiresConf["sdPublisher"]
######################################################################################

documents = input.csv_file_to_hash("#{SOURCE_RECORDS_DIR}/mansi_data/concilii_documents/documents.csv")
consilii  = input.csv_file_to_hash("#{SOURCE_RECORDS_DIR}/mansi_data/concilii_documents/concilii.csv")
docs_images = input.csv_file_to_hash("#{SOURCE_RECORDS_DIR}/mansi_data/concilii_documents/documents_images_join_table.csv")
images  = input.csv_file_to_hash("#{SOURCE_RECORDS_DIR}/mansi_data/volumes_images/images.csv")
volumes = input.csv_file_to_hash("#{SOURCE_RECORDS_DIR}/mansi_data/volumes_images/volumes.csv")
######################################################################################

volume_has_part = {}
event_about = {}

# documents
# ID => documents_images_join[Document ID],Name,Order,level,Concilium id => concillii[ID]
# 251,Symbolum Nicaeni concilii Graece et Latine,11,1,20

# documents_images_join
# ID,Document ID => documents[ID],Image ID => images[ID]
# 8497,251,786
# 8498,251,5033

# images
# ID => documents_images_join[Image ID],Note,Image Number,Columns,Real Columns,Volume ID => volumes[ID],Image path
# 786 ,'',342,665-666,665-666,2,/var/www/FSCIRE/concili/images/vol2/00342.jpg
# 5033,'',5,'','',9,/var/www/FSCIRE/concili/images/extra1/00005.jpg

# volumes
# ID => images[Volume ID],Volume name,Volume number,Edition,Images Path
# 2,Sacrorum conciliorum nova et amplissima collectio,2,"Mansi (Florentiae, 1759)",/var/www/FSCIRE/concili/images/vol2

# concilii
# ID => documents[Concilium id] ,Name,Series,Place,Year start,Year end,Notes
# 20,Nicaenum,I,Nicaea in Anatolia (= Iznik),325,325,''

##########################################################################################
# a concili is an 'event'
# Documents are proceedings of this event
# Documents are digitized as images (multiple images per document are possible)
# Every image is a part of a volume
#
# => The processed records are documents with
# -> Media : the digitized document = image 
# -> Is Part of : the volume of this document via the image 
# -> subject of : the event / console


log("Create Records from csv-files")
@records = documents.flat_map do | doc_row |
    doc = doc_row.to_h
    # puts doc["ID"]
    # puts "Concilium id #{doc["Concilium id"]}"
    # doc is a CSV::Table
    # select returns an Filtered Array
    # map will convert every row of the CSV::table to a hash
    # 1 image can be linked to multiple documents
    
    begin
        cons = consilii.select { |row| row["ID"] == doc["Concilium id"] }
        doc["Concilium"] = cons.map { |con| con.to_h }

        event_id = doc["Concilium id"]
        event_about[ event_id ] = [] unless event_about.has_key?(event_id)

        imgs_joint = docs_images.select { |row| row["Document ID"] == doc["ID"] }
        if imgs_joint.size > 1
            puts "Concilium id #{doc["Concilium id"]}"
            puts "Concilium Name #{doc["Name"]}"
            puts imgs_joint
        end

        vol_id = nil
        imgs = imgs_joint.map do |img|

            i = images.select { |row| row["ID"] == img["Image ID"] } 

            if i.size > 1
                raise "Found multiple images for ID (#{ img["Image ID"]  }) in images.csv; expected uniq ID!"
            end
            i = i.first.to_h 
           
            v = volumes.select { |row| row["ID"] == i["Volume ID"] } 
            if v.size > 1
                raise "Found multiple volumes for ID (#{ i["Volume ID"]  }) in volumes.csv; expected uniq ID!"
            end

            v = v.first.to_h
            vol_id = v["ID"]
            volume_has_part[ vol_id ] = [] unless volume_has_part.has_key?(vol_id)
            # puts "ID : #{v["ID"] }"

            i["Volume"] = v
            i.to_h
        end

        doc_id_nr = []
        doc_id = doc["ID"].to_s.rjust(9, "0")
        if imgs_joint.size > 1
            #doc["images"] = imgs.slice(0,1)
            doc_array = []           
            imgs.each_with_index do |img, index| 
                doc["images"] = [img]
                doc["ID"] = "#{doc_id}_#{index}"
                cleanup( doc.to_h )
                doc["images"] = [img]
                doc_array << doc.clone
                doc_id_nr << doc["ID"]
            end
            doc = doc_array
        else
            doc["ID"] = "#{doc_id}"
            doc["images"] = imgs
            doc_id_nr << doc["ID"]
            cleanup( doc.to_h )
        end
        ( volume_has_part[ vol_id ] << doc_id_nr ).flatten! if volume_has_part.has_key?(vol_id)
        ( event_about[ event_id ] << doc_id_nr ).flatten! if event_about.has_key?(event_id)
        doc

    rescue StandardError => msg  
        puts "ERROR Parsing csv documents: #{msg}"
    end   
end
log("Records from csv-files : => Created ")

file_counter = 0
record_counter = 0

def create_schema (record, record_id, record_type)
    begin 
        type = type_mapping( record_type )

        @counter  = 0
        person_counter = 0
        organization_counter = 0
        places_counter = 0
        creativework_counter = 0

        schema_out = schema_out_object(id: record_id, type: type) 

        language = @recordLanguage
        output[:language] = Iso639[language].alpha2
        schema_out["inLanguage"] =  Iso639[language].alpha3

        title = record['Name']
        output[:name] = script_checker(title, @unicode_script)
        schema_out["name"] = output[:name] if !output[:name].nil?

        unless record['has_part'].nil?
            partdata = record['has_part'].map do | doc_id |
               data = @records.select{ |row| 
                    if row
                        # puts "--- row[ID] #{row["ID"]} == doc_id #{doc_id}: #{row["ID"] == doc_id} --- "
                        row["ID"] == doc_id
                    else
                        false
                    end
                }
                if data.size > 1
                    raise "Found multiple records for has_part id; expected uniq ID!"
                end
                data = data.first
                id = "#{@prefixid}_#{ data["ID"] }"

                partObj = schema_out_object(id:  id, type: "CreativeWork", url: "#{@url_prefix}/#{id}") 
                partObj["name"] = "#{data["Name"]}".strip
                partObj        

            end
            output[:hasPart] = partdata
            schema_out["hasPart"] = output[:hasPart] if !output[:hasPart].nil?
        end

        unless record['about'].nil?
            about = record['about'].map do | doc_id |
               data = @records.select{ |row| 
                    if row
                        row["ID"] == doc_id
                    else
                        false
                    end
                }
                if data.size > 1
                    raise "Found multiple records for has_part id; expected uniq ID!"
                end
                data = data.first
                id = "#{@prefixid}_#{ data["ID"] }"

                aboutObj = schema_out_object(id:  id, type: "CreativeWork", url: "#{@url_prefix}/#{id}") 
                aboutObj["name"] = "#{data["Name"]}".strip
                aboutObj
            end
            output[:about] = about
            schema_out["about"] = output[:about] if !output[:about].nil?
        end

        unless  record['Concilium'].nil?
            event = record['Concilium'].map.with_index { |c,i|
                id = "#{@prefixid}_Event_#{c["ID"].to_s.rjust(9, "0")}"
                eventObj = {
                    "@id"         => id,
                    "@type"       => "Event",
                    "name"        => "#{c["Name"]} #{c["Series"]}".strip,
                    "startDate"   => c["Year start"],
                    "endDate"     => c["Year end"]
                } 
                                   
                eventObj["location"] = { "@type" => "Place", "name" => c["Place"], "@id" => "#{ id }_PLACE_#{i}" } unless c["Place"].nil? || c["Place"].empty?
                eventObj["description"] = c["Notes"] unless c["Notes"].nil? || c["Notes"].empty?
                eventObj
            }
            output[:subjectOf] = event
            schema_out["subjectOf"] = output[:subjectOf] if !output[:subjectOf].nil?
        end

        # ID,Volume name,Volume number,Edition,Images Path
        unless record['images'].nil?
            isPartOf = record["images"].map { |img| 
                id = img["Volume"]["ID"]
                id = "#{@prefixid}_Volume_#{id.to_s.rjust(9, "0")}"
                isPartOfObj = schema_out_object(id:  id, type: "PublicationVolume", url: "#{@url_prefix}/#{id}") 
                isPartOfObj["name"] = img["Volume"]["Volume name"]
                isPartOfObj["volumeNumber"] = img["Volume"]["Volume number"]
                isPartOfObj["bookEdition"] = img["Volume"]["Edition"]
                isPartOfObj
            }

            output[:isPartOf] = isPartOf
            schema_out["isPartOf"] = output[:isPartOf] if !output[:isPartOf].nil?

            output[:pagination] = record["images"].map { |img| img["Real Columns"] unless img["Real Columns"].empty? }
            schema_out["pagination"] = output[:pagination] unless output[:pagination].nil?

            associatedMedia = record["images"].map { |img| 
                associatedMediaObj = schema_out_object(id: "#{@prefixid}_image_#{img["ID"].to_s.rjust(9, "0")}", type: "MediaObject", url: "#{@mediaUrlPrefix}#{img["ID"]}") 
                associatedMediaObj["identifier"] ="#{@prefixid}_image_#{img["ID"].to_s.rjust(9, "0")}"
                associatedMediaObj["contentUrl"] = "#{@mediaUrlPrefix}#{img["ID"]}"
                associatedMediaObj
            }

            output[:associatedMedia] = associatedMedia
            schema_out["associatedMedia"]=output[:associatedMedia] if !output[:associatedMedia].nil?
        end
        schema_out
        
    rescue StandardError => msg  
        # display the system generated error message  
        puts "Error create_schema: #{msg}"
        puts record
    end
end  

def parse_type (record, type)
    begin
        urn_id = record["ID"]
        urn_id = urn_id.to_s.rjust(9, "0") # create a 9 digit long id

        if type.downcase == "issue"
            id = "#{@prefixid}_#{urn_id}"
        else
            id = "#{@prefixid}_#{type.capitalize}_#{urn_id}"
        end
        log("Parsing #{type} ID: #{ id }")

        output[:identifier] = urn_id

        schema_out = create_schema(record, id, type.capitalize)
        # puts schema_out

        #schema_out.reject!{|k,v| v.nil? || ( (!v.is_a? Integer) && v.empty? ) }
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
        puts "Error parsing #{type}: #{msg}"
        puts volume
    end 
end

Dir.glob("#{@records_dir}/*").each { |file| File.delete(file)}

@records.compact.each do |record|
    begin 
        parse_type(record, "issue")
    rescue StandardError => msg  
        # display the system generated error message  
        puts "Error each record: #{msg}"
        puts record
    end
end