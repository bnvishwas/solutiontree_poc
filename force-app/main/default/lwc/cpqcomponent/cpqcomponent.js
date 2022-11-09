import { LightningElement, api, track, wire } from 'lwc';
import getcontactrecords from '@salesforce/apex/ContactRecordsController.getcontactrecords1';
//import getcontactrecor from '@salesforce/apex/ContactRecordsController.getEventdata';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import Country_Region from '@salesforce/schema/Account.Country_Region__c';
import rating_Value from '@salesforce/schema/Contact.Ratings__c';

const cols = [
    {label : 'First Name', fieldName : 'FirstName'},
    {label: 'Last Name', fieldName: 'LastName'},
    {label: 'Email', fieldName: 'Email'},
    {label:'Subject', fieldName: 'Subject'},
    {label:'StartDateTime', fieldName: 'StartDateTime'},
    {label:'EndDateTime', fieldName: 'EndDateTime'}
]

export default class Cpqcomponent extends LightningElement {
connectedCallback(){
    this.loadspeaker();
}
    @api contactRecords;
    @api columns = cols;
@track Eventdate;
    @track regionvalue;
    @track countryregionlist;
    @wire(getPicklistValues, { recordTypeId: '012000000000000AAA', fieldApiName: Country_Region })
    regionlistValues({ data, error }) {
        if (data) {
            console.log('Value from Global Picklist' + JSON.stringify(data));
            this.countryregionlist = data.values;
        } else if (error) {
            console.log('No Value from org' + error);
        }
    }

    @track Eventdate;
    @track ratingvalue;
    @track ratinglist;
    @wire(getPicklistValues, { recordTypeId: '012000000000000AAA', fieldApiName: rating_Value })
    ratinglistValues({ data, error }) {
        if (data) {
            console.log('Value from Global Picklist' + JSON.stringify(data));
            this.ratinglist = data.values;
        } else if (error) {
            console.log('No Value from org' + error);
        }
    }
    // Eventdatehandle(event){
    // this.Eventdate=event.target.value;
    // getcontactrecor({d:this.Eventdate})
    // .then((data)=>{
    //     console.log( 'test data '+JSON.stringify(data));

    // }).catch((error)=>{
    //     console.log('error : '+error.message);
    // })
    // }
   /* @wire (getcontactrecords)
    getcontactrecords({data, error})
    {
        if(data)
        {
            this.contactRecords = data;
        }
        else if(error)
        {
            console.log('Error Message has been Occured.'+ error);
        }
    } */

    handleregionChange(event){
        this.regionvalue=event.target.value;
        this.loadspeaker();
    }

    handleratingChange(event){
        this.ratingvalue=event.target.value;
        this.loadspeaker();
    }

    Eventdatehandle(event){
        this.Eventdate=event.target.value;
        this.loadspeaker();
    }

    @track speakerlist = [];
    // loadspeaker(){
    //     var rating=this.ratingvalue;
    //     var region=this.regionvalue;
    //     if(this.regionvalue == undefined){
    //         region = null;
    //     }
    //     if(this.ratingvalue == undefined){
    //         rating = null;
    //     }
    //     getcontactrecords({region : region, rating : rating})
    //     .then((data)=>{
    //         console.log('speaker data : '+data);
    //         this.speakerlist = data;
    //     })
    //     .catch((error)=>{
    //         console.log('errora : '+error.message);
    //     })
        
    // }

    loadspeaker() {
        var rating = this.ratingvalue;
        var region = this.regionvalue;
        var d = this.Eventdate;
        if (this.regionvalue == undefined) {
          region = null;
        }
        if (this.ratingvalue == undefined) {
          rating = null;
        }
        if (this.Eventdate == undefined) {
            d = null;
          }
        getcontactrecords({ region: region, rating: rating, d: d })
          .then((data) => {
            var resultdata = JSON.parse(JSON.stringify(data));
            var modifieddata = [];
            for(var item in resultdata){
    
              var speakerdata = resultdata[item];
              speakerdata['FirstName'] = speakerdata.Who.FirstName;
              speakerdata['LastName'] = speakerdata.Who.LastName;
              speakerdata['Email'] = speakerdata.Who.Email;
              speakerdata['speakerId'] = speakerdata.Who.Id;
              modifieddata.push(speakerdata);
    
            }
            this.speakerlist = modifieddata;
          })
          .catch((error) => {
            console.log('errora : ' + error.message);
          })
    
      }
}