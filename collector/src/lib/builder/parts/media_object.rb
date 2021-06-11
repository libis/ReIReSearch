require 'pp'

module MediaObject

    def associatedMedia
        # LIBIS data model
        # 856 4 (0,1) Link (url) to related electronic resource (digital/digitized version hosted by KU Leuven)
        path = '$.datafield[?(@["_tag"] == "856" && @["_ind1"] == "4")].subfield'
        marcf = JsonPath.on(@record, path)
        mediaobjects_856 = marcf.map {|mediaobject|  parse_856_media_object(mediaobject) }

        path = '$.datafield[?(@["_tag"] == "AVD" && @["_ind1"] == "1")].subfield'
        marcf = JsonPath.on(@record, path)
        mediaobjects_AVD = marcf.map {|mediaobject|  parse_AVD_media_object(mediaobject) }

        return mediaobjects_856 + mediaobjects_AVD
    end

end