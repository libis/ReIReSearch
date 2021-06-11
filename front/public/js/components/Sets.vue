<template>
  <transition name="modal">
    <div class="modal" ref="modalcontainer">
      <div class="modal-background" @click="closeModal()"></div>
      <div class="modal-card"  style="width:50%;height:98%">
        <header class="modal-card-head">
          <p class="modal-card-title monda">Saved sets</p>
          <button class="delete" aria-label="close" @click="closeModal()"></button>
        </header>
        <section class="modal-card-body" style="height:100%">
          <!-- Content ... -->
            <div v-for="(set, idx) in savedsets" style="font-size:20px"><a @click.prevent.stop="loadSet(idx);closeModal();" ><strong>{{ set.name }}</strong></a>
                <a class="fa fa-trash" style="position:absolute;right:30px" href="" @click.prevent.stop="deleteset(idx)"></a>
                <ul style="margin-left:30px;font-size:16px">
                    <li v-for="(item,i) in set.items" class="truncate">
                      <a class="fa fa-trash" style="position:absolute;right:30px" href="" @click.prevent.stop="deletefromset(idx,i)"></a>
                      -&nbsp;<a @click.prevent.stop="loadSet(idx);showItem(i);closeModal();">{{ item.value._display.name[0] }}</a>
                    </li>
                </ul>
            </div>
            <!-- End Content ... -->
        </section>
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
    props : ['savedsets'],
    data: function() {
        return { itemdeleteurl:'/set/itemdelete/', setdeleteurl:'/set/delete/'}
    },
    methods: {
      showModal:function() {
        this.$nextTick(() => {
          this.$refs['modalcontainer'].classList.add('is-active');
        })
      },        
      closeModal:function() {
        this.$refs['modalcontainer'].classList.remove('is-active');
      },    
      loadSet:function(idx){
        this.$parent.loadSet(idx);
      },
      showItem:function(idx) {
        this.$nextTick(() => {
          this.$parent.showdetail(idx)     
        });          
      },
      deletefromset:function(setidx,itemidx) {
        if (confirm("Are you sure you wish to remove this item from the saved set ?")) {
          axios.get(this.itemdeleteurl+this.savedsets[setidx].items[itemidx].id);
          this.$emit('gevent', {"action" : 'setitemremove', "label": this.savedsets[setidx].items[itemidx]})
          this.savedsets[setidx].items.splice(itemidx,1);
        }
      },
      deleteset:function(setidx) {
        if (confirm("Are you sure you wish to remove this saved set ?")) {
          axios.get(this.setdeleteurl+this.savedsets[setidx].id);
          this.$emit('gevent', {"action" : 'setremove', "label": this.savedsets[setidx]})
          this.savedsets.splice(setidx,1);
        }
      }
    }
}
</script>