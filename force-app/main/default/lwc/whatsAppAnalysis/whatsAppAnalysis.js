import { LightningElement, track } from 'lwc';
import getData from '@salesforce/apex/WhatsAppAnalysisController.getData';
import getTemplateInsights from '@salesforce/apex/WhatsAppAnalysisController.getTemplateInsights';
import iCons from '@salesforce/resourceUrl/WhatsAppAnalysis';
import { NavigationMixin } from 'lightning/navigation';

export default class WhatsAppAnalysis extends  NavigationMixin(LightningElement) {
    @track selectedStartDate;
    @track selecteEndDate;
    @track daysDifference = 0;
    @track totalMessaegesPerday = 0;
    @track tableData = [];

    @track messageTotal = 0;
    @track mediaCount = 0;
    @track textCount = 0;
    @track serviceCount = 0;
    @track marketingCount = 0;
    @track utilityCount = 0;
    @track authenticationCount = 0;
    @track allConversationCount = 0;

    @track refreshData = false;


    @track icons = {
        messages: `${iCons}/Icons/Messages.svg`,
        endDate: `${iCons}/Icons/EndDate.svg`,
        startDate: `${iCons}/Icons/StartDate.svg`,
        mediaMessages: `${iCons}/Icons/MediaMessages.svg`,
        messagesPerDay: `${iCons}/Icons/MessagesPerDay.svg`,
        nofDays: `${iCons}/Icons/NofDays.svg`,
        textMessages: `${iCons}/Icons/TextMessages.svg`,
    };

    @track chartData = {
        "series": [0, 0, 0],
        "labels": ['All Messages', 'Text Messages', 'Media Messages'],
        "chart": {
            "type": "donut"
        },
        "colors": ["red", "blue", "orange"],
    };

    connectedCallback() {
        if (this.chartData != undefined) {
            this.refreshData = true;
        }
        const today = new Date();
        const startOfMonth = new Date(today.getFullYear(), today.getMonth(), 1);
        this.selectedStartDate = this.formatDateLocal(startOfMonth);
        this.selecteEndDate = this.formatDateLocal(today);
        setTimeout(() => {
            this.fetchData(); // call server
        }, 1000);
    }




    handleStartDateChange(event) {
        this.selectedStartDate = event.target.value;
        this.calculateDaysDifference();
        this.fetchData(); // update on change
    }

    handleEndDateChange(event) {
        this.selecteEndDate = event.target.value;
        this.calculateDaysDifference();
        this.fetchData(); // update on change
    }

    formatDateLocal(date) {
        const year = date.getFullYear();
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const day = String(date.getDate()).padStart(2, '0');
        return `${year}-${month}-${day}`;
    }

    calculateDaysDifference() {
        if (this.selectedStartDate && this.selecteEndDate) {
            const start = new Date(this.selectedStartDate);
            const end = new Date(this.selecteEndDate);
            const diffTime = end - start;
            const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24)) + 1;
            this.daysDifference = diffDays;
            this.totalMessaegesPerday = (this.messageTotal / diffDays).toFixed(2);
        } else {
            this.daysDifference = 0;
            this.totalMessaegesPerday = 0;
        }
    }

    fetchData() {
        getData({ startDate: this.selectedStartDate, endDate: this.selecteEndDate })
            .then(result => {

                const messages = result.messages || [];
                const userStats = result.userStats || [];
                const templateList = result.templateList || [];

                // User stats table
                this.tableData = userStats.map((user, index) => ({
                    id: index,
                    name: user.name,
                    sent: user.sent,
                    notDelivered: user.notDelivered,
                    index: user.index,
                    readMessages: user.readMessages
                }));
                console.log('tableData', JSON.parse(JSON.stringify(this.tableData)))

                // Template stats table
                this.templatetableData = templateList.map((item, index) => ({
                    id: index,
                    Templatename: item.name,
                    Countsent: item.sent,
                    countnotDelivered: item.failed,
                    index: item.index
                }));

                // Chart setup
                this.textCount = messages.filter(m => m.MessageType__c === 'text').length;
                this.mediaCount = messages.filter(m => ['image', 'video', 'document', 'audio'].includes(m.MessageType__c)).length;
                this.messageTotal = messages.length;
                this.serviceCount = messages.filter(m => m.ConversationOrigin__c === 'service').length;
                this.marketingCount = messages.filter(m => m.ConversationOrigin__c === 'marketing').length;
                this.utilityCount = messages.filter(m => m.ConversationOrigin__c === 'utility').length;
                this.authenticationCount = messages.filter(m => m.ConversationOrigin__c === 'authentication').length;
                this.allConversationCount = this.serviceCount + this.marketingCount + this.utilityCount + this.authenticationCount;

                this.calculateDaysDifference();

                if (this.messageTotal > 0 || this.textCount > 0 || this.mediaCount > 0) {
                    this.renderchart();

                }

            })
            .catch(error => {
                console.error('Error fetching WhatsApp data: ', error);
            });
    }

    renderchart() {
        console.log('Rendering chart with data:', this.messageTotal, this.textCount, this.mediaCount);
        this.chartData = {
            "series": [this.messageTotal, this.textCount, this.mediaCount],
            "labels": ['All Messages', 'Text Messages', 'Media Messages'],
            "chart": {
                "type": "donut"
            },
            "colors": ["red", "blue", "orange"],
        };
        this.refreshData = false;
        setTimeout(() => {
            this.refreshData = true;
        }, 1000);
    }

    handleViewInsights(event) {
        const templateName = event.target.dataset.templatename;
        getTemplateInsights({ templateName: templateName })
            .then((result) => {
               // console.log('TEmplate Insignts template ID==>', result);
                const tempid = result;
                this[NavigationMixin.Navigate]({
                    type: 'standard__navItemPage',
                    attributes: {
                        apiName: 'Template_Insights'
                    },
                    state: {
                          c__recordId: tempid
                    },
                });

            }).catch((err) => {

            });
            
    }

}