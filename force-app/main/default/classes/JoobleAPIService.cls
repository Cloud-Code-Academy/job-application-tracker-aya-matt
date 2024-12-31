public class JoobleAPIService {

    //Endpoint URL and API Key
    private static final String ENDPOINT_URL = 'https://jooble.org/api/';
    private static final String API_KEY = '582b4f21-15e5-4540-b872-4c6519d9f781';

    /**
     * Fetches job posting from Jooble API based on search criteria.
     * @param keywards Search keywords.
     * @param location Search location.
     */
    public static void fetchJobs(String keywords, String location) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();

        //set request URL and method
        request.setEndpoint(ENDPOINT_URL + API_KEY);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');

        //Create JSON request body
        String requestBody = JSON.serialize(new Map<String, String>{
            'keywords' => keywords,
            'location' => location    
        });

        request.setBody(requestBody);

        try{
            HttpResponse response = http.send(request);
            if(response.getStatusCode() == 200){
                //Parse JSON response
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

                //Parse Job Data
                List<Object> jobs = (List<Object>) result.get('jobs');
                List<Job_Application__c> jobApplications = new List<Job_Application__c>();

                for(Object jobObj : jobs){
                    Map<String, Object> job = (Map<String, Object>) jobObj;

                    Job_Application__c jobApp = new Job_Application__c();
                    jobApp.Name = (String) job.get('title');
                    jobApp.Status__c = 'Saved';
                    jobApp.Company_Account__c = null;
                    String snippet = (String) job.get('snippet');
                    jobApp.Description__c = snippet.stripHtmlTags();
                    jobApp.URL__c = '[View Job](' + (String) job.get('link') + ')';
                    jobApplications.add(jobApp);
                }

                //Insert Job Applications
                if(!jobApplications.isEmpty()){
                    insert jobApplications;
                }
            }else{
                System.debug('Error: ' + response.getStatus());
            }

        }catch(Exception e){
            System.debug('Error: ' + e.getMessage());

        }
    }
}