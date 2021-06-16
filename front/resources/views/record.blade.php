@extends('layouts.record')

@section('content')
    <script type="application/ld+json">
        <?=json_encode($source,JSON_PRETTY_PRINT+JSON_UNESCAPED_SLASHES); ?>
    </script>

    <? $display = $record; 
    
    //unset($display["source"]);
    //unset($display["sdPublisher"]);
    //unset($display["DataSet"]);
    
    ?>

    <div class="box">

    <? if (isset($display["type"])) { ?>
            <p class="detail_type"> 
                <?=$display["type"]?>
            </p>
    <? } ?>

    <? if (isset($display["thumbnails"])) { ?>
        <div style="float:right;width:25%;padding-left:15px">
        <? foreach($display["thumbnails"] as $thumb) { ?>
            <? if (isset($thumb["contentUrl"])) { ?>
                <a href="<?=$thumb["contentUrl"]?>" target="_blank">
                    <p><img class="preview" src="<?=$thumb["thumbnailUrl"]?>"></p>
                </a>
            <? } else { ?>
                <p><img class="preview" src="<?=$thumb["thumbnailUrl"]?>"></p>
            <? } ?>
        <? } ?>
        </div>
    <? } ?>

    <? if (isset($display["name"])) { 
        foreach ($display["name"] as $name) { ?>
            <h1 class="title is-5 monda"><?=$name?></h1>
        <? } 
    } ?>

    <? /* if (isset($display["alternateName"])) { 
        foreach ($display["alternateName"] as $alternateName) { ?>
            <h2 class="title is-7 monda"><?=$alternateName?></h2>
        <? } 
    }  */ ?>

    <? if (isset($display["source"])) { 
        $out = Array();
        foreach ($display["source"] as $tmp) {
            $out[] = Array('url'=>$tmp,'name'=>$tmp);
        }
        $display["source"] = $out;
      } ?>


<? if (isset($display["license"])) { 
        $out = Array();
        foreach ($display["license"] as $tmp) {
            $out[] = Array('url'=>$tmp,'name'=>$tmp);
        }
        $display["license"] = $out;
      } ?>
    <?

        $fields = array("honorificPrefix"=>"Honorific Prefix",
                        "honorificSuffix"=>"Honorific Suffix",
                        "familyName"=>"Familyname",
                        "givenName"=>"Givenname",
                        "additionalName"=>"Additional Name",
                        "gender"=>"Gender",
                        "nationality"=>"Nationality",
                        "birthDate"=>"Birthdate",
                        "birthPlace"=>"Birthplace",
                        "deathDate"=>"Deathdate",
                        "deathPlace"=>"Deatchplace",
                        "alumniOf"=>"Alumni of",
                        "associatedMedia"=>"Media",
                        "description"=>"Description",
                        "author"=>"Authors",
                        "creator"=>"Creators",
                        "editor"=>"Editors",
                        "contributor"=>"Contributors",
                        "illustrator"=>"Illustrators",
                        "translator"=>"Translator",
                        "source"=>"Access full record",
                        "license"=>"License",
                        "provider"=>"Data provider",
                        "DataSet"=>"DataSet",
//                        "isPartOf"=>"Is part of",
                        "pagination"=>"Pagination",
                        "numberOfPages"=>"Number of pages",
                        "volumeNumber"=>"Volume",
                        "issueNumber"=>"Issue",
                        "hasPart"=>"Has part",
                        "dateCreated"=>"Creationdate",
                        "locationCreated"=>"Creationlocation",
                        "datePublished"=>"Publication Date",
                        "publisher"=>"Publisher",
                        "inLanguage"=>"Language",
                        "Genre"=>"Discipline/classification",
                        "keywords"=>"Keywords",
                        "isbn"=>"ISBN",
                        "issn"=>"ISSN",
                        "sdDatePublished"=>"Record publication date",
                        "sdPublisher"=>"Record publisher",
                        "includedInDataCatalog"=>"Included in Data Catalog",
                        "startDate"=>"Start Date",
                        "endDate"=>"End Date",
                        "additionalType"=>"Additional Type",
                        "about"=>"About",
                        "subjectOf"=>"Subject of",
                        "contentLocation"=>"Content Location",
                        "spatialCoverage"=>"Spatial Coverage",
                        "temporalCoverage"=>"Temporal Coverage",
                        "mentions"=>"Mentions",
                        "distribution"=>"Distribution",
                        "copyright"=>"Copyright",
                        "bookEdition"=>"Edition of book",
                        "material"=>"Made of",
                        "review"=>"Review",
                        "itemReviewed"=>"Item Reviewed",
                        "translationOfWork"=>"Translation of work",
                        "workTranslation"=>"Has translation",
                        "version"=>"Version",
                        "id"=>"Identifier"
         );

         
        foreach($fields as $k => $v) {
            if (isset($display[$k])) { ?>
            <div class="columns nomargin">
              <div class="column detail is-narrow"><?=$v?>&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <?
                    if (is_array($display[$k])) {

                        foreach($display[$k] as $info) {
                ?>
                            <li class="detail">
                                <?
                                    if (isset($info['contentUrl']) && $info['contentUrl'] != "") {
                                ?>
                                    <a class="externallink" href="<?=$info["contentUrl"]?>" target="_blank"><?
                                        if (is_array($info["name"])) {
                                            foreach( $info["name"] as $n) {
                                                $m = (array)$n;
                                                print($m["@value"] . " ");
                                            }
                                        } else {
                                            print($info["name"]);
                                        }
                                    ?> <i class="fa fa-external-link"></i></a>
                                <?
                                    } else {
                                        if (is_array($info)) { ?>
                                            <?
                                            if (filter_var($info["name"], FILTER_VALIDATE_URL)) {  ?>
                                                <a class="externallink" href="<?=$info["name"]?>" target="_blank"><?=$info["name"]?> <i class="fa fa-external-link"></i></a>
                                            <? } else { ?>
                                                <? if (isset($info["url"]) && filter_var($info["url"], FILTER_VALIDATE_URL)) { ?>
                                                    <a class="externallink" href="<?=$info["url"]?>" target="_blank"><?=$info["name"]?></a>
                                            <? } else { ?>
                                                    <?=$info["name"]?>
                                                    <? if (isset($info["location"])) { ?>
                                                        <?= ((array)$info["location"])["name"] ?>
                                                        <? if (isset(((array)$info["location"])["address"])) { ?>
                                                            <?= ((array)$info["location"])["address"] ?>
                                                        <? } ?>
                                                    <? } ?>
                                                <? } ?>
                                            <? } ?>
                                        <? } else { ?>
                                            <? 
                                            if (filter_var($info, FILTER_VALIDATE_URL)) { ?>
                                                <a class="externallink" href="<?=$info?>" target="_blank"><?=$info?> <i class="fa fa-external-link"></i></a>
                                            <? } else { ?>
                                                <?=$info?>                                                
                                            <? } ?>
                                        <? } ?>
                                 <? } ?>
                            </li>
                <?      } 
                
                        } else {
                ?>
                            <li class="detail">
                                <?=$display[$k]?>
                            </li>
                <? } ?>
                </ol>    
              </div>
            </div>
        <?
            }
        }  ?>
</div>
@endsection