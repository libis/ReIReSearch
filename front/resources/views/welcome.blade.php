@extends('layouts.app')

@section('content')
                <div id="app" >
                    <search-box
                        v-on:busy="onbusy($event)" 
                        v-on:newsearch="currentIdx=-1; $refs.facetbox.clearall()"
                        v-on:gevent="ongevent($event)"
                        ref="searchbox" 
                        v-bind:results.sync="results" 
                        v-bind:facets.sync="facets" 
                        v-bind:resultstats.sync="resultstats"
                        v-bind:savedqueries.sync="savedqueries"
                        v-bind:savedsets="savedsets"
                        v-bind:history.sync="history"
                        v-bind:filters="filters" 
                        v-on:complete="oncompletechanged"
                        v-on:showqueries="showqueries();"
                        v-on:showsets="showsets();"
                        v-bind:is_auth="is_auth"
                        >
                    </search-box>
                    <info-box v-show="infoshown"></info-box>
                    <div class="columns">
                        <div class="column is-one-quarter">
                        <div v-show="facets.length > 0 || filters.length > 0">
                            <facet-box 
                                ref="facetbox" 
                                v-bind:facets="facets" 
                                v-bind:activefilters="filters"
                                @filterchanged="filterchanged($event)">
                            </facet-box>
                        </div>
                        </div>
                        <div class="column is-three-quarters">
                        
                        <div class="resultcontainer">
                        <moreresult-box
                            ref="moreresultbox"
                            :resultstats_total="resultstats['total']"
                            :resultstats_searchtotal="resultstats['search_total']"
                            >
                        </moreresult-box>
                        <result-box 
                            @busy="onbusy($event)" 
                            @showdetail="showdetail($event)" 
                            @moredata="$refs.searchbox.moredata()" 
                            ref="resultbox" 
                            v-bind:results="results" 
                            :busy="busy" 
                            :resultcomplete="complete"
                            :resultstats="resultstats"
                            v-bind:is_auth="is_auth"
                            v-on:showsetselect="showsetselect()"
                            >
                        </result-box>
                        <waiting-box 
                            ref="waitingbox" 
                            v-bind:busy="busy">
                        </waiting-box>
                        </div>                        
                    </div>
                    </div>
                    <div>
                        <modal 
                            ref="modal" 
                            @next="next()" 
                            @prev="prev()" 
                            :currentIdx="currentIdx" 
                            :maxIdx="resultstats.total-1" 
                            :currentrecord="currentRecord" 
                            :busy="busy"
                            :is_auth="is_auth"
                            v-bind:savedsets.sync="savedsets"
                            v-on:gevent="ongevent($event)">
                        </modal>
                        <queries
                            ref="queries"
                            :savedqueries="savedqueries"
                            :history="history"
                            v-on:gevent="ongevent($event)">
                        </queries>
                        <sets
                            ref="sets"
                            :savedsets="savedsets"
                            v-on:gevent="ongevent($event)">
                        </sets>
                        <setselect
                            ref="setselect"
                            v-bind:results="results"
                            v-bind:savedsets="savedsets"
                            v-on:gevent="ongevent($event)">
                        </setselect>
                    </div>
                </div>   

        <script src="https://unpkg.com/axios/dist/axios.min.js"></script>
        <? if ($_SERVER["SERVER_NAME"] == "localhost") { // for development it is usefull to have the non-minimized vue.js ?>
            <script src="https://cdn.jsdelivr.net/npm/vue@2.6.10/dist/vue.js"></script>
        <? } else { ?>
            <script src="https://cdn.jsdelivr.net/npm/vue@2.6.10/dist/vue.min.js"></script>
        <? } ?>
        <script src="https://unpkg.com/http-vue-loader"></script>
        <script src="https://unpkg.com/vue-infinite-scroll@2.0.2/vue-infinite-scroll.js"></script>
        <script src="/js/jstz.js"></script>
        <script src="/js/moment.js"></script>
        <script src="/js/moment-timezone-with-data.js"></script>
        <script src="/js/main.js"></script>
        @auth 
        <script> app.is_auth = true; </script>
        @endauth


        <script>
            if (window.navigator.userAgent.match(/(MSIE|Trident)/)) {
                    document.write("<article class=\"message is-warning\"><div class=\"message-body\">Internet Explorer is not supported by ReIRes. We recommend you use a more recent browser.</div></article>")
                }
        </script>

        @endsection        
