<template>
    <div v-if="extranumber > 0" class="box" ref="moreresults">
        <span v-if="extranumber > 1">{{ extranumber }} more results are available in the <a class="externallink" href="/page/subscriptions" target="_blank">subscription database</a> Brepols Index Religiosus</span>
        <span v-else>{{ extranumber }} more result is available in the <a class="externallink" href="/page/subscriptions" target="_blank">subscription database</a> Brepols Index Religiosus</span>

        <a class="delete" style="float:right" @click.prevent.stop="$refs.moreresults.classList.add('is-hidden')"></a>
    </div>
</template>
<script>
module.exports = {
    props:['resultstats_total','resultstats_searchtotal'],
    computed:{
        extranumber:function () {
            return (this.resultstats_searchtotal - this.resultstats_total);
        }
    }
}
</script>