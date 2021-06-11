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
    
##################################
# persons is an array of hashes
#    [
#      {
#          "namePart": "...",
#          "role": {
#            "roleTerm": [
#              {
#                "$text": "<RELATOR_CODE>",
#                "_type": "code",
#                "_authority": "marcrelator"
#              },
#              {
#                "$text": "...",
#                "_type": "text"
#              }
#            ]
#          },
#          "_type": "personal",
#          "_script": "...",
#          "_altRepGroup": "...",
#          "_authority": "...",
#          "_authorityURI": "http://d-nb.info/gnd/",
#          "_valueURI": "http://d-nb.info/gnd/11885447X"
#        },
#        {
#          "namePart": [
#            "...",
#            {
#              "$text": "...",
#              "_type": "given"
#            },
#            {
#                "$text": "...",
#              "_type": "family"
#            }
#          ],
#          "role": {
#            "roleTerm": [
#              {
#                "$text": "<RELATOR_CODE>",
#                "_type": "code",
#                "_authority": "marcrelator"
#              },
#              {
#                "$text": "...",
#                "_type": "text"
#              }
#            ]
#          },
#          "_type": "personal",
#          "_script": "...",
#          "_altRepGroup": "028A:01",
#          "_authority": "gnd",
#          "_authorityURI": "http://d-nb.info/gnd/",
#          "_valueURI": "http://d-nb.info/gnd/11885447X"
#        }
#      ]
###########
def parse_persons(persons)
    persons.each.map do |p|
        lang = p['_script'] 
        tmp_hash = {
            "@type" => "Person"
        }
        tmp_hash['name']       = script_checker( filter(p, '$.["namePart"]').first, lang)
        tmp_hash['familyName'] = script_checker( filter(p, '$.["namePart"][?(@._type=="family")].$text').first, lang)
        tmp_hash['givenName']  = script_checker( filter(p, '$.["namePart"][?(@._type=="given")].$text').first, lang)
        tmp_hash.reject!{|k,v| v.nil?}
        tmp_hash
    end
end  

def type_mapping( type )
    default_type = 'Book'
    types = {
        "multivolume monograph" => "PublicationVolume",
        "book" => "Book"
    }
    if type.nil?
        return default_type
    else
        types[type.downcase] unless type.nil?
    end
end

# Moved to lib/utils.rb 
=begin
def script_checker(value, script_code)
    if  !value.nil?
        if  value['$text'] && !value.nil?
            script_code ? {"@value": "#{value['$text']}", "@language": "#{output[:language]}-#{script_code}" } : "#{value['$text']}"
        else
            script_code ? {"@value": "#{value}", "@language": "#{output[:language]}-#{script_code}" } :  "#{value}"
        end
    end
end
=end

##################################
#  Which identifiers to use as rieresId
# <header>
# <identifier>oai:visualcollections.ub.uni-mainz.de/ubmzms:91617</identifier>
# </header>
# ...
# <metadata>
# <mods:mods version="3.5" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-5.xsd">
#     ...
#           <mods:identifier type="urn">urn:nbn:de:hebis:77-vcol-2607</mods:identifier>
#           <mods:recordInfo>
#              ...
#              <mods:recordIdentifier source="ubmz">380594900</mods:recordIdentifier>
#           </mods:recordInfo>
# </mods:mods>
# </metadata>
# 
# Possible links to the resource ( Use as SameAs ? )
# - https://visualcollections.ub.uni-mainz.de/urn/urn:nbn:de:hebis:77-vcol-2607
# - https://gutenberg-capture.ub.uni-mainz.de/ubmzms/oai?verb=GetRecord&metadataPrefix=mods&identifier=oai:visualcollections.ub.uni-mainz.de/ubmzms:91617
# - https://visualcollections.ub.uni-mainz.de/ubmzms/content/titleinfo/91617
# - https://visualcollections.ub.uni-mainz.de/ubmzms/search/quick?query=380594900
#
#  https://gutenberg-capture.ub.uni-mainz.de/ubmzms/oai?verb=GetRecord&metadataPrefix=mods&identifier=oai:visualcollections.ub.uni-mainz.de/ubmzms:197899
# - http://nbn-resolving.de/urn:nbn:de:hebis:77-vcol-4605
########################################

##################################
# @language in json-ld https://github.com/json-ld/json-ld.org/issues/133
#
# Internationalization and Localization
# 
# Challenges for the multilingual Web of Data:
# https://www.sciencedirect.com/science/article/pii/S1570826811000783
#
########################################


######################################################################################
reiresConfJson = File.read(File.join(File.dirname(__FILE__), './src/config/config.cfg'))
reiresConf = JSON.parse(reiresConfJson)


######################### Dataset and Dataprovider Configuration ######################
ingestConfJson =  File.read(File.join(File.dirname(__FILE__), './src/config/JGUMainz_JGUMAINZ.cfg'))
ingestConf = JSON.parse(ingestConfJson)

@dataset = ingestConf["dataset"]
@provider = ingestConf["provider"]
@license = ingestConf["license"]

@mediaUrlPrefix = ingestConf["mediaUrlPrefix"]
@same_as_template = ingestConf["same_as_template"]

@metaLanguage = ingestConf["metaLanguage"]
@unicode_script = ingestConf["unicode_script"]
@recordLanguage = ingestConf["recordLanguage"]
@defaulttype =ingestConf["defaulttype"] 
@genericRecordDesc = ingestConf["genericRecordDesc"]

ingestdata = {
    "provider" => @provider,
    "dataset" => @dataset,
    "license" => @license,
    "name" => @genericRecordDesc
}
@isBasedOn = build_isBasedOn(ingestdata)


######################### Dataset and Dataprovider Configuration ######################
listurl = 'https://gutenberg-capture.ub.uni-mainz.de/ubmzms/oai?verb=ListRecords'

metsurl = "#{listurl}&metadataPrefix=mets"
modsurl = "#{listurl}&metadataPrefix=mods"
oaiurl  = "#{listurl}&metadataPrefix=oai_dc"
url = metsurl

#options = {user: config[:user], password: config[:password]}
options = {user: 'nvt', password: 'nvt'}

#######################################################################################
@url_prefix = reiresConf["url_prefix"]
@prefixid =  "#{reiresConf["prefixid"]}_#{ @provider["@id"] }_#{ @dataset["@id"] }"

# @sdLicense = reiresConf["sdLicense"]
# @sdPublisher = reiresConf["sdPublisher"]
#######################################################################################

records_dir = "#{RECORDS_DIR}/JGU_Mainz/"
record_counter = 0
@counter = 0
file_counter = 0

Dir.glob("#{records_dir}/*").each { |file| File.delete(file)}

# source_file_name = 'JGUMainz_JGUMAINZ_mets.xml'
# source_file_name = 'JGUMainz_full_mets.xml'
#url = "file://#{SOURCE_RECORDS_DIR}/#{source_file_name}"

while url
    log("Load URL : #{  url }")
    timing_start = Time.now
    
#download to source_records
begin
    resp = HTTP.get( url )
    filename = "#{@provider["@id"]}_#{@dataset}_metsurl_#{file_counter}.xml"
    puts "write file to #{SOURCE_RECORDS_DIR}/#{filename}"
    open("#{SOURCE_RECORDS_DIR}/#{filename}", "w+") do |file|
        file.write(resp.body)
    end
    file_counter += 1
end
# commands to analyse the downloaded data
#grep '<mods:' *xml  | cut -d '<' -f 2 | cut -d '>' -f 1 | sort -u
#mods:dateIssued => DateCreated / DataPublished
    #Load data

    data = input.from_uri(url, options)
    log("Data loaded in #{((Time.now - timing_start) * 1000).to_i} ms")

    filter(data, '$..ListRecords.record').each do |record|
   
        @counter  = 0
        person_counter = 0
        organization_counter = 0
        places_counter = 0
        creativework_counter = 0

        # Use this with &metadataPrefix=mods
        # recordMetadata = filter(record, '$.metadata.mods').first

        # Use this with &metadataPrefix=mets:
        # get id through _CONTENTIDS from structMap.
        # With dmd_id the correct dmdSec-mods-object can be retrieved

        dmd_id = filter(record, '$.metadata.mets.structMap.[?(@._TYPE == "LOGICAL")]..div[?(@._CONTENTIDS)]._DMDID')
        if dmd_id.length == 1 
            dmd_id = dmd_id.first
        else
            puts "ERROR : too much md_id s : !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
            dmd_id = dmd_id.first
        end

        recordMetadata = filter(record, '$.metadata.mets.dmdSec[?(@._ID == "' + dmd_id + '")].mdWrap.xmlData.mods')
        if recordMetadata.length == 1
          recordMetadata = recordMetadata.first
        else
          puts "ERROR : too much metadata : !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
          recordMetadata = recordMetadata.first
        end

        ###################################################################

        urn_id = filter(recordMetadata, '$.identifier[?(@._type=="urn")].$text').first
        header_id = filter(record, '$..header.identifier' ).first
       
        id= "#{@prefixid}_#{urn_id}"
        log("ID: #{ id }")

        #######################################################################################
        # create raw_json file for this record
        #filename = "#{@dataset}_metsurl_#{id}.json"
        #    puts "write file to #{SOURCE_RECORDS_DIR}/#{@provider["@id"]}/#{filename}"
        #    open("#{SOURCE_RECORDS_DIR}/#{@provider["@id"]}/#{filename}", "w+") do |file|
        #    file.write(record.to_json)
        #end
        #######################################################################################

        #output[:sameAs] =  @prefix_sameAs + urn_id
        output[:sameAs] =  @same_as_template.gsub(/<#record_id>/, urn_id)
        output[:identifier] = urn_id
        output[:identifier] = header_id
        output[:identifier] = filter(recordMetadata, '$..recordIdentifier.$text').map{ |i| "recordIdentifier:#{i}"}
        
        type = type_mapping( filter(recordMetadata, '$.genre.$text')[0] )

        # Get Thumbnails and download URLs taking into acount the structMap of the mets-record
        thumbnailUrl = []
        contentUrl = []

        file_ids = filter(record, '$.metadata.mets.structMap..div[?(@._CONTENTIDS: "' + urn_id + '")].fptr.._FILEID')
        file_ids.each  do |file_id|
          thumbnailUrl.concat filter(record, '$.metadata.mets.fileSec.fileGrp[?(@._USE == "FRONTIMAGE")].file.[?(@._ID == "' + file_id + '")]..FLocat[?(@._LOCTYPE == "URL")]._xlink:href') 
          contentUrl.concat filter(record, '$.metadata.mets.fileSec.fileGrp[?(@._USE == "DOWNLOAD")].file.[?(@._ID == "' + file_id + '")]..FLocat[?(@._LOCTYPE == "URL")]._xlink:href')
        end

        schema_out = schema_out_object(id: id, type: type, url: "#{@url_prefix}/#{id}" ) 
                
        # schema_out["thumbnailUrl"] = thumbnailUrl
        # puts "schema_out[@id] #{schema_out["@id"]}" 

        language = filter(recordMetadata, '$.language.languageTerm.$text').first || @recordLanguage
        output[:language] = Iso639[language].alpha2
        schema_out["inLanguage"] =  Iso639[language].alpha3

        #puts JSON.pretty_generate(recordMetadata)
        titleInfos =  filter(recordMetadata, '$.titleInfo')

        if  titleInfos.length == 1
            output[:name] = titleInfos.map{ |t| script_checker(t['title'], t['_script']) }
        else  
            # if t['_script'] add @value / @langauge else add title as is
            output[:name]  = titleInfos.select{ |t| t['_type'] != 'alternative'  }.map{ |t| script_checker(t['title'], t['_script']) }
            output[:alternateName]  = titleInfos.select{ |t| t['_type'] == 'alternative'  }.map{ |t| t['title'] } 
        end

        schema_out["name"] = output[:name] if !output[:name] .nil?
        schema_out["alternateName"] = output[:alternateName]  if !output[:alternateName].nil?
        # SameAs ?????????????????????????
        schema_out["sameAs"] =  output[:sameAs] if !output[:sameAs].nil?
        schema_out["identifier"] =  output[:identifier]   if !output[:identifier].nil?

        relator_code=['aut']
        persons = filter(recordMetadata, '$.name').select do |n| 
             ! ( n['role']['roleTerm'].select { |r| relator_code.include? r['$text'] }.empty? || n['namePart'].nil? )
        end       
        output[:author] = parse_persons(persons) 

        relator_code=['edt']
        persons = filter(recordMetadata, '$.name').select do |n| 
            ! ( n['role']['roleTerm'].select { |r| relator_code.include? r['$text'] }.empty? || n['namePart'].nil? )
        end     
        output[:editor] = parse_persons(persons)

        relator_code=['ill']
        persons = filter(recordMetadata, '$.name').select do |n| 
            ! ( n['role']['roleTerm'].select { |r| relator_code.include? r['$text'] }.empty? || n['namePart'].nil? )
        end    
        output[:illustrator] = parse_persons(persons)

        relator_code=['tra']   
        persons = filter(recordMetadata, '$.name').select do |n| 
            ! ( n['role']['roleTerm'].select { |r| relator_code.include? r['$text'] }.empty? || n['namePart'].nil? )
        end       
        output[:translator] = parse_persons(persons)

        # all names that or not aut or edt
        relator_code=['aut','edt','ill','tra']
        persons = filter(recordMetadata, '$.name').select do |n| 
            ! ( n['role']['roleTerm'].select { |r| relator_code.include? r['$text'] }.empty? || n['namePart'].nil? )
        end
        output[:contributor] = parse_persons(persons)

       #@counter = person_counter
       #add_ids( data: output[:author] , prefix:  "#{id}_PERSONS",   counter_start:@counter )
       #add_ids( data: output[:contributor] , prefix:  "#{id}_PERSONS",   counter_start: @counter )
       #add_ids( data: output[:editor] , prefix:  "#{id}_PERSONS",   counter_start:@counter )
       #add_ids( data: output[:translator] , prefix:  "#{id}_PERSONS",   counter_start:@counter )
       #add_ids( data:  output[:illustrator] , prefix:  "#{id}_PERSONS",   counter_start:@counter )
       #person_counter = @counter
       
       schema_out["author"] =  output[:author]
       schema_out["contributor"] =  output[:contributor]
       schema_out["editor"] =  output[:editor]
       schema_out["translator"] =  output[:translator]
       schema_out["illustrator"] =  output[:illustrator]

       physicalDescription = filter(recordMetadata, '$.physicalDescription.extent')
       output[:numberOfPages] = physicalDescription.map{ |a| a =~ /.* Blätter/i ? a.gsub(/ Blätter/, '') : nil }
       schema_out["numberOfPages"] =  output[:numberOfPages].first.to_i unless output[:numberOfPages].nil? || output[:numberOfPages].first.to_i == 0
       output[:description] = physicalDescription.map{ |a| a !~ /.* Blätter/i ? a : nil }

       output[:description] = filter(recordMetadata, '$.note').select{ |n| n["_type"].nil? }.map{ |t| script_checker( t , t['_script']) }
       schema_out["description"] = output[:description] if !output[:description].nil?

#       originInfo = filter(recordMetadata, '$.originInfo')
#       elec_originInfo = originInfo.select{ |o_info| o_info["edition"] == "[Electronic ed.]" } 
#       originInfo = originInfo.select{ |o_info| o_info["edition"] != "[Electronic ed.]" } 
      
       output[:dateCreated] = filter(recordMetadata, '$..originInfo[?(@.edition != "[Electronic ed.]" || !@.edition )].dateIssued')
       schema_out["dateCreated"] =  output[:dateCreated].map{ |d| d['$text'] ? d['$text'] : d }.uniq

       locationCreated = filter(recordMetadata, '$..originInfo[?(@.edition != "[Electronic ed.]" || !@.edition )].place.placeTerm')
       locationCreated.map!{ |l| l['$text'] ? l['$text'] : l }.uniq unless locationCreated.nil?
       locationCreated.map!{ |l| { "@type" => "Place", "name" => l } }  unless locationCreated.nil?

       output[:locationCreated] = locationCreated
       schema_out["locationCreated"] =  output[:locationCreated] if !output[:locationCreated].nil?
       
       output[:datePublished] = filter(recordMetadata, '$..originInfo[?(@.edition != "[Electronic ed.]" || !@.edition )].dateIssued[?(@._keyDate=="yes")].$text') 
       schema_out["datePublished"] =  output[:datePublished] if !output[:datePublished].nil?

       output[:temporal] = filter(recordMetadata, '$..originInfo[?(@.edition != "[Electronic ed.]" || !@.edition )].dateIssued[?(!@._keyDate)].$text') 
       schema_out["temporal"] =  output[:temporal] if !output[:temporal].nil?

       # additionalType is already used for CreativeWork
       # filter(recordMetadata, '$.typeOfResource.$text' ) 
       
        
       output[:location] = filter(recordMetadata, '$.location[?(@.url)].url.$text')

       output[:sameAs]=output[:location]

       schema_out["sameAs"]=output[:sameAs] if !output[:sameAs].nil?

       digital_presentation = filter(record, '$.metadata..amdSec.digiprovMD')
       presentation_id = filter(digital_presentation, '$.._ID').first
       links = filter(digital_presentation, '$..links')
       presentation_links = filter(digital_presentation, '$..links.presentation')
       # viewer = links.first["_xmlns:dv"]
       
       dmdSecId = filter(record, '$.metadata..dmdSec.._ID')

       embedUrl = dmdSecId.map{ |i|  
        "http://dfg-viewer.de/show/?set[mets]=#{CGI::escape("http://visualcollections.ub.uni-mainz.de/oai/?verb=GetRecord&metadataPrefix=mets&identifier=#{i.sub(/^md/, '')}") }"
       }

       unless digital_presentation.empty?
          # puts "digital_presentation : #{digital_presentation}" 
          
            associatedMedia = schema_out_object(id: "#{id}_#{presentation_id}", type: "MediaObject", url: embedUrl) 

            associatedMedia["identifier"] = "#{id}_#{presentation_id}"
            associatedMedia["name"] = "#{presentation_id}"            
            associatedMedia["sameAs"] = presentation_links
            associatedMedia["thumbnailUrl"] = thumbnailUrl

                #"copyrightHolder"
                #"copyrightYear"
                #"text"
                #"transcript"
                #"creator"
                #"sourceOrganization"                
                #"encodingFormat"
            associatedMedia["embedUrl"]   = embedUrl
            associatedMedia["contentUrl"] = contentUrl
            
          
            output[:associatedMedia] = associatedMedia
            schema_out["associatedMedia"]=output[:associatedMedia]
        end

        isPartOf = []

        type_mapping = {
            "multivolume monograph" => "PublicationVolume"
        }

        filter(recordMetadata, '$.relatedItem').each do |related_item|
            relation_type = filter(related_item, '$._type').first
            related_item_urn_id = filter(related_item, '$.identifier[?(@._type=="urn")].$text').first

            title_infos =  filter(related_item, '$.titleInfo')
            name  = title_infos.select{ |t| t['_type'] != 'alternative'  }.map{ |t| script_checker(t['title'], t['_script']) }
            alternate_name = title_infos.select{ |t| t['_type'] == 'alternative'  }.map{ |t| t['title'] } 

            related_item_type = filter(related_item, '$.genre.$text').map{ |t| type_mapping[t] }

            related_item_id = "#{@prefixid}_#{related_item_urn_id}"
            if relation_type == "host"
                related_item = schema_out_object(id: related_item_id, type: related_item_type.first, url: "#{@url_prefix}/#{related_item_id}") 
                related_item["name"] = name
                related_item["alternateName"] = alternate_name
                isPartOf << related_item
            end
        end

       output[:isPartOf] = isPartOf
       schema_out["isPartOf"]=output[:isPartOf]

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
    url = nil

=begin    
<mets:fileSec>
<mets:fileGrp USE="DOWNLOAD">
<mets:file MIMETYPE="application/pdf" CHECKSUM="454968e6f8559fb05085b3c962adf301c769dd36" CREATED="2016-08-16T07:43:39Z" CHECKSUMTYPE="SHA-1" SIZE="1189886" ID="PDF_1949">
<mets:FLocat xlink:href="http://visualcollections.ub.uni-mainz.de/autographen/download/pdf/1949" LOCTYPE="URL"/>
</mets:file>
</mets:fileGrp>
<mets:fileGrp USE="FRONTIMAGE">
<mets:file MIMETYPE="image/jpeg" CREATED="2014-07-18T07:46:44Z" ID="IMG_FRONTIMAGE_10023">
<mets:FLocat xlink:href="http://visualcollections.ub.uni-mainz.de/autographen/download/webcache/304/10023" LOCTYPE="URL"/>
</mets:file>
</mets:fileGrp>
http://visualcollections.ub.uni-mainz.de/ubmzms/titlepage/urn/urn:nbn:de:hebis:77-vcol-3091
=end

# <oai:resumptionToken cursor="0" completeListSize="605">100-1389654000-testset-lom</oai:resumptionToken>
# https://gutenberg-capture.ub.uni-mainz.de/autographen/oai?verb=ListRecords&resumptionToken=0x96cfe6f726928101f4b50a1c4211d072-cursor_p_3D10_p_26metadataPrefix_p_3Dmets_p_26batch_size_p_3D11'


    filter(data, '$..ListRecords.resumptionToken.$text').each do |resumptionToken|
        url = "#{listurl}&resumptionToken=#{resumptionToken}"
    end


end

