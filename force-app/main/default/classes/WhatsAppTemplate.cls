public class WhatsAppTemplate {
    public String name;
    public String parameter_format;
    public List<Component> components;
    public String language;
    public String status;
    public String category;
    public String sub_category;
    public String correct_category;
    public String id;

    public class Component {
        public String type;
        public String format; 
        public String text;   
        public Example example;
        public List<Button> buttons;
    }

   public class Button {
    public String type;
    public String text;
    public String url; 
    public String phone_number; 
    public List<String> example;
}

    public class Example {
        public List<String> header_handle;     
        public List<List<String>> body_text;  
    }
}