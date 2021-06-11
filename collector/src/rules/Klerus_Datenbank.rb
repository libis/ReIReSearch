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

source_file_name = 'pfarrklerus.mdb'

url = "file://#{SOURCE_RECORDS_DIR}/JGUKlerusDatenbank/#{source_file_name}"

#options = {user: config[:user], password: config[:password]}
options = {user: 'nvt', password: 'nvt'}

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


Dir.glob("#{records_dir}/*").each { |file| File.delete(file)}

while url
    @logger.info ("Load URL : #{  url }")
    timing_start = Time.now

    data = input.from_uri(url, options)
    @logger.info ("Data loaded in #{((Time.now - timing_start) * 1000).to_i} ms")

    persons = data["Tab:-A)-Personen"]
    @logger.info("Number of Persons : #{persons.size}")

    #family            = data["Tab:-B)-Familie"]
    #study             = data["Tab:-C)-Studiengang"]       
    #ordination        = data["Tab:-D)-Weihen"]
    #incident          = data["Tab:-E)-Vorkommnisse"]
    #religious_clergy  = data["Tab:-F)-Ordensklerus"]
    #collegiate_clergy = data["Tab:-G)-Stiftsklerus"]
    #diocesan_clergy   = data["Tab:-H)-Diözesanklerus"]
    #sources           = data["Tab:-I)-Quellen/Literatur"]
    #biographic_notes  = data["Tab:-J)-Biograph-Notizen"]

    
    #persons = persons[120..180]
    #persons = persons[2500..2510]
    
    selection = ["180","11"]
    persons = persons.select { |person| selection.include?(person[:ID]) } 

    persons.each do |person|
        log ("person: #{person[:ID]}")
        urn_id = person[:ID]
        urn_id = urn_id.to_s.rjust(9, "0") # create a 9 digit long id
        id = "#{@prefixid}_#{urn_id}"
       
        type = "Person"
        schema_out_object(id: id, type: type, url: "#{@url_prefix}/#{id}")

        #puts output.raw
        puts "person"
        puts person

        output[:familyName] = person[:"Nachname"]
        output[:givenName]  = person[:"Vorname"]
        output[:name]       = "#{ person[:"Nachname"]}, #{ person[:"Vorname"] }"
    
        output[:birthDate]  = parse_date(person[:"Geb-Tag"]) unless person[:"Geb-Tag"].nil?

        output[:birthPlace] = {            
                :@type => "Place", 
                :name => person[:"Geb-Ort"]
            } unless person[:"Geb-Ort"].nil?

        output[:deathDate]  = parse_date(person[:"Sterbe-Tag"]) unless person[:"Sterbe-Tag"].nil?
        output[:deathPlace] = {            
                :@type => "Place", 
                :name => person[:"Sterbe-Ort"]
            } unless person[:"Sterbe-Ort"].nil?

        output[:description]  = person[:"Bemerkungen"]

        family = data["Tab:-B)-Familie"].select { |s|  s[:"ID"] ==  person[:"ID"] }
        family = join_tables(data, family, :"Stand-Nr", "Tab:-zB1)-Stand/Beruf", :"Stand-Nr")

        #puts "family"
        #puts family

        study = data["Tab:-C)-Studiengang"].select       { |s|  s[:"ID"] ==  person[:"ID"] }
        study = join_tables(data, study, :"Nrr", "Tab:-zC1)-Ausbildung", :"Nrr")
        study = join_tables(data, study, :"Fach-Nr", "Tab:-zC2)-Fächer", :"Fach-Nr")

        ordination = data["Tab:-D)-Weihen"].select { |s|  s[:"ID"] ==  person[:"ID"] }
        ordination = join_tables(data, ordination, :"Typ-Nr", "Tab:-zD1)-Weihe", :"Typ-Nr")

        incident  = data["Tab:-E)-Vorkommnisse"].select{ |s|  s[:"ID"] ==  person[:"ID"] }
     
        religious_clergy = data["Tab:-F)-Ordensklerus"].select { |s|  s[:"ID"] ==  person[:"ID"] }
        religious_clergy = join_tables(data, religious_clergy, :"Orden-Nr", "Tab:-zF1)-Orden", :"Orden-Nr")
        religious_clergy = join_tables(data, religious_clergy, :"Or-Status", "Tab:-zF3)-Ordensstatus", :"Or-Status")
        religious_clergy = join_tables(data, religious_clergy, :"Or-Amt", "Tab:-zF2)-Ordensämter", :"Or-Amt")

        collegiate_clergy = data["Tab:-G)-Stiftsklerus"].select { |s|  s[:"ID"] ==  person[:"ID"] }
        collegiate_clergy = join_tables(data, collegiate_clergy, :"Stel-Nr", "Tab:-zG1)-Funktion", :"Stel-Nr")

        diocesan_clergy  = data["Tab:-H)-Diözesanklerus"].select    { |s|  s[:"ID"] ==  person[:"ID"] }
        diocesan_clergy = join_tables(data, diocesan_clergy, :"AmtNr", "Tab:-zH1)-Amt/Funktion", :"AmtNr")

        sources           = data["Tab:-I)-Quellen/Literatur"].select { |s|  s[:"ID"] ==  person[:"ID"] }
        biographic_notes  = data["Tab:-J)-Biograph-Notizen"].select  { |s|  s[:"ID"] ==  person[:"ID"] }
       
        unless family.empty?
        #        parent     Tab: -B)-Familie: Vater-Vorname / Mutter-Vorname
        #        relatedTo	Tab: -B)-Familie: Paten, Verwandte
            @logger.debug "family: #{family}"
            
            output[:parent]    = family.reject{ |e|e[:"Vater-Vorname"].nil? }.map { |e| 
                { 
                    :@id => "#{id}_PERSON_MALE_#{e[:"Fam-Nr"]}", 
                    :@type => "Person", 
                    :gender => "Male", 
                    :name => e[:"Vater-Vorname"] 
                } 
            }
            output[:parent]    = family.reject{ |e|e[:"Mutter-Vorname"].nil? }.map { |e| 
                { 
                    :@id => "#{id}_PERSON_FEMALE_#{e[:"Fam-Nr"]}", 
                    :@type => "Person", 
                    :gender => "Female", 
                    :name => e[:"Mutter-Vorname"] 
                } 
            }
            output[:relatedTo] = family.reject{ |e|e[:"Verwandte"].nil?     }.map { |e|
                { 
                    :@id => "#{id}_PERSON_RELATED_#{e[:"Fam-Nr"]}",
                    :@type => "Person", 
                    :name => e[:"Verwandte"]
                }
            }
        end

        unless study.empty?
            #   alumniOf	Tab:- C)-Studiengang: Studienort
            #   memberOf 	Tab:- C)-Studiengang: Studienort
            #   affiliation Tab:- C)-Studiengang: Studienort
            
            @logger.debug "study: #{study}"

# {:Nrr=>"5", :Studienort=>"Rom, Germanicum", :von=>"1.6190000000000000e+03", :bis=>"1.6220000000000000e+03", :Ausland?=>"1", :"Fach-Nr"=>"3", :Abnr=>nil, :wann=>nil, :Veröffentlichungen=>nil, :Bemerkungen=>nil, :MK=>"1"}
#===== ALUMNI OF === https://stackoverflow.com/questions/51315725/resume-work-history-and-organization-format-with-json-ld-and-schema-org-vocab
            output[:alumniOf] = study.map { |e| 
                course = nil
                course = e[:"Fach-Nr"][:"Fach"] unless e[:"Fach-Nr"].nil?

                name = nil
                name = e[:"Nrr"][:"Ausb"] unless e[:"Nrr"].nil?
                unless name.nil?
                    {   
                        :@type => "Organization",
                        :@id   => "#{id}_ORGANIZATION_STUDY_#{e[:"Stud-Nr"]}",
                        :name  => name,
                        :location => e[:"Studienort"],
                        :description => course
                    }
                end
            }
            
        end

        unless ordination.empty?
            # honorificSuffix	Tab: -D)-Weihen: Weihetitel?
            # Tab: D)-Weihen: Titelbistum
    
            @logger.debug  "ordination #{ordination}"

            puts "ordination"
            puts ordination
            #:wann?=>"1.6210530000000001e+03", :Ort=>"Heiligenstadt", :Kirche=>"St. Ägidien", :durch=>"Christoph Weber", :"assistiert von"=>nil, :und=>nil, :Weihetitel=>nil, :Titelbistum=>nil, :Bemerkungen=>nil, :MK=>"1"}
            # @type   = Church
            # name    = :Kirche=>"St. Ägidien"
            # address = :Ort=>Heiligenstadt
               
            output[:subjectOf] = ordination.map { |e|  
                name = nil
                name = e[:"Typ-Nr"][:"Weihe"] unless e[:"Typ-Nr"].nil?

                location = [ e[:"Ort"], e[:"Titelbistum"] ].compact.join(", ")
                
                unless e[:"Kirche"].nil?
                    location =  {
                        :@type => "Place",
                        :name => e[:"Kirche"],
                        :address => location
                    } 
                end

                startDate = nil 
                startDate = parse_date( e[:"wann?"]) unless e[:"wann?"].nil?

                decription = nil
                unless e[:"durch"].nil?
                    decription = "Weihe durch #{e[:"durch"]}"
                    unless e[:"assistiert von"].nil?
                        decription += " mit assistiert von #{e[:"assistiert von"]}"
                        unless e[:"und"].nil?
                            decription += " und #{e[:"und"]}"
                        end
                    end
                    unless e[:"Weihetitel"].nil?
                        decription += " tot #{e[:"Weihetitel"]}}"  
                    end
                end

                unless e[:"Bemerkungen"].nil?
                    unless decription.nil?
                        decription += " (#{ e[:"Bemerkungen"]})" 
                    else
                        decription = "(#{ e[:"Bemerkungen"]})" 
                    end
                end
       
                unless name.nil?
                    {   
                        :@type => "Event",
                        :@id   => "#{id}_EVENT_ORDINATION_#{e[:"Weih-Nr"]}",
                        :name  => name,
                        :description => decription,
                        :location    => location,  
                        :startDate   => startDate
                    }   
                end
            }
        end
    
        unless religious_clergy.empty?
            #   worksFor	"Tab: -F)-Ordensklerus: Ord-Nr
            #   hasOccupation	"Tab: -F)-Ordensklerus: Or-Amt
            #   jobTitle	"Tab: -zF2)-Ordensämter: Ordensämter
            #   memberOf	"Tab: -F)-Ordensklerus: Ord-Nr
            
            @logger.debug  "religious_clergy #{religious_clergy}"

            output[:memberOf] = religious_clergy.map { |e|  

                roleName, startDate, endDate = nil

                roleName  = e[:"Or-Status"][:"Status"] unless e[:"Or-Status"].nil?
                roleName  = "#{roleName}, " unless (roleName.nil? || e[:"Or-Amt"].nil?)
                roleName  = e[:"Or-Amt"][:"Ordensämter"] unless e[:"Or-Amt"].nil?
                
                startDate = parse_date( e[:seit] ) unless e[:seit].nil?
                endDate   = parse_date( e[:bis] ) unless e[:bis].nil?

                name = "Ordensklerus: "
                name = "#{e[:"Orden-Nr"][:"Orden"]}" unless e[:"Orden-Nr"].nil?         

                location = [ e[:"Institution/Haus"], e[:"Institution/Ort"] ].compact.join("; ")
                desctiption = e[:":Bemerkungen"] 

                {
                    :@type => "Role",
                    :memberOf =>  {
                        :@type => "Organization",
                        :@id   => "#{id}_ORGANIZATION_REL_CLERGY_1",
                        :name  => name,
                        :location => location,
                        :desctiption => desctiption
                    },
                    :startDate => startDate,
                    :endDate   => endDate,
                    :roleName  => roleName
                }
            }
=begin
            output[:jobTitle] = religious_clergy.map { |e|  
                jobTitle = nil
                jobTitle = e[:"Or-Amt"][:"Ordensämter"] unless e[:"Or-Amt"].nil? 
                jobTitle
            }

            output[:worksFor] = religious_clergy.map { |e|   
                name = "Ordensklerus: "
                name = "#{e[:"Orden-Nr"][:"Orden"]}" unless e[:"Orden-Nr"].nil?         

                location = [ e[:"Institution/Haus"], e[:"Institution/Ort"] ].compact.join("; ")
                unless name.nil?
                    {   
                        :@type => "Organization",
                        :@id   => "#{id}_ORGANIZATION_REL_CLERGY_1",
                        :name  => name,
                        :location => location,
                        :desctiption => e[:":Bemerkungen"]
                    }
                end
            }
=end
        end

        unless collegiate_clergy.empty?  
            #Stiftsklerus => kapittel of seculiere kanunniken
            @logger.debug  "collegiate_clergy #{collegiate_clergy}"
            #Tab: -G)-Stiftsklerus: Sti-Nr"
            #Tab: -G)-Stiftsklerus: Stel-Nr"
            #Tab:- zG1)-Funktion: Funktion"


            output[:memberOf] = collegiate_clergy.map { |e|  

                roleName, startDate, endDate = nil

                roleName  = e[:"Stel-Nr"][:"Funktion"] unless e[:"Stel-Nr"].nil? 
                
                startDate = parse_date(e[:von]) unless e[:von].nil?
                endDate   = parse_date(e[:bis]) unless e[:bis].nil?

                name = "Stiftsklerus"
                location = [  e[:"Haus"], e[:"Ort"] ].compact.join("; ")
                desctiption = e[:":Bemerkungen"] 


                {
                    :@type => "Role",
                    :memberOf =>  {
                        :@type => "Organization",
                        :@id   => "#{id}_ORGANIZATION_COL_CLERGY_#{e[:"Sti-Nr"]}",
                        :name  => name,
                        :location => location,
                        :desctiption => desctiption
                    },
                    :startDate => startDate,
                    :endDate   => endDate,
                    :roleName  => roleName
                }
            }

=begin
            output[:jobTitle] = collegiate_clergy.map { |e|  
                jobTitle = nil
                jobTitle = e[:"Stel-Nr"][:"Funktion"] unless e[:"Stel-Nr"].nil? 
                jobTitle
            }

            output[:worksFor] = collegiate_clergy.map { |e|   
                name = "Stiftsklerus"
                location = [  e[:"Haus"], e[:"Ort"] ].compact.join("; ")
                unless name.nil?
                    {   
                        :@type => "Organization",
                        :@id   => "#{id}_ORGANIZATION_COL_CLERGY_#{e[:"Sti-Nr"]}",
                        :name  => name,
                        :location => location,
                        :desctiption => e[:":Bemerkungen"]
                    }
                end
            }
=end
        end

        
        unless diocesan_clergy.empty?
            @logger.debug  "diocesan_clergy #{diocesan_clergy}"
            #Tab: -H)-Diözesanklerus: Diö-Nr
            #Tab: -H)-Diözesanklerus: Amtnr
            #Tab: -zH1)-Amt/Funktion: Amt    

            output[:memberOf] = diocesan_clergy.map { |e|  

                roleName, startDate, endDate = nil
                roleName  = e[:"AmtNr"][:"Amt"] unless e[:"AmtNr"].nil? 
                
                startDate = parse_date(e[:von]) unless e[:von].nil?
                endDate   = parse_date(e[:bis]) unless e[:bis].nil?

                name = "Diözesanklerus "
                location = [ e[:"Kirche"], e[:"Ort"] ].compact.join("; ")
                desctiption = e[:":Bemerkungen"] 

                {
                    :@type => "Role",
                    :memberOf =>  {
                        :@type => "Organization",
                        :@id   => "#{id}_ORGANIZATION_DIO_CLERGY_#{e[:"Diö-Nr"]}",
                        :name  => name,
                        :location => location,
                        :desctiption => desctiption
                    },
                    :startDate => startDate,
                    :endDate   => endDate,
                    :roleName  => roleName
                }
            }

=begin
            output[:jobTitle] = diocesan_clergy.map { |e|  
                jobTitle = nil
                jobTitle = e[:"AmtNr"][:"Amt"] unless e[:"AmtNr"].nil? 
                jobTitle
            }

            output[:worksFor] = diocesan_clergy.map { |e|   
                name = "Diözesanklerus "
                location = [ e[:"Kirche"], e[:"Ort"] ].compact.join("; ")
                unless name.nil?
                    {   
                        :@type => "Organization",
                        :@id   => "#{id}_ORGANIZATION_DIO_CLERGY_#{e[:"Diö-Nr"]}",
                        :name  => name,
                        :location => location,
                        :desctiption => e[:":Bemerkungen"]
                    }
                end
            }
=end

        end

        unless sources.empty?
        # subjectOf	Tab: -I)-Quellen/Literatur: QQ-Lit-Nr
            @logger.debug  "sources #{sources}"
            output[:subjectOf] =  sources.map{ |e|
                unless e[:"Quellen/Literatur"].nil?
                    {   
                        :@type => "CreativeWork",
                        :@id   => "#{id}_CREATIVEWORK_LITERATUR_#{e[:"QQ-Lit-Nr"]}",
                        :name  => e[:"Quellen/Literatur"] 
                    }
                end
            }

        end

        unless biographic_notes.empty?
            # sameAs	Tab: -J)-Biograph-Notizen: Biog-Nr
            @logger.debug  "biographic_notes #{biographic_notes}"
            output[:description] =  biographic_notes.map{ |e| 
                "Notizen: #{e[:"Notizen"]}"
            }
        end

        output.clean()
        output.add_all_ids(prefix: id)

        output.to_json(id.gsub(/[.\/\\:\?\*|"<>]/, '-'), records_dir)
        output.clear()

    end

    url=nil
end
