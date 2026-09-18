import { LightningElement, track, wire, api } from 'lwc';

import getBusinessContacts from '@salesforce/apex/WhatsappConversationController.getBusinessContacts';
import getMessagingSession from '@salesforce/apex/WhatsappConversationController.getMessagingSessions';
import getTemplateJSON from '@salesforce/apex/WhatsappConversationController.getTemplateJSON';
import getAgetview from '@salesforce/apex/WhatsappConversationController.getAgetview';
import getAllConversationByContact from '@salesforce/apex/WhatsappConversationController.getAllConversationByContact';
import getAllConversationDetailByPhone from '@salesforce/apex/WhatsappConversationController.getAllConversationDetailByPhone';
import createNewWhatsapp from '@salesforce/apex/WhatsappConversationController.createNewWhatsapp';
import sendMediaFile from '@salesforce/apex/WhatsAppOutgoingMessage.sendMediaFile';
import getTemplatepicklistRecord from '@salesforce/apex/WhatsappConversationController.getTemplatepicklistRecord';
import sendTextMessage from '@salesforce/apex/WhatsAppOutgoingMessage.sendTextMessage';
import createEndChatRecord from '@salesforce/apex/WhatsappConversationController.createEndChatRecord';
import profileImage from '@salesforce/resourceUrl/profileImage';
import audioIcon from '@salesforce/resourceUrl/audioIcon';
import sentTick from '@salesforce/resourceUrl/sentTick';
import deliveredTick from '@salesforce/resourceUrl/deliveredTick';
import readTick from '@salesforce/resourceUrl/readTick';
import micIcon from '@salesforce/resourceUrl/mIcIcon';
import failedTick from '@salesforce/resourceUrl/failedTick';
import { subscribe } from 'lightning/empApi';
import { loadStyle } from 'lightning/platformResourceLoader';
import WhatsappConversationslds from '@salesforce/resourceUrl/WhatsappConversationslds';
import getWhatsAppMessages from '@salesforce/apex/WhatsappConversationController.getWhatsAppMessages';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import createTask from '@salesforce/apex/WhatsappConversationController.createTask';
import userTaskData from '@salesforce/apex/WhatsappConversationController.userTaskData';
import saveAllTagsData from '@salesforce/apex/WhatsappConversationController.saveAllTagsData';
import getSavedTags from '@salesforce/apex/WhatsappConversationController.getSavedTags';
export default class WhatsappConversationUtility extends LightningElement {
    @track isMobile = false;
    @track handleMobile = true;
    @track BusinessContacts = [];
    @track conversations = [];
    @track isMobileBack = false;
    @track error;
    activeContact;
    @track recordId;
    @track showTemplatePopup = false;
    @track showRecordForm = false;
    @track audioIcon = audioIcon;
    @track showAttechmentPopup = false;
    @track switchIcon = true;
    @track type;
    @track isLoading = false;
    @track allDataLoaded = false;
    @track chatStatusToDisable = false;
    @track isLoadingConvo = false;
    @track subscription = false;
    @track newContactNumber;
    @api isGroupChat = false;
    @track customerData = [];
    @track showConversationPopup = false;
    @track businessName = '';
    @track value = '';
    @track callOutString = '';
    @track micIcon = micIcon;
    @track sentTick = sentTick;
    @track deliveredTick = deliveredTick;
    @track readTick = readTick;
    @track failedTick = failedTick;
    @track isPickList = false;
    @track count = '1';
    @track WhatsappConversationslds = WhatsappConversationslds;
    @track phoneNumber = '';
    @track customerName = '';
    @track MessageStatus = '';
    @track ConversationExpiration = '';
    @track ConversationOrigin = '';
    @track PricingBillable = false;
    @track PricingCategory = '';
    @track PricingModel = '';
    @track timeCount;
    @track showEndChatPopup = false;
    @track ChatEnded = [];
    @track isPriorityOptions;
    @track isStatusOptions;
    @track isTemplateCategory = [
        { label: 'Marketing', value: 'Marketing' },
        { label: 'Utility', value: 'Utility' },
        { label: 'Authentication', value: 'Authentication' }
    ];
    @track selectedCategory;
    @track isTemplateOptions;
    istemplateName;
    templateJson;
    @track isPriority;
    @track isStatus;
    @track isTemplateType;
    @track contactLimit = 100;
    @track contactOffset = 0;
    @track allConversations = [];
    @track isTemplate;
    messages = [];
    @track profileImage = profileImage;
    @track refreshConversation = false;
    @track isSessionEnded = false;
    @track userId = '';
    @track tags = [];
    @track isParent = false;
    connectedCallback() {


        this.refreshConversation = false;
        document.addEventListener('click', this.boundHandleOutsideClick.bind(this));
        document.addEventListener('click', this.boundOutsideConversationClick);
        if (innerWidth <= 480) {
            setTimeout(() => {
                if (!this.isMobile) {
                    this.isMobileBack = true;
                    const chatSection = this.template.querySelector('.chat-section') || '';
                    console.log('chatSection=>', chatSection);
                    if (chatSection) {
                        chatSection.classList.add('display-none');
                    }
                }
            }, 1000);
        }
        if (!this.subscription) {
            const refreshCallback = function () {
                console.log('Refresh event received - starting smooth refresh');

                // Store scroll position if needed
                const scrollContainer = this.template.querySelector('.contacts-list');
                const scrollPosition = scrollContainer ? scrollContainer.scrollTop : 0;

                // Use requestAnimationFrame for smoother UI updates
                requestAnimationFrame(() => {
                    // Reset state but preserve existing data temporarily
                    const oldConversations = [...this.conversations];
                    this.contactOffset = 0;
                    this.allDataLoaded = false;
                    // this.isLoadingConvo = true;
                    this.refreshChats();

                    // // Show loading indicator smoothly
                    // this.conversations = oldConversations.map(c => ({...c, isLoading: true}));

                    // Small delay to allow UI to show loading state
                    setTimeout(() => {
                        getAllConversationByContact({
                            businessPhoneNumber: this.value,
                            contactLimit: this.contactLimit,
                            contactOffset: 0
                        }).then(data => {
                            // Process new data
                            const newContacts = data.map(contact => ({
                                ...contact,
                                badgeClass: contact.unreadCount > 0 ? 'agentView active' : 'agentView inactive',
                                showBadge: contact.unreadCount > 0
                            })).sort((a, b) => new Date(b.latestDateTime__c) - new Date(a.latestDateTime__c));

                            // Smooth transition to new data
                            requestAnimationFrame(() => {
                                this.conversations = newContacts;
                                this.allConversations = [...newContacts];
                                this.isLoadingConvo = false;

                                // Restore scroll position if needed
                                if (scrollContainer) {
                                    scrollContainer.scrollTop = scrollPosition;
                                }

                                console.log('Smooth refresh completed');
                            });
                        }).catch(error => {
                            console.error('Refresh error:', error);
                            // Revert to old data if refresh fails
                            this.conversations = oldConversations;
                            this.isLoadingConvo = false;
                        });
                    }, 100);
                });
            }.bind(this);

            subscribe("/event/WhatsappRefresher__e", -1, (response) => {

    console.log('Event received => ', response);

    const eventOwnerId =
        response?.data?.payload?.OwnerId__c;

    // Refresh only if current user is owner
    if (eventOwnerId === USER_ID) {
        console.log('Refreshing for current user');

        this.contactOffset = 0;
        this.allDataLoaded = false;
        this.refreshChats();
    } else {
        console.log('Event ignored');
    }

}).then(() => {
    this.subscription = true;
});
        }
        // this.isLoadingConvo = true;
        // this.isLoading = true;
        getBusinessContacts()
            .then((result) => {
                this.isLoadingConvo = false;
                console.log(JSON.stringify(result));
                this.BusinessContacts = result;
                this.value = this.BusinessContacts[0].Business_Number__c;
                this.handlegetAllContacts();
                this.newContactNumber = this.BusinessContacts[0].Business_Number__c;
                console.log(this.value);
                this.businessName = this.BusinessContacts[0].MasterLabel;
                console.log(this.businessName);
                this.isLoading = false;
            })
            .catch((err) => {
                this.isLoadingConvo = false;
                console.error(err);
                this.isLoading = false;
            });

        loadStyle(this, WhatsappConversationslds)
            .then(() => {
                console.log('Styles loaded successfully');
            })
            .catch(error => {
                console.error('Error loading styles:', error);
            });

        // this.getPicklistValues();
        //  this.getTemplatePicklistValues();

        // this.updateTimeCount();
        // this.interval = setInterval(() => this.updateTimeCount(), 60000);
        // document.addEventListener('click', this.handleScreenClick);



    }

    disconnectedCallback() {
        document.removeEventListener('click', this.boundHandleOutsideClick.bind(this));
        document.removeEventListener('click', this.boundOutsideConversationClick);

    }



    boundHandleOutsideClick(event) {
        if (this.showAttechmentPopup && !this.template.querySelector('.popsCls').contains(event.target)) {
            this.showAttechmentPopup = false;
        }
    }

    boundOutsideConversationClick = this.handleOutsideConversationClick.bind(this);

    handleOutsideConversationClick(event) {
        const popup = this.template.querySelector('.ConvesationPopup');
        const icon = this.template.querySelector('.dotIcon');
        if (
            this.showConversationPopup &&
            popup &&
            !popup.contains(event.target) &&
            !icon.contains(event.target)
        ) {
            this.showConversationPopup = false;
        }
    }

    refreshChats() {
        refreshApex(this.conversations);
        this.handleMessageChange();

    }

    /* updateTimeCount() {
         console.log('Hello count');
         const expireDateString = this.ConversationExpiration;
 
         const expireDate = new Date(
             expireDateString.replace(
                 /(\d{2})\/(\d{2})\/(\d{4}),\s(\d{1,2}):(\d{2})\s(am|pm)/i,
                 (_, day, month, year, hour, minute, period) => {
                     // Adjust hours for AM/PM format
                     const hours =
                         parseInt(hour) +
                         (period.toLowerCase() === "pm" && hour !== "12" ? 12 : 0) -
                         (period.toLowerCase() === "am" && hour === "12" ? 12 : 0);
                     return `${year}-${month}-${day}T${String(hours).padStart(2, "0")}:${minute}:00`;
                 }
             )
         );
         const now = Date.now();
         const timeDifference = expireDate - now;
         const days = Math.floor(timeDifference / (1000 * 60 * 60 * 24));
         const hours = Math.floor((timeDifference % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
         const minutes = Math.floor((timeDifference % (1000 * 60 * 60)) / (1000 * 60));
 
         if ((isNaN(days) || days <= 0) && (isNaN(hours) || hours <= 0) && (isNaN(minutes) || minutes <= 0)) {
             this.timeCount = 'expired';
         } else {
             this.timeCount = `${days} days ${hours} hours ${minutes} minutes`;
         }
 
     } */

    async handlegetAllContacts() {
        if (this.isLoadingConvo || this.allDataLoaded) return;

        this.isLoadingConvo = true;
        console.log('Loading contacts, offset:', this.contactOffset);

        try {
            const data = await getAllConversationByContact({
                businessPhoneNumber: this.value,
                contactLimit: this.contactLimit,
                contactOffset: this.contactOffset
            });

            if (data.length < this.contactLimit) {
                this.allDataLoaded = true;
            }

            // Create new array with fresh references
            const newContacts = data.map(contact => ({
                ...contact,
                badgeClass: contact.unreadCount > 0 ? 'agentView active' : 'agentView inactive',
                showBadge: contact.unreadCount > 0
            })).sort((a, b) => new Date(b.latestDateTime__c) - new Date(a.latestDateTime__c));

            // Use concat instead of spread operator for better reactivity
            this.conversations = this.conversations.concat(newContacts);

            // Create new reference for allConversations
            this.allConversations = this.conversations.slice();

            this.contactOffset += this.contactLimit;
            this.error = undefined;

            console.log('Loaded', newContacts.length, 'new contacts');
        } catch (error) {
            console.error('Error loading contacts:', error);
            this.error = error;
            this.conversations = []; // Reset on error
        } finally {
            this.isLoadingConvo = false;
            // Force update if needed
            this.dispatchEvent(new CustomEvent('update'));
        }
    }

    handleScroll(event) {
        // Get the scrollable element (make sure this is the correct one)
        const element = event.currentTarget;

        // Calculate scroll position
        const scrollTop = element.scrollTop;
        const scrollHeight = element.scrollHeight;
        const clientHeight = element.clientHeight;
        const scrollThreshold = 50; // pixels from bottom

        // Check if near bottom
        if (scrollTop + clientHeight + scrollThreshold >= scrollHeight) {
            // Cancel any pending debounced calls
            if (this.scrollDebounce) {
                clearTimeout(this.scrollDebounce);
            }

            // Only load if not already loading and more data exists
            if (!this.isLoadingConvo && !this.allDataLoaded) {
                console.log('Loading more contacts...');
                this.handlegetAllContacts();
            }
        }
    }

    handleEndChat() {
        console.log('hancleEndChat', this.value, this.phoneNumber);
        createEndChatRecord({ businessPhoneNumber: this.value, customerPhone: this.phoneNumber })
            .then((result) => {
                console.log('result', result);
                location.reload();
            }).catch((err) => {

            });
        this.showEndChatPopup = !this.showEndChatPopup;
    }

    showGroupPopup() {
        this.isGroupChat = !this.isGroupChat;
    }

    /*handleEndChatSave() {
        const subject = this.template.querySelector('.subject').value;
        const status = this.template.querySelector('.status').value;
        const priority = this.template.querySelector('.priority').value;

        createEndChatRecord({subject: subject,
            status: status,
            priority: priority,
            businessPhoneNumber: this.value,
            Phone: this.phoneNumber
        }).then(
            (result) => {
                if (result == 'Success') {
                    this.showEndChatPopup = !this.showEndChatPopup;
                    this.showToast('Success', 'Chat has been ended successfully', 'success');
                } else {
                    this.showToast('Error', 'Chat can not be end', 'error');
                    throw new Error('Error');
                }
            }
        ).catch(
            error => {
                this.showToast('Error', 'Error While Ending Chat', 'error');
            }
        );
    } */


    @wire(getAllConversationDetailByPhone, { businessPhoneNumber: '$value', Phone: '$phoneNumber' })
    wiredConversationDetails({ data, error }) {
        if (data) {
            console.log('Received data:', data);
            this.customerData = data[0];
            if (this.customerData) {
                this.ConversationExpiration = this.customerData.ConversationExpiration__c || 'N/A';
                this.ConversationOrigin = this.customerData.ConversationOrigin__c || 'N/A';
                this.PricingModel = this.customerData.PricingModel__c || 'N/A';
                this.PricingCategory = this.customerData.PricingCategory__c || 'N/A';
                this.PricingBillable = this.customerData.PricingBillable__c || false;
                // this.chatStatusToDisable = this.customerData.ChatActivityStatus__c || false;
                this.chatStatusToDisable = true;


            } else {
                console.warn('No customer data available.');
            }
        } else if (error) {
            this.error = error; // Store the error if one occurs
            console.error('Error fetching conversation details:', error);
        }
    }

    handleRecordForm() {
        this.customerName = '';
        this.showRecordForm = !this.showRecordForm;

    }

    handleFormSave() {
        this.isLoading = true;
        const customerName = this.template.querySelector('.slds-modal__content .customerName').value;
        const customerPhone = this.template.querySelector('.slds-modal__content .customerPhone').value;

        createNewWhatsapp({
            businessPhoneNumber: this.newContactNumber,
            customerName: customerName,
            customerPhone: customerPhone
        })
            .then((result) => {
                var data = JSON.parse(result);
                if (data[0] === 'Success') {
                    this.showToast('Record Created', 'Your record has been created successfully.', 'success');

                    // Create the new contact with the correct structure
                    let newUserData = {
                        user: {  // Nest the properties under 'user'
                            "Id": data[1],
                            "CustomerName__c": data[2],
                            "CustomerPhone__c": data[3],
                            "BusinessNumber__c": null,
                            "latestDateTime__c": new Date().toISOString() // Add timestamp if needed
                        },
                        badgeClass: 'agentView inactive', // Default badge state
                        showBadge: false,
                        unreadCount: 0
                    };

                    console.log('newUserData==>', JSON.stringify(newUserData));

                    // Add to beginning of arrays
                    this.conversations.unshift(newUserData);
                    this.allConversations.unshift(newUserData);
                    this.showRecordForm = !this.showRecordForm;
                } else if (result == 'Provide Complete Details') {
                    this.showToast('Warning', 'You can not create record, provide complete details.', 'warning');
                } else {
                    this.showToast('Error', result, 'error');
                }
                this.isLoading = false;
            })
            .catch((err) => {
                console.error(err);
                this.isLoading = false;
            });
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
                }, .1); // Delay to ensure the DOM updates correctly
            }
        }
    }

    togglePopup(event) {
        console.log('Method called button clicked')
        event.stopPropagation();
        this.showAttechmentPopup = !this.showAttechmentPopup;
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
        const fileType = 'audio'
        sendMediaFile({ fileName: fileName, base64Data: base64Audio, bussinessPhoneNumber: this.value, Phone: this.phoneNumber, fileType: fileType, customerName: this.customerName })
            .then((result) => {
                console.log('Audio file saved successfully!' + result);
                this.showToast('Success', 'File Uploaded Successfully', 'success');
                this.refreshChats();
                this.contentVersionId = result;
            })
            .catch(error => {
                console.error('Error saving audio file:', error);
            });
    }

    toggleConversationPopup(event) {
        event.stopPropagation();
        this.showConversationPopup = !this.showConversationPopup;
    }

    handleItemClick(event) {
        const selectedItem = event.target.dataset.item;
        console.log('Selected Item:', selectedItem);
        this.togglePopup(); // Close popup
    }

    handleIconSwitch() {
        this.showConversationPopup = false;
        this.showAttechmentPopup = false;
        console.log('Method Initialized');
        const inputValue = this.template.querySelector('.send-input')?.value || '';
        console.log('inputValue ==>', inputValue);

        if (!inputValue) {
            this.switchIcon = true;
        } else {
            this.switchIcon = false;
        }
    }

    handleHeaderChange() {
        if (this.count) {
            this.isPickList = true;
            this.count = 0;
        } else {
            this.isPickList = false;
            this.count = 1;
        }
    }

    handleBackButton() {
        if (innerWidth <= 480) {
            if (!this.isMobile) {
                if (this.activeContact) {
                    this.activeContact.classList.remove('active-contact');
                }
                const contactsSection = this.template.querySelector('.contacts-section') || '';
                console.log('contact Section=>', contactsSection);
                if (contactsSection) {
                    contactsSection.classList.remove('display-none');
                }
                const chatSection = this.template.querySelector('.chat-section') || '';
                console.log('chatSection=>', chatSection);
                if (chatSection) {
                    chatSection.classList.add('display-none');
                }
            }

            this.isMobile = true;
        }
    }

    handleMessageChange() {
        if (innerWidth <= 480) {
            this.isMobile = false;

            if (!this.isMobile) {
                const contactsSection = this.template.querySelector('.contacts-section') || '';
                console.log('contact Section=>', contactsSection);
                if (contactsSection) {
                    contactsSection.classList.add('display-none');
                }
                const chatSection = this.template.querySelector('.chat-section') || '';
                console.log('chatSection=>', chatSection);
                if (chatSection) {
                    chatSection.classList.remove('display-none');
                }
            }
        }
        //this.isLoading = true;
        getWhatsAppMessages({ PhoneNumber: this.phoneNumber, bussinessPhoneNumber: this.value })
            .then((data) => {
                console.log('call with refresh');
                if (data) {
                    this.messages = data.map(message => ({
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
                        formattedDateTime: this.formatDateTime(message.MessageSentTime__c),
                        templateButtons: this.generateButtons(message.TemplateButtonText__c),
                        isTemplateTypeText: message.TemplateHeaderType__c === 'text',
                        isTemplateTypeImage: message.TemplateHeaderType__c === 'image',
                        isTemplateTypeVideo: message.TemplateHeaderType__c === 'video',
                        isTemplateTypeAudio: message.TemplateHeaderType__c === 'audio',
                        isTemplateTypeDocument: message.TemplateHeaderType__c === 'document',
                        isParent: message.ParentMessageID__c != null
                    }));
                    console.log('new messsages==>', JSON.stringify(this.messages));

                    this.scrollToBottom();
                }
                this.isLoading = false;
            }).catch((error) => {
                this.isLoading = false;
                console.error("Error fetching messages", error);
            })
    }

    handleMessagingSession() {
        getMessagingSession({ PhoneNumber: this.phoneNumber, bussinessPhoneNumber: this.value })
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

    handleAgentView() {
        getAgetview({ PhoneNumber: this.phoneNumber, bussinessPhoneNumber: this.value })
            .then((result) => {
                console.log('handleAgentViewResult==>', JSON.stringify(result));

                // Update the conversations array with the new agent view data
                this.conversations = this.conversations.map(convo => {
                    // Check if this is the current conversation
                    if (convo.user.CustomerPhone__c === this.phoneNumber &&
                        convo.user.BusinessNumber__c === this.value) {

                        // Update the badge status based on the result
                        const hasUnread = result && result.length > 0 && result[0].ViewedByAgent__c === false;

                        return {
                            ...convo,
                            badgeClass: hasUnread ? 'agentView active' : 'agentView inactive',
                            showBadge: hasUnread,
                            unreadCount: hasUnread ? (convo.unreadCount || 1) : 0
                        };
                    }
                    return convo;
                });

                // Force a refresh of the template by creating a new array reference
                this.conversations = [...this.conversations];

            }).catch((err) => {
                console.error('Error in handleAgentView:', err);
            });
    }

    /*async handlegetAgetviewCount() {
        console.log('on select handle refresh whole data');
        try {
            const result = await getAgetviewCount({ businessPhoneNumber: this.value });

            const agentViewCounts = {};

            result.forEach(item => {
                if (!item.CustomerPhone__c || !item.BusinessPhoneNumber__c) return;

                const key = `${item.CustomerPhone__c}__${item.BusinessPhoneNumber__c}`;

                if (!agentViewCounts[key]) {
                    agentViewCounts[key] = 0;
                }

                if (item.ViewedByAgent__c === false) {
                    agentViewCounts[key] += 1;
                }
            });

            this.conversations = this.conversations.map(convo => {
                const key = `${convo.CustomerPhone__c}__${convo.BusinessNumber__c}`;
                const count = agentViewCounts[key] || 0;

                return {
                    ...convo,
                    agentViewCount: count,
                    agentViewClass: count > 0 ? 'agentView active' : 'agentView inactive',
                    agentViewDisplay: count > 0 ? count : ''
                };
            });

            await this.handlegetAllContacts();

            console.log('Updated conversations with agentViewCount:', JSON.stringify(this.conversations));

            // Refresh after 30 seconds (optional)
            //setTimeout(() => this.handlegetAgetviewCount(),30000);

        } catch (err) {
            console.error('Error fetching view count', err);
        }
    } */




    generateButtons(buttonString) {
        if (!buttonString) {
            return [];
        }

        return buttonString
            .split(',')
            .map(item => item.trim())
            .filter(item => item); // remove empty strings
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

    handleContactSearch() {
        const inputField = this.template.querySelector('.search-input');
        const inputValue = inputField ? inputField.value.trim().toLowerCase() : '';
        this.customerName = '';
        this.showConversationPopup = false;
        this.showAttechmentPopup = false;
        console.log('inputField =>', this.allConversations);
        console.log('inputValue =>', inputValue);
        console.log('all - ', JSON.stringify(this.conversations));
        console.log('loaded - ', JSON.stringify(this.allConversations));
        if (this.allConversations && inputValue) {
            this.conversations = this.conversations.filter(item => {
                return (
                    item.user.CustomerName__c?.toLowerCase().includes(inputValue) ||
                    item.user.CustomerPhone__c?.toLowerCase().includes(inputValue) ||
                    item.user.BusinessNumber__c?.toLowerCase().includes(inputValue)
                );
            });
        } else {
            console.log('Resetting to all conversations.');
            this.conversations = [...this.allConversations];
        }
    }


    getCustomerPhoneNumber(event) {

        console.log('this.customer -->> ', JSON.stringify(this.conversations));
        const { name, phone, id } = event.currentTarget.dataset;
        this.customerName = name;
        this.phoneNumber = phone;
        this.userId = id;
        console.log('userId is', this.userId);
        this.handleMessageChange();

        this.handleMessagingSession();

        this.handleAgentView();

        if (this.activeContact) {
            this.activeContact.classList.remove('active-contact');
        }
        this.showConversationPopup = false;
        this.showAttechmentPopup = false;

        // Identify the new active contact element
        this.activeContact = this.template.querySelector(`[data-id="${this.phoneNumber}"]`);
        if (this.activeContact) {
            this.activeContact.classList.add('active-contact');
        } else {
            console.error('Active contact element not found for phone:', this.phoneNumber);
        }

        // setTimeout(() => { this.handlegetAgetviewCount(); }, 1000)


    }


    get options() {
        return this.BusinessContacts.map(contact => ({
            label: contact.MasterLabel,
            value: contact.Business_Number__c
        }));
    }

    /*  getPicklistValues() {
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
              this.isTemplateType = '---None---';
              console.log('this.isTemplate==>', this.isTemplateType);
          }).catch(error => {
              console.error(error);
          });
      }
  */

    get statusOptions() {
        return this.isStatusOptions;
    }

    handleStatusChange(event) {
        this.isStatus = event.detail.value;
        console.log('this.isStatus==>', this.isStatus);
    }

    //    get templateTypeOptions() {
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
                // console.log('result===>', result);
                this.templateJson = result;
                console.log('this.templateJson===>', this.templateJson);


            }).catch((err) => {

            });
        console.log('this.isTemplate==>', this.isTemplate);
    }


    get priorityOptions() {
        return this.isPriorityOptions;
    }

    handlePriorityChange(event) {
        this.isPriority = event.detail.value;
    }

    handleChange(event) {
        this.value = event.detail.value;
        const selectedOption = this.options.find(option => option.value === this.value);
        this.customerName = false;
        this.showConversationPopup = false;
        this.contactOffset = 0;
        this.allDataLoaded = false;
        this.showAttechmentPopup = false;
        this.businessName = selectedOption ? selectedOption.label : 'CRM College';
        console.log('this.businessName ==>', this.businessName);
        this.conversations = [];
        this.handlegetAllContacts();

    }

    handleComboboxChange(event) {
        this.newContactNumber = event.detail.value;
        console.log('this.newContactNumber==>', this.newContactNumber);
    }

    callSendMethod(event) {
        if (event.key == 'Enter') {
            this.sendMessageHandler();
        }
    }

    get hasConversations() {
        return this.conversations && this.conversations.length > 0; // Check if conversations exist

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
        this.callOutString = this.phoneNumber + '@@' + this.value + '@@' + inputValue + '@@' + this.type + '@@' + this.customerName;
        // this.isLoading = true;
        console.log('callOutString==>', this.callOutString);
        sendTextMessage({ callOutString: this.callOutString })
            .then((result) => {
                console.log('Message sent successfully:', result);
                // this.isLoading = false;
                // Clear the input field
                if (result == 'success') {
                    // this.handleMessageChange();
                    // this.showToast('Message Sent', 'Your message has been sent successfully.', 'success');
                } else {
                    this.showToast('Failed!', result, 'error');
                }
                // Show success toast


            })
            .catch((error) => {
                this.isLoading = false;
                inputField.value = '';
                console.log(inputField.value);
                console.error('Error in sendTextMessage Apex call:', error);

                // Show error toast
                this.showToast('Error', 'Failed to send the message. Please try again later.', 'error');
            });
    }


    // file upload 

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
        if (!file || !(file instanceof Blob)) {
            console.error('Invalid file object');
            return;
        }
        this.showAttechmentPopup = false;
        const reader = new FileReader();
        reader.onload = () => {
            const base64 = reader.result.split(',')[1];
            const fileName = file.name;
            console.log(fileName);
            sendMediaFile({ fileName: fileName, base64Data: base64, bussinessPhoneNumber: this.value, Phone: this.phoneNumber, fileType: fileType, customerName: this.customerName })
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
        this.selectedCategory = null;
        this.isTemplateType = null;
        this.isTemplate = null;
        this.isTemplateOptions = [];
        this.istemplateName = [];
        this.showTemplatePopup = false;

    }

    handleSendTemplate() {
        console.log('Send Template Method called');
         //const JsonBody = '{"messaging_product":"whatsapp","to":"' + this.phoneNumber + '","type":"' + 'template' + '","template":{"name":"' + this.isTemplate + '","language":{"code":"en"}}}';
      
        const JsonBody = JSON.parse(this.templateJson);
        JsonBody.to = this.phoneNumber;

        console.log('JsonBody==>', JsonBody);
        this.isLoading = true;
        this.callOutString = this.phoneNumber + '@@' + this.value + '@@' + JSON.stringify(JsonBody) + '@@' + 'template' + '@@' + this.customerName;
        console.log('callOutString==>', this.callOutString);
        sendTextMessage({ callOutString: this.callOutString })
            .then((result) => {
                this.isLoading = false;
                console.log('Message sent successfully:', result);

                // Clear the input field
                if (result == 'success') {

                    this.selectedCategory = null;
                    this.isTemplateType = null;
                    this.isTemplate = null;
                    this.isTemplateOptions = [];
                    this.istemplateName = [];
                    this.handleMessageChange();
                    this.showToast('Message Sent', 'Your message has been sent successfully.', 'success');

                } else {
                    this.showToast('Failed!', result, 'error');
                }
                // Show success toast


            })
            .catch((error) => {
                this.isLoading = false;
                inputField.value = '';
                console.log(inputField.value);
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


    // side screen code
    // Compute the class for the side panel dynamically
    @track isSidePanelOpen = false;
    get sidePanelClass() {
        return this.isSidePanelOpen
            ? 'slds-col slds-size_5-of-12 side-panel'
            : 'slds-col slds-size_0-of-12 side-panel';

    }

    // Toggle the side panel visibility
    toggleSidePanel() {
        this.isSidePanelOpen = !this.isSidePanelOpen;

    }

    // Compute the class for the chat area dynamically
    get chatAreaClass() {
        return this.isSidePanelOpen
            ? 'slds-col slds-size_7-of-12'
            : 'slds-col slds-size_12-of-12';
    }


    @track customerTag = 'Fake Enquiry';
    @track customerOptIn = 'TRUE';
    @track customerNote = 'Asked to call back later';
    @track customerFollowUpDate = 'Tue May 29, 2025 10:00 AM';

    /*popup for crating task */

    @track subject = '';
    @track status = 'Not Started';
    @track dueDate = '';
    @track showModal = false;
    @track taskComment = '';

    statusOptions = [
        { label: 'Not Started', value: 'Not Started' },
        { label: 'In Progress', value: 'In Progress' },
        { label: 'Completed', value: 'Completed' },
        { label: 'Waiting on someone else', value: 'Waiting on someone else' },
        { label: 'Deferred', value: 'Deferred' }
    ];


    openPopup() {
        this.showModal = true;
    }
    closePopup() {
        this.showModal = false;
    }

    // handleCommentChange(event) {
    //     this.taskComment = event.target.value;
    //     console.log('comment is ',JSON.stringify(event.target.value));
    // }

    handleSubjectChange(event) {
        this.subject = event.target.value;
        console.log('Subject is :', this.subject);
    }
    handleStatusChange(event) {
        this.status = event.detail.value;
        console.log('Status is :', this.status);
    }

    handleDueDateChange(event) {
        this.dueDate = event.target.value;
        console.log('dueDate is :', this.dueDate);
    }

    createTask() {
        createTask({
            whatId: this.userId,
            subject: this.subject,
            status: this.status,
            dueDate: this.dueDate
        })
            .then(() => {
                this.showModal = false;
                this.taskComment = '';

                // Refresh task list
                return refreshApex(this.wiredTaskResult);
            })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Task Created Successfully!',
                        variant: 'success'
                    })
                );
            })
            .catch(error => {
                console.error(error);
            });
    }



    //Get All Task Data using wire method
    @track tasks = [];
    @track error;

    wiredTaskResult;
    @wire(userTaskData, { userId: '$userId' })
    wiredTasks(result) {
        this.wiredTaskResult = result; // store for refresh
        const { data, error } = result;
        if (data) {
            this.tasks = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.tasks = [];
        }
    }


    get formattedTasks() {
        return this.tasks.map(task => {
            const date = new Date(task.CreatedDate);
            return {
                ...task,
                formattedDateTime: date.toLocaleString() // 13/6/2025, 4:30 PM
            };
        });
    }


    // showTagsAsPills
    @track isOpen = false;
    // @track tags = ['Window', 'File Browser', 'Pirates of the Caribbean', 'Sequel'];
    @track newTag = '';
    @track draftTags = [];
    openModal() {
        this.isOpen = true;
        this.draftTags = [...this.tags]; // show existing saved tags if any
        this.newTag = '';
    }

    closeModal() {
        this.isOpen = false;
        this.draftTags = []; // discard unsaved changes
        this.newTag = '';
    }

    handleInputChange(event) {
        this.newTag = event.target.value;
    }

    handleKeyPress(event) {
        if (event.key === 'Enter' && this.newTag.trim() !== '') {
            this.draftTags = [...this.draftTags, this.newTag.trim()];
            this.newTag = '';
        }
        console.log('Draft Tags:', JSON.stringify(this.draftTags));
    }

    handleRemoveTag(event) {
        const tagLabel = event.target.label;
        this.draftTags = this.draftTags.filter(tag => tag !== tagLabel);
        console.log('Draft Tags after remove:', JSON.stringify(this.draftTags));
    }

    handleTagsSave() {
        this.tags = [...this.draftTags]; // copy draft to saved
        this.isOpen = false;

        console.log('Saving Tags:', JSON.stringify(this.tags));
        console.log('User ID:', this.userId);

        saveAllTagsData({ userId: this.userId, tags: this.tags })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Tags saved successfully.',
                        variant: 'success'
                    })
                );
            })
            .catch(error => {
                console.error('Error saving tags:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body?.message || 'Error saving tags',
                        variant: 'error'
                    })
                );
            });
    }

    @wire(getSavedTags, { userId: '$userId' })
    wiredTags({ error, data }) {
        if (data) {
            this.tags = data;
            console.log('Fetched saved tags:', this.tags);
        } else if (error) {
            console.error('Error fetching tags:', error);
            this.showToast('Error', 'Failed to fetch tags', 'error');
        }
    }

    handleClickOnContent(event) {
        console.log('clickd');
        console.log('eveent handle ===>', event.currentTarget.dataset.id);
        console.log('eveent handle parent===>', event.currentTarget.dataset.parent);
        const parentMessageId = event.currentTarget.dataset.parent;

        // Remove existing highlight if any
        const existing = this.template.querySelector('.highlight-parent');
        if (existing) {
            existing.classList.remove('highlight-parent');
        }

        if (parentMessageId) {
            // Find the element with matching data-message-id
            const parentEl = this.template.querySelector(
                `[data-message-id="${parentMessageId}"]`
            );
            if (parentEl) {
                parentEl.classList.add('highlight-parent');
            }
        }
        this.scrollToMessage(parentMessageId);
    }

    scrollToMessage(messageId) {
        console.log('scroll called!!  ' + messageId)
        const messageElement = this.template.querySelector(
            `[data-message-id="${messageId}"]`
        );
        console.log('messageElement:' + messageElement);
        if (messageElement) {
            console.log('message element!!')
            messageElement.classList.add('highlight-parent');
            setTimeout(() => {
                messageElement.classList.remove('highlight');
            }, 2000);
            messageElement.scrollIntoView({ behavior: 'smooth', block: 'center' });
        }
    }
}