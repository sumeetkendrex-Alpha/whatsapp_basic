public class WhatsAppMessageTriggerHandlerOrder {
    public static void CreateOrder(Set<Id> msgIdOrder) {
        System.debug('===== Start: CreateOrder =====');

        // Get Standard Pricebook
        Pricebook2 standardPB = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
        System.debug('Standard Pricebook Id: ' + standardPB.Id);

        // Get WhatsApp messages
        List<WhatsApp_Message__c> messages = [
            SELECT Id, OrderDetail__c FROM WhatsApp_Message__c WHERE Id IN :msgIdOrder
        ];
        System.debug('Fetched WhatsApp Messages: ' + messages);

        // Maps and collections
        Set<String> retailerIds = new Set<String>();
        Map<Id, List<Map<String, Object>>> msgToItems = new Map<Id, List<Map<String, Object>>>();
        Map<Id, String> msgToSender = new Map<Id, String>();

        // Parse JSON and collect product codes
        for (WhatsApp_Message__c msg : messages) {
            try {
                if (String.isNotBlank(msg.OrderDetail__c)) {
                    Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(msg.OrderDetail__c);
                    List<Object> entryList = (List<Object>) root.get('entry');
                    if (entryList != null && !entryList.isEmpty()) {
                        Map<String, Object> entry = (Map<String, Object>) entryList[0];
                        List<Object> changesList = (List<Object>) entry.get('changes');
                        if (changesList != null && !changesList.isEmpty()) {
                            Map<String, Object> change = (Map<String, Object>) changesList[0];
                            Map<String, Object> value = (Map<String, Object>) change.get('value');
                            List<Object> messagesList = (List<Object>) value.get('messages');
                            if (messagesList != null && !messagesList.isEmpty()) {
                                Map<String, Object> message = (Map<String, Object>) messagesList[0];
                                String sender = (String) message.get('from');
                                msgToSender.put(msg.Id, sender);
                                Map<String, Object> order = (Map<String, Object>) message.get('order');
                                List<Object> items = (List<Object>) order.get('product_items');

                                List<Map<String, Object>> itemList = new List<Map<String, Object>>();
                                for (Object obj : items) {
                                    Map<String, Object> item = (Map<String, Object>) obj;
                                    String code = (String) item.get('product_retailer_id');
                                    if (code != null) {
                                        retailerIds.add(code);
                                        itemList.add(item);
                                        System.debug('Parsed Item: ' + item);
                                    }
                                }
                                msgToItems.put(msg.Id, itemList);
                            }
                        }
                    }
                }
            } catch (Exception e) {
                System.debug('️ Error parsing JSON for message ' + msg.Id + ': ' + e.getMessage());
            }
        }

        System.debug('Collected Retailer IDs: ' + retailerIds);

        // Query Product2 by ProductCode
        Map<String, Product2> productCodeToProduct = new Map<String, Product2>();
        for (Product2 p : [
            SELECT Id, Name, ProductCode FROM Product2 WHERE ProductCode IN :retailerIds
        ]) {
            productCodeToProduct.put(p.ProductCode, p);
        }
        System.debug('Product Map: ' + productCodeToProduct);

        // Query PricebookEntry for those products
        Map<Id, PricebookEntry> productIdToPBE = new Map<Id, PricebookEntry>();
        for (PricebookEntry pbe : [
            SELECT Id, Product2Id FROM PricebookEntry
            WHERE Product2Id IN :productCodeToProduct.values() AND Pricebook2Id = :standardPB.Id
        ]) {
            productIdToPBE.put(pbe.Product2Id, pbe);
        }
        System.debug('PricebookEntry Map: ' + productIdToPBE);

        // Create Orders
        Id defaultAccountId = [SELECT Id FROM Account WHERE id='001Qy000018GyvxIAC' LIMIT 1 ].Id;
        List<Order> ordersToInsert = new List<Order>();
        Map<Id, Order> msgToOrder = new Map<Id, Order>();

        for (WhatsApp_Message__c msg : messages) {
            if (msgToSender.containsKey(msg.Id)) {
                Order ord = new Order(
                    Name = 'Order from ' + msgToSender.get(msg.Id),
                    Status = 'Draft',
                    EffectiveDate = Date.today(),
                    AccountId = defaultAccountId,
                    Pricebook2Id = standardPB.Id
                );
                ordersToInsert.add(ord);
                msgToOrder.put(msg.Id, ord);
                System.debug('Prepared Order: ' + ord);
            }
        }

        insert ordersToInsert;
        System.debug('Inserted Orders: ' + ordersToInsert);

        // Create OrderItems
        List<OrderItem> orderItemsToInsert = new List<OrderItem>();

        for (WhatsApp_Message__c msg : messages) {
            if (msgToOrder.containsKey(msg.Id) && msgToItems.containsKey(msg.Id)) {
                Order ord = msgToOrder.get(msg.Id);
                for (Map<String, Object> item : msgToItems.get(msg.Id)) {
                    String retailerId = (String) item.get('product_retailer_id');
                    Decimal price = item.containsKey('item_price') ? (Decimal) item.get('item_price') : 0;
                    Integer qty = item.containsKey('quantity') ? (Integer) item.get('quantity') : 1;

                    Product2 prod = productCodeToProduct.get(retailerId);
                    if (prod != null) {
                        PricebookEntry pbe = productIdToPBE.get(prod.Id);
                        if (pbe != null) {
                            OrderItem oi = new OrderItem(
                                OrderId = ord.Id,
                                PricebookEntryId = pbe.Id,
                                Quantity = qty,
                                UnitPrice = price
                            );
                            orderItemsToInsert.add(oi);
                            System.debug('Prepared OrderItem: ' + oi);
                        } else {
                            System.debug('️ No PBE found for product: ' + prod.Name);
                        }
                    } else {
                        System.debug('️ No Product found for retailer ID: ' + retailerId);
                    }
                }
            }
        }

        if (!orderItemsToInsert.isEmpty()) {
            insert orderItemsToInsert;
            System.debug(' Inserted OrderItems: ' + orderItemsToInsert);
        } else {
            System.debug(' No OrderItems to insert');
        }

    }
}