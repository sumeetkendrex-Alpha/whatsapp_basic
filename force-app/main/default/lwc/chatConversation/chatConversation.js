import { LightningElement, wire, api, track } from 'lwc';
import getBusinessContacts from '@salesforce/apex/WhatsappConversationController.getBusinessContacts';
import getMessagingSession from '@salesforce/apex/ChatConversationController.getMessagingSessions';
import getTemplateJSON from '@salesforce/apex/WhatsappConversationController.getTemplateJSON';
import getWhatsAppMessages from '@salesforce/apex/ChatConversationController.getWhatsAppMessages';
import getWhatsAppUser from '@salesforce/apex/ChatConversationController.getWhatsAppUser';
import sendTextMessage from '@salesforce/apex/WhatsAppOutgoingMessage.sendTextMessage';
import getTaskPicklistValues from '@salesforce/apex/WhatsappConversationController.getTaskPicklistValues';
import getTemplatepicklistRecord from '@salesforce/apex/WhatsappConversationController.getTemplatepicklistRecord';
import createEndChatRecord from '@salesforce/apex/WhatsappConversationController.createEndChatRecord';
import sendMediaFile from '@salesforce/apex/WhatsAppOutgoingMessage.sendMediaFile';
import sentTick from '@salesforce/resourceUrl/sentTick';
import deliveredTick from '@salesforce/resourceUrl/deliveredTick';
import readTick from '@salesforce/resourceUrl/readTick';
import micIcon from '@salesforce/resourceUrl/mIcIcon';
import failedTick from '@salesforce/resourceUrl/failedTick';
import audioIcon from '@salesforce/resourceUrl/audioIcon';
import WhatsappChatslds from '@salesforce/resourceUrl/WhatsappChatslds';
import profileImage from '@salesforce/resourceUrl/profileImage';
import { loadStyle } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { subscribe } from 'lightning/empApi';

export default class ChatConversation extends (LightningElement) {
    @api recordId;
    @api objectApiName;
    messages = [];
    @track callOutString;
    @track customerData = [];
    @track customerName = '';
    @track phoneNumber = '';
    @track showEndChatPopup = false;
    @track showTemplatePopup = false;
    @track switchIcon = true;
    @track Type;
    @track sentTick = sentTick;
    @track deliveredTick = deliveredTick;
    @track readTick = readTick;
    @track failedTick = failedTick;
    @track BusinessContacts = [];
    @track businessNumber = '';
    @track micIcon = micIcon;
    @track chatContainerRef = '';
    @track profileImage = profileImage;
    @track showConversationPopup = false;
    @track showAttechmentPopup = false;
    @track WhatsappChatslds = WhatsappChatslds;
    @track ConversationExpiration = '';
    @track ConversationOrigin = '';
    @track PricingBillable = false;
    @track PricingCategory = '';
    @track PricingModel = '';
    @track timeCount;
    @track audioIcon = audioIcon;
    @track ChatEnded = [];
    @track isTemplateType;
    @track isPickList = false;
    @track isTemplate;
    @track subscription = false;
    @track isTemplateCategory = [
        { label: 'Marketing', value: 'Marketing' },
        { label: 'Utility', value: 'Utility' },
        { label: 'Authentication', value: 'Authentication' }
    ];
    @track selectedCategory;
    @track isTemplateOptions;
    istemplateName;
    @track isPriority;
    @track isStatus;
    @track isPriorityOptions;
    @track isStatusOptions;
    connectedCallback() {
        document.addEventListener('click', this.boundHandleOutsideClick.bind(this));
        getBusinessContacts()
            .then((result) => {
                console.log(JSON.stringify(result));
                this.BusinessContacts = result;
                this.businessNumber = this.BusinessContacts[0].Business_Number__c;
                console.log(this.businessNumber);
            })
            .catch((err) => {
                console.error(err);
            });


        //get customer chat by record id and business number
        setTimeout(() => {
            this.getAllConversation();
            this.getUseretails();
        }, 1000);


        // static stylesheet

        loadStyle(this, WhatsappChatslds)
            .then(() => {
                console.log('Styles loaded successfully');
            })
            .catch(error => {
                console.error('Error loading styles:', error);
            });

        if (!this.subscription) {
            const refreshCallback = function () {
                this.refreshChats();
                console.log('hello from refresh');

            }.bind(this);

            subscribe("/event/WhatsappRefresher__e", -1, refreshCallback).then(response => {
                this.subscription = true;
            });
        }
        // all picklist values
        // this.getPicklistValues();
        // this.getTemplatePicklistValues();
    }

    getUseretails() {
        getWhatsAppUser({ recordId: this.recordId, businessNumber: this.businessNumber })
            .then((result) => {
                console.log('getWhatsAppUser==>', JSON.stringify(result));
                this.customerName = result[0].CustomerName__c;
                this.phoneNumber = result[0].CustomerPhone__c;

            }).catch((err) => {

            });

    }

    scrollToBottom() {
        if (this.messages && this.messages.length > 0) {
            // Get the last message's ID
            const lastMessage = this.messages[this.messages.length - 1];
            const lastMessageId = lastMessage?.Id;
            console.log('lastMessageId==>', lastMessageId);

            if (lastMessageId) {
                setTimeout(() => {
                    // Use the data-id selector to locate the last message
                    const selector = `[data-id="${CSS.escape(lastMessageId)}"]`;
                    console.log('selector==>', selector);
                    const element = this.template.querySelector(selector);
                    console.log('element==>', element);
                    if (element) {
                        element.scrollIntoView();
                    } else {
                        console.error('Element not found for the provided data-id:', lastMessageId);
                    }
                }, .1); // Delay to ensure the DOM updates correctly
            }
        }
    }

    refreshChats() {
        refreshApex(this.messages);
        this.getAllConversation();
    }

    get options() {
        return this.BusinessContacts.map(contact => ({
            label: contact.MasterLabel,
            value: contact.Business_Number__c
        }));
    }

    handleChange(event) {
        this.businessNumber = event.detail.value;
        this.getAllConversation();
    }

    disconnectedCallback() {
        document.removeEventListener('click', this.boundHandleOutsideClick.bind(this));
    }

    boundHandleOutsideClick(event) {
        const popup = this.template.querySelector('.popsCls');
        if (this.showAttechmentPopup && popup && !popup.contains(event.target)) {
            this.showAttechmentPopup = false;
        }
    }

    getAllConversation() {
        this.handleMessagingSession();

        getWhatsAppMessages({ recordId: this.recordId, businessNumber: this.businessNumber })
            .then((result) => {
                if (result) {
                    this.messages = result.map(message => ({
                        ...message,
                        isInbound: message.MessageSendType__c === 'Inbound',
                        isOutbound: message.MessageSendType__c === 'Outbound',
                        isEndChat: message.MessageSendType__c === 'End Chat',
                        isText: message.MessageType__c === 'text',
                        isImage: message.MessageType__c === 'image',
                        isVideo: message.MessageType__c === 'video',
                        isAudio: message.MessageType__c === 'audio',
                        isDocument: message.MessageType__c === 'document',
                        isButton: message.MessageType__c === 'button',
                        isTemplate: message.MessageType__c === 'template',
                        isReaction: message.Reaction__c === 'reaction',
                        isOrder: message.MessageType__c === 'order',
                        isInteractive: message.MessageType__c === 'interactive',
                        isMessageSent: message.MessageStatus__c === 'sent',
                        isMessageDelivered: message.MessageStatus__c === 'delivered',
                        isMessageRead: message.MessageStatus__c === 'read',
                        isMessageFailed: message.MessageStatus__c === 'failed',
                        formattedDateTime: this.formatDateTime(message.MessageSentTime__c)
                    }));
                    console.log('direct name', this.messages[0].CustomerName__c);

                    setTimeout(() => {
                        this.customerName = this.messages[0].CustomerName__c;
                    }, 1000)
                    console.log('name in namevar', this.customerName);
                    this.phoneNumber = this.messages[0].CustomerPhone__c;
                    this.scrollToBottom();
                    console.log('this.messages==>', JSON.stringify(this.messages));
                } else if (error) {
                    console.error("Error fetching messages", error);
                }
            }).catch((err) => {

            });
    }

    formatDateTime(dateString) {
        const date = new Date(dateString);
        return date.toLocaleString('en-US', {
            year: 'numeric',
            month: 'long',
            day: 'numeric',
            hour: 'numeric',
            minute: '2-digit',
            hour12: true,
            timeZone: 'Asia/Kolkata'
        });
    }

    toggleConversationPopup() {
        this.showConversationPopup = !this.showConversationPopup;
    }

    togglePopup(event) {
        console.log('Method called button clicked')
        event.stopPropagation();
        this.showAttechmentPopup = true;
    }

    scrollToBottom() {
        if (this.messages && this.messages.length > 0) {
            // Get the last message's ID
            const lastMessage = this.messages[this.messages.length - 1];
            const lastMessageId = lastMessage?.Id;

            if (lastMessageId) {
                setTimeout(() => {
                    // Use the data-id selector to locate the last message
                    const selector = `[data-id="${CSS.escape(lastMessageId)}"]`;
                    const element = this.template.querySelector(selector);
                    if (element) {
                        element.scrollIntoView();
                    } else {
                        console.error('Element not found for the provided data-id:', lastMessageId);
                    }
                }, 2000); // Delay to ensure the DOM updates correctly
            }
        }
    }
    handleMessagingSession() {
        getMessagingSession({ recordId: this.recordId })
            .then((result) => {
                console.log('MessagingSession==>', JSON.stringify(result));
                if (!result || result.length === 0 || result[0].Status__c === 'Ended') {
                    this.isSessionEnded = true;
                    this.chatStatusToDisable = true;
                } else {
                    this.isSessionEnded = false;
                    this.chatStatusToDisable = true;

                }
            }).catch((err) => {

            });
    }

    handleimageUpload(event) {
        console.log('image==>');
        this.handleFileUpload(event.target.files[0], 'image');
    }

    handlePdfUpload(event) {
        console.log('pdf==>');
        this.handleFileUpload(event.target.files[0], 'document');
    }

    handleVideoUpload(event) {
        console.log('video==>');
        this.handleFileUpload(event.target.files[0], 'video');
    }

    handleAudioUpload(event) {
        console.log('audio==>');
        this.handleFileUpload(event.target.files[0], 'audio');
    }

    handleTemplateUpload(event) {
        console.log('template==>');
        this.showTemplatePopup = !this.showTemplatePopup;
        this.showAttechmentPopup = false;
    }
    handleFileUpload(file, fileType) {
        this.showAttechmentPopup = false;
        const reader = new FileReader();
        reader.onload = () => {
            const base64 = reader.result.split(',')[1];
            console.log('base64 => ', base64);
            const fileName = file.name;
            console.log(fileName);
            sendMediaFile({ fileName: fileName, base64Data: base64, bussinessPhoneNumber: this.businessNumber, Phone: this.phoneNumber, fileType: fileType, customerName: this.customerName })
                .then(result => {
                    this.showToast('Success', 'File Uploaded Successfully', 'success');
                    this.refreshChats();
                })
                .catch(error => {
                    // Handle error
                });

        };
        reader.readAsDataURL(file);
    }

    handleTemplateClose() {
        this.showTemplatePopup = false;
    }

    handleSendTemplate() {
        console.log('json method');
        const JsonBody = '{"messaging_product":"whatsapp","to":"' + this.phoneNumber + '","type":"' + 'template' + '","template":{"name":"' + this.isTemplate + '","language":{"code":"en"}}}';
        console.log('JsonBody==>', JsonBody);

        this.callOutString = this.phoneNumber + '@@' + this.businessNumber + '@@' + JsonBody + '@@' + 'template' + '@@' + this.customerName;
        console.log('callOutString==>', this.callOutString);
        sendTextMessage({ callOutString: this.callOutString })
            .then((result) => {
                console.log('Message sent successfully:', result);
            })
            .catch((error) => {
                console.error('Error in sendTextMessage Apex call:', error);

                // Show error toast
                this.showToast('Error', 'Failed to send the message. Please try again later.', 'error');
            });

        this.showTemplatePopup = false;
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }


    callSendMethod(event) {
        if (event.key == 'Enter') {
            this.sendMessageHandler();
        }
    }


    sendMessageHandler() {
        // Locate the input field and retrieve its value
        const inputField = this.template.querySelector('.send-input');
        const inputValue = inputField ? inputField.value.trim() : '';
        inputField.value = '';
        this.handleIconSwitch();
        if (!inputField) {
            console.error('Input field not found.');
            this.showToast('Error', 'Input field is missing from the DOM.', 'error');
            return;
        }

        // Check for empty message input
        if (!inputValue) {
            this.showToast('Message Empty', 'Please enter a message before sending.', 'warning');
            return;
        } else {
            this.type = 'text';
        }


        // Validate if a phone number is selected
        if (!this.phoneNumber) {
            this.showToast('No Recipient', 'Please select a customer to send the message.', 'error');
            return;
        }

        // Debug: Log the parameters being sent to the Apex method
        console.log('Sending message to:', this.phoneNumber, 'Message:', inputValue);

        // Call the Apex method to send the message
        this.callOutString = this.phoneNumber + '@@' + this.businessNumber + '@@' + inputValue + '@@' + this.type + '@@' + this.customerName;
        console.log('callOutString==>', this.callOutString);
        sendTextMessage({ callOutString: this.callOutString })
            .then((result) => {
                console.log('Message sent successfully:', result);

                // Clear the input field
                if (result == 'success') {
                    this.showToast('Message Sent', 'Your message has been sent successfully.', 'success');
                } else {
                    this.showToast('Failed!', result, 'error');
                }
                // Show success toast


            })
            .catch((error) => {
                inputField.value = '';
                console.log(inputField.value);
                console.error('Error in sendTextMessage Apex call:', error);

                // Show error toast
                this.showToast('Error', 'Failed to send the message. Please try again later.', 'error');
            });
    }

    handleIconSwitch() {
        console.log('Method Initialized');
        const inputValue = this.template.querySelector('.send-input')?.value || '';
        console.log('inputValue ==>', inputValue);

        if (!inputValue) {
            this.switchIcon = true;
        } else {
            this.switchIcon = false;
        }
    }

    handleEndChat() {
        this.showEndChatPopup = !this.showEndChatPopup;
    }

    handleEndChatSave() {
        const subject = this.template.querySelector('.subject').value;
        const status = this.template.querySelector('.status').value;
        const priority = this.template.querySelector('.priority').value;

        createEndChatRecord({
            subject: subject,
            status: status,
            priority: priority,
            businessPhoneNumber: this.businessNumber,
            Phone: this.phoneNumber
        }).then(
            (result) => {
                if (result == 'Success') {
                    this.showEndChatPopup = !this.showEndChatPopup;
                    this.showToast('Success', 'success', 'Chat has been ended successfully');
                } else {
                    this.showToast('Error', 'error', 'Chat can not be end');
                    throw new Error('Error');
                }
            }
        ).catch(
            error => {
                this.showToast('Error', 'error', 'Error While Ending Chat');
            }
        );
    }

    getPicklistValues() {
        getTaskPicklistValues({ objectName: 'Task', fieldName: 'Priority' }).then(result => {
            console.log('Picklist Values:', result);
            this.isPriorityOptions = result.map(option => ({
                label: option,
                value: option
            }));
            this.isPriority = this.isPriorityOptions[0].value;
            console.log('this.isPriority==>', this.isPriority);
        }).catch(error => {
            console.error(error);
        });

        getTaskPicklistValues({ objectName: 'Task', fieldName: 'Status' }).then(result => {
            console.log('Picklist Values:', result);
            this.isStatusOptions = result.map(option => ({
                label: option,
                value: option
            }));
            this.isStatus = this.isStatusOptions[0].value;
            console.log('this.isStatus==>', this.isStatus);
        }).catch(error => {
            console.error(error);
        });

        getTaskPicklistValues({ objectName: 'MetaTemplates__mdt', fieldName: 'Template_Type__c' }).then(result => {
            console.log('Picklist Values:', result);
            this.isTemplateTypeOptions = result.map(option => ({
                label: option,
                value: option
            }));
            this.isTemplateType = this.isTemplateTypeOptions[0].value;
            console.log('this.isTemplate==>', this.isTemplateType);
        }).catch(error => {
            console.error(error);
        });
    }


    get statusOptions() {
        return this.isStatusOptions;
    }

    handleStatusChange(event) {
        this.isStatus = event.detail.value;
        console.log('this.isStatus==>', this.isStatus);
    }

    // get templateTypeOptions() {
    //     return this.isTemplateTypeOptions;
    // }

    // get templateOptions() {
    //     return this.isTemplateOptions;
    // }



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

        // this.getTemplatePicklistValues();
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

        getTemplateJSON({ templateName: this.isTemplate })
            .then((result) => {
                console.log('result===>', result);
                this.templateJson = result;

            }).catch((err) => {

            });
        console.log('this.isTemplate==>', this.isTemplate);
    }

    get priorityOptions() {
        return this.isPriorityOptions;
        console.log('this.isPriority==>', this.isPriority);
    }

    handlePriorityChange(event) {
        this.isPriority = event.detail.value;
    }

    toggleActive(event) {
        const circleElement = event.currentTarget;
        if (circleElement.classList.contains('active')) {
            circleElement.classList.remove('active');
            this.stopRecording();
        } else {
            circleElement.classList.add('active');
            this.startRecording();
        }
    }

    startRecording() {
        navigator.mediaDevices.getUserMedia({ audio: true })
            .then(stream => {
                this.mediaRecorder = new MediaRecorder(stream, { mimeType: 'audio/webm' });
                this.audioChunks = [];
                this.mediaRecorder.addEventListener('dataavailable', event => this.audioChunks.push(event.data));
                this.mediaRecorder.start();
            })
            .catch(error => {
                console.error('Error accessing microphone:', error);
            });
    }

    stopRecording() {
        if (this.mediaRecorder && this.mediaRecorder.state !== 'inactive') {
            this.mediaRecorder.stop();
            this.mediaRecorder.addEventListener('stop', () => {
                const audioBlob = new Blob(this.audioChunks, { type: 'audio/ogg' });
                const reader = new FileReader();
                reader.readAsDataURL(audioBlob);
                reader.onloadend = () => {
                    const base64Audio = reader.result.split(',')[1];
                    this.uploadAudio(base64Audio);
                };
            });
        }
    }

    uploadAudio(base64Audio) {
        const fileName = this.customerName + '.wav';
        const fileType = 'audio';
        console.log('fileName==>', fileName);
        console.log('base64Audio==>', base64Audio);
        console.log('fileType==>', fileType);
        console.log('this.businessNumber==>', this.businessNumber);
        console.log('this.phoneNumber==>', this.phoneNumber);
        console.log('this.customerName==>', this.customerName);

        sendMediaFile({ fileName: fileName, base64Data: base64Audio, bussinessPhoneNumber: this.businessNumber, Phone: this.phoneNumber, fileType: fileType, customerName: this.customerName })
            .then((result) => {
                console.log('Audio file saved successfully!' + result);
                this.showToast('Success', 'File Uploaded Successfully', 'success');
                //this.contentVersionId = result;
            })
            .catch(error => {
                console.error('Error saving audio file:', error);
            });
    }
}