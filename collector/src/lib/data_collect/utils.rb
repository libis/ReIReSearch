require "iso639"
require "unicode"
require "unicode/scripts"
module Utils

  def schema_out_object(id:, type:, url: "#{@url_prefix}/#{id}")
    begin
    
      output[:@context] = build_context
      output[:@id] = id
      output[:@type] = type
      output[:additionalType] = "CreativeWork"
      output[:isBasedOn] =  @isBasedOn

      {
        "@context" => build_context,

        "@id" => "#{ id }",
        "@type" => "#{ type }",
        "additionalType" => "CreativeWork",
        
       # "url" => url,

       # "sdPublisher" => @sdPublisher,
       # "sdDatePublished" => Time.now.strftime("%Y-%m-%d"),
       # "sdLicense" => @sdLicense,
        
        "thumbnailUrl" => [],
        "downloadUrl" => [],

        "isBasedOn" => @isBasedOn
      }

    rescue
      puts "Error init_schema_out_object: #{msg}"
    end
  end
  
  def build_context
    ["http://schema.org", { "@language": "#{@metaLanguage}-#{@unicode_script}" }]
  end

  def script_checker(value, unicode_script)
    begin
      if !value.nil?
        unicode_script = Unicode::Scripts.scripts("#{value}", format: :short)
        if  value['$text'] && !value.nil?
          {"@value": "#{value['$text']}", "@language": "#{output[:language]}-#{unicode_script[0]}" }
        else  
          {"@value": "#{value}", "@language": "#{output[:language]}-#{unicode_script[0]}" }
        end
    end
    rescue StandardError => msg  
      # display the system generated error message  
      puts "Error script_checker: #{msg}"
      puts "#{value}"
      puts "#{Unicode::Scripts.scripts("#{value}") }"
    end
  end

  def prefix_datasetid (dataset) 
    prefixed_dataset = dataset.dup
    prefixed_dataset["@id"] = "REIRES_Dataset_#{dataset["@id"]}"
    prefixed_dataset
  end

  def build_isBasedOn(ingestdata) 
    {
      "@type" => "CreativeWork",
      "@id" => "REIRES_#{ ingestdata["provider"]["@id"] }_#{ ingestdata["dataset"]["@id"]}",
      "license" => ingestdata["license"],
      "name" => ingestdata["name"],
      "provider" => ingestdata["provider"],
      "isPartOf" => [
        ingestdata["dataset"]
      ]
    }
  end

  def type_mapping( type )
    default_type = 'Book'
    types = {
        "multivolume monograph" => "Book",
        "publicationvolume" => "PublicationVolume",
        "volume" => "PublicationVolume",
        "publicationissue" => "PublicationIssue",
        "issue" => "PublicationIssue",
        "book" => "Book",
        "event" => "Event"
    }
    if type.nil?
        return default_type
    else
        types[type.downcase] || default_type
    end
  end

  def cleanup_schema(data)
    data.reject!{|k,v| v.nil? || ( (!v.is_a? Integer) && v.empty? )  || v.is_a?(Hash) && v.has_key?("name") && v["name"].empty? }
  end

  def becompact( s )
    if s.is_a?(Hash)
      #puts " - Hash - #{s}"
      s.compact!
      s = s.each { |k, v| s[k] = becompact(v) }
      s.compact!
      s
      #puts " - Hash End - #{s}"
    elsif s.is_a?(Array)
        #puts " - Array - #{s}"
        s.compact!
        s = s.each { |v| becompact(v) }
        s.compact!
        s = s.empty? ? nil : s.compact
        unless s.nil?
          s = s.size == 1 ? s[0] : s
        end
        #puts " - Array End - #{s}"
        s
    elsif s.is_a?(String)
      #puts " - String - #{s}"
      s = s.blank? ? nil : s
      #puts " - String End - #{s}"
      s
    else
      s
    end
  end

end