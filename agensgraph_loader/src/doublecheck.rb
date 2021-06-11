require 'json'
require './lib/agensgraph'

def findfiles(filepattern)
  puts "Finding files in " + filepattern
    Dir.foreach(filepattern) do |filename|
        if File.directory?(filepattern + '/' + filename)
              findfiles(filepattern + '/' + filename) unless (filename == "." || filename == "..") unless filename == "deletes"
                  else
                        $foundfiles.push(filepattern + '/' + filename)
                            end
                              end
                              end

                              @agens = AgensGraph.new('agensgraph')
                              @agens.connect('agens', 'agens')
                              @agens.set_graph('reires_graph')


                              filepattern = '/app/datain/DHGE'

                              $foundfiles = []
                              $lijst = []

                              findfiles(filepattern)


                              $foundfiles.each do |filename|
                              # puts "Processing " + filename
                                file = File.open(filename, 'r:utf-8')
                                  content = file.read

                                    data = JSON.parse(content)
                                    #  pp data["@id"]

                                      query = "match (t:Thing{'@id':'" + data["@id"] + "'}) return count(*) as c"

                                        result = @agens.execute_query(query)

                                          if (result[0].c.value == 0)
                                            puts data["@id"] + "  " + filename
                                          end


                                          end
