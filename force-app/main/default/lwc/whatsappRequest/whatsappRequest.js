import { LightningElement, wire, track } from 'lwc';
import getUnmatchedNewWhatsAppMessages from '@salesforce/apex/WhatsAppRequestController.getUnmatchedNewWhatsAppMessages';
import createLead from '@salesforce/apex/WhatsAppRequestController.createLead';
import redirectToWhatsappChatActivity from '@salesforce/apex/WhatsAppRequestController.redirectToWhatsappChatActivity';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { subscribe } from 'lightning/empApi';
import notificationSound from '@salesforce/resourceUrl/notificationSound';
import {refreshApex} from '@salesforce/apex';

export default class whatsappRequest extends NavigationMixin(LightningElement) {
    @track conversations;
    @track wiredConversationsResult;
    @track totalMessages = 0;
    @track subscription = false;
     
    
    connectedCallback() {
        console.log('refresh again');
        this.getConversation();
        if (!this.subscription) {
            console.log('hello from refresh');
            const refreshCallback = function () {
            this.playSound();
                return refreshApex(this.getConversation());
            }.bind(this);
            subscribe("/event/WhatsApp_Notify_Lwc__e", -1, refreshCallback).then(response => {
                this.subscription = true;
            });
        }
        this.subscription = false;
        if (!this.subscription) {
            console.log('hello from refresh 2');
            const refreshCallback = function () {
                return refreshApex(this.getConversation());
            }.bind(this);
            subscribe("/event/Whatsapp_Request_Lwc__e", -1, refreshCallback).then(response => {
                this.subscription = true;
            });
        }       
    }

     playSound() {
        const audio = new Audio(notificationSound);
        audio.play().catch(error => {
            console.error('Error playing audio:', error);
        });
    }


   getConversation() {
    getUnmatchedNewWhatsAppMessages()
        .then(result => {
            console.log('result ===>', result);
            if (result) {
                // Sort by CreatedDate descending
                this.conversations = [...result].sort((a, b) => new Date(b.CreatedDate) - new Date(a.CreatedDate));
                console.log('Sorted conversations:', this.conversations);
            }
        })
        .catch(error => {
            console.error('Error fetching conversations:', error);
            this.error = error;
        });

    // Start the clock or additional processing
    this.startClock();
}

startClock() {
    setInterval(() => {
        if (this.conversations && this.conversations.length > 0) {
            const currentTime = new Date();

            this.conversations = this.conversations.map(conversation => {
                if (conversation.CreatedDate) {
                    const messageTime = new Date(conversation.CreatedDate);
                    const elapsed = currentTime - messageTime;

                    const seconds = Math.floor(elapsed / 1000);
                    const minutes = Math.floor(seconds / 60);
                    const hours = Math.floor(minutes / 60);

                    return {
                        ...conversation,
                        timeElapsed: `${hours}h ${minutes % 60}m ${seconds % 60}s`
                    };
                }
                return conversation;
            });

            // Force reactivity
            this.conversations = [...this.conversations];
            this.totalMessages = this.conversations.length;
        }
    }, 1000);
}



   
   

    handleAccept(event) {

        const index = event.currentTarget.dataset.index;
        const conversation = this.conversations[index];

        createLead({
            customerName: conversation.CustomerName__c,
            customerPhone: conversation.CustomerPhone__c
        })
            .then((result) => {

                console.log('result=>', result);
                this.showToast('Success', 'Lead created and assigned to you.', 'success');
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: result,
                        objectApiName: 'Lead',
                        actionName: 'view'
                    }
                });

                return refreshApex(this.getConversation());

            })
            .catch(error => {
                // Show error toast
                this.showToast('Error', 'Failed to create lead: ' + error.body.message, 'error');
                console.error(error);
            });
    }



    handleRedirectToUser(event){
        const index = event.currentTarget.dataset.index;
        const conversation = this.conversations[index];

        redirectToWhatsappChatActivity({businessNumber: conversation.BusinessNumber__c, customerPhone: conversation.CustomerPhone__c})
            .then((result) => {
                console.log('result=>', result);
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: result,
                        objectApiName: 'WhatsappUser__c',
                        actionName: 'view'
                    }
                });
                
                return refreshApex(this.getConversation());
            })
            .catch(error => {
                console.error(error);
            });
    }



    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

}