import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';


export default class ParentComponent extends NavigationMixin(LightningElement) {
    @track currentStep = 'A';
    @track formData = {};

    handleInputChange(event) {
        const name = event.detail.name;
        const value = event.detail.value;

        this.formData = { name:name,value:value};
    }

    handleNext() {
        if (this.currentStep === 'A') {
            this.currentStep = 'B';
        } else {
            console.log('Final data submitted:', JSON.stringify(this.formData));
            // Final submission logic
        }
    }
  
    handlePrevious() {
        if (this.currentStep === 'B') {
            this.currentStep = 'A';
        }
        this. formData = {};

    }
    handleSave(){
          this.template.querySelector("c-whatsapp-template-builder").handleSave();
    }

    get isStepA() {
        return this.currentStep === 'A';
    }

    get isStepB() {
        return this.currentStep === 'B';
    }

    get nextButtonLabel() {
        return this.currentStep === 'B' ? 'Finish' : 'Next';
    }
    
    handleCancel(){
        console.log('template wizard')
           this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/lightning/o/WhatsAppMetaTemplate__c/list?filterName=Recent'
            }
        });
    }
}