require 'pp'
require 'logger'

module Persons

    def author()
        path ='$.datafield[?(@["_tag"] == "700" ||  @["_tag"] == "710" )].subfield[?(@["4"])]'
        marcf = JsonPath.on(@record, path)
# & Returns a new array containing unique elements common to the two arrays. => https://ruby-doc.org/core-2.7.0/Array.html#method-i-26
        contributor_codes= ["aut","eda","rev","ivr","adp","arr","lbt","sce","ede","edc","com","cmp","dir","drt","ctg","pht"]
        marcf = marcf.select{ |el| !( ( el["4"] || [] ).map(&:downcase) & contributor_codes).empty?  && ! el["a"].nil? } 

        persons = marcf.map {|person|  parse_person (person) }
#        puts "AUTHORS : " 
#        pp persons
        return persons
    end

    def editor()
        path = '$.datafield[?(@["_tag"] == "700" ||  @["_tag"] == "710" )].subfield[?(@["4"].include? "edt")]'
        marcf = JsonPath.on(@record, path)
        marcf.map {|person|  parse_person (person) }
    end



    def illustrator()
        path = '$.datafield[?(@["_tag"] == "700" ||  @["_tag"] == "710" )].subfield[?(@["4"].include? "ill")]'
        marcf = JsonPath.on(@record, path)
        marcf.map {|person|  parse_person (person) }
    end

    def translator()
        path = '$.datafield[?(@["_tag"] == "700" ||  @["_tag"] == "710" )].subfield[?(@["4"].include? "tra")]'
        marcf = JsonPath.on(@record, path)
        marcf.map {|person|  parse_person (person) }
    end

    def publisher_person()
        path = '$.datafield[?(@["_tag"] == "700")].subfield[?(@["4"].include? "prt")]'
        marcf = JsonPath.on(@record, path)
        persons = marcf.map {|person|  parse_person (person) }

        path = '$.datafield[?(@["_tag"] == "710" )].subfield[?(@["4"].include? "prt")]'
        marcf = JsonPath.on(@record, path)

        temp_persons = marcf.map {|person|  
            parse_person (person) 
        }
       
        temp_persons = temp_persons.map {|person|
            unless person.nil?
                person.except!("honorificPrefix")
            end
        }
        
        persons << temp_persons  unless temp_persons.empty?
        return persons unless persons.empty?
        return nil
    end

    def contributor()
        path ='$.datafield[?(@["_tag"] == "700" ||  @["_tag"] == "710" )].subfield[?(@["4"])]'
        marcf = JsonPath.on(@record, path)
# contributor : Is not author, editor,illustrator, translator or publisher_person
        contributor_codes= ["aut","eda","rev","ivr","adp","arr","lbt","sce","ede","edc","com","cmp","dir","drt","ctg","pht","edt","ill","tra","prt" ]
        marcf = marcf.select{|el| ( ( el["4"] || [] ).map(&:downcase) & contributor_codes).empty? && ! el["a"].nil? } 

        persons = marcf.map {|person|  parse_person (person) }
        return persons
    end

end