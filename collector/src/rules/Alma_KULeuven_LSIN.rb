#encoding: UTF-8
$LOAD_PATH << '.' << './lib'
require 'lib/builder/marc'
require 'net/sftp'
require 'rules/Alma_KULeuven.rb'

######################### Dataset and Dataprovider Configuration ######################
ingestConfJson =  File.read(File.join(File.dirname(__FILE__), './src/config/KULeuven_LSIN.cfg'))
ingestConf = JSON.parse(ingestConfJson)

#######################################################################################

ConfigFile.config_file="Alma_KULeuven_LSIN.yml"
from_date = CGI.escape(DateTime.parse(config[:last_run_updates]).xmlschema)
from_date_deleted = CGI.escape(DateTime.parse(config[:last_run_deletes]).xmlschema)

options = { 
  user: config[:user], 
  password: config[:password],
  base_dir: config[:sftp_dir],
  host: config[:sftp_url],
  file_type: config[:file_type],
  last_run_updates: config[:last_run_updates],
  full_export: config[:full_export]
}
start_parsing = DateTime.now

source_file_name = "ReIReS_LSIN"
#######################################################################################
source_dir = "/app/source_records/#{config[:source_record_dir]}/"

begin

  Net::SFTP.start( options[:host],  options[:user], :password => options[:password]) do |sftp|
    puts "download #{options[:base_dir]}, **/*.#{options[:file_type]}"
    sftp.dir.glob(options[:base_dir], "**/*.#{options[:file_type]}").each do |entry|
      if (DateTime.parse(options[:last_run_updates]) < DateTime.parse(Time.at(entry.attributes.mtime).to_s)  )
        Dir.mkdir source_dir unless Dir.exists?(source_dir)
        sftp.download!("#{options[:base_dir]}#{entry.name}", "#{source_dir}#{entry.name}")
      end
    end
  end
rescue Timeout::Error
  puts "  Timed out"
rescue Errno::EHOSTUNREACH
  puts "  Host unreachable"
rescue Errno::ECONNREFUSED
  puts "  Connection refused"
rescue Net::SSH::AuthenticationFailed
  puts "  Authentication failure"
end

tar_gz_file = "#{source_file_name}*tar.gz"

#options[:last_run_updates] = '2001-02-03T04:05:06+07:00'

Dir["#{source_dir}/#{tar_gz_file}"].each do |source_file|
  if (DateTime.parse(options[:last_run_updates]) < DateTime.parse(Time.at(File.mtime(source_file)).to_s)  )
    puts "New file #{source_file}"
    tgz = Zlib::GzipReader.new(File.open(source_file, 'rb'))
    Minitar::unpack(tgz, source_dir)
  end
end

puts "collect_alma_data #{source_file_name}*new.xml"

xml_file  = "#{source_file_name}*new.xml"
collect_alma_data( source_dir: source_dir, source_file_name: xml_file , ingestConf: ingestConf, options: options)
config[:last_run_updates] = start_parsing.to_s

xml_file  = "#{source_file_name}*_delete.xml"
collect_alma_deletes( source_dir: source_dir, source_file_name: xml_file , ingestConf: ingestConf, options: options)
config[:last_run_deletes] = start_parsing.to_s

Dir.glob("#{source_dir}/*.xml").each { |file| File.delete(file)}
