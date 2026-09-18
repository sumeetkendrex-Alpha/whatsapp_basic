public class WhatsAppMessageOutbound {
    
    public String messaging_product;
    public List<contacts> contacts;
    public List<messages> messages;
    public text text;
    public image image;
    public video video;
    public audio audio;
    public document document;
    public String to;                
    public String type;             
    public Template template;        
    public entry[] entry;
    
    public class contacts {
        public String input; 
        public String wa_id; 
    }
    
    public class messages {
        public String id; 
        public String message_status;
    }
    public class text{
        public string body;
    }
    
    public class template{
        public string name;
        public language language;
        public components[] components;

    }
    public class language{
        public string code;
    }
   public class components {
		public String type;	
    public List<parameters> parameters;
	}
    
   public class parameters {
		public String type;	
		public image image;
       	public audio audio;
		public video video;
		public document document;

	}
	
    
    public class image {
        public String link;	
    }
     public class video {
        public String link;	
    }
     public class audio {
        public String link;	
    }
    
     public class document {
        public String link;
        public String filename;
    }
    
    public class entry {
        public String id;	
        public changes[] changes;
    }
    
    public class changes {
        public  value value;
        public String field;
    }
    
    public class value {
        public String messaging_product;	
        public metadata metadata;
        public statuses[] statuses;
    }
    public class metadata {
        public String display_phone_number;	//15550759185
        public String phone_number_id;	//255525520973097
    }
    public class statuses {
        public String id;	//wamid.HBgMOTE3NjE1OTExNzQ0FQIAERgSRjM1MDEyNkE5MzMyRjg4RDMxAA==
        public String status;	//delivered
        public String timestamp;	//1733640935
        public String recipient_id;	//917615911744
        public conversation conversation;
        public pricing pricing;
    }
    public class conversation {
        public String id;	//6ea3e348c5a8111dbc2f4fd2705999a8
        public origin origin;
        public String expiration_timestamp;
    }
    public class origin {
        public String typex;	//marketing
    }
    public class pricing {
        public boolean billable;
        public String pricing_model;	//CBP
        public String category;	//marketing
    }
}