public with sharing class CTLocationController {
    public CTLocationController() {

    }
    public static List<Location__c> getRecentStatusChanges()
    {
        return [SELECT Id, Name, Address__c, Pincode__c, Status_Update_Date__c, Red_Score__c, Status__c FROM Location__c ORDER BY Status_Update_Date__c DESC NULLS LAST LIMIT 100];
    }

    public static List<Location__c> searchLocations(String searchTerm)
    {
        searchTerm='%'+searchTerm+'%';
        return [SELECT Id, Name, Address__c, Pincode__c, Status_Update_Date__c, Red_Score__c, Status__c FROM Location__c WHERE Name LIKE :searchTerm OR Pincode__c LIKE :searchTerm OR Address__c LIKE :searchTerm  ORDER BY Status_Update_Date__c DESC NULLS LAST];
    }

    public static Location__c getLocationById(String locationId)
    {
        Id id=Id.valueOf(locationId);
        List<Location__c> locations=[SELECT Id, Name, Address__c, Pincode__c, Status_Update_Date__c, Red_Score__c, Status__c FROM Location__c WHERE Id=:id];
        if(locations!=null && locations.size()>0)
        {
            return locations[0];
        }
        return null;
    }

    public static Map<String, Integer> getStatusCount()
    {
        Map<String, Integer> statusCount = new Map<String, Integer>();
        for(AggregateResult ar : [SELECT Count(Id) total, Status__c FROM Location__c GROUP BY Status__c]){
            String status = String.valueOf(ar.get('Status__c'));
            Integer count = Integer.valueOf(ar.get('total'));
            statusCount.put(status,count);
        }
        return statusCount;
    }

    public static void updateRedScore(Set<Id> locationIds)
    {
        
        Map<Id, Location__c> locationToBeUpdated = new Map<Id, Location__c>();
        AggregateResult[] redPeoplePerLocation=[SELECT Location__c, COUNT(Id) total
            FROM Location_Tracing__c
            WHERE Person__r.Health_Status__c= 'Red' 
            AND Visit_Date__c = LAST_N_DAYS:10
            AND Location__c IN: locationIds
            GROUP BY Location__c];
        
        for(AggregateResult ar : redPeoplePerLocation){
            String locationId = String.valueOf(ar.get('Location__c'));
            Integer redScore = Integer.valueOf(ar.get('total'));
            String status = getStatus(redScore);
            locationToBeUpdated.put(locationId, new Location__c(Id=locationId, Red_Score__c=redScore, Status__c=status));
        }

        for(Id id: locationIds)
        {
            if(!locationToBeUpdated.containsKey(id)){
                locationToBeUpdated.put(id, new Location__c(Id=id, Red_Score__c=0, Status__c='Green'));
            }
        }

        update locationToBeUpdated.values();
        
    }

    public static String getStatus(Integer redCount){
        if(redCount==0)
            return 'Green';
        else if(redCount<=5)
            return 'Yellow';
        else if(redCount<=10)
            return 'Orange';
        else
            return 'Red';
    }

}
