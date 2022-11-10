public class SpeakerListController {

    @AuraEnabled
    public static String getSpeakerRecords(String region, String rating)
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

        List<Responsedata> speakerList= new List<Responsedata>();

        for(Contact speaker : lstContact){
            Responsedata speakerdata = new Responsedata();
            speakerdata.Name = speaker.Name;
            speakerdata.Id = speaker.Id;
            speakerdata.Rating = Integer.valueof(speaker.Ratings__c);
            speakerdata.Region = speaker.Account.Country_Region__c;
            speakerdata.Available_Slot = getSlotDistribustion(speaker, speaker.Working_Hour_Start__c, speaker.Working_Hour_End__c);
            speakerList.add(speakerdata);
        }
       
        return JSON.serialize(speakerList);
    }

    public static List<Available_Slot> getSlotDistribustion(Contact speaker, Time startTime,Time endTime){
        List<Available_Slot> slotList = new List<Available_Slot>();
        if(startTime != null && endTime != null){
            //System.debug('Start Time : '+startTime+' End time : '+endTime);
            Time startSlotTime = startTime;
            Time endSlotTime;
            Integer count = 1;
            while(startSlotTime < endTime){
                Available_Slot slot = new Available_Slot();
                endSlotTime = startSlotTime.addHours(1);
                System.debug('Speaker Name : '+speaker.Name);
                if(endSlotTime > endTime){
                    System.debug('Start Time : '+startSlotTime+' End time : '+endTime);
                    endSlotTime = endTime;
                }
                slot.start_time = startSlotTime;
                slot.end_time = endSlotTime;
                count++ ;
                startSlotTime = endSlotTime;
                slotList.add(slot);
            }
        }
        return slotList;
    }

    class Responsedata {
        public Id Id;
		public String Name;
		public Integer Rating;
        public String Region;
		public List<Available_Slot> Available_Slot;
	}
	class Available_Slot {
		public Time start_time;
		public Time end_time;
	}
}