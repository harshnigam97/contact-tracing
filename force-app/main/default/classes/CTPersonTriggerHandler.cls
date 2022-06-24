public with sharing class CTPersonTriggerHandler {
    public CTPersonTriggerHandler() {

    }
    public static void beforeInsert(List<Person__c> newRecords)
    {
        for(Person__c person : newRecords)
            {
                person.Health_Status__c='Green';
                person.Token__c=CTPersonController.getToken(person.Mobile__c);
            }
    }

    public static void beforeUpdate(List<Person__c> newRecords, Map<Id, Person__c> oldRecordsMap)
    {
        for(Person__c person : newRecords)
            {
                if(person.Health_Status__c!=oldRecordsMap.get(person.Id).Health_Status__c)
                person.Status_Update_Date__c=Date.Today();
            }
    }

    public static void afterUpdate(List<Person__c> newRecords, Map<Id, Person__c> oldRecordsMap)
    {
        Set<Id> personIds = new Set<Id>();
        Set<Id> personInRed = new Set<Id>();
        for(Person__c person : newRecords)
            {
                if(person.Health_Status__c!=oldRecordsMap.get(person.Id).Health_Status__c)
                personIds.add(person.Id);
                
                if(person.Health_Status__c == 'Red' && oldRecordsMap.get(person.Id).Health_Status__c != 'Red')
                personInRed.add(person.Id);
            }
        if(personIds!=null && personIds.size()>0)
        {
        List<Location_Tracing__c> locationTraces = CTLocationTracingController.getLocationsByPersonIds(personIds);
        Set<Id> locationIds = new Set<Id>();
        for(Location_Tracing__c trace: locationTraces)
        locationIds.add(trace.Location__c);
        CTLocationController.updateRedScore(locationIds);
        }
        
        if(personInRed!=null && personInRed.size()>0)
        {
        Set<Id> alreadyAdded = new Set<Id>();
        alreadyAdded.addAll(personInRed);
        Set<Id> cohabitants = CTPeopleTracingController.getCohabitants(personInRed, alreadyAdded);
        alreadyAdded.addAll(cohabitants);
        Set<Id> primaryContacts = CTPeopleTracingController.getPrimaryContacts(personInRed, alreadyAdded);
        alreadyAdded.addAll(primaryContacts);
        Set<Id> neighbours = CTPeopleTracingController.getNeighbours(personInRed, alreadyAdded);
        alreadyAdded.addAll(neighbours);
        Set<Id> secondaryContacts = CTPeopleTracingController.getSecondaryContacts(primaryContacts, alreadyAdded);
        
        List<Person__c> updateStatus = new List<Person__c>();
        for(Id id : cohabitants)
        updateStatus.add(new Person__c(Id=id, Health_Status__c='Orange'));
        for(Id id : primaryContacts)
        updateStatus.add(new Person__c(Id=id, Health_Status__c='Orange'));
        for(Id id : neighbours)
        updateStatus.add(new Person__c(Id=id, Health_Status__c='Yellow'));
        for(Id id : secondaryContacts)
        updateStatus.add(new Person__c(Id=id, Health_Status__c='Yellow'));

        update updateStatus;
        }

    }
}
