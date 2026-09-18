import { LightningElement, api } from 'lwc';
import getTemplateData from '@salesforce/apex/TemplateMessageController.getTemplateData';
import addJson from '@salesforce/apex/TemplateMessageController.addJson';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class TemplateMessage extends LightningElement {
    @api recordId;
    templateData;

    connectedCallback() {
        if (this.recordId) {
            this.loadTemplateAndGenerateJson();
        }
    }

    loadTemplateAndGenerateJson() {
        getTemplateData({ recordId: this.recordId })
            .then((data) => {
                this.templateData = data;
                this.generateAndSaveJson();
            })
            .catch((error) => {
                console.error('Error fetching template:', error);
                this.showToast('Error', 'Failed to fetch template data', 'error');
            });
    }

    generateAndSaveJson() {
        const data = this.templateData;
        if (!data) return;

        const components = [];

        if (data.headerType && data.headerHandle) {
            const type = data.headerType.toLowerCase();
            components.push({
                type: "header",
                parameters: [
                    {
                        type: type,
                        [type]: {
                            link: data.headerHandle
                        }
                    }
                ]
            });
        }

        // Process bodyText only if it has placeholders
        if (data.bodyText) {
            const placeholderRegex = /{{(\d+)}}/g;
            let match;
            const foundPlaceholders = new Set();

            while ((match = placeholderRegex.exec(data.bodyText)) !== null) {
                foundPlaceholders.add(parseInt(match[1], 10));
            }

            if (foundPlaceholders.size > 0) {
                const bodyParams = [];
                const maxNumber = Math.max(...foundPlaceholders);

                for (let i = 1; i <= maxNumber; i++) {
                    bodyParams.push({
                        type: "text",
                        text: i.toString()
                    });
                }

                components.push({
                    type: "body",
                    parameters: bodyParams
                });
            }
        }

        // Add buttons
        const buttonComponents = [];
        if (data.buttonType) {
            const buttonTypes = data.buttonType.split(',').map(s => s.trim().toUpperCase());

            buttonTypes.forEach((buttonType, index) => {
                if (buttonType === "FLOW" || buttonType === "CATALOG") {
                    let buttonObj = {
                        type: "button",
                        sub_type: buttonType,
                        index: index
                    };
                    buttonComponents.push(buttonObj);
                }
            });
        }

        if (buttonComponents.length > 0) {
            components.push(...buttonComponents);
        }
        console.log('components:' + components);
        // Final JSON
        let finalJson;
        if (components.length > 0) {
            finalJson = {
                messaging_product: "whatsapp",
                recipient_type: "individual",
                to: "{{Recipient-Phone-Number}}",
                type: "template",
                template: {
                    name: data.templateName || "template-name",
                    language: {
                        code: data.language || "en_US"
                    },
                    components: components
                }
            };
        }
        else {
            finalJson = {
                messaging_product: "whatsapp",
                recipient_type: "individual",
                to: "{{Recipient-Phone-Number}}",
                type: "template",
                template: {
                    name: data.templateName || "template-name",
                    language: {
                        code: data.language || "en_US"
                    }
                }
            };
        }
        const jsonString = JSON.stringify(finalJson, null, 4);
        console.log('Generated JSON:\n', jsonString);

        addJson({ recordId: this.recordId, jsonResponese: jsonString })
            .then(() => {
                this.showToast('Success', 'Template JSON saved successfully!', 'success');
                window.location.reload();
            })
            .catch((error) => {
                console.error('Error saving JSON:', error);
                this.showToast('Error', 'Failed to save JSON', 'error');
                  window.location.reload();
            });
    }


    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}