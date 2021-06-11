<template>
  <transition name="modal">
    <div class="modal" ref="modalcontainer" >
      <div class="modal-background" @click="closeModal()"></div>
      <div class="modal-card"  style="width:50%;height:98%">
        <header class="modal-card-head">
          <p class="modal-card-title"></p>
          <button class="delete" aria-label="close" @click="closeModal()"></button>
        </header>
        <section class="modal-card-body" style="height:100%">
          <!-- Content ... -->

            <slot name="body">

            <p class="detail_type" v-if="this.currentrecord._display.type !== undefined"> 
                {{ this.currentrecord._display.type }}
            </p>
            <div style="float:right;width:25%;padding-left:15px">
              <div v-for="thumb in this.currentrecord._display.thumbnails">
                  <div v-if="thumb.contentUrl != undefined">
                    <a :href="thumb.contentUrl"  target="_blank">
                      <p><img class="preview" :src="thumb.thumbnailUrl" v-if="thumb.thumbnailUrl != undefined"></p>
                    </a>
                  </div>
                  <div v-else>
                    <p><img class="preview" :src="thumb.thumbnailUrl" v-if="thumb.thumbnailUrl != undefined"></p>
                  </div>
              </div>
            </div>
            <h1 class="title is-5 monda" v-for="name in this.currentrecord._display.name">{{ name }}</h1>
            <h2 class="title is-7 monda" v-for="alternateName in this.currentrecord._display.alternateName">{{ alternateName }}</h2>

            <div class="columns nomargin" v-if="this.currentrecord._display.honorificPrefix !== undefined">
              <div class="column detail is-narrow">Honorific Prefix&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="honorificPrefix in this.currentrecord._display.honorificPrefix">
                    {{ honorificPrefix }}
                </li>
                </ol>    
              </div>
            </div>

            <div class="columns nomargin" v-if="this.currentrecord._display.honorificSuffix !== undefined">
              <div class="column detail is-narrow">Honorific Suffix&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="honorificSuffix in this.currentrecord._display.honorificSuffix">
                    {{ honorificSuffix }}
                </li>
                </ol>    
              </div>
            </div>

            <div class="columns nomargin" v-if="this.currentrecord._display.familyName !== undefined">
              <div class="column detail is-narrow">Familyname&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="familyName in this.currentrecord._display.familyName">
                    {{ familyName }}
                </li>
                </ol>    
              </div>
            </div>

            <div class="columns nomargin" v-if="this.currentrecord._display.givenName !== undefined">
              <div class="column detail is-narrow">Givenname&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="givenName in this.currentrecord._display.givenName">
                    {{ givenName }}
                </li>
                </ol>    
              </div>
            </div>

            <div class="columns nomargin" v-if="this.currentrecord._display.additionalName !== undefined">
              <div class="column detail is-narrow">Additional name&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="additionalName in this.currentrecord._display.additionalName">
                    {{ additionalName }}
                </li>
                </ol>    
              </div>
            </div>

            <div class="columns nomargin" v-if="this.currentrecord._display.gender !== undefined">
              <div class="column detail is-narrow">Gender&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="gender in this.currentrecord._display.gender">
                    {{ gender }}
                </li>
                </ol>    
              </div>
            </div>                                    

            <div class="columns nomargin" v-if="this.currentrecord._display.nationality !== undefined">
              <div class="column detail is-narrow">Nationality&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="nationality in this.currentrecord._display.nationality">
                    {{ nationality }}
                </li>
                </ol>    
              </div>
            </div>                                    

            <div class="columns nomargin" v-if="this.currentrecord._display.birthDate !== undefined">
              <div class="column detail is-narrow">Birthdate&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="birthDate in this.currentrecord._display.birthDate">
                    {{ birthDate }}
                </li>
                </ol>    
              </div>
            </div>

            <div class="columns nomargin" v-if="this.currentrecord._display.birthPlace !== undefined">
              <div class="column detail is-narrow">Birth Place&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="birthPlace in this.currentrecord._display.birthPlace">
                    {{ birthPlace }}
                </li>
                </ol>    
              </div>
            </div>

            <div class="columns nomargin" v-if="this.currentrecord._display.deathDate !== undefined">
              <div class="column detail is-narrow">Death date&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="deathDate in this.currentrecord._display.deathDate">
                    {{ deathDate }}
                </li>
                </ol>    
              </div>
            </div>

            <div class="columns nomargin" v-if="this.currentrecord._display.deathPlace !== undefined">
              <div class="column detail is-narrow">Death Place&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="deathPlace in this.currentrecord._display.deathPlace">
                    {{ deathPlace }}
                </li>
                </ol>    
              </div>
            </div>                                    

            <div class="columns nomargin" v-if="this.currentrecord._display.alumniOf !== undefined">
              <div class="column detail is-narrow">Alumni of&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="alumniOf in this.currentrecord._display.alumniOf">
                    {{ alumniOf }}
                </li>
                </ol>    
              </div>
            </div>

            <div class="columns nomargin" v-if="this.currentrecord._display.associatedMedia !== undefined">
              <div class="column detail is-narrow">Media&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="associatedMedia in this.currentrecord._display.associatedMedia">
                  <span v-if="associatedMedia.contentUrl != '' && associatedMedia.contentUrl != undefined"><a class="externallink" :href="associatedMedia.contentUrl" target="_blank">{{ associatedMedia.name }} <i class="fa fa-external-link"></i></a></span>
                  <span v-else>{{ associatedMedia.name }}</span>
                </li>
                </ol>
              </div>
            </div>

            <div class="columns nomargin" v-if="this.currentrecord._display.description !== undefined">
              <div class="column detail is-narrow">Description&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="description in this.currentrecord._display.description">
                    {{ description }}
                </li>
                </ol>    
              </div>
            </div>


            <div class="columns nomargin" v-if="this.currentrecord._display.author !== undefined">
              <div class="column detail is-narrow">Authors&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="author in this.currentrecord._display.author">
                    {{ author }}
                </li>
                </ol>    
              </div>
            </div>

            <div class="columns nomargin" v-if="this.currentrecord._display.creator !== undefined">
              <div class="column detail is-narrow">Creators&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="creator in this.currentrecord._display.creator">
                    {{ creator }}
                </li>
                </ol>    
              </div>
            </div>

            <div class="columns nomargin" v-if="this.currentrecord._display.editor !== undefined">
              <div class="column detail is-narrow">Editors&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="editor in this.currentrecord._display.editor">
                    {{ editor }}
                </li>
                </ol>    
              </div>
            </div>

            <div class="columns nomargin" v-if="this.currentrecord._display.contributor !== undefined">
              <div class="column detail is-narrow">Contributors&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="contributor in this.currentrecord._display.contributor">
                    {{ contributor }}
                </li>
                </ol>    
              </div>
            </div>

            <div class="columns nomargin" v-if="this.currentrecord._display.illustrator !== undefined">
              <div class="column detail is-narrow">Illustrators&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="illustrator in this.currentrecord._display.illustrator">
                    {{ illustrator }}
                </li>
                </ol>    
              </div>
            </div>

            <div class="columns nomargin" v-if="this.currentrecord._display.translator !== undefined">
              <div class="column detail is-narrow">Translator&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="translator in this.currentrecord._display.translator">
                    {{ translator }}
                </li>
                </ol>    
              </div>
            </div>

            <div class="columns nomargin" v-if="this.currentrecord._display.source !== undefined">
              <div class="column detail is-narrow">Access full record&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="url in this.currentrecord._display.source">
                    <a class="externallink" :href="url" target="_blank">{{ url }} <i class="fa fa-external-link"></i></a>
                </li>
                </ol>                    
                
              </div>
            </div>

            <div class="columns nomargin" v-if="this.currentrecord._display.license !== undefined">
              <div class="column detail is-narrow">License&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="license in this.currentrecord._display.license">
                    <a class="externallink" :href="license" target="_blank">{{ license }} <i class="fa fa-external-link"></i></a>
                </li>
                </ol>                    
              </div>
            </div>


            <div class="columns nomargin" v-if="this.currentrecord._display.provider !== undefined">
              <div class="column detail is-narrow">Data provider&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="provider in this.currentrecord._display.provider">
                    {{ provider }}
                </li>
                </ol>    
              </div>
            </div>

            <div class="columns nomargin" v-if="this.currentrecord._display.DataSet !== undefined">
              <div class="column detail is-narrow">Dataset&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="DataSet in this.currentrecord._display.DataSet">
                    <span v-if="DataSet.url != '' && DataSet.url != undefined"> 
                      <a class="externallink" :href="DataSet.url" target="_blank">{{ DataSet.name }}</a>
                    </span>
                    <span v-else>
                      {{ DataSet.name }}
                      </span>
                </li>
                </ol>
              </div>
            </div>


            <div class="columns nomargin" v-if="this.currentrecord._display.isPartOf !== undefined">
              <div class="column detail is-narrow">Is part of&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="part in this.currentrecord._display.isPartOf">
                    <span v-if="part.url != '' && part.url != undefined"> 
                      <a class="externallink" :href="part.url" target="_blank">{{ part.name }} <i class="fa fa-external-link"></i></a>
                    </span>
                    <span v-else>
                      {{ part.name }}
                      </span>
                </li>
                </ol>    
              </div>
            </div>


            <div class="columns nomargin" v-if="this.currentrecord._display.pagination !== undefined">
              <div class="column detail is-narrow">Pagination&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="page in this.currentrecord._display.pagination">
                    {{ page }}
                </li>
                </ol>    
              </div>
            </div>

            <div class="columns nomargin" v-if="this.currentrecord._display.numberOfPages !== undefined">
              <div class="column detail is-narrow">Number of pages&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="numberOfPages in this.currentrecord._display.numberOfPages">
                    {{ numberOfPages }}
                </li>
                </ol>    
              </div>
            </div>


            <div class="columns nomargin" v-if="this.currentrecord._display.volumeNumber !== undefined">
              <div class="column detail is-narrow">Volume&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="volume in this.currentrecord._display.volumeNumber">
                    {{ volume }}
                </li>
                </ol>    
              </div>
            </div>

            <div class="columns nomargin" v-if="this.currentrecord._display.issueNumber !== undefined">
              <div class="column detail is-narrow">Issue&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="issue in this.currentrecord._display.issueNumber">
                    {{ issue }}
                </li>
                </ol>    
              </div>
            </div>

            <div class="columns nomargin" v-if="this.currentrecord._display.hasPart !== undefined">
              <div class="column detail is-narrow">Has part&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="part in this.currentrecord._display.hasPart">
                    <a class="externallink" :href="part.url">{{ part.name }} <i class="fa fa-external-link"></i></a>
                </li>
                </ol>    
              </div>
            </div>
            <div class="columns nomargin" v-if="this.currentrecord._display.dateCreated !== undefined">
              <div class="column detail is-narrow">Creationdate&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="dc in this.currentrecord._display.dateCreated">
                    {{ dc }}
                </li>
                </ol>    
              </div>
            </div>

            <div class="columns nomargin" v-if="this.currentrecord._display.locationCreated !== undefined">
              <div class="column detail is-narrow">Creationlocation&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="lc in this.currentrecord._display.locationCreated">
                    {{ lc.name }}
                </li>
                </ol>    
              </div>
            </div>


            <div class="columns nomargin" v-if="this.currentrecord._display.datePublished !== undefined">
              <div class="column detail is-narrow">Publication&nbsp;Date&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="dp in this.currentrecord._display.datePublished">
                    {{ dp }}
                </li>
                </ol>    
              </div>
            </div>

            <div class="columns nomargin" v-if="this.currentrecord._display.publisher !== undefined">
              <div class="column detail is-narrow">Publisher&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="publisher in this.currentrecord._display.publisher">
                    {{ publisher }}
                </li>
                </ol>    
              </div>
            </div>

            <div class="columns nomargin" v-if="this.currentrecord._display.inLanguage !== undefined">
              <div class="column detail is-narrow">Language&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="language in this.currentrecord._display.inLanguage">
                    {{ language }}
                </li>
                </ol>    
              </div>
            </div>

            <div class="columns nomargin" v-if="this.currentrecord._display.Genre !== undefined">
              <div class="column detail is-narrow">Discipline/classification&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="Genre in this.currentrecord._display.Genre">
                    {{ Genre }}
                </li>
                </ol>    
              </div>
            </div>



            <div class="columns nomargin" v-if="this.currentrecord._display.keywords !== undefined">
              <div class="column detail is-narrow">Keywords&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="keyword in this.currentrecord._display.keywords">
                    {{ keyword }}
                </li>
                </ol>    
              </div>
            </div>


            <div class="columns nomargin" v-if="this.currentrecord._display.isbn !== undefined">
              <div class="column detail is-narrow">ISBN&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="isbn in this.currentrecord._display.isbn">
                    {{ isbn }}
                </li>
                </ol>    
              </div>
            </div>

            <div class="columns nomargin" v-if="this.currentrecord._display.issn !== undefined">
              <div class="column detail is-narrow">ISSN&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="issn in this.currentrecord._display.issn">
                    {{ issn }}
                </li>
                </ol>    
              </div>
            </div>


            <div class="columns nomargin" v-if="this.currentrecord._display.sdDatePublished !== undefined">
              <div class="column detail is-narrow">Record publication date&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="sdDatePublished in this.currentrecord._display.sdDatePublished">
                  {{ sdDatePublished }}
                </li>
                </ol>
              </div>
            </div>

            <div class="columns nomargin" v-if="this.currentrecord._display.sdPublisher !== undefined">
              <div class="column detail is-narrow">Record publisher&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="sdPublisher in this.currentrecord._display.sdPublisher">
                  {{ sdPublisher }}
                </li>
                </ol>
              </div>
            </div>

            <div class="columns nomargin" v-if="this.currentrecord._display.includedInDataCatalog !== undefined">
              <div class="column detail is-narrow">Included&nbsp;in&nbsp;Data&nbsp;Catalog&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="includedInDataCatalog in this.currentrecord._display.includedInDataCatalog">
                  {{ includedInDataCatalog }}
                </li>
                </ol>
              </div>
            </div>

            <div class="columns nomargin" v-if="this.currentrecord._display.startDate !== undefined">
              <div class="column detail is-narrow">Start&nbsp;Date&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="startDate in this.currentrecord._display.startDate">
                  {{ startDate }}
                </li>
                </ol>
              </div>
            </div>

            <div class="columns nomargin" v-if="this.currentrecord._display.endDate !== undefined">
              <div class="column detail is-narrow">End&nbsp;Date&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="endDate in this.currentrecord._display.endDate">
                  {{ endDate }}
                </li>
                </ol>
              </div>
            </div>

            <div class="columns nomargin" v-if="this.currentrecord._display.additionalType !== undefined">
              <div class="column detail is-narrow">Additional Type&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="additionalType in this.currentrecord._display.additionalType">
                  {{ additionalType }}
                </li>
                </ol>
              </div>
            </div>

            <div class="columns nomargin" v-if="this.currentrecord._display.about !== undefined">
              <div class="column detail is-narrow">About&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="about in this.currentrecord._display.about">
                  {{ about }}
                </li>
                </ol>
              </div>
            </div>


            <div class="columns nomargin" v-if="this.currentrecord._display.subjectOf !== undefined">
              <div class="column detail is-narrow">Subject&nbsp;of&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="subjectOf in this.currentrecord._display.subjectOf">
                  <p v-if="subjectOf.url != undefined">
                    <a class="externallink" :href="subjectOf.url" target="_blank">{{ subjectOf.name }} <i class="fa fa-external-link"></i></a>
                  </p>
                  <p v-else>
                    {{ subjectOf.name }} <span v-if="subjectOf.location != undefined">{{ subjectOf.location.name}} <span v-if="subjectOf.location.address != undefined">{{ subjectOf.location.address}}</span></span> 
                  </p>
                </li>
                </ol>
              </div>
            </div>

            <div class="columns nomargin" v-if="this.currentrecord._display.contentLocation !== undefined">
              <div class="column detail is-narrow">Content Location&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="contentLocation in this.currentrecord._display.contentLocation">
                  {{ contentLocation }}
                </li>
                </ol>
              </div>
            </div>

            <div class="columns nomargin" v-if="this.currentrecord._display.spatialCoverage !== undefined">
              <div class="column detail is-narrow">Spatial Coverage&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="spatialCoverage in this.currentrecord._display.spatialCoverage">
                  {{ spatialCoverage }}
                </li>
                </ol>
              </div>
            </div>

            <div class="columns nomargin" v-if="this.currentrecord._display.temporalCoverage !== undefined">
              <div class="column detail is-narrow">Temporal Coverage&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="temporalCoverage in this.currentrecord._display.temporalCoverage">
                  {{ temporalCoverage }}
                </li>
                </ol>
              </div>
            </div>

            <div class="columns nomargin" v-if="this.currentrecord._display.mentions !== undefined">
              <div class="column detail is-narrow">Mentions&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="mentions in this.currentrecord._display.mentions">
                  {{ mentions }}
                </li>
                </ol>
              </div>
            </div>

            <div class="columns nomargin" v-if="this.currentrecord._display.distribution !== undefined">
              <div class="column detail is-narrow">Distribution&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="distribution in this.currentrecord._display.distribution">
                  {{ distribution }}
                </li>
                </ol>
              </div>
            </div>

            <div class="columns nomargin" v-if="this.currentrecord._display.copyright !== undefined">
              <div class="column detail is-narrow">Copyright&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="copyright in this.currentrecord._display.copyright">
                  {{ copyright }}
                </li>
                </ol>
              </div>
            </div>
 
            <div class="columns nomargin" v-if="this.currentrecord._display.bookEdition !== undefined">
              <div class="column detail is-narrow">Edition of book&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="bookEdition in this.currentrecord._display.bookEdition">
                  {{ bookEdition }}
                </li>
                </ol>
              </div>
            </div>

           <div class="columns nomargin" v-if="this.currentrecord._display.material !== undefined">
              <div class="column detail is-narrow">Made of&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="material in this.currentrecord._display.material">
                  {{ material }}
                </li>
                </ol>
              </div>
            </div>

           <div class="columns nomargin" v-if="this.currentrecord._display.review !== undefined">
              <div class="column detail is-narrow">Review&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="review in this.currentrecord._display.review">
                  {{ review }}
                </li>
                </ol>
              </div>
            </div>

           <div class="columns nomargin" v-if="this.currentrecord._display.itemReviewed !== undefined">
              <div class="column detail is-narrow">Item Reviewed&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="itemReviewed in this.currentrecord._display.itemReviewed">
                  {{ itemReviewed }}
                </li>
                </ol>
              </div>
            </div>

           <div class="columns nomargin" v-if="this.currentrecord._display.translationOfWork !== undefined">
              <div class="column detail is-narrow">Translation of work&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="translationOfWork in this.currentrecord._display.translationOfWork">
                  {{ translationOfWork }}
                </li>
                </ol>
              </div>
            </div>


           <div class="columns nomargin" v-if="this.currentrecord._display.workTranslation !== undefined">
              <div class="column detail is-narrow">Has translation&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="workTranslation in this.currentrecord._display.workTranslation">
                  {{ workTranslation }}
                </li>
                </ol>
              </div>
            </div>

           <div class="columns nomargin" v-if="this.currentrecord._display.version !== undefined">
              <div class="column detail is-narrow">Version&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail" v-for="version in this.currentrecord._display.version">
                  {{ version }}
                </li>
                </ol>
              </div>
            </div>

            <div class="columns nomargin" v-if="this.currentrecord._display.id !== undefined">
              <div class="column detail is-narrow">Identifier&nbsp;:&nbsp;</div>
              <div class="column detail">
                <ol>
                <li class="detail">
                    {{ this.currentrecord._display.id }}
                </li>
                </ol>    
              </div>
            </div>

            <div class="is-hidden">
              <textarea ref="jsonarea">{{ JSON.stringify(this.currentrecord._source, null, 4) }}</textarea>
            </div>
            </slot>

        </section>
        <div class="modal-card-body toolbar" v-if="this.popin==''">

            <div class="columns">
              <div class="column is-half"></div>
              <div class="column" style="text-align:center">
                <i class="fa fa-quote-left" style="font-size:25px" @click="popin='citation';"></i>
                <p style="font-size:12px">Citation</p>
              </div>
              <div class="column" style="text-align:center">
                <i class="fa fa-envelope" style="font-size:25px" @click="popin='email';"></i>
                <p style="font-size:12px">E-mail</p>
              </div>
              <div class="column" style="text-align:center">
                <i class="fa fa-link" style="font-size:25px" @click="popin='permalink';"></i>
                <p style="font-size:12px">Persistent link</p>
              </div>
              <!--
              <div class="column" style="text-align:center">
                <i class="fa fa-clipboard" style="font-size:25px" @click="exportToClipboard()"></i>
                <p style="font-size:12px">Export</p>
              </div>
              -->
              <div class="column" style="text-align:center" v-if="is_auth">
                <i class="fa fa-save" style="font-size:25px"@click="popin='saveset';"></i>
                <p style="font-size:12px">Save to set</p>
              </div>
            </div>

        </div>

        <div class="modal-card-body toolbar" style="border-top:1px solid #dbdbdb" v-if="this.popin=='citation'">
          <a class="delete" style="float:right" @click.prevent.stop="popin=''"></a>
          <div class="columns">
            <div class="column is-narrow">
              <aside class="menu">
                <ul class="menu-list">
                    <li class="detail" v-for="(value,key) in this.citation_styles"><a :ref="key" v-on:click.prevent.stop="activeCitationStyle=key">{{ value.name }}</a><li>
                </ul>
              </aside>
            </div>
            <div class="column ">
                <div class="box" style="font-size:12px" ref="citationbox" v-html="this.activeCitation"></div>
                <!-- <button class="button is-primary" @click="copyToClipboard($refs.citationbox)">Copy to clipboard</button> -->
                <a class="link" @click="copyToClipboard($refs.citationbox)">Copy citation to clipboard <i class="fa fa-clipboard"></i></a>
            </div>
          </div>
        </div>
        <div class="modal-card-body toolbar" style="border-top:1px solid #dbdbdb" v-if="this.popin=='email'">
          <a class="delete" style="float:right" @click.prevent.stop="popin=''"></a>
          <table border=0 cellspacing=0 width="100%">
            <tr>
              <td nowrap>Subject : </td><td width="100%">{{ this.mailsubject }}</td>
            </tr>
            <tr>
              <td>To : </td><td><input class="input" name="email" ref="email" style="width:70%" v-model="mailto"></td>
            </tr>
            <tr>
              <td nowrap>Message : </td><td><textarea class="input" rows=3 stylename="msg" ref="msg" style="width:70%;height:5.5em" v-model="mailmsg"></textarea></td>
            </tr>
          </table>

          <button class='button is-primary' style="float:right" @click="emailItem()">Send</button>
        </div>

        <div class="modal-card-body toolbar" style="border-top:1px solid #dbdbdb" v-if="this.popin=='permalink'">
          <a class="delete" style="float:right" @click.prevent.stop="popin=''"></a>
          <div class="columns">
            <div class="column">
              <div class="box" ref="permalinkbox" v-html="this.currentrecord._display.url[0]"></div>
              <!-- <button class="button is-primary" @click="copyToClipboard($refs.permalinkbox)">Copy permalink to clipboard</button> -->
              <a class="link" @click.prevent.stop="copyToClipboard($refs.permalinkbox)">Copy permalink to clipboard <i class="fa fa-clipboard"></i></a>
            </div>
          </div>
        </div>

        <div class="modal-card-body toolbar" style="border-top:1px solid #dbdbdb" v-if="this.popin=='saveset'">
          <a class="delete" style="float:right" @click.prevent.stop="popin=''"></a>
          Store this record in set : <input class="input" style="width:50%" list="sets" name="set" ref="set" v-model="shelf">
            <datalist id="sets">
              <option v-for="option in this.savedsets" v-bind:value="option.name">
            </datalist>
            <button  class='button is-primary' @click="storeinset()">Save</button>
        </div>


        <footer class="modal-card-foot">
            <button class="button" style="float:left;" @click="down" v-if="this.currentidx>0" >&lt;&lt;</button>
            <button ref="nextbtn" class="button" v-if="this.currentidx < this.maxidx" @click="up" style="margin-left:auto">&gt;&gt;</button>
        </footer>
      </div>
    </div>
  </transition>
</template>
<script>
module.exports = {
    props : ['currentidx', 'maxidx', 'currentrecord', 'busy', 'is_auth', 'savedsets'],
    data: function() {
        return {json_visible: false, popin:'', activeCitationStyle:"", mailto:'', shelf:'',
                citation_styles: {"MLA7": {csl:"modern-language-association-7th-edition", name:"Modern Language Assocation, 7th edition (MLA 7)"},
                                "MLA8": {csl:"modern-language-association", name:"Modern Language Assocation, 8th edition (MLA 8)"},
                                "APA": {csl:"apa-6th-edition", name:"American Psychological Association (APA)"},
                                "CT16": {csl:"chicago-author-date-16th-edition", name:"Chicago/Turabian, 16th edition"},
                                "HAR1": {csl:"elsevier-harvard", name:"Harvard 1"}},
                listseturl : "/set/list",
                storeseturl : "/set/store",
                mailmsg : ""
                }
    },
    mounted() {
      if (this.is_auth) axios.get(this.listseturl).then(response => this.listSets(response.data));
    },
    watch: {
      busy : {
        handler: function(valobj, oldvalobj){
          if (this.$refs["nextbtn"] != undefined) {
            if (valobj) {
              this.$refs["nextbtn"].classList.add('is-loading')
            } else {
              this.$refs["nextbtn"].className='button'
            }
          }
        }
      },
      activeCitationStyle: {
        handler: function() {
          for (var key in this.citation_styles) {
            this.$refs[key][0].classList.remove("is-active");
          }

          if (this.activeCitationStyle != "") {
            this.$refs[this.activeCitationStyle][0].classList.add("is-active");
            if (this.currentrecord._display.citations[this.activeCitationStyle] == undefined || this.currentrecord._display.citations[this.activeCitationStyle] == "") {
              citeurl = "/cite/"+this.citation_styles[this.activeCitationStyle].csl+"/text/bibliography";
              this.citebusy = true
              axios.post(citeurl, this.currentrecord._source, {headers: {'Content-Type': 'application/ld+json'}}).then(response => this.citeResult(response.data)).catch(error => this.handleError(error)); 
            }
          }
        }
      },
      popin: {
        handler: function () {
          if (this.popin == 'citation') {
            this.$nextTick(() => {
              tmp = this.activeCitationStyle;
              if (tmp == "") {
                this.activeCitationStyle = 'MLA7'
              } else {
                this.activeCitationStyle = ''
                this.$nextTick (() => {
                  this.activeCitationStyle = tmp
                })
              }
            })
          }
        }

      },
      currentidx: {
        handler: function() {
          if (this.popin == 'citation' && this.activeCitationStyle != '') {
            tmp = this.activeCitationStyle;
            this.activeCitationStyle = ''
            this.$nextTick (() => {
              this.activeCitationStyle = tmp
            })
          }
        }
      } 
    },
    methods: {
        up:function() {
          if (!this.citebusy) {
            this.json_visible=false;
            this.$emit("next");
          }
        },
        down:function() {
          if (!this.citebusy) {
            this.json_visible=false;
            this.$emit("prev");
          }
        },
        setjson_visible(tf) {
            this.json_visible = tf;
        },
        showModal:function() {
          this.$nextTick(() => {
            this.popin="";
            this.$refs['modalcontainer'].classList.add('is-active');
          })
        },
        closeModal:function() {
          this.popin="";
          this.$parent.currentIdx = -1;
          this.$refs['modalcontainer'].classList.remove('is-active');
        },
        exportToClipboard:function() {
          toCopy = this.$refs['jsonarea'];
          toCopy.select();
          alert(toCopy.value)
        },
        copyToClipboard(ref) {
          var range = document.createRange();
          range.selectNode(ref);
          window.getSelection().removeAllRanges();
          window.getSelection().addRange(range);
          document.execCommand("copy");
          window.getSelection().removeAllRanges(); 
          alert("Information has been copied to the clipboard.")         
        },
        emailItem: function() {
          data = Object();
          data["to"] = this.mailto;
          data["subject"] = this.mailsubject;
          data["message"] = this.mailmsg;
          data['item'] = this.currentrecord._display;
          axios.post('/mail/item', data).then(response => this.mailResult(response.data)).catch(error => this.mailError(error)); 
          this.$emit('gevent', {"action" : 'mail', "label": this.currentrecord._display.id})
        },
        mailResult: function() {
          this.popin="";
          alert('Email has been sent');
        },
        mailError: function(error) {
          Vue.nextTick(function() { alert(error.response.data.message); }, error);
        },
        citeResult : function(data) {
          this.currentrecord._display.citations[this.activeCitationStyle] = data;
          this.citebusy = false;
          tmp = this.activeCitationStyle;
          this.activeCitationStyle = ''
          this.$nextTick (() => {
            this.activeCitationStyle = tmp
          })
        },
        handleError: function(error) {
          Vue.nextTick(function() { this.citebusy = false; alert(error.response.data.message); }, error);
        },
        listSets: function(data) {
            while (this.savedsets.length > 0) this.savedsets.pop();
            for (key in data) {
                this.savedsets.push(data[key]);
            }          
        },
        storeinset: function() {
            data = Object();
            data["value"] = this.currentrecord;
            data["shelf"] = this.shelf;
            axios.post(this.storeseturl, data).then(response => this.setResult(response.data)).catch(error => this.handleError(error)); 
            this.$emit('gevent', {"action" : 'setstore', "label": this.currentrecord._display.id})            
        },
        setResult: function() {
          this.popin="";
          if (this.is_auth) axios.get(this.listseturl).then(response => this.listSets(response.data));
          alert("Record has been stored in '" + this.shelf + "'");          
        }
    },
    computed: {
      activeCitation: function() {
        return this.currentrecord._display.citations[this.activeCitationStyle];
      },
      mailsubject: function() {
        maxlength = 80;
        title = this.currentrecord._display.name[0];
        if (title.length > maxlength) {
          title = title.substr(0,maxlength)
          while (title.slice(-1) != " "){
            title = title.substr(0, title.length -1);
          } 
          title += '...';
        }
        return '[ReIReS] ' + title;
      }
    }
  }
</script>
  