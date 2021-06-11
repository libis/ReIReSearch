<template>
  <transition name="modal">
    <div class="modal" ref="modalcontainer" >
        <div class="modal-background" @click="closeModal()"></div>
        <div class="modal-card"  style="width:50%;height:30%">
            <header class="modal-card-head">
            <p class="modal-card-title"></p>
            <button class="delete" aria-label="close" @click="closeModal()"></button>
            </header>
            <section class="modal-card-body" style="height:100%">

            Store the selected records in set : <input class="input" style="width:50%" list="sets" name="set" ref="set" v-model="shelf">
            <datalist id="sets">
              <option v-for="option in this.savedsets" v-bind:value="option.name">
            </datalist>
            <button  class='button is-primary' @click="storeinset()" :disabled="shelf==''">Save</button>



            </section>
            <footer class="modal-card-foot">
            </footer>
        </div>
    </div>
</template>
<script>
module.exports = {
    data:function() {
        return {
            shelf:"",
            storeseturl : "/set/store",
            listseturl : "/set/list",
        }
    },
    props:['results','savedsets'],
    methods: {
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
        storeinset:function() {
            data = Object();
            data["shelf"] = this.shelf;
            data["values"] = []
            for (var i=0; i < this.$parent.$refs['resultbox'].$refs['item'].length; i++) {
                if (this.$parent.$refs['resultbox'].$refs['item'][i].$refs['selectcb'].checked) {
                    data["values"].push(this.results[i]);
                    this.$emit('gevent', {"action" : 'setstore', "label": this.results[i]._display.id})
                    this.$parent.$refs['resultbox'].$refs['item'][i].$refs['selectcb'].checked = false
                    this.$parent.$refs['resultbox'].$refs['item'][i].checkboxChange(i)
                }
            }
            axios.post(this.storeseturl, data).then(response => this.setResult(response.data)).catch(error => this.handleError(error)); 
        },
        setResult() {
            axios.get(this.listseturl).then(response => this.$parent.$refs["modal"].listSets(response.data));
            this.closeModal();
            alert("Records have been stored in '" + this.shelf + "'");            
        }

    }
}