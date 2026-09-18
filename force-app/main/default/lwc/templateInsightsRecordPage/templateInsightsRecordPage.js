import { LightningElement, wire, track, api } from 'lwc';
import apexchartJs from '@salesforce/resourceUrl/ApexCharts';
import { loadScript } from 'lightning/platformResourceLoader';
import getRecordSummedTemplateAnalytics from '@salesforce/apex/TemplateInsightsController.getRecordSummedTemplateAnalytics';
import { getRecord } from 'lightning/uiRecordApi';

const FIELDS = ['WhatsAppMetaTemplate__c.Id__c'];

export default class TemplateInsights extends LightningElement {
    @api recordId; // Automatically populated on record page
    @track templateId;
    @track showBarSpinner = true;
    @track summaryData = {
        CostPerDelivered__c: 0,
        AmountSpent__c: 0,
        CostPerUrlButtonClick__c: 0,
        Sent__c: 0,
        Delivered__c: 0,
        Read__c: 0
    };
    chart;
    barOptions = {
        chart: { type: 'bar', height: 350 },
        series: [{ name: 'Metrics', data: [0, 0, 0, 0] }],
        xaxis: { categories: ['Sent', 'Delivered', 'Read', 'Clicked'] },
        plotOptions: { bar: { horizontal: true, borderRadius: 4 } }
    };

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ data, error }) {
        if (data) {
            this.templateId = data.fields.Id__c.value;
            console.log('this.templateId:'+  this.templateId);
            this.getAnalyticsData();
        } else if (error) {
            console.error('Error loading record', error);
        }
    }

    async renderedCallback() {
        if (!this.chart) {
            await loadScript(this, apexchartJs + '/dist/apexcharts.js');
        }
    }

    getAnalyticsData() {
        getRecordSummedTemplateAnalytics({ templateId: this.templateId })
            .then(result => {
                this.summaryData = result;
                this.updateChartData();
                this.renderBarChart();
            })
            .catch(error => {
                console.error('Error fetching data:', error);
            })
            .finally(() => {
                this.showBarSpinner = false;
            });
    }

    updateChartData() {
        this.barOptions.series[0].data = [
            this.summaryData.Sent__c,
            this.summaryData.Delivered__c,
            this.summaryData.Read__c,
            0 // Placeholder for clicks
        ];
    }

    renderBarChart() {
        const barDiv = this.template.querySelector('.bar-chart');
        if (barDiv && typeof ApexCharts !== 'undefined') {
            if (this.chart) {
                this.chart.updateOptions(this.barOptions);
            } else {
                this.chart = new ApexCharts(barDiv, this.barOptions);
                this.chart.render();
            }
        }
    }
}