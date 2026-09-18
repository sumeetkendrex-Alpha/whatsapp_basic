import { LightningElement, track, api } from 'lwc';
import createMetaTemplate from '@salesforce/apex/CreateMetaTemplate.createMetaTemplate';
import uploadToFacebook from '@salesforce/apex/FacebookUploader.uploadToFacebook';
import createContentVersion from '@salesforce/apex/FacebookUploader.createContentVersion';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class QuickReplyButtons extends NavigationMixin(LightningElement) {
    @track showDropdown = false;
    @track buttons = [];
    @track customfields = [];
    @track useLinkTracking = false;
    @track templateType = '';
    @track templateTypeName = ''
    @track templateName = '';
    @track selectedLanguage = 'en';
    selectedLanguageLabel = 'English';
    @track bodyContent = '';
    @track selectedDate = new Date().toISOString().slice(0, 10);
    @track showVarDropdown = false;
    @track visbleCall = false;
    @track visibleQuick = false;
    isLoading = false;

    @track headerText = '';
    @track headerImageHandle = '';
    selectedHeader = 'None';
    //file upload
    fileName = '';
    fileType = '';
    fileContentBase64 = '';
    fileSelected = false;
    isUploading = false;
    uploadResult = '';
    //file upload
    bodyText = '';
    inputFields = [];
    showError = false;
    footervalue = '';
    @track contentDIstributionUrl = '';
    languages = [
        { label: 'English', value: 'en' },
        { label: 'Spanish', value: 'es' },
        { label: 'French', value: 'fr' }
    ];

    actionTypes = [
        { label: 'Custom', value: 'custom' },
        { label: 'Visit website', value: 'website' },
        { label: 'Call phone number', value: 'phone' },
        { label: 'Copy offer code', value: 'offer' }
    ];

    urlTypes = [
        { label: 'Static', value: 'static' },
        { label: 'Dynamic', value: 'dynamic' }
    ];

    countries = [
        { label: 'India', value: 'IN' },
    ];

    // UI Getters for conditional display
    get showTextField() {
        return this.selectedHeader === 'Text';
    }

    get showImageUploader() {
        return this.selectedHeader === 'Image';
    }

    get showVideoUploader() {
        return this.selectedHeader === 'Video';
    }

    get showDocumentUploader() {
        return this.selectedHeader === 'Document';
    }

    // Dynamic JSON State Builder
    get state() {
        const components = [];

        // HEADER
        if (this.selectedHeader !== 'None') {
            const capitalized = this.selectedHeader.toUpperCase();
            const headerComponent = {
                type: 'HEADER',
                format: capitalized
            };

            if (this.selectedHeader === 'Image' || this.selectedHeader === 'Document') {
                headerComponent.example = {
                    header_handle: [this.headerImageHandle]
                };
            }
            else if (this.selectedHeader === 'Text') {
                headerComponent.text = this.headerText;
            }

            components.push(headerComponent);
        }



        // BODY
        if (this.bodyContent.trim()) {
            const bodyComponent = {
                type: 'BODY',
                text: this.bodyContent
            };

            // If sample values exist, add example
            if (this.inputFields.length > 0) {
                const samples = this.inputFields
                    .sort((a, b) => a.index - b.index)
                    .map(field => field.value || '');

                bodyComponent.example = {
                    body_text: [samples]
                };
            }

            components.push(bodyComponent);
        }

        // FOOTER
        if (this.footervalue != '') {
            components.push({
                type: 'FOOTER',
                text: this.footervalue
            });
        }

        // BUTTONS (phone, website, offer)
        const mappedButtons = this.buttons.map(button => {
            switch (button.type) {
                case 'phone':
                    return {
                        type: 'PHONE_NUMBER',
                        text: button.text,
                        phone_number: '+91' + button.phone || null
                    };
                case 'website':
                    return {
                        type: 'URL',
                        text: button.text,
                        url: button.url || null
                    };
                case 'offer':
                    return {
                        type: 'COPY_CODE',
                        example: button.Code
                    };
                default:
                    return null;
            }
        }).filter(Boolean);

        // QUICK_REPLY Buttons
        const customButtons = this.customfields.map(obj => ({
            type: 'QUICK_REPLY',
            text: obj.text
        }));

        // Merge all buttons into one BUTTONS block if any
        const allButtons = [...mappedButtons, ...customButtons];
        if (allButtons.length > 0) {
            components.push({
                type: 'BUTTONS',
                buttons: allButtons
            });
        }

        // Final Response
        const response = {
            name: this.templateName || 'default_template',
            language: this.selectedLanguage || 'en',
            category: this.templateTypeName || 'MARKETING',
            components: components
        };

        return JSON.stringify(response);
    }


    // Format date
    formatDate(dateString) {
        const date = new Date(dateString);
        return date.toLocaleDateString('en-US', {
            month: 'long',
            day: 'numeric',
            year: 'numeric'
        });
    }

    @api formData;
    connectedCallback() {
        this.isLoading = false;
        // Automatically get data from A
        if (this.formData) {
            console.log('Data received from Component A:', this.formData.name);
            this.templateTypeName = this.formData.name || 'marketing';
            this.templateType = this.formData.value || 'custom';
        }

    }
    // Input handlers
    handleTemplateNameChange(event) {
        const value = event.target.value.trim().replace(/\s+/g, '_').toLowerCase();

        this.templateName = value;

    }

    handleLanguageChange(event) {
        this.selectedLanguage = event.detail.value;
        const selectedOption = this.languages.find(opt => opt.value === this.selectedLanguage);
        this.selectedLanguageLabel = selectedOption ? selectedOption.label : 'None';
    }

    handleDateChange(event) {
        this.selectedDate = event.target.value;
    }

    handleBodyChange(event) {
        this.bodyContent = event.target.value;
        this.generateSampleInputsFromBody();


    }

    generateSampleInputsFromBody() {
        const body = this.bodyContent || '';
        const regex = /\{\{(\d+)\}\}/g;

        let max = 0;
        let match;

        // Find highest {{n}}
        while ((match = regex.exec(body)) !== null) {
            max = Math.max(max, parseInt(match[1], 10));
        }

        const updatedFields = [];

        for (let i = 1; i <= max; i++) {
            const existing = this.inputFields.find(f => f.index === i);

            updatedFields.push({
                index: i,
                label: `Sample for {{${i}}}`,
                value: existing ? existing.value : ''
            });
        }

        this.inputFields = updatedFields;
        this.showError = max > 0 && this.inputFields.some(f => !f.value);
    }

    handleInputChange(event) {
        const index = event.target.dataset.index;
        this.inputFields[index].value = event.target.value;
        this.inputFields = [...this.inputFields];
    }


    handleHeaderChange(event) {
        this.selectedHeader = event.target.value;
    }

    handleHeaderTextChange(event) {
        this.headerText = event.target.value;
    }

    handleImageUpload(event) {
        this.headerImageHandle = event.detail.fileId;
    }

    handleTrackingChange(event) {
        this.useLinkTracking = event.target.checked;
    }

    showButtonTypes() {
        console.log('show button')
        this.showDropdown = !this.showDropdown;

        if (this.showDropdown) {
            // Timeout ensures the dropdown is rendered before attaching event
            setTimeout(() => {
                window.addEventListener('click', this.handleClickOutside);
            }, 0);
        } else {
            window.removeEventListener('click', this.handleClickOutside);
        }
    }

    // Button add/remove methods
    addWebsiteButton() {
        const size = this.buttons.length + this.customfields.length;
        if (size < 10) {
            const websiteCount = this.buttons.filter(b => b.type === 'website').length;
            if (websiteCount >= 2) return this.showDropdown = false;

            this.buttons.push({
                id: Date.now(),
                type: 'website',
                text: 'Visit website',
                urlType: 'static',
                url: '',
                isWebsite: true,
                isPhone: false,
                isOffer: false,
                isCustom: false
            });
        }
        this.showDropdown = false;
        this.visbleCall = this.buttons.length > 0;
    }

    addCustomfield() {
        const size = this.buttons.length + this.customfields.length;
        if (size < 10) {
            const customfieldCount = this.customfields.length;
            if (customfieldCount >= 10) return this.showDropdown = false;

            this.customfields.push({
                id: Date.now(),
                type: 'text',
                text: 'custom',
                isCustom: true
            });
        }
        this.showDropdown = false;
        this.visibleQuick = this.customfields.length > 0;
    }

    addPhoneButton() {
        const size = this.buttons.length + this.customfields.length;
        if (size < 10) {
            const phoneCount = this.buttons.filter(b => b.type === 'phone').length;
            if (phoneCount >= 1) return this.showDropdown = false;

            this.buttons.push({
                id: Date.now(),
                type: 'phone',
                text: 'Contact US',
                country: 'IN +91',
                phone: '',
                isPhone: true
            });
        }
        this.showDropdown = false;
        this.visbleCall = this.buttons.length > 0;
    }

    addOfferCodeButton() {
        const size = this.buttons.length + this.customfields.length;
        if (size < 10) {
            const offerCount = this.buttons.filter(b => b.type === 'offer').length;
            if (offerCount >= 1) return this.showDropdown = false;

            this.buttons.push({
                id: Date.now(),
                type: 'offer',
                text: 'Copy offer code',
                isOffer: true
            });
        }
        this.showDropdown = false;
        this.visbleCall = this.buttons.length > 0;
    }

    // Input handlers for buttons
    handleTextChange(event) {
        const index = event.target.dataset.index;
        this.customfields[index].text = event.target.value;
        console.log('this.customfields.text:' + this.customfields[index].text);
    }

    handleUrlTypeChange(event) {
        const index = event.target.dataset.index;
        this.buttons[index].urlType = event.detail.value;
    }

    handleUrlChange(event) {
        const index = event.target.dataset.index;
        this.buttons[index].url = event.target.value;
    }
    handleButtonTextChange(event) {
        const index = event.target.dataset.index;
        this.buttons[index].text = event.target.value;
    }

    handleCountryChange(event) {
        const index = event.target.dataset.index;
        this.buttons[index].country = event.detail.value;
    }
    handleOfferCodeChange(event) {
        const index = event.target.dataset.index;
        this.buttons[index].Code = event.target.value;
    }

    handlePhoneChange(event) {
        const index = event.target.dataset.index;
        this.buttons[index].phone = event.target.value;
    }
    handlebuttonTextpChange(event) {
        const index = event.target.dataset.index;
        this.buttons[index].text = event.target.value;
    }

    removeButton(event) {
        const index = event.target.dataset.index;
        this.buttons.splice(index, 1);
        this.buttons = [...this.buttons];
        this.visbleCall = this.buttons.length > 0;
    }

    removeCustomButton(event) {
        const index = event.target.dataset.index;
        this.customfields.splice(index, 1);
        this.customfields = [...this.customfields];
        this.visibleQuick = this.customfields.length > 0;
    }
    handlechangefooter(event) {
        console.log('handle footer change!!:' + event.target.value);
        this.footervalue = event.target.value;
        console.log(' this.footervalue:' + this.footervalue);
    }

    //previous next
    previousStep() {
        this.dispatchEvent(new CustomEvent('previous'));
    }

    finish() {
        const payload = {
            address: this.address,
            phone: this.phone
        };
        this.dispatchEvent(new CustomEvent('finish', { detail: payload }));
    }
    @api
    handleSave() {
        this.isLoading = true;
        createMetaTemplate({ body: this.state, templateType: this.templateType, distUrl: this.contentDIstributionUrl })
            .then((result) => {
                console.log('result==>', result);
                this.isLoading = false;
                if (result.isSuccess == true) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Template Created Successfully',
                            message: result.message,
                            variant: 'Success'
                        })
                    );
                    this.handleClose();
                }
                if (result.isSuccess == false) {
                    let errorMessage = result.message;

                    try {
                        // Extract JSON part starting at Response:
                        const jsonStart = result.message.indexOf('{');
                        const jsonString = result.message.substring(jsonStart);

                        const fbResponse = JSON.parse(jsonString);

                        if (fbResponse.error) {
                            // Prefer user friendly message if available
                            errorMessage = fbResponse.error.error_user_msg
                                || fbResponse.error.message
                                || errorMessage;
                        }
                    } catch (e) {
                        console.error("JSON parsing failed:", e);
                    }

                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Failed to create template',
                            message: errorMessage,
                            variant: 'error'
                        })
                    );
                }




            })
            .catch((error) => {
                console.error('Error: ', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error saving template',
                        message: error.body.message || 'Unknown error',
                        variant: 'error'
                    })
                );
                // this.handleClose();
            });
        console.log('Saved Values:', JSON.stringify(this.state));

    }

    handleClose() {
        console.log('handle close!!');
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/lightning/o/WhatsAppMetaTemplate__c/list?filterName=Recent'
            }
        });
    }

    handleFileChange(event) {
        console.log('file upload !!');
        const file = event.target.files[0];
        if (file) {
            const reader = new FileReader();
            reader.onload = () => {
                const base64 = reader.result.split(',')[1]; // Remove metadata from base64
                this.uploadFileToFacebook(file.name, file.type, base64);
            };
            reader.readAsDataURL(file);
        }
    }

    uploadFileToFacebook(fileName, fileType, base64Data) {
        this.isLoading = true;
        const uploadPromise = uploadToFacebook({ fileName, fileType, base64Data })
            .then(response => {
                console.log('Upload success:', response);
                const parsedResponse = JSON.parse(response);
                this.headerImageHandle = parsedResponse.h;
                console.log(' this.headerImageHandle :' + this.headerImageHandle);

            })
            .catch(error => {
                console.error('Upload error:', error.body.message);

            });

        const contentPromise = createContentVersion({ fileName, fileType, base64Data })
            .then(response => {
                this.contentDIstributionUrl = response;
                console.log('ContentDistribution:', response);
                console.log('this.contentDIstributionUrl:', this.contentDIstributionUrl);
            })
            .catch(error => {
                console.error('Upload error:', error.body.message);

            });

        Promise.allSettled([uploadPromise, contentPromise])
            .then(() => {
                this.isLoading = false;
                console.log('All uploads finished (success or fail). Loader stopped.');
            });
    }

    //dropDown

    handleClickOutside = (event) => {
        const dropdownWrapper = this.template.querySelector('.dropdown-container');
        if (!dropdownWrapper.contains(event.target)) {
            this.showDropdown = false;
            window.removeEventListener('click', this.handleClickOutside);
        }
    };

    closeDropdown() {
        this.showDropdown = false;
        window.removeEventListener('click', this.handleClickOutside);
    }

}