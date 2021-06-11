<template>
  <transition name="queries">
    <div class="modal" ref="modalcontainer">
      <div class="modal-background" @click="closeModal()"></div>
      <div class="modal-card">
        <header class="modal-card-head">
          <p class="modal-card-title monda">Searches</p>
          <button class="delete" aria-label="close" @click="closeModal()"></button>
        </header>
        <section class="modal-card-body">
            <slot name="body">
              <div class="tabs is-boxed" style="margin-bottom:5px">
              <ul>
                  <li v-if="savedqueries.length > 0" v-bind:class="{'is-active': currenttab=='saved'}"><a @click.prevent.stop="currenttab='saved'">Saved searches</a></li>
                  <li v-if="history.length > 0" v-bind:class="{'is-active': currenttab=='history'}"><a @click.prevent.stop="currenttab='history'">Search history</a></li>
              </ul>
              </div>       
              <div  v-if="currenttab=='saved'" class="scroll">
                <div v-for="(q,i) in savedqueries">
                  <a href="" @click.prevent.stop="loadquery(i)">{{ localTime(q["created"]) }} {{ q["querystring"] }}</a><a class="fa fa-trash" href="" @click.prevent.stop="deletequery(i)"></a>
                </div>
              </div>
              <div  v-if="currenttab=='history'" class="scroll">
                <div v-for="(q,i) in history">
                  <a href="" @click.prevent.stop="rerunquery(i)">{{ localTime(q["created"]) }} {{ q["q"] }}</a>
                </div>
              </div>
            </slot>
        </section>
        <footer class="modal-card-foot">
        </footer>
      </div>
    </div>
  </transition>
</template>
<script>
module.exports = {
    data:function () {
      return {
        currenttab: "saved"
      }
    },
    props : ['savedqueries','history'],
    methods: {
        loadquery:function(idx) {
          this.$parent.$refs.searchbox.setQuery(idx);
          this.$emit('gevent', {"action" : 'loadquery', "label": JSON.stringify(this.savedqueries[idx])})
          this.$emit('close');
          this.closeModal();
        },
        rerunquery:function(idx) {
          this.$parent.$refs.searchbox.setHistory(idx);
          this.$emit('gevent', {"action" : 'loadquery', "label": JSON.stringify(this.history[idx])})
          this.$emit('close');
          this.closeModal();
        },
        deletequery:function(idx) {
          if (confirm("Are you sure you wat to remove this saved search ?")) {
            axios.get('/query/delete/'+this.savedqueries[idx]["id"]);
            this.$emit('gevent', {"action" : 'deletequery', "label": JSON.stringify(this.savedqueries[idx])})
            this.savedqueries.splice(idx,1);
          }
        },
        showModal:function() {
          this.$nextTick(() => {
            if (this.savedqueries.length == 0) {
              this.currenttab = 'history';
            }

            this.$refs['modalcontainer'].classList.add('is-active');
          })
        },
        closeModal:function() {
          this.$refs['modalcontainer'].className='modal';
        },
        localTime:function(stamp) {
          var currTz = jstz.determine() || 'UTC';
          var momentTime = moment(stamp);
          var tzTime = momentTime.tz(currTz.name());
          var formattedTime = tzTime.format('Y-MM-DD H:mm');

          return formattedTime;
        }
    }
  }
</script>
  