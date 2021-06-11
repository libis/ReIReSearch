<template>
    <div>
        <div class="card" style="text-align:right" v-if="hasSelected">
            <i class="fa fa-save" style="margin-left:5px;margin-right:20px;margin-top:6px;margin-bottom:6px" @click="$emit('showsetselect')" title="Save selection in set"></i>

        </div>
        <div 
            class="records" 
            v-infinite-scroll="loadMore" 
            infinite-scroll-disabled="busy" 
            infinite-scroll-distance="10" >
        
            
            <table class="table is-striped is-hoverable fullwidth"><tbody>
                <tr is ="result-item"
                    v-for="(result, index) in results" 
                    v-bind:data="result" 
                    v-bind:key="result._id" 
                    v-bind:result="result" 
                    v-bind:index="index" 
                    v-bind:is_auth="is_auth"
                    v-on:showdetail="showdetail($event)"
                    v-on:checkboxchange="checkboxChange($event)"
                    ref="item"
                >
                </tr>
            </tbody></table>
            <div v-if="(this.resultstats['search_total'] == 0 || this.resultstats['search_total'] == undefined) && this.results.length == 0 && !this.busy && this.resultcomplete">
                <article class="message is-warning" style="width:50%">
                <div class="message-header">Notice</div>
                <div class="message-body" style="font-weight:Bold">No results found</div>
                </article>
            </div>
        </div>
    </div>
</template>
<script>
module.exports = {
    data: function(){
        return {
            hasSelected:false
        }
    },
    props: { 
        results:{type:Array,required:true},
        resultcomplete:{type:Boolean,required:true},
        busy:{type:Boolean,required:true},
        resultstats:{type:Object,required:true},
        is_auth:{type:Boolean,required:true},
    },
    methods : {
        loadMore: function() {
            if (this.results.length > 0 && !this.resultcomplete && !this.busy) {
                this.$emit("busy", true);
                this.$emit("moredata");
            }        
        },
        showdetail(event) {
            this.$emit('showdetail', event);
        },
        checkboxChange(event) {
            this.hasSelected = false;
            for (var i = 0; i < this.$refs['item'].length; i++){
                if (this.$refs['item'][i].$refs['selectcb'].checked) {
                    this.hasSelected = true;
                }
            }
        }
    },
    components: {
        'result-item': window.httpVueLoader('/js/components/ResultItem.vue')
    }
};
</script>