public with sharing class AccountSync {
    @future(callout=true)
    public static void sendAccountData(Id accountId, String name, String phone, String website) {
        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('https://techjagruti5-dev-ed.develop.my.site.com/whatsApp/services/apexrest/accountSync');
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            
            // Build JSON payload
            Map<String, Object> payload = new Map<String, Object>();
            payload.put('id', accountId);
            payload.put('name', name);
            payload.put('phone', phone);
            payload.put('website', website);
            request.setBody(JSON.serialize(payload));
            
            // Send request
            HttpResponse response = http.send(request);
            if (response.getStatusCode() != 201) {
                System.debug('Error: ' + response.getBody());
            }
        } catch (Exception e) {
            System.debug('Callout error: ' + e.getMessage());
        }
    }
}