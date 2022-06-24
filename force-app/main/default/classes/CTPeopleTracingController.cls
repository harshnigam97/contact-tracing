public with sharing class CTPeopleTracingController {
    public CTPeopleTracingController() {

    }
    public static List<People_Tracing__c> getTraces(String recordId)
    {
        List<People_Tracing__c> peopleTraces=[SELECT Id, Contact_Date__c, Person_1__c, Person_2__c, Person_1__r.Health_Status__c, Person_2__r.Health_Status__c, Person_1__r.Token__c, Person_2__r.Token__c 
        FROM People_Tracing__c 
        WHERE Person_1__c=:recordId OR Person_2__c=:recordId
        ORDER BY Contact_Date__c DESC NULLS LAST];
            if(peopleTraces!=null && peopleTraces.size()>0)
            return peopleTraces;
            return null;
    }

    public static List<People_Tracing__c> checkDuplicates(List<People_Tracing__c> newPeopleTraces)
    {
        Set<Id> personIds = new Set<Id>();
        for(People_Tracing__c trace: newPeopleTraces)
        {
            personIds.add(trace.Person_1__c);
            personIds.add(trace.Person_2__c);
        }

        List<People_Tracing__c> duplicates = new List<People_Tracing__c>();

        Map<Id, Set<Id>> extTracesMap = new Map<Id, Set<Id>>();

        List<People_Tracing__c> existingRecords = [SELECT Id, Contact_Date__c, Person_1__c, Person_2__c 
                FROM People_Tracing__c 
                WHERE Person_1__c IN :personIds 
                OR Person_2__c IN :personIds];
        if(existingRecords!=null && existingRecords.size()>0)
        {
            for (People_Tracing__c trace : existingRecords) {
                if(!extTracesMap.containsKey(trace.Person_1__c))
                {
                    extTracesMap.put(trace.Person_1__c, new Set<Id>());
                }
                extTracesMap.get(trace.Person_1__c).add(trace.Person_2__c);

                if(!extTracesMap.containsKey(trace.Person_2__c))
                {
                    extTracesMap.put(trace.Person_2__c, new Set<Id>());
                }
                extTracesMap.get(trace.Person_2__c).add(trace.Person_1__c);
                
            }

            for (People_Tracing__c trace : newPeopleTraces) {
                if((extTracesMap.containsKey(trace.Person_1__c)&&extTracesMap.get(trace.Person_1__c).contains(trace.Person_2__c)) || (extTracesMap.containsKey(trace.Person_2__c)&&extTracesMap.get(trace.Person_2__c).contains(trace.Person_1__c)))
                duplicates.add(trace);
            }
        }
        return duplicates;
    }

    public static Set<Id> getCohabitants(Set<Id> personIds, Set<Id> alreadyAdded)
    {
        List<String> statuses= new List<String>{'Green', 'Yellow'};
        List<People_Tracing__c> traces=[SELECT Person_1__c, Person_2__c
        FROM People_Tracing__c
        WHERE (Person_1__c IN:personIds OR Person_2__c IN:personIds)
        AND (Person_1__r.Health_Status__c IN: statuses OR Person_2__r.Health_Status__c IN: statuses)
        AND Contact_Type__c = 'Cohabitant'];

        Set<Id> cohabitants = new Set<Id>();
        for(People_Tracing__c pt:traces)
        {
            if(!personIds.contains(pt.Person_1__c) && !alreadyAdded.contains(pt.Person_1__c))
            cohabitants.add(pt.Person_1__c);
            if(!personIds.contains(pt.Person_2__c) && !alreadyAdded.contains(pt.Person_2__c))
            cohabitants.add(pt.Person_2__c);
        }
        return cohabitants;
    }

    public static Set<Id> getPrimaryContacts(Set<Id> personIds, Set<Id> alreadyAdded)
    {
        List<String> statuses= new List<String>{'Green', 'Yellow'};
        List<People_Tracing__c> traces=[SELECT Person_1__c, Person_2__c
        FROM People_Tracing__c
        WHERE (Person_1__c IN:personIds OR Person_2__c IN:personIds)
        AND (Person_1__r.Health_Status__c IN: statuses OR Person_2__r.Health_Status__c IN: statuses)
        AND Contact_Type__c = 'Other'
        AND Contact_Date__c = LAST_N_DAYS:10];

        Set<Id> primaryContacts = new Set<Id>();
        for(People_Tracing__c pt:traces)
        {
            if(!personIds.contains(pt.Person_1__c) && !alreadyAdded.contains(pt.Person_1__c))
            primaryContacts.add(pt.Person_1__c);
            if(!personIds.contains(pt.Person_2__c) && !alreadyAdded.contains(pt.Person_2__c))
            primaryContacts.add(pt.Person_2__c);
        }
        return primaryContacts;
    }

    public static Set<Id> getNeighbours(Set<Id> personIds, Set<Id> alreadyAdded)
    {
        List<People_Tracing__c> traces=[SELECT Person_1__c, Person_2__c
        FROM People_Tracing__c
        WHERE (Person_1__c IN:personIds OR Person_2__c IN:personIds)
        AND (Person_1__r.Health_Status__c = 'Green' OR Person_2__r.Health_Status__c = 'Green')
        AND Contact_Type__c = 'Neighbour'];

        Set<Id> neighbours = new Set<Id>();
        for(People_Tracing__c pt:traces)
        {
            if(!personIds.contains(pt.Person_1__c) && !alreadyAdded.contains(pt.Person_1__c))
            neighbours.add(pt.Person_1__c);
            if(!personIds.contains(pt.Person_2__c) && !alreadyAdded.contains(pt.Person_2__c))
            neighbours.add(pt.Person_2__c);
        }
        return neighbours;
    }

    public static Set<Id> getSecondaryContacts(Set<Id> primaryContacts, Set<Id> alreadyAdded)
    {
        List<String> statuses= new List<String>{'Green', 'Yellow'};
        List<People_Tracing__c> traces=[SELECT Person_1__c, Person_2__c
        FROM People_Tracing__c
        WHERE (Person_1__c IN:primaryContacts OR Person_2__c IN:primaryContacts)
        AND (Person_1__r.Health_Status__c IN: statuses OR Person_2__r.Health_Status__c IN: statuses)
        AND Contact_Type__c = 'Other'
        AND Contact_Date__c = LAST_N_DAYS:10];

        Set<Id> secondaryContacts = new Set<Id>();
        for(People_Tracing__c pt:traces)
        {
            if(!primaryContacts.contains(pt.Person_1__c) && !alreadyAdded.contains(pt.Person_1__c))
            secondaryContacts.add(pt.Person_1__c);
            if(!primaryContacts.contains(pt.Person_2__c) && !alreadyAdded.contains(pt.Person_2__c))
            secondaryContacts.add(pt.Person_2__c);
        }
        return secondaryContacts;
    }
}

