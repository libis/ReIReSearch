require 'date'
require 'time'

class Validator
  def initialize
    puts "Initializing validator"
    json_data = JSON.parse(File.open('validation.json', 'r:utf-8').read)
    @root = json_data.keys[0]
    @struct = parse_struct(json_data[@root])
    puts "Initializing complete"


  end


  def mixProperties(aProp,bProp)
    resProp = aProp.clone
    bProp.clone.each do |key, value|
      if resProp[key]
        resProp[key]["possibleTypes"] = mixPossibleTypes(resProp[key]["possibleTypes"],value["possibleTypes"])
#        resProp[key]['mandatory'] = resProp[key]['mandatory'] || value['mandatory']
      else
        resProp[key] = value
      end
    end
    resProp
  end

  def mixPossibleTypes(aPossibleTypes,bPossibleTypes)
    resPossibleTypes = aPossibleTypes.clone
    bPossibleTypes.clone.each do |key, value|
      resPossibleTypes[key] = value;
    end
    resPossibleTypes
  end

  def parse_struct(st)
    struct = {}
    st.each do |v1|
      p = {}
      if v1['properties']
        v1['properties'].each do |v2|
          v2['repeatable'] = true if v2['repeatable'].is_a?NilClass
          v2['mandatory'] = false if v2['mandatory'].is_a?NilClass
          pt = {}
          if v2['possibleTypes']
            v2['possibleTypes'].each do |v3|
              pt[v3['type']] = v3.reject! { |k| k == 'type'}
            end
            v2['possibleTypes'] = pt
          end
          p[v2['name']] = v2.reject! { |k| k == 'name'}
        end
      end
      v1['properties'] = p
      struct[v1['type']] = v1.reject! { |k| k == 'type'}
    end
    struct
  end

  def all_properties(type)
#    puts "allproperties : " + type.to_s
#    pp @struct
#    if @struct[type]['properties'].empty?
    if @struct[type]['properties'].is_a?NilClass
      @struct[type]
    else
      properties = all_properties(@struct[type]['inherits']) unless @struct[type]['inherits'].is_a?NilClass
      properties = {} if properties.is_a?NilClass
      @struct[type]['properties'].each do |k,v|
        properties[k] = v
      end
      if properties.empty?
        @struct[type]
      else
        properties
      end
    end
  end


  def all_relations
    rels = []
    @struct.each do |k, v|
      v['properties'].each do |kk, vv|
        vv['possibleTypes'].each do |kkk, vvv|
          rels << vvv['relation'] unless vvv['relation'].is_a?NilClass
        end
      end
    end
    rels.uniq
  end

  def info(type)
    @struct[type]
  end


  def check_mandatory_keys(data, type)
    all_properties(type).each do |name,property|
      if property['mandatory'] and data[name].is_a?NilClass
        puts 'Warning : Missing mandatory property ' + name + ' in ' + type
      end
    end
  end

  def key_allowed(key, type, additionalType)
    if (additionalType)
      !((mixProperties(all_properties(type), all_properties(additionalType))[key]).is_a?NilClass)
    else
      !((all_properties(type)[key]).is_a?NilClass)
    end
  end

  def hash_is_valid_type(type,key,tocheck)
    !(all_properties(type)[key]['possibleTypes'][tocheck].is_a?NilClass)
  end

  def is_repeatable(type, key)
    (all_properties(type)[key]['repeatable'])
  end

  def isThing(type)
    type = @struct[type]['inherits'] until @struct[type]['inherits'].is_a?NilClass
    return (type == 'Thing')
  end

  def isBase(type)
    return !self.isThing(type)
  end

  def childrenOf(type)
    r = []
    @struct.each do |k,v|
      r << k if v['inherits'] == type
    end
    r
  end

  def validate_hash(key,value)
#    puts 'validate_hash ' + key
    # 2 possibilities :
    #     - subnode
    #     - detailnode
    ok = false
    unless value['@type'].instance_of?NilClass
      ok = validate(value)
    end
    unless value['@value'].instance_of?NilClass or value['@language'].instance_of?NilClass
      ok = validate_detailnode(value)
    end
    if key == '@context' and not value['@language'].instance_of?NilClass
      ok = true
    end
    puts "Warning (127) : Invalid value for key " + key + " " + value.to_s unless ok
    ok
  end

  def validate_detailnode(value)
    return true unless value['@value'].instance_of?NilClass or value['@language'].instance_of?NilClass
    return false
  end

  def validate_array(key, value, type, additionalType)
    puts 'Warning : Empty value not allowed for ' + key + ' in type ' + type if value.empty?
    value.each do |v|
      case v.class.to_s
      when 'Hash'
        validate_hash(key, v)
      when 'String'
        validate_value(key,v, type, additionalType)
      end
    end
  end

  def validate_value(key, value, type, additionalType)
    ok = false
#    puts "---------------------------------- validate_value " + key.to_s + " " + value.to_s + " " + type.to_s + " " + additionalType.to_s

#    all_properties(type)[key]['possibleTypes'].each do |t|

    if additionalType.instance_of?NilClass
      possibleProperties = all_properties(type) 
    else
      possibleProperties = mixProperties(all_properties(type), all_properties(additionalType))
    end
    possibleProperties[key]['possibleTypes'].each do |t|
      begin
        ok ||= self.method(all_properties(t[0])["validator"]).call(value)
      rescue TypeError

      end

#      case t[1]['storeAs']
#      when 'String'
#        match_pattern = /<\s*[^>]*>/
#        ok ||= ((value.instance_of?String) && (value != '') && value !~ match_pattern )
#      when 'Integer'
#        match_pattern = /^[-+]?[1-9]([0-9]*)?$/
#        ok ||= (value =~ match_pattern)
#      end
    end
    puts "Warning (169) : Invalid value for key " + key + " " + value unless ok
    ok
  end

  def validate(data)
    raise StandardError if data['@type'].instance_of?NilClass
    type = data['@type']
    additionalType = data['additionalType']
#    puts type
    check_mandatory_keys(data, type)
    ok = false
    data.each do |key, value|
      puts "Warning : Key " + key + " not allowed in type " + type unless key_allowed(key, type, additionalType)
      puts "Warning : Null value for key " + key + " in type " + type + " is not allowed" if value.instance_of?NilClass
      if key_allowed(key, type, additionalType)
#        puts key + " " + value.class.to_s
        case value.class.to_s
        when 'Hash'
          if not value["@type"].instance_of?NilClass
	          puts "Warning : Type " + value["@type"].to_s + " not valid for key " + key  + " in " + type  unless checkRelation(type,additionalType,key,value["@type"])
	  end
#          if not value['@type'].instance_of?NilClass
#            findRelation(data["@type"],key, value["@type"])
#          end
          ok = validate_hash(key, value)
        when 'Array'
          ok = validate_array(key, value, type, additionalType)
        when 'String'
          ok = validate_value(key, value, type, additionalType)
        end
      end
    end
    ok
  end

  def findRelation(ntype,atype,nproperty,sntype)
#    puts "1)" + ntype
#    puts "2)" + nproperty
#    puts "3)" + sntype
#    puts "findRelation : " + ntype + " " + nproperty + " " + sntype + " -> " + all_properties(ntype)[nproperty]["possibleTypes"][sntype]["relation"]
    if (atype)
      mixProperties(all_properties(ntype),all_properties(atype))[nproperty]["possibleTypes"][sntype]["relation"]
    else
      all_properties(ntype)[nproperty]["possibleTypes"][sntype]["relation"]  
    end
  end

  def checkRelation(ntype,atype,nproperty,sntype)
    begin
      if (atype)
        mixProperties(all_properties(ntype),all_properties(atype))[nproperty]["possibleTypes"][sntype]["relation"]
      else
        all_properties(ntype)[nproperty]["possibleTypes"][sntype]["relation"]
      end
    rescue
      false
    end
  end


  def findRelations(ntype)
#    puts "findRelations : " + ntype.to_s
    relations = Array.new
    all_properties(ntype).each do |nproperty,v|
      v["possibleTypes"].each do |sntype,v2|
        relations <<  [nproperty,v2["relation"],sntype] unless v2["relation"].instance_of?NilClass
      end
    end
    relations
  end

  def isText(value)
#    puts "isText " + value
    (value.instance_of?String)
  end

  def isUrl(value)
#    puts "isUrl " + value
    begin

#      if value.instance_of?(Array)
#        value.each do |k,v|
#          v = v.gsub("[","%5B").gsub("]","%5D")
#          uri = URI.parse(URI::encode(v))
#          %w( http https ).include?(uri.scheme)
#        end
#      else
#        value = value.gsub("[","%5B").gsub("]","%5D")
        uri = URI.parse(URI::encode(value))
        %w( http https ).include?(uri.scheme)
#      end
    rescue URI::BadURIError
      puts "BadURIError : " + value
      false
    rescue URI::InvalidURIError
      puts "InvalidURIError : " + value
      false
    end
  end

  def isDate(value)
#    puts "isDate " + value
    if (value.instance_of?String)
      begin
        Date.iso8601(value)
        true
      rescue
        false
      end
    else
      false
    end
  end


  def isDateTime(value)
 #   puts "isDateTime " + value
    if (value.instance_of?String)
      begin
        Date.iso8601(value)
        true
      rescue
        false
      end
    else
      false
    end
  end

  def isTime(value)
#    puts "isTime " + value
    if (value.instance_of?String)
      begin
        Time.iso8601(value)
        true
      rescue
        false
      end
    else
      false
    end
  end


  def isNumber(value)
 #   puts "isNumber " + value
    if (value.instance_of?String)
      true if Float(value) rescue false
    else
      false
    end
  end


  def isInteger(value)
#    puts "isInteger " + value
    begin
      Integer(value)
      true
    rescue
      false
    end
  end

  def isDuration(value)
#    puts "isDuration " + value
    if (value.instance_of?String)
      begin
        Date.iso8601(value)
        true
      rescue
        false
      end
    else
      false
    end
  end

end
