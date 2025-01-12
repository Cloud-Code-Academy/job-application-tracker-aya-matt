public class JoobleAPIService implements Schedulable {

    //Endpoint URL and API Key
    private static final String ENDPOINT_URL = 'https://jooble.org/api/';
    private static final String API_KEY = '582b4f21-15e5-4540-b872-4c6519d9f781';

    public static void fetchJobs(String keywords, String location) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();

        //set request URL and method
        request.setEndpoint(ENDPOINT_URL + API_KEY);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');

        Date lastSyncDate = Date.today().addDays(-2);

        //Create JSON request body
        String requestBody = JSON.serialize(new Map<String, String>{
            'keywords' => keywords,
            'location' => location,
            'datecreatefrom' => lastSyncDate.format()    
        });

        request.setBody(requestBody);

        
            HttpResponse response = http.send(request);
            if(response.getStatusCode() != 200){
                System.debug('Error: ' + response.getStatus());
                return;
            }
            
                //Parse JSON response
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                List<Object> jobs = (List<Object>) result.get('jobs');

                //Prepare existing data
                Set<String> joobleJobIds = new Set<String>();
                set<String> companyNames = new Set<String>();

                //Collect Jooble job ids and company names
                for(object jobObj : jobs){
                    Map<String, Object> job = (Map<String, Object>) jobObj;
                    joobleJobIds.add(String.valueOf(job.get('id')));
                    companyNames.add((String) job.get('company'));
                }

                //Query existing job applications
                Map<String, Job_Application__c> existingApplicationMap = new Map<String, Job_Application__c>([
                    SELECT JobId__c
                    FROM Job_Application__c 
                    WHERE JobId__c IN :joobleJobIds
                    ]);

                //Query existing company accounts
                Map<String, Id> existingAccountsMap = new Map<String, Id>();
                for(Account acc : [SELECT Name FROM Account WHERE Name IN :companyNames]){
                    existingAccountsMap.put(acc.Name, acc.Id);
                }

                //Create new Accounts
                List<Account> accountsToCreate = new List<Account>();
                for(String companyName : companyNames){
                    if(!existingAccountsMap.containsKey(companyName)){
                        accountsToCreate.add(new Account(Name = companyName));
                    }
                }

                if(!accountsToCreate.isEmpty()){
                    insert accountsToCreate;
                    for(Account acc : accountsToCreate){
                        existingAccountsMap.put(acc.Name, acc.Id);
                    }
                }

                //Create Job Applications
                List<Job_Application__c> applicationsToCreate = new List<Job_Application__c>();
                for(object jobObj : jobs){
                    Map<String, Object> job = (Map<String, Object>) jobObj;
                    String joobleJobId = String.valueOf (job.get('id'));
                
                    if(!existingApplicationMap.containsKey(joobleJobId)){
                        Job_Application__c jobApp = new Job_Application__c();
                        String jobTitle = (String) job.get('title');
                        if(jobTitle.length() > 80){
                        jobTitle = jobTitle.substring(0, 80);
                        }
                        jobApp.Name = jobTitle;
                        jobApp.Status__c = 'Saved';
                        jobApp.Company_Account__c = existingAccountsMap.get((String) job.get('company'));
                        jobApp.JobId__c = joobleJobId;
                        String snippet = (String) job.get('snippet');
                        jobApp.Description__c = snippet.stripHtmlTags();
                        jobApp.URL__c = (String) job.get('link');

                        if(job.containsKey('salary') && String.isNotBlank((String)job.get('salary'))){
                            string salaryStr = (String)job.get('salary');
                            //validate salary is numeric
                            if(!String.isBlank(salaryStr) && Pattern.matches('^[0-9]+(\\.[0-9]{1,2})?$', salaryStr)){
                                jobApp.Salary__c = Decimal.valueOf(salaryStr);
                            }else{
                                jobApp.Salary__c = null;
                            }
                        }
                
                        applicationsToCreate.add(jobApp);
                    }
                }

                //Insert Job Applications
                if(!applicationsToCreate.isEmpty()){
                    insert applicationsToCreate;
                }
    }
    public void execute(SchedulableContext sc) {
        System.enqueueJob(new JoobleAPIQueueable('Salesforce', 'Remote'));
    }
}