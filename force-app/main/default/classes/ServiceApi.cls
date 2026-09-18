@RestResource(urlMapping='/ServiceApi/*')
global with sharing class ServiceApi {
    // Define response wrapper
    global class ResponseWrapper {
        public Boolean success;
        public String id;
        public String error;
    }

    @HttpPost
    global static ResponseWrapper createCase() {
        RestRequest req = RestContext.request;
        String body = req.requestBody.toString();
        Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(body);

        ResponseWrapper res = new ResponseWrapper();

        try {
            Case c = new Case(
                Subject = (String)data.get('Subject'),
                Description = (String)data.get('Description'),
                Origin = (String)data.get('Origin'),
                Status = 'New'
            );
            insert c;
            res.success = true;
            res.id = c.Id;
        } catch (Exception e) {
            res.success = false;
            res.error = e.getMessage();
        }

        return res;
    }
}