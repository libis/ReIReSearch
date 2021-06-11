require 'net/smtp'
require 'logger'
require 'fileutils'
require 'json'
require 'pp'
require 'date'

#def config
#    @config ||= ConfigFile
#end

def default_options
  { 
    :config_file         => "config.yml",
    :log                 => "es_loader.log",
    :last_run_updates    => '2000-01-01T11:11:11+01:00',
    :max_records_per_file => 300,
    :full_reload         => false,
    :load_type           => "update",
    :record_dirs_to_load => nil,
    :record_pattern      => nil,
    :es_url              => nil,
    :es_version          => nil,
    :es_index            => nil,
    :es_pipeline_id      => nil,
    :import_mappings     => "/elastic/mappings.json",
    :import_settings     => "/elastic/settings.json",
    :import_pipeline     => "/elastic/pipeline.json"
  }
end

#######################################################################

def  checkData( jsondata)
    if jsondata.is_a?(Hash)
        if jsondata.key?("@context")
            if jsondata['@context'].is_a? String
                jsondata['@context'] = [  { "schema": "schema.org" } , { "@language" => "nl-Latn" } ]
            end
            if jsondata['@context'].is_a?(Array)
                if jsondata['@context'][0] == "http://schema.org"
                    jsondata['@context'][0] = { "schema": "schema.org" }
                end
            end
        end
        if jsondata.key?("location")
            if jsondata["location"].is_a? String
                jsondata["location"] = { "@type": "Place", "name": jsondata["location"] }
            end
            if jsondata["location"].is_a?(Array)
                jsondata["location"].map! do |loc|
                    if loc.is_a?(String)
                        {  "@type": "Place", "name": loc }
                    else
                        loc
                    end
                end
            end
        end
        jsondata.each do |jk,jd|
            jsondata[jk] = checkData( jd )
        end
    end
    if jsondata.is_a?(Array)
        jsondata.each do |jd|
            checkData( jd )
      end
    end
   jsondata
end

def  checkLangauge( jsondata, field_path, lang )
    fields = field_path.split('.')
    if fields.first == fields.last
        jsondata[ field_path ] = checkFieldLangauge( jsondata[ field_path ] , lang  )
    else
        field =  fields.shift
        field_path =  fields.join('.')
        data = jsondata[field]
        if ! data.nil?
            if data.is_a?(Array)
                #data.map! { |d| checkLangauge( d, field_path, lang ) }
                data.each { |d|
                    checkLangauge( d, field_path, lang )
                }
            else
                checkLangauge( data, field_path, lang )
            end
        end
    end
end

def  checkFieldLangauge( field, lang  )
    if field.is_a? String
        x = field
        field = { "@value": x , "@language": "#{ lang }-Latn" }
    else
        if field.is_a?(Array)
            field =  field.map { |x|
                if x.is_a? String
                { "@value": x , "@language": "#{ lang }-Latn" }
                else x
                end
            }
        end
    end
    field
end

def  checkPersonLangauge( person, lang  )
    if  person['name'].is_a?(Array)
        person['name'].map! do |n|
            if  n['name'].is_a? String
                n = { "@value": n['name'] , "@language": "#{ lang }-Latn" }
            end
            n
        end
    end
    if  person['name'].is_a? String
        person['name']  = { "@value": person['name'] , "@language": "#{ lang }-Latn" }
    end

    if  person['familyName'].is_a?(Array)
        person['familyName'].map! do |n|
            if  n['familyName'].is_a? String
                n = { "@value": person['familyName'] , "@language": "#{ lang }-Latn" }
            end
            n
        end
    end
    if  person['familyName'].is_a? String
        person['familyName']  = { "@value": person['familyName'] , "@language": "#{ lang }-Latn" }
    end

    person
end


def  parseDate( date, c_int  )
    r = nil
    date.upcase.each_char do |c|
        if ["X", "U", "?"].include?(c)
            r = ( (r.nil?) ? c_int  : r + c_int  )
        else
            r = ( (r.nil?) ? c : r + c )
        end
    end
    return r
end


#########################################################
# How to sort records based on the publication range
# Date Ascending : use the from date ["gte"]  the oldest first
# Date Descending : use the till date ["lte"] the newest first
#
# Records without date info must occur on the end of the list
# datePublished_from => 9999 (oldest first)
# datePublished_till => 0001 (newest first)
#

def createDateRange(date)

    fromyear = "9999"
    tillyear = "0001"

    if (date =~ /^.*([0-9UX?]{4}-[0-9UX?]{4}).*$/)
        date = date[/^.*([0-9UX?]{4}-[0-9UX?]{4}).*$/,1]
    end

    if (date =~ /^[^0-9UX]*-([0-9UX?]{4}).*$/)
        date = date[/^[^0-9UX]*-([0-9UX?]{4}).*$/,1]
    end
    if (date =~ /^.*([0-9UX?]{4})-(?!([0-9UX?]{1})).*$/)
        date = date[/^.*([0-9UX?]{4})-.*$/,1]
    end

    if (date =~ /^[0-9UX?]{4}-[0-9UX?]{4}$/)
        fromyear = parseDate( date[0, 4],"0");
        tillyear = parseDate( date[5, 9],"9");
        if tillyear < fromyear
            fromyear = parseDate( date[5, 9],"0");
            tillyear = parseDate( date[0, 4],"9");
        end
        return fromyear, tillyear
    end

    if (date =~ /^[^0-9UX?]*([0-9UX?]{4}).*$/)
        date = date[/^[^0-9UX?]*([0-9UX?]{4}).*$/,1]
    end

    if (date =~ /^[0-9UX?]{4}$/)
        fromyear = parseDate( date[0, 4],"0");
        tillyear = parseDate( date[0, 4],"9");
        if tillyear < fromyear
            fromyear = parseDate( date[0, 4],"0");
            tillyear = parseDate( date[0, 4],"9");
        end
        return fromyear, tillyear
    end

    return fromyear, tillyear

end



def create_record(jsondata)
#    checkContext( jsondata )
    checkData( jsondata )

   # if jsondata['@context'].is_a? String
   #     jsondata['@context'] = [ jsondata['@context'] , "@language": "nl" ]
   # end

    # jsondata["@context"][0] = "schema.org"
    # jsondata["@context"][1] = { "@language": "fr-Latn" }

    puts jsondata["@context"]
    if jsondata["@context"].select{ |l| l.key?("@language") }.empty?
        jsondata["@context"] << { "@language": "nl-Latn" }
    end

    lang = jsondata["@context"].select{ |l| l.key?("@language") }.map { |l| l["@language"]  }.first.split('-').first 

    checkLangauge( jsondata,'name', lang )
    checkLangauge( jsondata, 'description' , lang )
    checkLangauge( jsondata, 'isPartOf.name', lang )
    checkLangauge( jsondata, 'keywords', lang )
    checkLangauge( jsondata, 'associatedMedia.name', lang )

    if jsondata['author'].is_a?(Array)
        jsondata['author'].each do |a|
            a = checkPersonLangauge(a, lang )
        end
    end
    if jsondata['author'].is_a?(Hash)
        jsondata['author'] = checkPersonLangauge( jsondata['author'], lang )
    end
    if jsondata['contributor'].is_a?(Array)
        jsondata['contributor'].each do |a|
            a = checkPersonLangauge(a, lang )
        end
    end
    if jsondata['contributor'].is_a?(Hash)
        jsondata['contributor'] = checkPersonLangauge( jsondata['contributor'], lang )
    end
    if jsondata['editor'].is_a?(Array)
        jsondata['editor'].each do |a|
            a = checkPersonLangauge(a, lang )
        end
    end
    if jsondata['editor'].is_a?(Hash)
        jsondata['editor'] = checkPersonLangauge( jsondata['editor'], lang )
    end

    if jsondata['datePublished'].is_a?(Array)
        datePublished =  jsondata['datePublished'][0]
    else
        datePublished = jsondata['datePublished']
    end

    fromyear = "9999"
    tillyear = "0001"

    if ! datePublished.nil?
        fromyear, tillyear = createDateRange(datePublished)
        if fromyear != "9999" && tillyear != "0001"
            datePublished_time_frame = {
                "gte" => fromyear ,
                "lte" => tillyear
            }
        end
        jsondata['datePublished_time_frame'] = datePublished_time_frame
    end

    jsondata['datePublished_time_frame_from'] = fromyear
    jsondata['datePublished_time_frame_till'] = tillyear

    if jsondata['dateCreated'].is_a?(Array)
        dateCreated =  jsondata['dateCreated'][0]
    else
        dateCreated = jsondata['dateCreated']
    end

    fromyear = "9999"
    tillyear = "0001"

    if ! dateCreated.nil?
        fromyear, tillyear = createDateRange(dateCreated)
        if fromyear != "9999" && tillyear != "0001"
            dateCreated_time_frame = {
                "gte" => fromyear ,
                "lte" => tillyear
            }
        end
        jsondata['dateCreated_time_frame'] = dateCreated_time_frame
    end

    jsondata['dateCreated_time_frame_from'] = fromyear
    jsondata['dateCreated_time_frame_till'] = tillyear

    jsondata.reject!{ |j| j.empty? || j.nil? }
    jsondata.reject!{ |k,v| v.nil? || v.to_s.empty? }

    return jsondata

end

