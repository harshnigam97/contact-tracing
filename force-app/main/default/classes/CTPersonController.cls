public with sharing class CTPersonController {
    public CTPersonController() {

    }
    public static String getToken(String mobileNo)
    {
        Blob targetBlob = Blob.valueOf(mobileNo);
        Blob hash = Crypto.generateDigest('MD5', targetBlob);

        //Get the string value of Hash blob
        return EncodingUtil.base64Encode(hash);
    }

    public static List<Person__c> getRecentHealthChanges()
    {
        List<Person__c> persons = [SELECT Token__c, Id, Name, Health_Status__c, Mobile__c, Status_Update_Date__c FROM Person__c ORDER BY Status_Update_Date__c DESC NULLS LAST LIMIT 100];
            return persons;
    }

    public static Person__c getPersonById(String personId)
    {
        Id id = Id.valueOf(personId);
        List<Person__c> persons = [SELECT Token__c, Id, Name, Health_Status__c, Mobile__c, Status_Update_Date__c FROM Person__c WHERE Id=:id];
        if(persons !=null && persons.size()>0)
            return persons[0];
        return null;
    }

    public static List<Person__c> searchPeople(String searchTerm)
    {
        List<Person__c> persons = [SELECT Token__c, Id, Name, Health_Status__c, Mobile__c, Status_Update_Date__c FROM Person__c WHERE (Name LIKE '%searchTerm%' OR Mobile__c LIKE '%searchTerm%' OR Token__c LIKE '%searchTerm%') ORDER BY Status_Update_Date__c DESC NULLS LAST];
        return persons;
    }

    public static Map<String, Integer> getHealthStatusCount()
    {
        Map<String, Integer> healthStatusMap= new Map<String,Integer>();
        for(AggregateResult ar : [SELECT Health_Status__c, COUNT(Id) total
                                    FROM Person__c
                                    GROUP BY Health_Status__c]){
            String healthStaus=String.valueOf(ar.get('Health_Status__c'));
            Integer count=Integer.valueOf(ar.get('total'));
            healthStatusMap.put(healthStaus,count);
         }
          
         return healthStatusMap;
    }

}
