#encoding: UTF-8
$LOAD_PATH << '.' << './lib'
require 'lib/builder/marc'

#######################################################################################
# Alma sandbox 32KUL_KUL 
# Profiel "Linked data bible Marc21" output format XML Marc21
#
# RUN publishing profiles 
#
# Files will be created on libis-p-ftp-1 /ftp/ALMA/ALMA
#
#######################################################################################

def collect_alma_data( source_dir:, source_file_name:, ingestConf:, options:)

  puts "START COLLECTING"
  ######################################################################################
  reiresConfJson = File.read(File.join(File.dirname(__FILE__), '../config/config.cfg'))
  reiresConf = JSON.parse(reiresConfJson)

  ######################### Dataset and Dataprovider Configuration ######################
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

  #######################################################################################
  @url_prefix = reiresConf["url_prefix"]
  @prefixid =  "#{reiresConf["prefixid"]}_#{ @provider["@id"] }_#{ @dataset["@id"] }"

  # @sdLicense = reiresConf["sdLicense"]
  # @sdPublisher = reiresConf["sdPublisher"]
  #######################################################################################

 
  #Link to Limo => bases on institution id
  #same_as_template = "https://limo.libis.be/primo-explore/search?query=any,contains,<#record_id>&vid=KULeuven&lang=en_US"
  #Link to Limo => bases on networkzone  id (different publishing profile)
  # same_as_template = https://limo.libis.be/primo-explore/fulldisplay?docid=<#record_id>&context=L&vid=KULeuven&search_scope=ALL_CONTENT&tab=all_content_tab&lang=en_US

  records_dir = "#{RECORDS_DIR}/Alma_KULeuven/#{@dataset["@id"]}"
  
  @counter = 0
  record_count = 0
  
  if options[:full_export] 
    log("Clear records #{records_dir}/*.json")
    Dir.glob("#{records_dir}/*.json").each { |file| File.delete(file)}
  else
    log("DO NOT CLEAR RECORDS DIR; It is a partial export [#{records_dir}]")
  end

  source_dir = source_dir || SOURCE_RECORDS_DIR
  log("SOURCE_RECORDS_DIR : #{ source_dir }")
  log("source_file_name : #{ source_file_name }")
  
#  filter(data, '$..collection.record').each do |record|

  nori = Nori.new(parser: :nokogiri, strip_namespaces: true, convert_tags_to: lambda {|tag| tag.gsub(/^@/, '_')})

  Dir["#{source_dir}/#{source_file_name}"].each_with_index do |source_file, index| 
    log(" parsing #{source_file}")
    timing_start = Time.now
    x = XmlSplit.new(source_file, 'record')
    x.each_with_index { |node,i| 
        filter( nori.parse(node) , '$.record').each do |record|
            #@logger.debug(" ReIReS parser - record : #{record} ")
            ## To debug a large xml-file.
            ## Split the xml-file in smal chunks; 1 json representation per file

=begin
            #if i % 7 == 0
              split_dir = "/app/records/split_records"
              unless File.directory?(split_dir)
               FileUtils.mkdir_p(split_dir)
              end
              file_name = "#{split_dir}/record_#{i}.json"
              File.open(file_name, 'wb') do |f|
                f.puts record.to_json
              end
            #end
=end            
            #if i.between?(24660 , 24670)
              parse_record( record: record, index: i, records_dir: records_dir)
            #end
        end
        index += 1
        if index % 5000 == 0
            @logger.info(" ReIReS parser - #{index} records already parsed ")   
        end
    }
    record_count += index
  end

####### PARSE A FEW RECORDS !!!!!!!!!!!!!!!!!!######################
=begin
files =[]
files <<  "/app/records/split_records/record_68138.xml"
files << "/app/records/split_records/record_15489.xml"
###################################################################
records_dir = "/app/records/Alma_KULeuven/test/"
Dir.glob("#{records_dir}/*.json").each { |file| File.delete(file)}

files.each_with_index do |file,i|  
  record = JSON.parse(File.read(file))
  parse_record( record: record, index: 0, records_dir: records_dir)
end
=end

end

def parse_record( record: , index: , records_dir: )
  #filter(data, '$..collection.record').each do |record|
   
    builder = Builder::MARC.new(record)
    @counter  = 0
    person_counter = 0
    organization_counter = 0
    places_counter = 0
    creativework_counter = 0
    json_out ={}

    id = "#{@prefixid}_#{builder.id}"
    type = builder.type_detection || @defaulttype

    # log("type after type_detection: #{ type }")

    #output[:source_record_id] = "32LIBIS_ALMA_DS#{builder.id}"
    output[:source_record_id] = "#{builder.id}"
    output[:id] = "#{@prefixid}_#{builder.id}"
    output[:url] = @url_prefix + id
    
      ### Rare books have signature statement instead of pagination in tag 300
    rare_book_detection = builder.rare_book_detection
    schema_out = schema_out_object(id:  id, type: type, url: "#{@url_prefix}/#{id}") 
    
    sameAs = @same_as_template.gsub(/<#record_id>/, output[:source_record_id])

    #######################################################
    # Titles => Name and AlternateName
    #######################################################
    title = builder.title
    unless ! title.empty?
      title = ['NO TITLE']
      log("TITLE: #{ title }")
    end
    
    other_title = builder.other_title
    translated_title = builder.translated_title # check datamodel @language schema.org/name
    abbreviated_title = builder.abbreviated_title   
    uniform_title = builder.abbreviated_title
    
    output[:sameAs] =  sameAs unless sameAs.nil?

    output[:title] = title
    output[:other_title] = other_title unless other_title.nil?
    output[:other_title] = uniform_title unless uniform_title.nil?
    output[:other_title] = abbreviated_title unless abbreviated_title.nil?


    schema_out["name"] = output[:title]

    schema_out["alternateName"] = output[:other_title] unless output[:other_title].nil?
    schema_out["sameAs"] = output[:sameAs] unless output[:sameAs].nil?

    languages = builder.languages
    output[:language] = languages unless languages.nil?
    schema_out["inLanguage"] = output[:language][0] unless output[:language].nil?

    #######################################################
    # Persons  => Author, contributor, editor, ...
    #######################################################

    author      = builder.author
    editor      = builder.editor
    contributor = builder.contributor
    illustrator = builder.illustrator
    translator  = builder.translator

  #  @counter = person_counter
  #  add_ids( data: author , prefix:  "#{@prefixid}_#{builder.id}_PERSONS",   counter_start:@counter )
  #  add_ids( data: contributor , prefix:  "#{@prefixid}_#{builder.id}_PERSONS",   counter_start: @counter )
  #  add_ids( data: editor , prefix:  "#{@prefixid}_#{builder.id}_PERSONS",   counter_start:@counter )
  #  add_ids( data: illustrator , prefix:  "#{@prefixid}_#{builder.id}_PERSONS",   counter_start:@counter )
  #  add_ids( data: translator , prefix:  "#{@prefixid}_#{builder.id}_PERSONS",   counter_start:@counter )
  #  person_counter = @counter
  
    output[:author] = author unless author.nil?
    output[:contributor] = contributor unless contributor.nil?
    output[:editor] =  editor unless editor.nil?

    schema_out["author"] = output[:author] unless output[:author].nil?
    schema_out["contributor"] = output[:contributor] unless output[:contributor].nil?
    schema_out["editor"] = output[:editor] unless output[:editor].nil?

    #######################################################
    # Publication Data => Publisher, 
    #######################################################
    publisher = builder.publisher
  #  @counter = organization_counter
  #  add_ids( data: publisher , prefix:  "#{@prefixid}_#{builder.id}_ORGANIZATIONS",   counter_start: @counter )
  #  organization_counter = @counter
    output[:publisher] =  publisher unless publisher.nil?    

    publisher_person = builder.publisher_person
  #  @counter = person_counter
  #  add_ids( data: publisher_person , prefix:  "#{@prefixid}_#{builder.id}_PERSONS",   counter_start:@counter )
  #  person_counter = @counter

    output[:publisher] = publisher_person unless publisher_person.nil?
    schema_out["publisher"] = output[:publisher] unless output[:publisher].nil?

    #######################################################
    # Dates => datePublished, dateCreated
    #######################################################

    datePublished = builder.datePublished
    dateCreated = builder.dateCreated

    output[:datePublished] =  datePublished  unless datePublished.nil?
    output[:dateCreated]   =  dateCreated unless dateCreated.nil?

    schema_out["datePublished"] = output[:datePublished] unless output[:datePublished].nil?
    schema_out["dateCreated"] = output[:dateCreated]  unless output[:dateCreated].nil?

    #######################################################
    # Places => locationCreated
    #######################################################
    locationCreated = builder.locationCreated
    
  #  @counter = places_counter
  #  add_ids( data: locationCreated , prefix:  "#{@prefixid}_#{builder.id}_PLACES",   counter_start: @counter )
  #  places_counter = @counter

    output[:locationCreated] =  locationCreated unless locationCreated.nil?
    schema_out["locationCreated"] = output[:locationCreated]  unless output[:locationCreated].nil?

    #######################################################
    # Identifiers => ISBN, ISSN, ... 
    #######################################################
    identifier = builder.identifiers

    identifier1 = identifier.slice!("ISBN", "ISSN")  unless identifier.nil?

    output[:identifier] = identifier unless identifier.nil?
    schema_out["isbn"] = output[:identifier]["ISBN"] unless output[:identifier].nil? || output[:identifier]["ISBN"].nil?
    schema_out["issn"] = output[:identifier]["ISSN"] unless output[:identifier].nil? || output[:identifier]["ISSN"].nil?
    schema_out["identifier"] = identifier1 unless output[:identifier].nil? || identifier1.nil? || identifier1.empty?
  
    unless schema_out["isbn"].nil?
      unless type == "Book"
        unless schema_out["additionalType"].kind_of?(Array)
          schema_out["additionalType"] = [ schema_out["additionalType"] ]
        end
        schema_out["additionalType"] << "Book"
        # Momenteel kan het systeem niet overweg met een array van additionalTypes
        schema_out["additionalType"] = "Book"
      end
    end

    unless schema_out["issn"].nil?
      unless type == "CreativeWorkSeries"
        unless schema_out["additionalType"].kind_of?(Array)
          schema_out["additionalType"] = [ schema_out["additionalType"] ]
        end
        schema_out["additionalType"] << "CreativeWorkSeries"
        # Momenteel kan het systeem niet overweg met een array van additionalTypes
        schema_out["additionalType"] = "CreativeWorkSeries"
      end
    end    
  
    #######################################################
    # Edition
    #######################################################
    edition = builder.edition
    output[:edition] =  edition unless edition.nil?
    schema_out["bookEdition"] = output[:edition] unless output[:edition].nil?

    #######################################################
    # Description
    #######################################################

    description = builder.description
    output[:description] =  description unless description.nil?
    schema_out["description"] = output[:description] unless output[:description].nil?

    #######################################################
    # Subjects => keyword
    # 650_7 => WAT TE DOEN MET LOCAL SUBJECTS ???????????
    #######################################################
      
    keyword = builder.keyword
    output[:keywords] =  keyword unless keyword.nil?
    schema_out["keywords"] = output[:keywords] unless output[:keywords].nil?

    #######################################################
    # Pagination, VolumeNumber
    #######################################################

    pagination =  builder.pagination

    if type == "Article" && !pagination.nil?
      output[:pagination]  = pagination unless pagination.nil?
      schema_out["pagination"] = output[:pagination] unless output[:pagination].nil?   
    else
      if output[:description].nil?
        output[:description] = ["Signature statement: #{ pagination.join(", ") }"]
      else
        output[:description] << "Signature statement: #{ pagination.join(", ") }"
      end
      schema_out["description"] = output[:description]
    end

    if type == "Article"
      volumeNumber =  builder.volumeNumber
      output[:volumeNumber]  = volumeNumber unless volumeNumber.nil?
      schema_out["volumeNumber"] = output[:volumeNumber] unless output[:volumeNumber].nil?
    end

    #######################################################
    # Related Work
    #######################################################
    
    isPartOf = builder.isPartOf
  #  @counter = creativework_counter
  #  add_ids( data: isPartOf , prefix:  "#{@prefixid}_#{builder.id}_CREATIVE_WORKS",   counter_start: @counter )
  #  creativework_counter = @counter
    
    output[:isPartOf]  = isPartOf unless isPartOf.nil?
    schema_out["isPartOf"] = output[:isPartOf] unless output[:isPartOf].nil?

    translationOfWork = builder.translationOfWork
  #  @counter = creativework_counter
  #  add_ids( data: translationOfWork , prefix:  "#{@prefixid}_#{builder.id}_CREATIVE_WORK",   counter_start: @counter )
  #  creativework_counter = @counter
    
    output[:translationOfWork]  = translationOfWork unless translationOfWork.nil?
    schema_out["translationOfWork"] = output[:translationOfWork] unless output[:translationOfWork].nil?

    #######################################################
    # Same As
    #######################################################
    # 856 4 (0,1) Link (url) to related electronic resource (digital/digitized version hosted by KU Leuven)
    # 865 _ 2     Link (url) to related electronic resource (any related online document) 

### associatedMedia  => resolver.libis.be/IIE4952832/representation
### sameAs => 856 u
#<datafield tag="856" ind1="4" ind2="1">
#  <subfield code="u">http://mdz-nbn-resolving.de/urn:nbn:de:bvb:12-bsb11203529-7</subfield>
#  <subfield code="y">Digitized version</subfield>
#  <subfield code="z">Bayerische Staatsbibliothek</subfield>
#</datafield>

    sameAs = builder.identifiers_same_as
    output[:sameAs] =  sameAs unless sameAs.nil?
    schema_out["sameAs"] = output[:sameAs]  unless output[:sameAs].nil?


    #######################################################
    # associatedMedia
    #######################################################
    # 856 4 (0,1) Link (url) to related electronic resource (digital/digitized version hosted by KU Leuven)
    # 865 _ 2     Link (url) to related electronic resource (any related online document) 

    ### associatedMedia  => resolver.libis.be/IIE4952832/representation
    ### sameAs => 856 u
    #<datafield tag="856" ind1="4" ind2="1">
    #  <subfield code="u">http://mdz-nbn-resolving.de/urn:nbn:de:bvb:12-bsb11203529-7</subfield>
    #  <subfield code="y">Digitized version</subfield>
    #  <subfield code="z">Bayerische Staatsbibliothek</subfield>
    #</datafield>

      associatedMedia = builder.associatedMedia

      associatedMedia.map! do |m|
        associatedMediaObj = schema_out_object(id: nil, type: nil, url: nil) 
        m["license"] = "https://bib.kuleuven.be/english/BD/digit/digitisation/images-as-open-data"
        associatedMediaObj.merge(m)
      end

=begin
      tmp_hash = {
        "@type"   => "CreativeWork",
        "name" =>  :name,
        "sameAs" =>  mediaobject["u"],
        #"url" => "system generated",
        "thumbnailUrl" =>  mediaobject[:name],
        "license" =>  mediaobject[:name],
        "copyrightHolder" =>  mediaobject[:name],
        "copyrightYear" =>  mediaobject[:name],
        #"provider" => "system generated",
        #"sdDatePublished" => "system generated",
        #"sdLicense" => "system generated",
        """sdPublisher" => "system generated",
        "text" => mediaobject[:name],
        "transcript" => mediaobject[:name],
        "creator" => mediaobject[:name],
        "sourceOrganization" => mediaobject[:name],
        "embedUrl" => mediaobject[:name],
        "encodingFormat" => mediaobject[:name]
      }
=end
      output[:associatedMedia] =  associatedMedia unless associatedMedia.nil?
      schema_out["associatedMedia"] = output[:associatedMedia]  unless output[:associatedMedia].nil?
###############################################################################

    cleanup_schema(schema_out)
    add_all_ids( data: schema_out, prefix:  "#{@prefixid}_#{builder.id}")
    schema_out = becompact(schema_out)

    unless schema_out.empty?
        output.to_jsonfile(schema_out.compact, id.gsub(/[.\/\\:\?\*|"<>]/, '-'), records_dir )
        #output.to_jsonfile(schema_out, id.gsub(/[.\/\\:\?\*|"<>]/, '-'), records_dir )
    end
    output.clear()   

# end
end



def collect_alma_deletes( source_dir:, source_file_name:, ingestConf:, options:)
  ######################################################################################
  reiresConfJson = File.read(File.join(File.dirname(__FILE__), '../config/config.cfg'))
  reiresConf = JSON.parse(reiresConfJson)

  ######################### Dataset and Dataprovider Configuration ######################
  @dataset = ingestConf["dataset"]
  @provider = ingestConf["provider"]
  @license = ingestConf["license"]

  #######################################################################################
  @url_prefix = reiresConf["url_prefix"]
  @prefixid =  "#{reiresConf["prefixid"]}_#{ @provider["@id"] }_#{ @dataset["@id"] }"

  delete_records_dir = "#{RECORDS_DIR}/Alma_KULeuven/#{@dataset["@id"]}/deletes"

  if options[:full_export] 
    log("Clear records #{delete_records_dir}/*.json")
    Dir.glob("#{delete_records_dir}/*.json").each { |file| File.delete(file)}
  else
    log("DO NOT CLEAR RECORDS DIR; It is a partial export [#{delete_records_dir}]")
  end

  source_dir = source_dir || SOURCE_RECORDS_DIR
  log("SOURCE_RECORDS_DIR : #{ source_dir }")
  log("source_file_name : #{ source_file_name }")

  records_dir = "#{RECORDS_DIR}/Alma_KULeuven/#{@dataset["@id"]}"
  log("records_dir : #{ records_dir }")
  existing_files = Dir.glob("#{records_dir}/*").select { |f| File.file?(f) }
  log("existing_files : #{ existing_files[0..10] }")

  Dir["#{source_dir}/#{source_file_name}"].each do |source_file|
    log("Load URL : file://#{  source_file }")
    timing_start = Time.now
    options = {user: 'nvt', password: 'nvt'}

    data = input.from_uri("file://#{ source_file }", options)
    log("Data loaded in #{((Time.now - timing_start) * 1000).to_i} ms")
    timing_start = Time.now

    filter(data, '$..collection.record').each do |record|
      builder = Builder::MARC.new(record)
      id = "#{@prefixid}_#{builder.id}"
      schema_out = {
        "@context": ["http://schema.org"],
        "@id": "#{id}",
      }

      file_id = id.gsub(/[.\/\\:\?\*|"<>]/, '-')
      files_to_delete_pattern = Regexp.new("#{records_dir.gsub("/","\\/")}#{file_id}_.*json")
      # puts("files_to_delete_pattern #{files_to_delete_pattern}  !!!!!")

      files_to_delete = existing_files.select{ |f| f.match(files_to_delete_pattern) }
      files_to_delete.each { |file| 
        log("Delete #{file}  !!!!!")
        File.delete(file)
      }

      unless schema_out.empty?
        output.to_jsonfile(schema_out.compact, file_id, delete_records_dir )
      end
      output.clear()   

    end
  end


end