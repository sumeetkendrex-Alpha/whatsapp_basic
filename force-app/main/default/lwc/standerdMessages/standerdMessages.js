import { LightningElement, api, track, wire } from 'lwc';
import getStandardMessages from '@salesforce/apex/StandardMessageController.getStandardMessages';
import sendTextMessage from '@salesforce/apex/WhatsAppOutgoingMessage.sendTextMessage';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class StanderdMessages extends LightningElement {
    @api value;
    @api phoneNumber;
    @api customerName;
    @track isLoading = false;
    @track isShowModal = false;



    @track messages = [];
    @track selectedMessage = '';

    @wire(getStandardMessages)
    wiredMessages({ data, error }) {
        if (data) {
            this.messages = data;
        } else if (error) {
            console.error('Error fetching messages:', error);
        }
    }
    connectedCallback() {
        console.log('recordId from parent:', this.value);
        console.log('userName from parent:', this.phoneNumber);

    }

    
    showModalBox() {
        this.isShowModal = true;
    }
    hideModalBox() {
        this.isShowModal = false;
    }

    handleSelection(event) {
        const selectedId = event.target.value;
        this.selectedMessage = this.messages.find(msg => msg.Id === selectedId);
        console.log('Selected message:', this.selectedMessage);
    }

    handleSend(event) {
        this.isLoading = true;
        if (this.selectedMessage != null) {
            const body = this.selectedMessage.Description__c;
            console.log('body==>', body);
            //   const JsonBody ='{"messaging_product":"whatsapp","recipient_type":"individual","to":"'+this.phoneNumber+'","type":"text","text":{"body":"'+body+'"}}';
            const JsonBody = JSON.stringify({ messaging_product: "whatsapp", recipient_type: "individual", to: this.phoneNumber, type: "text", text: { body: body } });

            this.callOutString = this.phoneNumber + '@@' + this.value + '@@' + JsonBody + '@@' + 'template' + '@@' + this.customerName;
            console.log('callOutString==>', this.callOutString);
            sendTextMessage({ callOutString: this.callOutString })
                .then((result) => {
                    console.log('Message sent successfully:', result);
                    if (result == 'success') {
                        this.resetForm();
                    } else {
                        this.showToast('Failed!', result, 'error');
                        this.resetForm();
                    }
                    this.resetForm();
                })
                .catch((error) => {
                    this.resetForm();
                    console.error('Error in sendTextMessage Apex call:', error);
                    this.showToast('Error', 'Failed to send the message. Please try again later.', 'error');
                });
        }


    }

    resetForm() {
        this.hideModalBox();
        this.selectedMessage = '';
        this.isLoading = false;
    }



    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }


}