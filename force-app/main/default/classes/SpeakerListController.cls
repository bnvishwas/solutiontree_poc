public class SpeakerListController {

    @AuraEnabled
    public static List<Contact> getSpeakerRecords(String region, String rating)
    {

        String query = 'Select Id, Name, Firstname, Lastname, Email, Account.Country_Region__c,Ratings__c,Working_Hour_Start__c, Working_Hour_End__c from Contact where RecordType.Name =\'Speaker\'';
        if(region != null ){

            query = query + 'and Account.Country_Region__c Like \'%' +region+'%\'' ;
        }
    
        if(rating != null){
            query = query + 'and Ratings__c Like \'%' +rating+'%\'' ;
        }
        
        
        
        List<Contact> lstContact = Database.query(query);    
        
        System.debug('Speaker Count : '+lstContact.size());

        for(Contact speaker : lstContact){
            getSlotDistribustion(speaker, speaker.Working_Hour_Start__c, speaker.Working_Hour_End__c);
        }
       
        return lstContact;
    }

    public static void getSlotDistribustion(Contact speaker, Time startTime,Time endTime){

        if(startTime != null && endTime != null){
            //System.debug('Start Time : '+startTime+' End time : '+endTime);
            Time startSlotTime = startTime;
            Time endSlotTime;
            Integer count = 1;
            while(startSlotTime < endTime){
                
                endSlotTime = startSlotTime.addHours(1);
                System.debug('Speaker Name : '+speaker.Name);
                if(endSlotTime > endTime){
                    System.debug('Start Time : '+startSlotTime+' End time : '+endTime);
                }
                else{
                    System.debug('Start Time : '+startSlotTime+' End time : '+endSlotTime);
                }
                count++ ;
                startSlotTime = endSlotTime;
                
            }
        }
        
    }
}