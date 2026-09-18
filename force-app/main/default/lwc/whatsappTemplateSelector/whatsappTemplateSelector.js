import { LightningElement, track ,api} from 'lwc';

export default class TemplateSetup extends LightningElement {
    @track activeTab = 'marketing';
    @track customChecked = true;
    isDialogVisible = false;
    showChild = false;
    modalContainer;
    @api formData;
    connectedCallback() {
        this.showDialog();
    }

    nextScreen() {
        this.showChild = true;
    }
    showDialog() {
        this.isDialogVisible = true;
    }

    hideDialog() {
        this.isDialogVisible = false;
    }

    // Tab class getters
    get categoryMarketingClass() {
        return this.getCategoryClass('marketing');
    }

    get categoryUtilityClass() {
        return this.getCategoryClass('utility');
    }

    get categoryAuthClass() {
        return this.getCategoryClass('authentication');
    }

    getCategoryClass(tabName) {
        return `category ${this.activeTab === tabName ? 'active' : ''}`;
    }

    // Option rendering conditions
    get isMarketingActive() {
        return this.activeTab === 'marketing';
    }

    get isUtilityActive() {
        return this.activeTab === 'utility';
    }

    get isAuthActive() {
        return this.activeTab === 'authentication';
    }

    // Tab switch handlers
    switchToMarketing() {
        this.activeTab = 'marketing';
        const name = this.activeTab;
        const value = 'Custom'
        this.dispatchEvent(new CustomEvent('inputchange', {
            detail: { name, value }
        }));
    }

    switchToUtility() {
        this.activeTab = 'utility';
        this.customChecked = true; // Default checked when switching to Utility
        const name = this.activeTab;
        const value = 'Custom'
        this.dispatchEvent(new CustomEvent('inputchange', {
            detail: { name, value }
        }));
    }

    switchToAuth() {
        this.activeTab = 'authentication';
        const name = this.activeTab;
        const value = 'Custom'
        this.dispatchEvent(new CustomEvent('inputchange', {
            detail: { name, value }
        }));
    }

    // Checkbox handler
    handleCustomCheck(event) {
        this.customChecked = event.target.checked;
    }

    renderedCallback() {
        const STYLE = document.createElement("style"); STYLE.innerText = `.uiModal--medium .modal-container{
        width: 100% !important;
        max-width: 900px;
        min-width:100%;
        max-height:100%;
        min-height:480px;
        }`;
        this.template.querySelector('lightning-card').appendChild(STYLE);
    }
}