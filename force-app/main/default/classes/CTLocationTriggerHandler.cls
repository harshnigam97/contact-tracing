public with sharing class CTLocationTriggerHandler {
    public CTLocationTriggerHandler() {

    }

    public static void beforeInsert(List<Location__c> newrecords){
        for(Location__c location: newRecords)
        {
            location.Status__c='Green';
        }
    }

    public static void beforeUpdate(List<Location__c> newRecords, Map<Id, Location__c> oldRecordsMap){
        for(Location__c location: newRecords)
        {
            if(location.Status__c!=oldRecordsMap.get(location.Id).Status__c)
            location.Status_Update_Date__c=Date.Today();
        }
    
    }

    public static void afterUpdate(List<Location__c> newRecords, Map<Id, Location__c> oldRecordsMap){
        Set<Id> redStatusLocation = new Set<Id>();
        for(Location__c location: newRecords)
        {
            if(location.Status__c=='Red' && oldRecordsMap.get(location.Id).Status__c!='Red')
            redStatusLocation.add(location.Id);
        }
        if(redStatusLocation!=null && redStatusLocation.size()>0)
        {
            Set<Id> personIds = CTLocationTracingController.getPeopleOfLocation(redStatusLocation);
            List<Person__c> personsToUpdate= new List<Person__c>();
            for(Id id: personIds)
            personsToUpdate.add(new Person__c(Id=id, Health_Status__c='Yellow'));
            
            update personsToUpdate;
        }
    }
}
