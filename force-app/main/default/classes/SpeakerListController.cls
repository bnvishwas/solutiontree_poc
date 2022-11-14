public class SpeakerListController {

    @AuraEnabled
    public static String getSpeakerRecords(String region, String rating, String weekDay, String eventDate)
    {

        String query = 'Select Id, Name, Firstname, Lastname, Email, Account.Country_Region__c,Ratings__c,Working_Hour_Start__c, Working_Hour_End__c, Lunch_Start_Time__c, Lunch_End_Time__c, Working_Days__c from Contact where RecordType.Name =\'Speaker\'';
        if(region != null ){

            query = query + 'and Account.Country_Region__c Like \'%' +region+'%\'' ;
        }
    
        if(rating != null){
            query = query + 'and Ratings__c Like \'%' +rating+'%\'' ;
        }

        if(weekDay != null){
            query = query + ' and Working_Days__c includes (\''+weekDay+'\')';
        }
        
        
        //System.debug('SOQL Query : '+ query);
        List<Contact> lstContact = Database.query(query);    
        
        //System.debug('Speaker Count : '+lstContact.size());

        List<Responsedata> speakerList= new List<Responsedata>();

        //Set<Id> speakerId = new Set<Id>();

        for(Contact speaker : lstContact){
            Responsedata speakerdata = new Responsedata();
            speakerdata.Name = speaker.Name;
            speakerdata.Id = speaker.Id;
            //speakerdata.Rating = Integer.valueof(speaker.Ratings__c);
            //speakerdata.Region = speaker.Account.Country_Region__c;
            speakerdata.Email = speaker.Email;
            speakerdata.Available_Slot = getSlotDistribustion(speaker, speaker.Working_Hour_Start__c, speaker.Working_Hour_End__c);
            speakerList.add(speakerdata);
            //speakerId.add(speaker.Id);
        }

        //String eventQuery = 

        //List<Event> eventList = 
       
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
                //System.debug('Speaker Name : '+speaker.Name);
                if(endSlotTime > endTime){
                    //System.debug('Start Time : '+startSlotTime+' End time : '+endTime);
                    endSlotTime = endTime;
                }
                slot.start_time = startSlotTime;
                slot.end_time = endSlotTime;
                count++ ;
                startSlotTime = endSlotTime;
                slotList.add(slot);
            }
            System.debug('Break Time '+speaker.Lunch_Start_Time__c+' '+speaker.Lunch_End_Time__c);
            slotList = eliminateBreakHours(slotList, speaker.Lunch_Start_Time__c, speaker.Lunch_End_Time__c, speaker);
        }
        return slotList;
    }

    public static List<Available_Slot> eliminateBreakHours(List<Available_Slot> slotList, Time lunchStartTime,Time lunchEndTime, Contact speaker){
        try{
            
            List<Available_Slot> derivedSlots = new List<Available_Slot>();
            List<Integer> indexList = new List<Integer>();
            Integer count = 0;
            System.debug('SlotList Size : '+slotList.size());
            for(Available_Slot slot : slotList){
                //Available_Slot slot = slotList[slot];
                System.debug('Break Time '+lunchStartTime+' '+lunchEndTime);
                System.debug('Start Time '+slot.start_time+' End Time'+slot.end_time);
                if(lunchStartTime <= slot.start_time && lunchEndTime > slot.start_time && lunchEndTime < slot.end_time){
                    slot.start_time = lunchEndTime;
                    System.debug('Logic 1 executer');
                }
                else if((slot.start_time < lunchStartTime) && (lunchStartTime < slot.end_time) &&  (slot.start_time < lunchEndTime) && (lunchEndTime < slot.end_time)){
                    slot.end_time = lunchEndTime;
                    Available_Slot newSlotData = new Available_Slot();
                    newSlotData.start_time = lunchEndTime;
                    newSlotData.end_time = slot.end_time;
                    derivedSlots.add(newSlotData);
                    System.debug('Logic 2 executer');

                }
                else if((slot.start_time == lunchStartTime ) &&  (slot.start_time < lunchEndTime) && (lunchEndTime < slot.end_time)){
                    slot.start_time = lunchEndTime;
                    System.debug('Logic 3 executer');

                }
                else if((slot.start_time < lunchStartTime) && (lunchStartTime < slot.end_time) &&  ( lunchEndTime == slot.end_time)){
                    slot.end_time = lunchStartTime;
                    System.debug('Logic 4 executer');
                }
                // else if((slot.start_time <= lunchStartTime < slot.lunchEndTime) &&  (slot.start_time < lunchEndTime < slot.lunchEndTime)){
                //     slot.start_time = lunchEndTime;

                // }
                else if((lunchStartTime < slot.start_time ) && (slot.start_time < lunchEndTime) && (lunchEndTime < slot.end_time)){
                    slot.start_time = lunchEndTime;
                    System.debug('Logic 5 executer');
                }
                else if((slot.start_time < lunchStartTime) && (lunchStartTime < slot.end_time) && lunchEndTime > slot.end_time){
                    slot.end_time = lunchStartTime;
                    System.debug('Logic 6 executer');
                }
                else if(lunchStartTime <= slot.start_time && lunchEndTime <= slot.start_time){
                    System.debug('Logic 7 executer');
                }
                else if(lunchStartTime >= slot.end_time && lunchEndTime >= slot.end_time){
                    System.debug('Logic 8 executer');
                }
                else{
                    //slotList.remove(count);
                    indexList.add(count);
                    System.debug('Logic 9 remove executer');
                }
                count++;
            }
            System.debug('Speaker : '+speaker.Name+' new slot : '+derivedSlots);
            System.debug('Current list : '+slotList);
            System.debug('New list : '+derivedSlots);
            System.debug('Break Time '+lunchStartTime+' '+lunchEndTime);
            System.debug('New list size: '+derivedSlots.size());
            
            
            if(derivedSlots.size() > 0){
                slotList.addAll(derivedSlots);                
            }
            if(indexList.size() > 0){
                for(Integer item : indexList){
                    slotList.remove(item);
                }
            }
            System.debug('SlotList Size after iteration: '+slotList.size());
            //return derivedSlots;
            return slotList;
            }
        catch(Exception e){
            System.debug('Exception Occured '+e.getMessage());
            return null;
        }
    }

    class Responsedata {
        public Id Id;
		public String Name;
		//public Integer Rating;
        //public String Region;
        public String Email;
		public List<Available_Slot> Available_Slot;
	}
	class Available_Slot {
		public Time start_time;
		public Time end_time;
	}
}