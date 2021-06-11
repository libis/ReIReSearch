<template>
    <tr style="cursor:pointer">
        <td style="width:130px" @click="showdetail(index)">
        <div v-if="result._display.thumbnails == undefined">
            <i v-bind:class="icon" style="font-size:50px"></i>    
        </div>
        <div v-else>
            <img class="thumbnail" :src="result._display.thumbnails[0].thumbnailUrl" v-if="result._display.thumbnails[0].thumbnailUrl != undefined" align=left>
            <i v-bind:class="icon" style="font-size:50px" v-if="result._display.thumbnails[0].thumbnailUrl == undefined"></i>
        </div>
        </td>
        <td @click="showdetail(index)">
        <p class="rec_type" v-if="result._display.type !== undefined"> 
            {{ result._display.type }}
        </p>
        <p v-if="result._display.name !== undefined"> 
        <ol>
            <li class="rec_name" v-for="name in result._display.name" v-bind:key="name._id" >
                {{ name }}
            </li>
        </ol>    
        </p>

        <p v-if="result._display.author !== undefined"> 
        <ol>
            <li class="rec_author" v-for="author in result._display.author" v-bind:key="author">
                {{ author }}
            </li>
        </ol>    
        </p>

        <p  v-if="result._display.publisher !== undefined"> 
        <ol>
            <li class="rec_publisher" v-for="publisher in result._display.publisher" v-bind:key="publisher">
                {{ publisher }} 
            </li>
        </ol>    
        </p>
        <p  v-if="result._display.datePublished !== undefined"> 
            <span class="rec_publisher" v-for="dp in result._display.datePublished" v-bind:key="dp">
                {{ dp }}&nbsp;&nbsp;
            </span>
        </p>
        <p  v-if="result._display.DataSet !== undefined"> 
            <span class="rec_dataset" v-for="ds in result._display.DataSet" v-bind:key="ds">
                {{ ds.name }}
            </span>
        </p>
        </td>
        <td v-if="is_auth">
            <input type="checkbox" @change="checkboxChange(index)" ref="selectcb">
        </td>
    </tr>
</template>
<script>
module.exports = {
    props: {result:{type:Object,required:true},index:{type:Number,required:true},is_auth:{type:Boolean,required:true}},
    methods : {
        showdetail(index) { 
            this.$emit('showdetail', index);
        },
        checkboxChange(index) {
            this.$emit('checkboxchange', index);
        }


    },
    computed: {
        icon: function() {
            return {
                fa : true,
                'fa-book' : (this.result._display.type != "Person" && this.result._display.type != "Event"),
                'fa-user' : (this.result._display.type == "Person"),
                'fa-calendar' : (this.result._display.type == "Event")
            }
        }

    }
};
