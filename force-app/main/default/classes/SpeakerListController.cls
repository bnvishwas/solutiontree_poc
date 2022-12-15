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
        
        
        System.debug('SOQL Query : '+ query);
        List<Contact> lstContact = Database.query(query);    
        
        //System.debug('Speaker Count : '+lstContact.size());

        List<Responsedata> speakerList= new List<Responsedata>();

        Set<Id> speakerId = new Set<Id>();

        for(Contact speaker : lstContact){
            Responsedata speakerdata = new Responsedata();
            speakerdata.Name = speaker.Name;
            speakerdata.Id = speaker.Id;
            //speakerdata.Rating = Integer.valueof(speaker.Ratings__c);
            //speakerdata.Region = speaker.Account.Country_Region__c;
            speakerdata.Email = speaker.Email;
            speakerdata.Available_Slot = getSlotDistribustion(speaker, speaker.Working_Hour_Start__c, speaker.Working_Hour_End__c);
            speakerList.add(speakerdata);
            speakerId.add(speaker.Id);
        }

        List<Event> speakerEvent = [Select Id, WhoId, StartDateTime, EndDateTime, EndDate, Status__c FROM Event];

        List<Event> modedEventList = new List<Event>();

        Map<Id, List<Available_Slot>> speakerEventMap = getEventDetails(speakerEvent, eventDate);
        //System.debug('Speaker Events: '+speakerEvent.size());
        ///List<Event> leaves = [Select ContactId, Leave_End_Date__c, Leave_Start_Date__c FROM Event where ContactId in : speakerId];
        //System.debug('Leave List: '+leaves.size());


        speakerList = removeEventSlots(speakerEventMap, speakerList);
        

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
            //System.debug('Break Time '+speaker.Lunch_Start_Time__c+' '+speaker.Lunch_End_Time__c);
            slotList = eliminateBreakHours(slotList, speaker.Lunch_Start_Time__c, speaker.Lunch_End_Time__c, speaker);
        }
        return slotList;
    }

    public static List<Available_Slot> eliminateBreakHours(List<Available_Slot> slotList, Time lunchStartTime,Time lunchEndTime, Contact speaker){
        try{
            
            List<Available_Slot> derivedSlots = new List<Available_Slot>();
            List<Integer> indexList = new List<Integer>();
            Integer count = 0;
            //System.debug('SlotList Size : '+slotList.size());
            for(Available_Slot slot : slotList){
                //Available_Slot slot = slotList[slot];
                //System.debug('Break Time '+lunchStartTime+' '+lunchEndTime);
                //System.debug('Start Time '+slot.start_time+' End Time'+slot.end_time);
                if(lunchStartTime <= slot.start_time && lunchEndTime > slot.start_time && lunchEndTime < slot.end_time){
                    slot.start_time = lunchEndTime;
                    //System.debug('Logic 1 executer');
                }
                else if((slot.start_time < lunchStartTime) && (lunchStartTime < slot.end_time) &&  (slot.start_time < lunchEndTime) && (lunchEndTime < slot.end_time)){
                    slot.end_time = lunchEndTime;
                    Available_Slot newSlotData = new Available_Slot();
                    newSlotData.start_time = lunchEndTime;
                    newSlotData.end_time = slot.end_time;
                    derivedSlots.add(newSlotData);
                    //System.debug('Logic 2 executer');

                }
                else if((slot.start_time == lunchStartTime ) &&  (slot.start_time < lunchEndTime) && (lunchEndTime < slot.end_time)){
                    slot.start_time = lunchEndTime;
                    //System.debug('Logic 3 executer');

                }
                else if((slot.start_time < lunchStartTime) && (lunchStartTime < slot.end_time) &&  ( lunchEndTime == slot.end_time)){
                    slot.end_time = lunchStartTime;
                    //System.debug('Logic 4 executer');
                }
                // else if((slot.start_time <= lunchStartTime < slot.lunchEndTime) &&  (slot.start_time < lunchEndTime < slot.lunchEndTime)){
                //     slot.start_time = lunchEndTime;

                // }
                else if((lunchStartTime < slot.start_time ) && (slot.start_time < lunchEndTime) && (lunchEndTime < slot.end_time)){
                    slot.start_time = lunchEndTime;
                    //System.debug('Logic 5 executer');
                }
                else if((slot.start_time < lunchStartTime) && (lunchStartTime < slot.end_time) && lunchEndTime > slot.end_time){
                    slot.end_time = lunchStartTime;
                    //System.debug('Logic 6 executer');
                }
                else if(lunchStartTime <= slot.start_time && lunchEndTime <= slot.start_time){
                    //System.debug('Logic 7 executer');
                }
                else if(lunchStartTime >= slot.end_time && lunchEndTime >= slot.end_time){
                    //System.debug('Logic 8 executer');
                }
                else{
                    //slotList.remove(count);
                    indexList.add(count);
                    //System.debug('Logic 9 remove executer');
                }
                count++;
            }
            //System.debug('Speaker : '+speaker.Name+' new slot : '+derivedSlots);
            //System.debug('Current list : '+slotList);
            //System.debug('New list : '+derivedSlots);
            //System.debug('Break Time '+lunchStartTime+' '+lunchEndTime);
            //System.debug('New list size: '+derivedSlots.size());
            
            
            if(derivedSlots.size() > 0){
                slotList.addAll(derivedSlots);                
            }
            if(indexList.size() > 0){
                // for(Integer item : indexList){
                //     slotList.remove(item);
                // }
                List<Integer> nindexList = new List<Integer>(indexList);
                nindexList.sort();
                for(Integer item = nindexList.size()-1 ;  item >= 0 ; item--){
                    slotList.remove(nindexList.get(item));
                }
            }
            //System.debug('SlotList Size after iteration: '+slotList.size());
            //return derivedSlots;
            return slotList;
            }
        catch(Exception e){
            //System.debug('Exception Occured '+e.getMessage());
            return null;
        }
    }

    public static Map<Id, List<Available_Slot>> getEventDetails(List<Event> speakerEvent , String eventDate){
        Map<Id, List<Available_Slot>> eventSlotMap = new Map<Id, List<Available_Slot>>();

        for(Event e : speakerEvent){
            // System.debug(' Normal time'+e.StartDateTime);
            // System.debug('GMt time '+string.valueOfGmt(e.StartDateTime));
            // System.debug(e.StartDateTime.formatGmt('HH:mm:ss.SSS\'Z\''));
            // System.debug(e.StartDateTime.format('yyyy-MM-dd'));
            // System.debug(eventDate);
            String formattedEventStartDate = e.StartDateTime.format('yyyy-MM-dd');
            List<Available_Slot> eventSlots = new List<Available_Slot>();

            if(formattedEventStartDate == eventDate){
                Available_Slot newEvent = new Available_Slot();
                //newEvent.start_time = e.StartDateTime.formatGmt('HH:mm:ss.SSS\'Z\'');
                newEvent.start_time = Time.newInstance(
                    e.StartDateTime.hour(), 
                    e.StartDateTime.minute(), 
                    e.StartDateTime.second(), 
                    e.StartDateTime.millisecond());
                    System.debug(newEvent.start_time);
                //newEvent.end_time = e.EndDateTime.formatGmt('HH:mm:ss.SSS\'Z\'');
                newEvent.end_time = Time.newInstance(
                    e.EndDateTime.hour(), 
                    e.EndDateTime.minute(), 
                    e.EndDateTime.second(), 
                    e.EndDateTime.millisecond());
                    System.debug(newEvent.end_time);
                if(eventSlotMap.containsKey(e.whoId)){
                    eventSlots = eventSlotMap.get(e.whoId);
                    eventSlots.add(newEvent);
                }
                else{
                    eventSlots.add(newEvent);
                }
                eventSlotMap.put(e.whoId, eventSlots);
            }
        }
        System.debug(eventSlotMap);
        return eventSlotMap;

    }

    public static List<Responsedata> removeEventSlots(Map<Id, List<Available_Slot>> speakerEventMap, List<Responsedata> speakerSlotData){

        for(Responsedata availableSpeakerData : speakerSlotData){
            List<Available_Slot> scheduledEvent = speakerEventMap.get(availableSpeakerData.Id);
            if(scheduledEvent!= null ){
                Set<Integer> indexList = new Set<Integer>();
                List<Available_Slot> derivedSlots = new List<Available_Slot>();
                System.debug('scheduledEvent '+scheduledEvent.size());
                System.debug('scheduled Event '+scheduledEvent);
                for(Available_Slot eventData : scheduledEvent){
                    Integer count = 0;
                    System.debug('Derived slots' + availableSpeakerData.Available_Slot);
                    for( Available_Slot derivedSlot : availableSpeakerData.Available_Slot){
                        //Available_Slot slot = slotList[slot];
                        //System.debug('Break Time '+lunchStartTime+' '+lunchEndTime);
                        //System.debug('Start Time '+slot.start_time+' End Time'+slot.end_time);
                        if(eventData.start_time <= derivedSlot.start_time && eventData.end_time > derivedSlot.start_time && eventData.end_time < derivedSlot.end_time){
                            derivedSlot.start_time = eventData.end_time;
                            System.debug('Logic 1 executer');
                        }
                        else if((derivedSlot.start_time < eventData.start_time) && (eventData.start_time < derivedSlot.end_time) &&  (derivedSlot.start_time < eventData.end_time) && (eventData.end_time < derivedSlot.end_time)){
                            derivedSlot.end_time = eventData.end_time;
                            Available_Slot newSlotData = new Available_Slot();
                            newSlotData.start_time = eventData.end_time;
                            newSlotData.end_time = derivedSlot.end_time;
                            derivedSlots.add(newSlotData);
                            System.debug('Logic 2 executer');

                        }
                        else if((derivedSlot.start_time == eventData.start_time ) &&  (derivedSlot.start_time < eventData.end_time) && (eventData.end_time < derivedSlot.end_time)){
                            derivedSlot.start_time = eventData.end_time;
                            System.debug('Logic 3 executer');

                        }
                        else if((derivedSlot.start_time < eventData.start_time) && (eventData.start_time < derivedSlot.end_time) &&  ( eventData.end_time == derivedSlot.end_time)){
                            derivedSlot.end_time = eventData.start_time;
                            System.debug('Logic 4 executer');
                        }
                        // else if((derivedSlot.start_time <= eventData.start_time < slot.eventData.end_time) &&  (derivedSlot.start_time < eventData.end_time < slot.eventData.end_time)){
                        //     derivedSlot.start_time = eventData.end_time;

                        // }
                        else if((eventData.start_time < derivedSlot.start_time ) && (derivedSlot.start_time < eventData.end_time) && (eventData.end_time < derivedSlot.end_time)){
                            derivedSlot.start_time = eventData.end_time;
                            System.debug('Logic 5 executer');
                        }
                        else if((derivedSlot.start_time < eventData.start_time) && (eventData.start_time < derivedSlot.end_time) && eventData.end_time > derivedSlot.end_time){
                            derivedSlot.end_time = eventData.start_time;
                            System.debug('Logic 6 executer');
                        }
                        else if(eventData.start_time <= derivedSlot.start_time && eventData.end_time <= derivedSlot.start_time){
                            System.debug('Logic 7 executer');
                        }
                        else if(eventData.start_time >= derivedSlot.end_time && eventData.end_time >= derivedSlot.end_time){
                            System.debug('Logic 8 executer');
                        }
                        else{
                            //slotList.remove(count);
                            indexList.add(count);
                            //System.debug('Logic 9 remove executer');
                        }
                        count++;
                    }
                }
                System.debug('created event : '+indexList.size());
                if(derivedSlots.size() > 0){
                    availableSpeakerData.Available_Slot.addAll(derivedSlots);                
                }
                if(indexList.size() > 0){
                    System.debug('created event slot : '+indexList); 
                    // for(Integer item : indexList){
                    //     availableSpeakerData.Available_Slot.remove(item);
                    // }
                    List<Integer> nindexList = new List<Integer>(indexList);
                    nindexList.sort();
                    for(Integer item = nindexList.size()-1 ;  item >= 0 ; item--){
                        availableSpeakerData.Available_Slot.remove(nindexList.get(item));
                    }
                }
            }
        }
        return speakerSlotData;
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