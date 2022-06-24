public with sharing class CTLocationTracingTriggerHandler {
    public CTLocationTracingTriggerHandler() {

    }
    public static void beforeInsert(List<Location_Tracing__c> traces){
        List<Location_Tracing__c> duplicates = CTLocationTracingController.checkDuplicates(traces);
        for(Location_Tracing__c trace : duplicates)
        trace.addError('Duplicate error found. Location:'+trace.Location__c+', Person:'+trace.Person__c);
    }
}
