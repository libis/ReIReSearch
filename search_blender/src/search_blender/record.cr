require "../search/search"

module SearchBlender
  module Record
    extend self

    class ReIReSDoc
        include JSON::Serializable
        include JSON::Serializable::Unmapped
        property _id : String = "id"
        property _source : JSON::Any?
        property message : String?
        property status_code : Int32 = 200
    end

    LOGGER = searchblender_logger()

    def get_record(id : String, options : Hash(String, String | Int32))
    
      LOGGER.debug ( "SearchBlender::Record get_record id         #{ id }" )

      prefixid = JSON.parse( SearchBlender.config.datamodel_constants["prefixid"].to_json )
      datamodel = JSON.parse ( SearchBlender.config.read_json_config("reires_brepols_datamodel.json") )
      brepols_engine_records_starts_with = "#{prefixid.as_s}_#{datamodel["provider"].as_h["@id"].as_s}_#{datamodel["dataset"].as_h["@id"].as_s}"

      LOGGER.debug ( "SearchBlender::Record get_record id.starts_with?(#{brepols_engine_records_starts_with})   #{ id.starts_with?( brepols_engine_records_starts_with ) }" )

      options["engine"] = "elastic"
      if id.starts_with?(brepols_engine_records_starts_with)
        options["engine"] = "brepols"
        id = id.gsub(/^#{brepols_engine_records_starts_with}_/, "")
      end
    
      LOGGER.debug ( "SearchBlender::Record : get_record - options")
      LOGGER.debug ( "SearchBlender::Record  id : #{id}")
      LOGGER.debug ( "     #{ options }" )

      s = Search::Search.new(options)
      r = s.record("#{id}", options)
      return r
    end

  end
end




