var app = new window.Vue({
    el: '#app',
    data: function() {
        return {currentIdx: -1, 
                currentRecord:{'_display':{}}, 
                complete: false,
                busy: false,
                results : [],
                facets: [],
                filters: [],
                resultstats: {'total':0},
                savedqueries: [],
                savedsets: [],
                history: [],
                is_auth:false,
                infoshown: true }
      },
    components: {
        'modal': window.httpVueLoader('/js/components/Modal.vue'),
        'waiting-box': window.httpVueLoader('/js/components/Waiting.vue'),
        'search-box': window.httpVueLoader('/js/components/Search.vue'),
        'moreresult-box': window.httpVueLoader('/js/components/Moreresults.vue'),
        'result-box': window.httpVueLoader('/js/components/Result.vue'),
        'facet-box': window.httpVueLoader('/js/components/Facet.vue'),
        'queries': window.httpVueLoader('/js/components/Queries.vue'),
        'sets': window.httpVueLoader('/js/components/Sets.vue'),
        'setselect': window.httpVueLoader('/js/components/SetSelect.vue'),
        'keyboard': window.httpVueLoader('/js/components/Keyboard.vue'),
        'info-box': window.httpVueLoader('/js/components/Info.vue'),
    },      
    methods: {
        showdetail: function(event){
            this.currentIdx = event;
            this.$refs["modal"].showModal()
        },
        showqueries: function(event) {
            this.$refs["queries"].showModal();
        },
        showsets: function(event) {
            this.$refs["sets"].showModal();
        },
        showsetselect: function(event) {
            this.$refs["setselect"].showModal();
        },
        onbusy: function(event) {
            this.busy=event;
            this.infoshown = false;
        },
        ongevent: function(event) {
            gtag('event', event.action, {'event_category' : 'engagement' , 'event_label': event.label})
        },
        filterchanged: function(event) {
            this.filters = event;
            this.$refs.searchbox.filtersearch()
        },
        oncompletechanged: function(event) {
            this.complete = event;
        },
        loadSet: function(idx){
            this.infoshown = false;
            this.$refs["searchbox"].clear();
            this.$refs["searchbox"].setid=this.savedsets[idx].id;

            this.complete=true;
            for (itemidx in this.savedsets[idx].items) {
                this.results.push(this.savedsets[idx].items[itemidx].value);
            }
            this.resultstats.total = this.results.length;
        },
        next: function() {
            if (this.currentIdx < (this.resultstats.total-1)) { this.currentIdx +=1; }
        },
        prev: function() {
            if (this.currentIdx > 0) { this.currentIdx -= 1; }
        }
    },
    watch: {
        currentIdx: function(val) {
            this.currentRecord = this.results[val];
            if (this.currentIdx == this.results.length-1){
                this.$refs.resultbox.loadMore();
            }
        },
        currentRecord: function(val) {
            if (this.currentRecord != undefined) {
                gtag('event', 'view_detail', {
                    'event_category' : 'engagement',
                    'event_label' : this.currentRecord._display.id
                  });
            }
        }
    },
    created: function() {
        let that = this
        document.addEventListener('keydown', function (evt) {
            if (that.$refs['modal'].$refs['modalcontainer'].classList.contains('is-active') ||
                that.$refs['queries'].$refs['modalcontainer'].classList.contains('is-active') ||
                that.$refs['sets'].$refs['modalcontainer'].classList.contains('is-active') ) {
                if (evt.keyCode === 27) {  // ESCAPE
                    that.$refs['modal'].closeModal();
                    that.$refs['queries'].closeModal();
                    that.$refs['sets'].closeModal();
                }
                if (evt.keyCode === 8) {  // BACKSPACE
                    if (document.activeElement.tagName == 'INPUT' || 
                    document.activeElement.tagName == 'TEXTAREA') {

                    } else {
                        that.$refs['modal'].closeModal();
                        that.$refs['queries'].closeModal();
                        that.$refs['sets'].closeModal();
                        evt.preventDefault();
                        evt.stopPropagation();
                    }
                }
                var ctrl = evt.ctrlKey ? evt.ctrlKey : ((evt.keyCode === 17) ? true : false); // ctrl detection
                if ( evt.keyCode == 67 && ctrl ) {   // CTRL-C  (copy to clipboard)
                    document.execCommand('copy');
                }                
            }
            if (that.$refs['modal'].$refs['modalcontainer'].classList.contains('is-active')) {
                if (document.activeElement.tagName == 'INPUT' || 
                document.activeElement.tagName == 'TEXTAREA' ) {

                } else {
                    if (evt.keyCode == 37) { // LEFT ARROW
                        that.prev()
                    }
                    if (evt.keyCode == 39) { // RIGHT ARROW
                        that.next()
                    }
                    evt.preventDefault();
                    evt.stopPropagation();
                }
            }
        });
    }
  });

  window.onload = function () {
    that = app
    if (typeof history.pushState === "function") {
        history.pushState("jibberish", null, null);
        window.onpopstate = function () {
			if (that.$refs["modal"].$refs['modalcontainer'].classList.contains('is-active')) {
                history.pushState('newjibberish', null, null);
                that.$refs["modal"].closeModal();
            }
			if (that.$refs["queries"].$refs['modalcontainer'].classList.contains('is-active')) {
                history.pushState('newjibberish', null, null);
                that.$refs["queries"].closeModal();
            }
			if (that.$refs["sets"].$refs['modalcontainer'].classList.contains('is-active')) {
                history.pushState('newjibberish', null, null);
                that.$refs["sets"].closeModal();
            }
        };
    }
}
