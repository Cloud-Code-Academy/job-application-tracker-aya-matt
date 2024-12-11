public class JobApplicationTriggerHandler {
    public static void beforeInsertUpdate(List<Job_Application__c> newRecords, Map<Id, Job_Application__c> oldMap) {
        //Handle Primary Contact Assignment
        for(Job_Application__c application : newRecords) {
            if(String.isBlank(application.Primary_Contact__c)){
                List<Contact> relatedContacts =[
                    SELECT Id FROM Contact
                    Where AccountId = :application.Company_Account__c
                    LIMIT 1
                ];
                if(!relatedContacts.isEmpty()){
                    application.Primary_Contact__c = relatedContacts[0].Id;
                }
            }
        }

    }
    Public static void afterInsertUpdate(List<Job_Application__c> newRecords, Map<Id, Job_Application__c> oldRecords){ 
        //Handle Task Creation on Status Change
        List<Task> tasksToInsert = new List<Task>();
        for(Job_Application__c application : newRecords){
            if(oldRecords != null && application.Status__c != oldRecords.get(application.Id)?.Status__c){
                Task newTask = new Task(
                    WhatId = application.Id,
                    Subject = 'Follow-up for Status Change:' + application.Status__c,
                    ActivityDate = System.today().addDays(7),
                    Priority = 'Normal'
                );
                tasksToInsert.add(newTask);
            }
        }
        if(!tasksToInsert.isEmpty()){
            insert tasksToInsert;
        }
    }
}