public class JobApplicationTriggerHandler {
    public static void beforeInsertUpdate(List<Job_Application__c> newRecords, Map<Id, Job_Application__c> oldMap) {
        
        for(Job_Application__c application : newRecords) {
            //Perform Pay Estimation Calculation
            PayEstimationHelper.calculatePayEstimation(application);

            //Handle Primary Contact Assignment
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

            String newStatus = application.Status__c;
            String oldStatus = oldRecords != null ? oldRecords.get(application.Id)?.Status__c : null;

            //skip if status is blank or changed to a non-value
            if(String.isBlank(newStatus) || newStatus.equalsIgnoreCase('None')){
                continue;
            }

            //Skip if status hasn't changed
            if(oldStatus != null && oldStatus.equalsIgnoreCase(newStatus)){
                continue;
            }
            
            //Create Task
            Task newTask = new Task(
                WhatId = application.Id,
                Subject = 'Follow-up for Status Change:' + application.Status__c,
                ActivityDate = System.today().addDays(7),
                Priority = 'Normal'
            );
            tasksToInsert.add(newTask);
                
            }
        if(!tasksToInsert.isEmpty()){
            insert tasksToInsert;
        }
    }
}