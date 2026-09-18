import { LightningElement, api, track } from 'lwc';
import getTemplateById from '@salesforce/apex/WhatsappBulkSenderListViewController.getTemplateById';
import getUsers from '@salesforce/apex/WhatsappBulkSenderListViewController.getUsers';
import sendTextMessage from '@salesforce/apex/WhatsAppOutgoingMessage.sendTextMessage';

export default class WhatsappBulkSenderListView extends LightningElement {
    @api recordId;
    @track templateJson = '';
    @track templateName = '';
    @track users = [];
    @track isLoading = false;
    @track processedCount = 0;
    @track showDialog = true;

    connectedCallback() {
        this.loadTemplate();
    }

    async loadTemplate() {
        try {
            const templateRecord = await getTemplateById({ templateId: this.recordId });
            this.templateJson = templateRecord.TemplateJSON__c;
            this.templateName = templateRecord.Template_Name__c;
            await this.loadUsers();
        } catch (error) {
            console.error('Error loading template:', error);
        }
    }

    async loadUsers() {
        try {
            this.users = await getUsers();
        } catch (error) {
            console.error('Error loading users:', error);
        }
    }

    async sendMessages() {
        if (!this.templateJson || this.users.length === 0) {
            alert('Template or users missing.');
            return;
        }

        this.isLoading = true;
        this.processedCount = 0;

        for (let user of this.users) {
            const JsonBody = JSON.parse(this.templateJson);
            JsonBody.to = user.CustomerPhone__c;

            const callOutString = user.CustomerPhone__c + '@@' +user.BusinessNumber__c + '@@' +JSON.stringify(JsonBody) + '@@' +'template' + '@@' +user.CustomerName__c;
            try {
                await sendTextMessage({ callOutString });
                this.processedCount++;
            } catch (error) {
                console.error('Error sending message to', user.CustomerPhone__c, error);
            }
        }
        this.isLoading = false;
        alert(`Messages sent successfully! (${this.processedCount}/${this.users.length})`);
        this.closeDialog();
    }
    get progressValue() {
    return this.users.length > 0 
        ? (this.processedCount / this.users.length) * 100 
        : 0;
}

    closeDialog() {
        this.showDialog = false;
    }
}