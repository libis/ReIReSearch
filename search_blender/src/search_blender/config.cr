require "json"
require "env"

module SearchBlender
  
    # Stores all general configuration options.
    # SearchBlender.config

    class Config
        CONFIG_FILE = "/app/config/reires.json"
        JSON.mapping(
            logger_level: String,
            logger_file: String,
            search_indexes: Array(String),
            environment: String,
            datamodel_constants: Hash(String, String | Array(String) | Hash(String, String  | Array(String) ) )
        )
        INSTANCE        = Config.load

        property logger_level, logger_file, search_indexes, environment
        
        def self.load : Config
            from_json(File.read(CONFIG_FILE))
        end
    
        #def token?(auth)
        #  tokens.has_key?(auth)
        #end

        def read_json_config(file)
            config_path = "/app/config/"
            puts SearchBlender.config.environment
            if SearchBlender.config.environment == "development"
                if File.file?("#{config_path}development/#{file}")
                    config_path = "/app/config/development/"
                end
            end
            File.read("#{config_path}#{file}") 
        end
    end
    def self.config
        SearchBlender::Config::INSTANCE
    end
end
