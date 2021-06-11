<template>
<div class="waiting">
<img src="/img/waiting.gif" width="28" v-if="busy"></img>
</div>
</template>
<script>
module.exports = {
    props:{
        busy:{type:Boolean,required:true}
    }
}
</script>