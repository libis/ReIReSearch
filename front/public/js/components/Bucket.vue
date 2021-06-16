<template>
    <div>
        <span v-if="facettranslations[facetkey] != undefined" class="facet monda">{{ facettranslations[facetkey] }} </span> 
        <span v-else class="facet monda">{{ facetkey }} </span>&nbsp;&nbsp;<span class="facet monda" style="cursor:pointer" @click="toggleopen()"><img :src="chevron" width="12px" align="bottom"></span>
        <li class="bucket" v-bind:class="[open ? 'isVisible' : 'isInvisible']">
            <ul class="bucketitem" v-for="(bucket, idx) in buckets" v-bind:key="idx" v-bind:class="[(fullview || idx<ll) ? 'isVisible' : 'isInvisible']">
                <div  v-if="bucket.key_as_string != undefined">
                    <input type="checkbox" :value="bucket" v-model="$parent.localfilters" :id="bucket.cbvalue" @click="clickcb();"><label :for="bucket.cbvalue" @click="clicklbl();" style="cursor:pointer"> {{ bucket.key_as_string }} <span v-if="bucket.doc_count != undefined">({{ bucket.doc_count }})</span></label>
                </div>
                <div v-else>
                    <input type="checkbox" :value="bucket" v-model="$parent.localfilters" @click="clickcb();" :id="bucket.cbvalue"><label :for="bucket.cbvalue" @click="clicklbl();" style="cursor:pointer"> {{ bucket.key }} <span v-if="bucket.doc_count != undefined">({{ bucket.doc_count }})</span></label>
                </div>
            </ul>
        </li>
        <div v-if="buckets.length > ll && open">
            <div v-if="this.fullview" @click="showless()" class="centered monda">Show less</div>
            <div v-else @click="showmore()" class="centered monda">Show more</div>
        </div>
    </div>
</template>
<script>
module.exports = {
    props:{
        buckets:{type:Array,required:true},
        facetkey:{type:String,required:true}
    },
    data: function() {
        return { fullview: false,
                 open:true,
                 chevron:"/img/arrow_up.png",
                 ll: 6,
                 facettranslations : { "inLanguage":"Language", "datePublished":"Publication date", "dateCreated":"Creationdate", "provider":"Metadata provider", "author":"Author", "contributor":"Contributor", "subjects":"Subjects", "locationCreated":"Creation location", "publisher":"Publisher", "type":"Type", "sdDatePublished":"Metadata publication date", "dataset":"Dataset", "digitalrepresentation":"Digital Representation"},

               }
    },
    methods: {
        showmore() {
            this.fullview = true
        },
        showless() {
            this.fullview = false
        },
        clickcb() {
            this.$parent.clickcb();
        },
        clicklbl() {
            this.$parent.clicklbl();
        },
        toggleopen() {
            this.open = !this.open;
            this.chevron = (this.open?"/img/arrow_up.png":"/img/arrow_dn.png");
        }
    }
}
</script>
<style scoped>
.isVisible {
    visibility: visible;
    display:inline
}
.isInvisible {
    visibility: hidden;
    display:none
}
.centered {
    text-align: center;
    cursor: pointer;
    width:100%;
    font-size: 12px;
}
</style>