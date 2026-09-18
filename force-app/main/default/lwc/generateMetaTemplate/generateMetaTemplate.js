import { LightningElement, track } from 'lwc';
import createMetaTemplate from '@salesforce/apex/CreateMetaTemplate.createMetaTemplate';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';


export default class GenerateMetaTemplate extends NavigationMixin(LightningElement) {
    @track isTextSelected = false;
    @track isImageSelected = false;
    @track isVideoSelected = false;
    @track isDocumentSelected = false;
    @track isLocationSelected = false;
    @track comboboxValue;
    @track isCustomSelected = false;
    @track isWebsiteSelected = false;
    @track custom = [];
    @track websiteUrl = '';
    @track showVisitWebsite = false;
    @track showCustom = true;
    @track componentText = '';
    @track website = [];
    @track phnDetails = [];
    @track copyOffer = [];
    @track selectedItem;
    @track modalOpen = true;
    @track isCategory = false;

    @track isShowModal = false;


    connectedCallback() {   
        this.showModalBox();
    }

    showModalBox() {  
        this.isShowModal = true;
    }

    hideModalBox() {  
       
        //this.isShowModal = false;

        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'WhatsAppMetaTemplate__c',
                actionName: 'list'
            },
            state: {
                filterName: 'All' // Or any other list view API name
            }
        });
    }
    
    @track state = {
        name: '',
        language: 'en',
        category: '',
        components: [
        ]
    };


    get options() {
        return [
            { label: 'Marketing', value: 'Marketing' },
            { label: 'Utility', value: 'Utility' }
        ];
    }

    get language() {
        return this.state.language;
    }

    get category() {
        return this.state.category;
    }

    get headerType() {

        if (this.state.components.length > 0) {
            return this.state.components[0].type;
        }
        return '';
    }

    handleChange(event) {

        const field = event.target.name;
        const value = event.target.value;
        this.state.category=value;   
        
        let newState = { ...this.state };

        if (field === 'language' || field === 'category') {
            newState[field] = value;
        }
        this.state = newState;

        if (this.state.category !='') {
            this.isCategory = true;
            this.modalOpen = false;
        }else{
            this.isCategory = false;
        }

    }

    handleUtility(event) {
        const field = event.target.name;
        const value = event.target.value;
        this.state.category=value;   
        //this.modalOpen = false;
        let newState = { ...this.state };

        if (field === 'language' || field === 'category') {
            newState[field] = value;
        }
        this.state = newState;
        console.log('this.state.category = '+this.state.category);
        if (this.state.category !='') {
            this.isCategory = true;
            this.modalOpen = false;
        }else{
            this.isCategory = false;
        }
    }

    handleAuthentication(event) {
        const field = event.target.name;
        const value = event.target.value;
        this.state.category=value;   
        //this.modalOpen = false;
        let newState = { ...this.state };

        if (field === 'language' || field === 'category') {
            newState[field] = value;
        }
        this.state = newState;
        console.log('this.state.category = '+this.state.category);
        if (this.state.category !='') {
            this.isCategory = true;
            this.modalOpen = false;
        }else{
            this.isCategory = false;
        }
    }

    handleNameChange(event) {
        const field = event.target.name;
        console.log('field : ', field);

        // Remove leading and trailing spaces, replace remaining spaces with underscores, and convert to lowercase
        const value = event.target.value.trim().replace(/\s+/g, '_').toLowerCase();
        console.log('value  : ', value);

        if (field === 'name') {
            this.state = { ...this.state, [field]: value };
        }
    }

    handleFormatChange(event) {
        const field = event.target.name;
        const value = event.target.value;

        if (field === 'handleFormat' || field === 'headerText') {
            let newComponent;

            if (field === 'handleFormat') {
                this.isTextSelected = value === 'TEXT';
                this.isImageSelected = value === 'IMAGE';
                this.isVideoSelected = value === 'VIDEO';
                this.isDocumentSelected = value === 'DOCUMENT';
                this.isLocationSelected = value === 'LOCATION';

                newComponent = {
                    type: 'HEADER',
                    format: value,
                    text: this.state.components.find(comp => comp.type === 'HEADER')?.text || ''
                };
            } else if (field === 'headerText') {
                newComponent = {
                    type: 'HEADER',
                    format: this.state.components.find(comp => comp.type === 'HEADER')?.format || '',
                    text: value
                };
            }
            const components = this.state.components.filter(comp => comp.type !== 'HEADER');
            components.unshift(newComponent);

            this.state = {
                ...this.state,
                components
            };
        }
    }

    handleMediaUpload(event) {
        const file = event.target.files[0];
        const fieldName = event.target.name;

        if (file) {
            const reader = new FileReader();
            reader.onload = () => {
                const fileData = reader.result;
                let mediaType = '';

                switch (fieldName) {
                    case 'handleImageUpload':
                        mediaType = 'image';
                        break;
                    case 'document-upload':
                        mediaType = 'document';
                        break;
                    case 'video-upload':
                        mediaType = 'video';
                        break;
                    default:
                        mediaType = 'unknown';
                }

                const newComponent = {
                    type: 'HEADER',
                    format: 'media',
                    value: fileData
                };

                const components = [...this.state.components, newComponent];

                this.state = {
                    ...this.state,
                    components
                };
            };
            reader.readAsDataURL(file);
        }
    }

    handleBodyText(event) {
        const value = event.target.value;

        const newComponent = {
            type: 'BODY',
            text: value
        };

        const components = this.state.components.filter(comp => comp.type !== 'BODY');
        components.unshift(newComponent);

        this.state = {
            ...this.state,
            components
        };
    }

    handleFooterText(event) {
        const value = event.target.value;

        const newComponent = {
            type: 'FOOTER',
            text: value
        };

        const components = this.state.components.filter(comp => comp.type !== 'FOOTER');
        components.unshift(newComponent);

        this.state = {
            ...this.state,
            components
        };
    }

    handleCustomText(event) {
        var ind = event.target.dataset.index;
        this.custom[ind].text = event.target.value

        console.log('this.custom = ' + JSON.stringify(this.custom));
    }


    handleWebsiteChange(event) {
        var ind = event.target.dataset.index;
        var field = event.target.name;

        if (field === 'buttonText') {
            this.website[ind].text = event.target.value
        } else if (field === 'websiteUrl') {
            this.website[ind].url = event.target.value
            // }else if (field === 'handleurltype') {  

            //     this.website[ind].urlType=event.target.value

            //     if (value === 'Dynamic') {
            //         console.log('OUTPUT=====> : ',websiteComponent.urlType);
            //         this.website[ind].text='';
            //         this.website[ind].text='';
            //     }
        }

        console.log('this.website = ' + JSON.stringify(this.website));
    }

    handlePhoneChange(event) {

        var ind = event.target.dataset.index;
        var field = event.target.name;

        if (field === 'phoneCountryText') {
            this.phnDetails[ind].text = event.target.value
        } else if (field === 'handleCountryCode') {
            this.phnDetails[ind].country = event.target.value
        } else if (field === 'phoneCountryNumber') {

            this.phnDetails[ind].phone_number = event.target.value
        }

    }


    handleOfferChange() {
        var ind = event.target.dataset.index;
        this.copyOffer[ind].example = [event.target.value];
        console.log('this.copyOffer => ', JSON.stringify(this.copyOffer));
    }

    handleSave() {

        const nameInput = this.template.querySelector("input[name='name']");
        if (nameInput && nameInput.value.trim() === '') {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Failed',
                    message: 'Please fill in the required Name field',
                    variant: 'error'
                })
            );
            return;
        }


        console.log('OUTPUT : ', JSON.stringify(this.state));

        if (this.custom.length > 0 || this.website.length > 0 || this.phnDetails.length > 0 || this.copyOffer.length > 0) {
            var buttonsList = [];
            this.custom.forEach(item => {
                if (item.text != '') {
                    buttonsList.push(item);
                }
            });
            this.website.forEach(item => {
                if (item.text != '' || item.url != '') {
                    buttonsList.push(item);
                }
            });
            this.phnDetails.forEach(item => {
                if (item.text != '' || item.phone_number != '') {
                    buttonsList.push(item);
                }
            });
            this.copyOffer.forEach(item => {
                if (item.text != '') {
                    buttonsList.push(item);
                }
            });
            this.state.components.push({ "buttons": buttonsList, "type": "BUTTONS" });
        }
        createMetaTemplate({ body: JSON.stringify(this.state) })
            .then((result) => {
                console.log('result==>', result);
                if (result.isSuccess == true) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Template Created Successfully',
                            message: result.message,
                            variant: 'Success'
                        })
                    );
                }
                if (result.isSuccess == false) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Failed',
                            message: result.message,
                            variant: 'Error'
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
            });

        console.log('Saved Values:', JSON.stringify(this.state));

        setTimeout(() => {
            this.state = {
                name: '',
                language: 'en',
                category: '',
                components: [

                ]
            };
            this.isMarketing = false;
            this.isUtility = false;
            this.isTextSelected = false;
            this.isMediaSelected = false;
            this.isCustomSelected = false;
            this.isWebsiteSelected = false;
            this.custom = [];
            this.website = [];
            this.phnDetails = [];
            this.copyOffer = [];
            this.websiteUrl = '';
            this.modalOpen = false;
            console.log('OUTPUT : ', JSON.stringify(this.state));
            this.closeQuickAction();
        }, 5000);


    }



    handleClose() {
        this.closeQuickAction();
    }

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleAddCustom() {
        this.custom.push({ type: 'QUICK_REPLY', text: '' });
        console.log("call" + JSON.stringify(this.custom));

    }

    handleAddWebsite() {
        if (this.website.length < 2) {
            this.website.push({ type: 'URL', text: '', url: '' });
            console.log('im Here csllrf' + JSON.stringify(this.website));
        } else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Failed',
                    message: 'Can\'t add more than two website buttons',
                    variant: 'error'
                })
            );

        }
    }

    handleAddPhone() {
        if (this.phnDetails.length < 1) {
            console.log('im Here');
            this.phnDetails = [...this.phnDetails, { type: 'PHONE_NUMBER', text: '', phone_number: '+916568687687' }];
        } else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Failed',
                    message: 'Can\'t add more than one phone call button',
                    variant: 'error'
                })
            );

        }
    }

    handleAddOffer() {
        if (this.copyOffer.length < 1) {
            console.log('im Here');
            this.copyOffer = [...this.copyOffer, { type: 'COPY_CODE', text: 'Copy offer code', example: [] }];
        }
        else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Failed',
                    message: 'Can\'t add more than one offer button',
                    variant: 'error'
                })
            );

        }
    }

    handleRemoveCustom(event) {
        const index = parseInt(event.target.dataset.index, 10);
        this.custom = this.custom.filter((_, i) => i !== index);

    }

    handleRemoveWebsite(event) {
        const index = parseInt(event.target.dataset.index, 10);
        this.website = this.website.filter((_, i) => i !== index);

    }

    handleRemovePhn(event) {
        const index = parseInt(event.target.dataset.index, 10);
        this.phnDetails = this.phnDetails.filter((_, i) => i !== index);

    }

    handleRemoveOffer(event) {
        const index = parseInt(event.target.dataset.index, 10);
        this.copyOffer = this.copyOffer.filter((_, i) => i !== index);

    }

    handlePrevious() {
        this.state = {
            name: '',
            language: 'en',
            category: '',
            components: [

            ]
        };
        this.isCategory=false;
        this.isMarketing = false;
        this.isUtility = false;
        this.isTextSelected = false;
        this.isMediaSelected = false;
        this.isCustomSelected = false;
        this.isWebsiteSelected = false;
        this.custom = [];
        this.website = [];
        this.phnDetails = [];
        this.copyOffer = [];
        this.websiteUrl = '';

        this.modalOpen = true;
    }

}