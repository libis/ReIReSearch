require "logger"

def searchblender_logger
    # puts SearchBlender.config.logger_file

    log_file = File.new( filename: SearchBlender.config.logger_file, mode: "a")
    writer=IO::MultiWriter.new(log_file, STDOUT)  
    logger = Logger.new(writer)
    #logger = Logger.new(log_file)

    case  SearchBlender.config.logger_level.upcase
    when "DEBUG"
        logger.level = Logger::DEBUG
    when "ERROR"
        logger.level = Logger::ERROR
    when "FATAL"
        logger.level = Logger::FATAL
    when "INFO"
        logger.level = Logger::INFO
    when "UNKNOWN"
        logger.level = Logger::UNKNOWN
    else
        logger.level = Logger::DEBUG      
    end

    return logger

end