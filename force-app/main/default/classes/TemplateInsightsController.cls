public class TemplateInsightsController {
    
    @AuraEnabled
    public static void getTemplateAnalytics(String startDate, String endDate, String templateId) {
        system.debug('Highlight');
        
        Date sDstartDate = Date.valueOf(startDate); // dateStr must be 'YYYY-MM-DD'
        Date eDendDate  = Date.valueOf(endDate);
        DateTime stDate = DateTime.newInstance(sDstartDate, Time.newInstance(0, 0, 0, 0));
        DateTime sdDate = DateTime.newInstance(eDendDate, Time.newInstance(0, 0, 0, 0));
        // Convert to Unix timestamp in seconds
        Long SdTimestamp = stDate.getTime() / 1000;
        Long EdTimestamp = sdDate.getTime() / 1000;
        System.debug('SdTimestamp:'+SdTimestamp);
        System.debug('EdTimestamp:'+EdTimestamp);
        WhatsappMeta__mdt metaData = [SELECT Id, AccessToken__c, Business_Number__c, PhoneNumber_Id__c, WABA_Id__c, Version__c, Meta_URL__c FROM WhatsappMeta__mdt LIMIT 1];
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        String endpoint = 'https://graph.facebook.com/v22.0/490308664171285/template_analytics?start='+SdTimestamp+'&end='+EdTimestamp+'&granularity=daily&metric_types=cost%2Cclicked%2Cdelivered%2Cread%2Csent&template_ids='+templateId;
        
        system.debug('endpoint==>' + endpoint);
        
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        request.setHeader('Authorization', 'Bearer ' + metaData.AccessToken__c);
        request.setHeader('Content-Type', 'application/json');
        
        try {
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                System.debug('Response: ' + response.getBody());
                
                Map<String, Object> fullResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                List<Object> dataList = (List<Object>) fullResponse.get('data');
                
                List<TemplateAnalytics__c> recordsToInsert = new List<TemplateAnalytics__c>();
                
                for (Object item : dataList) {
                    Map<String, Object> dataItem = (Map<String, Object>) item;
                    List<Object> dataPoints = (List<Object>) dataItem.get('data_points');
                    
                    for (Object dp : dataPoints) {
                        Map<String, Object> dataPoint = (Map<String, Object>) dp;
                        
                        TemplateAnalytics__c ta = new TemplateAnalytics__c();
                        ta.TemplateId__c = String.valueOf(dataPoint.get('template_id'));
                        
                        Long startTimestamp = dataPoint.get('start') != null ? Long.valueOf(String.valueOf(dataPoint.get('start'))) : null;
                        Long endTimestamp = dataPoint.get('end') != null ? Long.valueOf(String.valueOf(dataPoint.get('end'))) : null;
                        
                        if (startTimestamp != null) {
                            ta.StartDate__c = DateTime.newInstance(startTimestamp * 1000).date();
                        }
                        if (endTimestamp != null) {
                            ta.EndDate__c = DateTime.newInstance(endTimestamp * 1000).date();
                        }
                        
                        ta.Sent__c = dataPoint.get('sent') != null ? String.valueOf(dataPoint.get('sent')) : null;
                        ta.Delivered__c = dataPoint.get('delivered') != null ? String.valueOf(dataPoint.get('delivered')) : null;
                        ta.Read__c = dataPoint.get('read') != null ? String.valueOf(dataPoint.get('read')) : null;
                        
                        List<Object> costItems = (List<Object>) dataPoint.get('cost');
                        if (costItems != null) {
                            for (Object costItem : costItems) {
                                Map<String, Object> costMap = (Map<String, Object>) costItem;
                                String costType = String.valueOf(costMap.get('type'));
                                Object costValue = costMap.get('value');
                                
                                if (costType == 'amount_spent') {
                                    ta.AmountSpent__c = String.valueOf(costValue);
                                } else if (costType == 'cost_per_delivered') {
                                    ta.CostPerDelivered__c = String.valueOf(costValue);
                                } else if (costType == 'cost_per_url_button_click') {
                                    ta.CostPerUrlButtonClick__c = String.valueOf(costValue);
                                }
                            }
                        }
                        
                        recordsToInsert.add(ta);
                    }
                }
                
                // Optional: Avoid inserting duplicate records
                Set<String> existingKeys = new Set<String>();
                for (TemplateAnalytics__c existing : [
                    SELECT TemplateId__c, StartDate__c 
                    FROM TemplateAnalytics__c 
                    WHERE TemplateId__c = :templateId
                ]) {
                    existingKeys.add(existing.TemplateId__c + '-' + String.valueOf(existing.StartDate__c));
                }
                
                List<TemplateAnalytics__c> filteredRecords = new List<TemplateAnalytics__c>();
                for (TemplateAnalytics__c ta : recordsToInsert) {
                    String key = ta.TemplateId__c + '-' + String.valueOf(ta.StartDate__c);
                    if (!existingKeys.contains(key)) {
                        filteredRecords.add(ta);
                    }
                }
                
                if (!filteredRecords.isEmpty()) {
                    insert filteredRecords;
                    System.debug('Inserted ' + filteredRecords + ' records.');
                } else {
                    System.debug('No new records to insert.');
                }
                
            } else {
                System.debug('Error: ' + response.getBody());
                throw new CalloutException('Failed to fetch data from API. Status: ' + response.getStatusCode());
            }
            
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage() + ' Stack: ' + e.getStackTraceString());
            throw new CalloutException('Callout failed: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Decimal> getSummedTemplateAnalytics(String templateId) {
        List<TemplateAnalytics__c> records = [
            SELECT CostPerDelivered__c, AmountSpent__c, CostPerUrlButtonClick__c,
            Sent__c, Delivered__c, Read__c
            FROM TemplateAnalytics__c
            WHERE TemplateId__c =: templateId And CreatedDate = TODAY 
        ];
        
        Decimal totalCostPerDelivered = 0;
        Decimal totalAmountSpent = 0;
        Decimal totalCostPerUrlButtonClick = 0;
        Decimal totalSent = 0;
        Decimal totalDelivered = 0;
        Decimal totalRead = 0;
        
        for (TemplateAnalytics__c record : records) {
            totalCostPerDelivered += tryParseDecimal(record.CostPerDelivered__c);
            totalAmountSpent += tryParseDecimal(record.AmountSpent__c);
            totalCostPerUrlButtonClick += tryParseDecimal(record.CostPerUrlButtonClick__c);
            totalSent += tryParseDecimal(record.Sent__c);
            totalDelivered += tryParseDecimal(record.Delivered__c);
            totalRead += tryParseDecimal(record.Read__c);
        }
        
        return new Map<String, Decimal>{
            'CostPerDelivered__c' => totalCostPerDelivered,
                'AmountSpent__c' => totalAmountSpent,
                'CostPerUrlButtonClick__c' => totalCostPerUrlButtonClick,
                'Sent__c' => totalSent,
                'Delivered__c' => totalDelivered,
                'Read__c' => totalRead
                };
                    }
    
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Decimal> getRecordSummedTemplateAnalytics(String templateId) {
        List<TemplateAnalytics__c> records = [
            SELECT CostPerDelivered__c, AmountSpent__c, CostPerUrlButtonClick__c,
                   Sent__c, Delivered__c, Read__c
            FROM TemplateAnalytics__c
            WHERE TemplateId__c = :templateId // Removed date filter
        ];
        
        Decimal totalCostPerDelivered = 0;
        Decimal totalAmountSpent = 0;
        Decimal totalCostPerUrlButtonClick = 0;
        Decimal totalSent = 0;
        Decimal totalDelivered = 0;
        Decimal totalRead = 0;
        
        for (TemplateAnalytics__c record : records) {
            totalCostPerDelivered += tryParseDecimal(record.CostPerDelivered__c);
            totalAmountSpent += tryParseDecimal(record.AmountSpent__c);
            totalCostPerUrlButtonClick += tryParseDecimal(record.CostPerUrlButtonClick__c);
            totalSent += tryParseDecimal(record.Sent__c);
            totalDelivered += tryParseDecimal(record.Delivered__c);
            totalRead += tryParseDecimal(record.Read__c);
        }
        
        return new Map<String, Decimal>{
            'CostPerDelivered__c' => totalCostPerDelivered,
            'AmountSpent__c' => totalAmountSpent,
            'CostPerUrlButtonClick__c' => totalCostPerUrlButtonClick,
            'Sent__c' => totalSent,
            'Delivered__c' => totalDelivered,
            'Read__c' => totalRead
        };
    }
    
    private static Decimal tryParseDecimal(String value) {
        try {
            return Decimal.valueOf(value);
        } catch (Exception e) {
            return 0;
        }
    }
}