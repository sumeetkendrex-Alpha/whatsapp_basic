import { LightningElement, track, wire, api } from 'lwc';
import sendtoNewUser from '@salesforce/apex/sendWhatsAppTemplateController.SendtoNewUser';
import infoLogo from '@salesforce/resourceUrl/Info';
// import infoImage from '@salesforce/resourceUrl/infoImage';
import getTemplatepicklistRecord from '@salesforce/apex/WhatsappConversationController.getTemplatepicklistRecord';
import sendTextMessage from '@salesforce/apex/WhatsAppOutgoingMessage.sendTextMessage';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import myCsvFile from '@salesforce/resourceUrl/myCsvFile';
export default class sendWhatsAppTemplate extends LightningElement {
    @track isLoading = false;

    @api businessNumber
    @track isSendTemplte = false;
    @track isfinalstep = false;
    @track isModalOpen = false;
    @track fileName;
    @track errorMessage;
    @track isImagePopupOpen = false;
    @track isTemplateCategory = [
        { label: 'Marketing', value: 'Marketing' },
        { label: 'Utility', value: 'Utility' },
        { label: 'Authentication', value: 'Authentication' }
    ];
    @track selectedCategory;
    @track isTemplateOptions;
    istemplateName;

    infoLogoUrl = infoLogo;
    // infoImageUrl = infoImage;
    recordlist = [];
    columns = [
        { label: 'Name', fieldName: 'Name' },
        { label: 'Phone', fieldName: 'Phone' }
    ];

    connectedCallback() {
        this.isModalOpen = true;
    }

    handledownload(event) {
        const link = document.createElement('a');
        link.href = myCsvFile;
        link.download = 'WhatsAppData.csv';
        link.click();
    }

    handleFileChange(event) {
        this.errorMessage = '';
        const file = event.target.files[0];
        if (file) {
            this.fileName = file.name;
            if (!file.name.toLowerCase().endsWith('.csv')) {
                this.showToast('Error', 'Please upload a valid CSV file.', 'error');
                return;
            }
            this.isLoading = true;
            this.readFileContent(file);

        }
    }

    readFileContent(file) {
        const reader = new FileReader();
        reader.onload = () => {
            const csvData = reader.result;
            this.parseCsvData(csvData);
             this.isLoading = false;
        };
        reader.readAsText(file);
    }

  parseCsvData(csvData) {
    const lines = csvData.split('\n').filter(line => line.trim() !== '');
    const headers = lines[0].trim().split(',').map(h => h.trim());

    // ✅ Create columns dynamically
    this.columns = headers.map(header => ({
        label: header,
        fieldName: header
    }));

    const jsonDataArray = [];
    for (let i = 1; i < lines.length; i++) {
        const data = lines[i].trim().split(',');
        if (data.length === 0 || data.every(v => !v)) continue; // skip empty rows
        const jsonObject = {};
        for (let j = 0; j < headers.length; j++) {
            jsonObject[headers[j]] = data[j]?.trim() || '';
        }
        jsonDataArray.push(jsonObject);
    }

    console.log('Parsed CSV JSON:', JSON.stringify(jsonDataArray));
    console.log('Generated Columns:', JSON.stringify(this.columns));

    this.recordlist = jsonDataArray;
}



    arrayEquals(a, b) {
        return Array.isArray(a) &&
            Array.isArray(b) &&
            a.length === b.length &&
            a.every((val, index) => val === b[index]);
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }



    handleInfoClick() {
        this.isImagePopupOpen = true;
        console.log("clicked");;
    }

    handleCloseModal() {
        this.isImagePopupOpen = false;
        this.isLoading = false;
    }

    handleRowSelection(event) {

        this.isLoading = true;
        const selectedRows = event.detail.selectedRows;
        this.selectedRecords = selectedRows;
        // For example: log selected
        console.log('Selected Records:', this.selectedRecords);
         this.isLoading = false;
    }

    closeModal() {
        this.isModalOpen = false;
    }

    handleNext() {
        this.isLoading = true;
        console.log('Selected Records:', this.selectedRecords);
        this.isSendTemplte = true;
        this.isfinalstep = true;
         this.isLoading = false;
    }

    handleCategoryChange(event) {
        this.selectedCategory = event.detail.value;
        console.log('Selected category:', this.selectedCategory);
        // Add any additional logic when category changes

        this.isTemplateType = null;
        this.isTemplate = null;
        if (this.selectedCategory != null) {
            this.getTemplatePicklistValues(this.selectedCategory);
        }
    }

    handleTemplateTypeChange(event) {
        this.isTemplateType = event.detail.value;
        console.log('this.isTemplateType==>', this.isTemplateType);
        this.isTemplate = null;

        this.getTemplatePicklistValues();
    }

    getTemplatePicklistValues() {
        getTemplatepicklistRecord({ category: this.selectedCategory })
            .then(result => {
                console.log('Picklist Values from Apex:', result);

                // Extract SubCategory__c values
                const values = result
                    .map(rec => rec.SubCategory__c)
                    .filter(value => value); // Filter out null/undefined
                console.log('Formatted values:', values);

                const names = result
                    .map(rec => rec.Template_Name__c)
                    .filter(name => name); // Filter out null/undefined
                console.log('Formatted name :', name);
                // Deduplicate values
                const uniqueValues = [...new Set(values)];
                console.log('Formatted uniqueValues:', uniqueValues);
                const uniqueValuesName = [...new Set(names)];

                // Format for lightning-combobox
                this.isTemplateOptions = uniqueValues.map(value => ({
                    label: value,
                    value: value
                }));

                this.istemplateName = uniqueValuesName.map(value => ({
                    label: value,
                    value: value
                }));

                // Optionally set a default
                this.isTemplate = '---None---';

                console.log('Formatted picklist options:', JSON.stringify(this.isTemplateOptions));
                console.log('Default selected template:', this.isTemplate);
            })
            .catch(error => {
                console.error('Error fetching picklist values:', error);
            });
    }


    handleTemplateChange(event) {
        this.isTemplate = event.detail.value;
        console.log('this.isTemplate==>', this.isTemplate);
    }

  handleSendTemplate(event) {
    this.isLoading = true;
    sendtoNewUser({recordlist: this.selectedRecords,templateName: this.isTemplate, businessNumber: this.businessNumber,templatetype: this.isTemplateType})
    .then((calloutStrings) => {
        calloutStrings.forEach(async (str) => {
            try {
                let result = await sendTextMessage({ callOutString: str });
                console.log('Sent successfully:', str, result);

                
            // ✅ Show actual error toast
            this.showToast('Send', ` ${result}`, 'info');

            } catch (error) {
                console.error('Failed to send:', str, error);
                
            }
        });
 this.isLoading = false;
        this.showToast('Success', 'Messages queued for sending', 'success');

        this.isModalOpen = false;
    })
    .catch((err) => {
        console.error('Error preparing messages:', err);
        this.showToast('Error', 'Failed to prepare messages', 'error');
        this.isModalOpen = false;
    });
}

    





    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

}