<template>
    <div class="">
        <div v-if="activefilters.length > 0" class="box bottommargin smallpadding">
            <span class="facet monda">Active filters </span>
            <div class="block" v-for="(filt,idx) in activefilters" v-bind:key="idx" style="margin-bottom:0.1rem">
            <span class="tag is-primary" style="min-height:2em;height:auto;white-space:normal">
                {{ filt.key_as_string.replace (/(^")|("$)/g, '') }}
                <button class="delete is-small" @click="removefilter(filt.cbvalue)"></button>
            </span>
            </div>
        </div>

        <div v-if="applybtn" class="box bottommargin" style="text-align: center;">
            <button class="button is-primary" @click="applyfilters()">Apply filters</button>
<!--            <a class="link" @click.prevent.stop="applyfilters()">&gt;&gt; Apply filters &lt;&lt;</a> -->
        </div>
        <div class="box bottommargin smallpadding monda" style="margin-bottom:10px">
            Filters
        </div>
        <div v-if="facets.length>0">
<!--
            <div v-for="(facet, index) in facets" v-bind:key="index">
                <div v-if="facet.buckets.length > 0 && facet.key == 'dataset'" class="box bottommargin smallpadding">
                    <span v-if="facettranslations[facet.key] != undefined" class="facet monda">{{ facettranslations[facet.key] }} </span> 
                    <span v-else class="facet monda">{{ facet.key }} </span>
                    <li class="bucket">
                        <ul class="bucketitem" v-for="(bucket, idx) in facet.buckets" v-bind:key="idx">
                            <div  v-if="bucket.key_as_string != undefined">
                                <input type="checkbox" :value="bucket" v-model="localfilters" :id="bucket.cbvalue" @click="clickcb();"><label :for="bucket.cbvalue" @click="clicklbl();" style="cursor:pointer"> {{ bucket.key_as_string }} <span v-if="bucket.doc_count != undefined">({{ bucket.doc_count }})</span></label>
                            </div>
                            <div v-else>
                                <input type="checkbox" :value="bucket" v-model="localfilters" @click="clickcb();" :id="bucket.cbvalue"><label :for="bucket.cbvalue" @click="clicklbl();" style="cursor:pointer"> {{ bucket.key }} <span v-if="bucket.doc_count != undefined">({{ bucket.doc_count }})</span></label>
                            </div>
                        </ul>
                    </li>
                </div>
            </div>
-->
            <div class="box bottommargin smallpadding">
                <span class="facet monda">{{ facettranslations['datePublished'] }} </span>&nbsp;&nbsp;<span class="facet monda" style="cursor:pointer" @click="toggleopen()"><img :src="chevron" width="12px" align="bottom"></span>
                <li class="bucket"  v-bind:class="[open ? 'isVisible' : 'isInvisible']">
                    <ul class="bucketitem">From : <input class="input" type="number" ref="datePublished_from" v-model="datePublished_from" :min="min_datePublished" :max="max_datePublished" @change="clickcb();"></ul>
                    <ul class="bucketitem">Until : <input class="input" type="number" ref="datePublished_until" v-model="datePublished_until" :min="min_datePublished" :max="max_datePublished" @change="clickcb();"></ul>
                </li>
            </div>
        </div>

        <div v-for="(facet, index) in facets" v-bind:key="index">
            <div v-if="facet.buckets.length > 0" class="box bottommargin smallpadding">
                <bucket v-bind:buckets="facet.buckets" v-bind:facetkey="facet.key"></bucket>
            </div>
        </div>

        <div v-if="facets.length>999999999999">
            <div class="box bottommargin smallpadding">
                <span class="facet monda">{{ facettranslations['sdDatePublished'] }} </span> 
                <li class="bucket">
                    <ul class="bucketitem" v-for="(bucket, idx) in buckets_sdDatePublished[0].buckets" v-bind:key="idx">
                        <div  v-if="bucket.key_as_string != undefined">
                            <input type="checkbox" :value="bucket" v-model="localfilters" :id="bucket.cbvalue" @click="clickcb();"><label :for="bucket.cbvalue" @click="clicklbl();" style="cursor:pointer"> {{ bucket.key_as_string }}</label>
                        </div>
                        <div v-else>
                            <input type="checkbox" :value="bucket" v-model="localfilters" @click="clickcb();" :id="bucket.cbvalue"><label :for="bucket.cbvalue" @click="clicklbl();" style="cursor:pointer"> {{ bucket.key }}</label>
                        </div>
                    </ul>
                </li>
            </div>
        </div>
        <div v-if="applybtn" class="box bottommargin" style="text-align: center;">
            <button class="button is-primary" @click="applyfilters()">Apply filters</button>
<!--            <a class="link" @click.prevent.stop="applyfilters()">&gt;&gt; Apply filters &lt;&lt;</a> -->
        </div>
    </div>
</template>
<script>
module.exports = {
    props:{
        facets:{type:Array,required:true},
        activefilters:{type:Array,required:true}        
    },
    data: function() {
        return { localfilters: [], 
                 applybtn: false, 
                 labelclicked : false,
                 datePublished_from:-500,
                 datePublished_until:2020,
                 facettranslations : { "inLanguage":"Language", "datePublished":"Publication date", "dateCreated":"Creationdate", "provider":"Metadata provider", "author":"Author", "contributor":"Contributor", "subjects":"Subjects", "locationCreated":"Creation location", "publisher":"Publisher", "type":"Type", "sdDatePublished":"Publication date of metadata", "dataset":"Dataset", "digitalrepresentation":"Digital Representation"},
                 open:true,
                 chevron:"/img/arrow_up.png"
        }
    },
    watch: {
        localfilters: function() {
            if (this.labelclicked) {
                this.$emit('filterchanged', this.localfilters)
                this.applybtn = false;
                this.labelclicked = false;
            }
        },
        facets: function() {
            this.datePublished_from = this.min_datePublished;
            this.datePublished_until = this.max_datePublished;
        }
    },
    methods: {
        clearall: function() {
            while(this.localfilters.length > 0) this.localfilters.pop();
            this.applybtn = false
        },
        clickcb: function() {
            this.applybtn = true;
        },
        clicklbl: function() {
            this.labelclicked = true;
        },
        applyfilters: function() {

            for (i in this.localfilters) {
                if (this.localfilters[i].cbvalue.split(/:(.+)/)[0] == "datePublished" || this.localfilters[i].cbvalue.split(/:(.+)/)[0] == "dateCreated") {
                    this.localfilters.splice(i,1);
                }
            }
            if (this.$refs.datePublished_from.min != this.$refs.datePublished_from.value || this.$refs.datePublished_until.max != this.$refs.datePublished_until.value) {
                f=Object();
                f.cbvalue="publicationdate:[" + this.datePublished_from + " TO " + this.datePublished_until + "]";
                f.key_as_string = this.datePublished_from + " - " + this.datePublished_until;
                this.localfilters.push(f);
            }
            this.$emit('filterchanged', this.localfilters);
            this.applybtn = false;
            this.labelclicked = false;
        },
        removefilter: function(f) {
            for(i=0; i<this.localfilters.length; i++) {
                if (this.localfilters[i].cbvalue == f) {
                    this.labelclicked = true;
                    this.localfilters.splice(i,1);
                    break;
                }
            }
        },
        toggleopen() {
            this.open = !this.open;
            this.chevron = (this.open?"/img/arrow_up.png":"/img/arrow_dn.png");
        }
    },
    computed: {
        min_datePublished: function() {
            for(k in this.facets) {
                if (this.facets[k].key == 'min_datePublished') return this.facets[k].value_as_string;
            }

        },
        max_datePublished: function() {
            for(k in this.facets) {
                if (this.facets[k].key == 'max_datePublished') return this.facets[k].value_as_string;
            }

        }        
    },
    components: {
        'bucket': window.httpVueLoader('/js/components/Bucket.vue')
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
</style>