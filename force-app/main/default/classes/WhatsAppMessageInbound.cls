public class WhatsAppMessageInbound {
    
    public entry[] entry;
 
    public class entry {
        public String id;	
        public changes[] changes;
    }
    public class changes {
        public value value;
        public String field;	
    }
    public class value {
        public String messaging_product;	
        public metadata metadata;
        public contacts[] contacts;
        public messages[] messages;
        public Statuses[] Statuses;
    }
    public class metadata {
        public String display_phone_number;	
        public String phone_number_id;	
    }
    public class Statuses {
        public String id ;
        public String status ;
        public String timestamp ;
        public String recipient_id ;
        public Conversation conversation ;
        public Pricing pricing ;
        public List<Errors> errors;
    }
 public class Errors {
        public Integer code;
        public String title;
        public String message;
        public ErrorData error_data;
        public String href;
    }

    public class ErrorData {
        public String details;
    }
    public class Conversation {
        public String id ;
        public String expiration_timestamp;
        public Origin origin ;
    }
    public class Origin {
        public String typex ;
    }
    
    public class Pricing {
        public Boolean billable ;
        public String pricing_model ;
        public String category ;
    }
    
    public class contacts {
        public profile profile;
        public String wa_id;	
    }
    public class profile {
        public String name;	
    }
    public class messages {
        public context context;
        public String fromx;	
        public String id;	
        public String timestamp;	
        public text text;
        public String typex;	
        public reaction reaction;
        public media image;
        public media video;
        public media audio;
        public media sticker;
        public button button;
        public order order;
        public interactive interactive;
        public location location;
    }
    public class location{
        public decimal latitude;
        public Decimal longitude;
    }
    
   public class order {
		public String catalog_id;
		public String text;
		public product_items[] product_items;
	}
    
    public class product_items {
		public String product_retailer_id;
		public Integer quantity;
		public Integer item_price;
		public String currencyx;	
	}
    public class context {
        public String fromx;	
        public String id;	
    } 
    public interactive interactive;
    public class interactive {
		public String typex;	//nfm_reply
		public nfm_reply nfm_reply;
	}
	public class nfm_reply {
		public String response_json;	//{"screen_0_Name_0":"Sumeet Kendre","screen_0_Order_number_1":"112233","screen_0_Choose_a_topic_2":"1_Maintenance","screen_0_Description_of_issue_3":"I have problem with the HR team.","flow_token":"<FLOW_TOKEN>"}
		public String body;	//Sent
		public String name;	//flow
	}

    public class text {
        public String body;	
    }
    public class reaction{
        public String emoji;
        public String message_id;
    }
    public class media{
        public String mime_typex;
        public String id;
        public String sha256;
        public String animated;
    }
    public class button {
        public String payload;	
        public String text;	
    }
    
    
}