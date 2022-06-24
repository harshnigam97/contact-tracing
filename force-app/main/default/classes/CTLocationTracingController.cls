public with sharing class CTLocationTracingController {
    public CTLocationTracingController() {

    }
    public static List<Location_Tracing__c> getVisitors(String locationId)
    {
        return [SELECT Id, Name, Person__c, Location__c, Visit_Date__c, Person__r.Token__c, Person__r.Health_Status__c 
                    FROM Location_Tracing__c 
                    WHERE Location__c=:locationId
                    ORDER BY Visit_Date__c DESC NULLS LAST];
    }

    public static List<Location_Tracing__c> getLocationsByPersonIds(Set<Id> personIds)
    {
        return [SELECT Id, Person__c, Location__c, Visit_Date__c, Person__r.Token__c, Person__r.Health_Status__c 
            FROM Location_Tracing__c 
            WHERE Visit_Date__c=LAST_N_DAYS:10 
            AND Person__c IN :personIds
            ORDER BY Visit_Date__c DESC NULLS LAST];
    }

    public static List<Location_Tracing__c> getLocationsByLocationsIds(Set<Id> locationIds)
    {
        return [SELECT Id, Person__c, Location__c
            FROM Location_Tracing__c 
            WHERE Visit_Date__c=LAST_N_DAYS:10 
            AND Person__r.Health_Status__c='Green' 
            AND Location__c IN :locationIds
            ORDER BY Visit_Date__c DESC NULLS LAST];
    }

    public static List<Location_Tracing__c> checkDuplicates(List<Location_Tracing__c> newLocationTraces)
    {
        Set<Id> personIds = new Set<Id>();
        Set<Id> locationIds = new Set<Id>();
        for(Location_Tracing__c locationTrace : newLocationTraces)
        {
             personIds.add(locationTrace.Person__c);
             locationIds.add(locationTrace.Location__c);
        }

        List<Location_Tracing__c> existingRecords = [SELECT Id, Person__c, Location__c 
                                                        FROM Location_Tracing__c
                                                        WHERE Location__c IN :locationIds 
                                                        OR Person__c IN :personIds];
        Map<Id, Set<Id>> extTracesMap = new Map<Id, Set<Id>>();
        List<Location_Tracing__c> duplicates = new List<Location_Tracing__c>();
        if(existingRecords!=null && existingRecords.size()>0)
        {
        for(Location_Tracing__c extLocationTrace : existingRecords)
        {
            if(!extTracesMap.containsKey(extLocationTrace.Location__c)){
            extTracesMap.put(extLocationTrace.Location__c, new Set<Id>());
            }
            extTracesMap.get(extLocationTrace.Location__c).add(extLocationTrace.Person__c);

        }

        for(Location_Tracing__c trace : newLocationTraces)
        {
            if(extTracesMap.containsKey(trace.Location__c) && (extTracesMap.get(trace.Location__c).contains(trace.Person__c)))
            duplicates.add(trace);
        }
        }
        return duplicates;
    }

    public static Set<Id> getPeopleOfLocation(Set<Id> locationIds)
    {
        List<String> statuses = new List<String>{'Green', 'Yellow'};
        Set<Id> personIds =new Set<Id>();
        List<Location_Tracing__c> traces = [SELECT Person__c
        FROM Location_Tracing__c
        WHERE Location__c IN: locationIds
        AND Visit_Date__c = LAST_N_DAYS:10
        AND Person__r.Health_Status__c IN:statuses];

        for(Location_Tracing__c trace: traces)
        personIds.add(trace.Person__c);

        return personIds;
    }
}
