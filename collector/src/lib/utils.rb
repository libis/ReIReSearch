module Utils
  
  def marcfields(record:, field:, ind1: nil, ind2: nil, code: nil)
    if (field == "ldr")
      path = '$.leader'
      return JsonPath.on(record, path).first.to_s
    elsif (["001", "003", "005", "006", "007", "008"].include? field)
      path = '$.controlfield[?(@._tag == "' + field + '")].$text'
      return JsonPath.on(record, path).first.to_s
    else

      path = '$.datafield[?(@._tag == "' + field + '")]'
      fields = JsonPath.on(record, path)

      return fields
    end
  end

  def validateFMT(ldr, match)
    fmthash = {"c" => "MU", "d" => "MU", "e" => "MP", "f" => "MP", "g" => "VM", "i" => "AM", "j" => "AM", "k" => "VM", "m" => "CF", "o" => "VM", "p" => "MX", "r" => "VM", "t" => "BK", "w" => "RB"}
    idx1 = ldr[6]
    idx2 = ldr[7]
    out = nil
    if idx1 == 'a'
      case idx2
      when "a"
      when "c"
      when "d"
      when "m"
        out = "BK"
      when "B"
      when "I"
      when "S"
        out = "SE"
      end
    else
      out = fmthash[idx1]
      if out == nil
        out = "BK"
      end
    end
    return (out == match)
  end

  def convert_subfield (subfield_array)
    if !subfield_array.nil?
      if subfield_array.kind_of?(Array)
        if subfield_array.length > 1
          tmpf = []
          subfield_array.each do |f|
            tf = block_given? ? ( yield( f ) ) : ( f )
            tmpf << tf
          end
          tmpf
        else
          f = subfield_array.first 
          block_given? ? ( yield( f ) ) : ( f )
        end
      else
        f = subfield_array
        block_given? ? ( yield( f ) ) : ( f )
      end
    end
  end

  def parse_subfields(subfield: , output_templ: output_templ='', subfields_config: )
    # Transform subfield with { |s| ...... }
    # concat al subfields with delimiter => * "<delimiter>" 

    pattern = /({[^}]*\#{[^}]+}[^}]*})/
    matches = output_templ.enum_for(:scan, pattern).map { $~ }
    output = output_templ.clone

    matches.each do |m|
        m = m.to_s
        pattern = /(?<=\#{)[^}]+(?=})/
        subfield_code = pattern.match(m).to_s
        if subfield.key?(subfield_code) 
          default_trans = Proc.new {  |i| i.to_s }
          default_delimiter = ', '
          if  subfields_config.key?(subfield_code.to_sym)
              transformation     = subfields_config[subfield_code.to_sym][:transformation] || default_trans
              subfield_delimiter = subfields_config[subfield_code.to_sym][:delimiter]      || default_delimiter
              #subfield_text = subfield[subfield_code.to_s].map { |s| transformation.call(s) }.join(subfield_delimiter)
              subfield_text = subfield[subfield_code.to_s].map { |s| ( convert_subfield(s, &transformation)  ) }.join(subfield_delimiter)
              subfield_text = m.gsub( /(\#{[^}]+})/, subfield_text).gsub(/^{(.*)}$/, "\\1")    
              output.to_s.gsub!(m, subfield_text)
          else
            subfield_text = subfield[subfield_code.to_s].map { |s| ( convert_subfield(s,  &default_trans)  ) }.join(default_delimiter)
            subfield_text = m.gsub( /(\#{[^}]+})/, subfield_text).gsub(/^{(.*)}$/, "\\1")                
            output.to_s.gsub!(m, subfield_text)
          end
        else
          output.to_s.gsub!(m, '')
        end
    end      
    output
  end

  def parse_marcfields(marcf:, output_templ: '', subfields_config:{})
    output=[]
    if ! marcf.empty?
      marcf.each do |mf|
        fieldoutput = parse_subfields( subfield: mf, output_templ: output_templ, subfields_config: subfields_config)
        output << fieldoutput if fieldoutput != ""
        fieldoutput = ""
      end
    end
    output
  end

  def parse_person(person)
    tmp_hash = {
      #"@id" => "#{@provider}_DATASOURCE_RECORDSNR_CREATOR_#{counter}",
      "@type" => "Person",
      "name" => convert_subfield( person["a"] )
    } unless person["a"].nil?
    tmp_hash["familyName"] = ( convert_subfield( person["a"] )  { |s| s.split(/,/).first } )   unless person["a"].nil?
    tmp_hash["honorificPrefix"] =( convert_subfield( person["c"] )  { |s| s.to_s } ) unless person["c"].nil?
    if !person["d"].nil?
          birthDate = person["d"].first.split(/-/).first 
          deathDate = person["d"].first.split(/-/).last unless birthDate.nil?
          tmp_hash["birthDate"]  = birthDate unless birthDate.empty?
          tmp_hash["deathDate"]  = person["d"].first.split(/-/).last unless deathDate.empty?
    end
    description = ''
    description =  ( convert_subfield( person["g"] )  )  unless person["g"].nil?
    description = description + ( convert_subfield( person["q"] )  )  unless person["q"].nil?
    tmp_hash["description"] = description unless description == ''
    tmp_hash["sameAs"] = ( convert_subfield( person["0"] ){ |s| s.gsub(/^\((uri|URI)\)[\s]*/, '') } )  unless person["0"].nil?
    tmp_hash
  end

  def parse_organization(organization)
    location = {
      "a" => convert_subfield( organization["a"] )
    } 
    tmp_hash = {
      "@type" => "Organization",
      "name" => convert_subfield( organization["b"] )
    }
    unless location["a"].nil?
      tmp_hash["location"] = parse_location(location)
    end
    tmp_hash
  end

  def parse_location(location)
    unless location["a"].nil?
      tmp_hash = {
        "@type" => "Place",
        "name" =>  location["a"] 
      }
      tmp_hash
    end
  end

  def parse_creative_work (creativework)
    tmp_hash = {
      "@type" => "CreativeWork",
      "name" =>  creativework[:name]
    }
    tmp_hash
  end

end

def checkcharonposition(str, match)
  s = match.split("@@")
  return (str[s[0].to_i, s[1].length] == s[1])
end

