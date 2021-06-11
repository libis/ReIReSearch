<template>
    <div class="card bottommargin">
        <header class="card-header">
            <div class="tabs">
            <ul>
                <li v-bind:class="{'is-active': !advanced}"><a @click.prevent.stop="advanced=false">Simple Search</a></li>
                <li v-bind:class="{'is-active': advanced}"><a @click.prevent.stop="advanced=true">Advanced Search</a></li>
            </ul>
            </div>                
        </header>
        <div class="card-content">
            <div v-if="!advanced">
                <input type="text" class="input" v-model="searchQuery" style="width:70%" v-on:keyup.enter="search()">
                <button class="button is-primary" v-on:click="search()">Search</button>
                <button class="button" v-on:click="clear()">Clear</button>
            </div>
            <div v-else>
                <table border=0 cellspacing=2 cellpadding=2>
                    <tr v-for="(advancedQ,index) in advancedQueryObj">
                        <td class="formtd">
                            <div class="select" v-if="advancedQ.operator!='blank'">
                            <select  v-model="advancedQ.operator">
                                <option value="AND">AND</option>
                                <option value="OR">OR</option>
                                <option value="NOT">NOT</option>
                            </select>
                            </div>
                        </td>
                        <td class="formtd">
                            <div class="select">
                            <select v-model="advancedQ.field">
                                <option value="any">Any</option>
                                <option value="title">Title</option>
                                <option value="author">Author</option>
                                <option value="subject">Subject</option>
                                <option value="isbn">ISBN</option>
                                <option value="issn">ISSN</option>
                                <option value="publicationdate">Publication Date</option>
                                <option value="creationLocation">Publication Place</option>
                                <option value="publisher">Publisher</option>
                                <option value="provider">Provider</option>
                                <option value="dataset">Dataset</option>
                            </select>
                            </div>
                        </td>
                        <td class="formtd">
                            <div class="select" v-if="advancedQ.field != 'provider' && advancedQ.field != 'dataset'">
                            <select v-model="advancedQ.condition">
                                <option value="contains">contains the words</option>
                                <option value="phrase">contains the exact phrase</option>
                                <option value="starts">starts with</option>
                            </select>
                            
                            </div>
                        </td>
                        <td class="formtd">
                            <input class="input" type="text" v-if="advancedQ.field != 'provider' && advancedQ.field != 'dataset'" v-model="advancedQ.query" v-on:keyup.enter="search()">
                            <div class="select" v-if="advancedQ.field == 'provider'">
                            <select style="width:315px" v-model="advancedQ.query" >
                                <option v-for="item in this.ddlists.providers" :value="item">{{ item }}</option>
                            </select>
                            </div>
                            <div class="select" v-if="advancedQ.field == 'dataset'">
                            <select style="width:315px" v-model="advancedQ.query">
                                <option v-for="item in this.ddlists.datasets" :value="item">{{ item }}</option>
                            </select>
                            </div>
                        </td>
                        <td  class="formtd" v-if="advancedQueryObj.length > 1">
                            <button class="button" @click="removeLine(index)">-</button>
                        </td>
                    </tr>
                    <tr>
                        <td  class="formtd" colspan=4></td>
                        <td>
                            <button class="button" @click="addNewLine">+</button>
                        </td>
                    </tr>
                </table>
                
                <button class="button is-primary" v-on:click="search()">Search</button>
                <button class="button" v-on:click="clear()">Clear</button>
            </div>
        </div>
        <footer class="columns">
            <div class="column is-3" style="margin-left:20px" v-if="resultstats['search_total'] > 0">N° of hits : {{ resultstats['total'] }}</div>
            <div class="column is-5"  style="text-align:right" v-if="resultstats.search_total > 0">Sort by : 
                <div class="select">
                    <select v-if="results.length > 0" v-model="sortorder" @change="search()">
                    <option value="relevance">Relevance</option>
                    <option value="title">Title</option>
                    <option value="date DESC">Publication Date - newest first</option>
                    <option value="date ASC">Publication Date - oldest first</option>
                    </select>
                </div>
            </div>
            <div class="column" style="text-align:right;margin-right:20px">
                <i class="fa fa-save" style="margin-left:5px" v-if="results.length > 0 && is_auth" @click="saveQuery" title="Save this query"></i>
                <i class="fa fa-list-ul" style="margin-left:5px" v-if="(savedqueries.length + history.length) > 0" @click="showQueries" title="Show saved queries"></i>
                <i class="fa fa-folder" style="margin-left:5px" v-if="savedsets.length > 0" @click="showSets" title="Show saved sets"></i> 
                <a style="margin-left:5px;border:0px;background:none" v-if="results.length > 0 && is_auth" @click="exportResult('json')" title="Export results as JSON-LD"><i class="fa fa-file"></i>.json</a>
                <a style="margin-left:5px;border:0px;background:none" v-if="results.length > 0 && is_auth" v-if="results.length > 0 && is_auth" @click="exportResult('csv')" title="Export results as CSV"><i class="fa fa-file"></i>.csv</a>
            </div>

        </footer>
    </div>
</template>
<script>
module.exports = {
    data: function () {
      return {
        searchQuery: "",
        advancedSearchQuery: "",
        url : "/search",
        savequeryurl : "/query/save",
        listqueryurl : "/query/list",
        listhistoryurl : "/history/list",
        exportqueueurl : "/query/queue",
        ddlistsurl : "/ddlists",
        advanced:false,
        advancedQueryObj : [{'operator':'blank','field':'any','condition':'contains','query':''}],
        sortorder: "relevance",
        sources : ['elastic','brepols'],
        ddlists : [],
        setid :0
      }
    },
    props: {
        results:{type:Array,required:true},
        facets:{type:Array,required:true},
        filters:{type:Array,required:true},
        resultstats:{type:Object,required:true},
        savedqueries:{type:Array,required:true},
        savedsets:{type:Array,required:true},
        history:{type:Array,required:true},
        is_auth:{type:Boolean,required:true},
    },
    watch: {
       advancedQueryObj: {
           handler: function(valobj, oldvalobj) {
                this.advancedSearchQuery = '';
                for(let i = 0; i < valobj.length; i++) {
                    line = valobj[i];
                    if (line.query != '') {
                        if (line.field == 'provider' || line.field == 'dataset') {
                            line.condition = "phrase";
                        }
                        if (line.operator == 'NOT') {
                            this.advancedSearchQuery += ' AND NOT '
                        }
                        if (line.operator == 'AND' || line.operator == 'OR') {
                            this.advancedSearchQuery += ' ' + line.operator + ' '
                        }
                        if (line.condition == "contains") {
                            this.advancedSearchQuery += line.field+':'+line.query
                        }
                        if (line.condition == "starts") {
                            this.advancedSearchQuery += line.field+':'+line.query+'*'
                        }
                        if (line.condition == "phrase") {
                            this.advancedSearchQuery += line.field+':"'+line.query+'"'
                        }
                    }
                }
           },
           deep : true
        },
    },
    methods :{
        clear : function() {
            // results = [] werkt niet omwille dat Vue dat blijkbaar niet detecteert, dus los ik het maar even zo op 
            while (this.results.length > 0) this.results.pop(); 
            while (this.facets.length > 0) this.facets.pop(); 
            while (this.filters.length > 0) this.filters.pop(); 
            this.$parent.currentIdx=-1; 
            this.searchQuery = "";
            this.advancedSearchQuery = "";
            this.sortorder = 'relevance';
            this.advancedQueryObj = [{'operator':'blank','field':'any','condition':'contains','query':''}];
            this.resultstats['total'] = 0;
            this.resultstats['search_total'] = 0;
            this.setid = 0;
            this.$emit('complete', false);
        },
        search : function () {
            while (this.results.length > 0) this.results.pop(); 
            this.resultstats['total'] = 0;
            this.resultstats['search_total'] = 0;
            this.setid = 0;
            this.$emit("newsearch");
            while (this.facets.length > 0) this.facets.pop();
            this.$emit('complete', false);
            this.$emit("busy", true);
            axios.post(this.url, this.searchRequest('first')).then(response => this.searchResult(response.data)).catch(error => this.handleError(error)); 
        },
        filtersearch : function () {
            while (this.results.length > 0) this.results.pop(); 
            this.resultstats['total'] = 0;
            this.resultstats['search_total'] = 0;
            this.setid = 0;
            while (this.facets.length > 0) this.facets.pop();
            this.$emit('complete', false);
            this.$emit("busy", true);
            this.$parent.currentIdx=-1; 
            this.$nextTick(() => {
                axios.post(this.url, this.searchRequest('first')).then(response => this.searchResult(response.data)).catch(error => this.handleError(error)); 
            });
        },
        moredata : function() {
            if (!this.complete) {
              axios.post(this.url, this.searchRequest('next')).then(response => this.searchResult(response.data)).catch(error => this.handleError(error)); 
            }
        },
        searchRequest : function(nav) {
            if (this.advanced) {
                searchparam = {"q":this.advancedSearchQuery,"f":this.filter,"s":this.sortorder,"nav":nav,"sources":this.sources}
            } else {
                searchparam = {"q":this.searchQuery,"f":this.filter,"s":this.sortorder,"nav":nav,"sources":this.sources}
            }
            this.$emit('gevent', {"action" : 'search', "label": JSON.stringify(searchparam)})
            return searchparam
        },
        searchResult : function(data) {
            if (data["hits"].length == 0) {
                this.$emit('complete', true);
            } else {
                for (idx in data["hits"]) {
                    this.results.push(data["hits"][idx]);
                }
                while (this.facets.length > 0) this.facets.pop();
                for (key in data["aggregations"]) {
                    var f = {}
                    f.key = key;
                    f.buckets = data["aggregations"][key].buckets;
                    f.value_as_string = data["aggregations"][key].value_as_string;
                    for (k in f.buckets) {
                        if (f.buckets[k].cbvalue == undefined) {
                            if (f.buckets[k].key_as_string != undefined) {
                                f.buckets[k].cbvalue = f.key+':"'+f.buckets[k].key_as_string+'"'
                            } else {
                                f.buckets[k].cbvalue = f.key+':"'+f.buckets[k].key+'"'
                                f.buckets[k].key_as_string = f.buckets[k].key
                            }
                        }
                    }
                    this.facets.push(f);
                }
                while (this.history.length > 0) this.history.pop();
                h = data["history"].slice().reverse();
                for (key in h) {
                    this.history.push(h[key]);
                }
            }
            this.resultstats['total'] = data["total"];
            this.resultstats['search_total'] = data["search_total"];

            this.$emit("busy", false);
            if (this.results.length >= this.resultstats['total']) {
                this.$emit('complete', true); 
            }
        },
        handleError: function(error) {
            this.$emit("busy", false);
            Vue.nextTick(function() { alert(error.response.data.message); }, error);
        },
        addNewLine: function() {
            this.advancedQueryObj.push({'operator':'AND','field':'any','condition':'contains','query':''});
        },
        removeLine: function(idx) {
            this.advancedQueryObj.splice(idx,1);
            this.advancedQueryObj[0].operator='blank';
        },
        saveQuery: function() {
            if (this.advanced) {
                saveRequest = {"q":this.advancedSearchQuery,"qobj":this.advancedQueryObj,"f":this.filters,"s":this.sortorder}
            } else {
                saveRequest = {"q":this.searchQuery,"f":this.filters,"s":this.sortorder}
            }
            axios.post(this.savequeryurl, saveRequest).then(response => this.saveResult(response.data)).catch(error => this.handleError(error)); 
            this.$emit('gevent', {"action" : 'savequery', "label": JSON.stringify(saveRequest)})
        },
        saveResult: function(data) {
            this.listQueries(data);
            alert("Query has been saved");
        },
        listQueries: function(data) {
            while (this.savedqueries.length > 0) this.savedqueries.pop();
            for (key in data) {
                this.savedqueries.push(data[key]);
            }
        },
        listHistory: function(data) {
            while (this.history.length > 0) this.history.pop();
            h = data.slice().reverse();
            for (key in h) {
                this.history.push(h[key]);
            }
        },
        setQuery: function(idx) {
            sq = JSON.parse(this.savedqueries[idx].query);

            if (sq["qobj"] == undefined) {
                this.advanced = false;
                this.searchQuery = sq["q"];
            } else {
                this.advanced = true;
                this.advancedSearchQuery = sq["q"];
                this.advancedQueryObj = sq["qobj"];
            }
            this.sortorder = sq["s"];
            this.$parent.$refs.facetbox.localfilters = sq["f"];
            this.$parent.filters = sq["f"];
            this.filters = sq["f"];
            
            this.filtersearch();
        },
        setHistory: function(idx) {
            sq = this.history[idx];

            if (sq["qobj"] == undefined) {
                this.advanced = false;
                this.searchQuery = sq["q"];
            } else {
                this.advanced = true;
                this.advancedSearchQuery = sq["q"];
                this.advancedQueryObj = sq["qobj"];
            }
            if (sq["f"] == "") {
                sq["f"] = []
            }
            this.sortorder = sq["s"];
            this.$parent.$refs.facetbox.localfilters = sq["f"];
            this.$parent.filters = sq["f"];
            this.filters = sq["f"];
            
            this.filtersearch();
        },

        showQueries: function() {
            this.$emit("showqueries");
        },
        showSets: function() {
            this.$emit("showsets");
        },
        exportResult(format) {
            if (this.setid > 0) {
                request = {"set":this.setid, "querytype":"set", "format":format}
            } else {
                if (this.advanced) {
                    request = {"q":this.advancedSearchQuery,"qobj":this.advancedQueryObj,"f":this.filter,"s":this.sortorder, "querytype":"advanced", "format":format, "sources":this.sources}
                } else {
                    request = {"q":this.searchQuery,"f":this.filter,"s":this.sortorder, "querytype":"simple", "format":format, "sources":this.sources}
                }
            }
          axios
            .post(this.exportqueueurl, request)
            .then(response => {
                msg = "Your export is being prepared.\n\nYou will receive a message at %% when it is ready for download.";
                msg2 = msg.replace("%%", response.data.email);
                alert(msg2);
          })
            .catch(error => {
              console.log(error);
          });
        }        
    },
    mounted() {
        axios.get(this.listhistoryurl).then(response => this.listHistory(response.data));
        if (this.is_auth) {
            axios.get(this.listqueryurl).then(response => this.listQueries(response.data));
        }
        axios.get(this.ddlistsurl).then(function(response) { this.ddlists = response.data} );
        //.catch(error => this.handleError(error)); 
    },    
    computed:{
        filter: function() {
            filter = "";
            if (this.filters.length >0) {
                sorted = this.filters.slice(0);
                sorted.sort((a,b) => (a.cbvalue > b.cbvalue) ? 1 : ((b.cbvalue > a.cbvalue) ? -1 : 0));
                tmp = {};
                oldf = "";
                for (i in sorted){
                    f = sorted[i].cbvalue.split(/:(.+)/)[0];
                    
                    if (f != oldf) {
                        tmp[f] = [];
                    }
                    tmp[f].push(sorted[i].cbvalue);
                    oldf = f;
                }
                tmp2 = []
                for (k in tmp) {
                    t = '(';
                    t += tmp[k].join(' OR ');
                    t += ')';
                    tmp2.push(t);
                }
                filter = tmp2.join(' AND ');
            }
            return filter
        }
    },
 
  };