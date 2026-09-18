import { LightningElement, track } from 'lwc';
import apexchartJs from '@salesforce/resourceUrl/ApexCharts';
import { loadScript } from 'lightning/platformResourceLoader';
import getTemplateAnalytics from '@salesforce/apex/TemplateInsightsController.getTemplateAnalytics';
import getSummedTemplateAnalytics from '@salesforce/apex/TemplateInsightsController.getSummedTemplateAnalytics';

export default class TemplateInsights extends LightningElement {
    isChartJsInitialized = false;
    @track templateId = 'demoid';
    @track showBarSpinner = false;
    chart; 
    @track summaryData = {
        CostPerDelivered__c: 0,
        AmountSpent__c: 0,
        CostPerUrlButtonClick__c: 0,
        Sent__c: 0,
        Delivered__c: 0,
        Read__c: 0
    };
    barOptions = {
        chart: {
            type: 'bar',
            height: 350
        },
        series: [{
            name: 'Metrics',
            data: [
               243,
               240,
               80,
                0
            ]
        }],
        xaxis: {
            categories: ['Sent', 'Delivered', 'Read', 'Clicked']
        },
        plotOptions: {
            bar: {
                horizontal: true,
                borderRadius: 4
            }
        }
    };

    renderedCallback() {
        // Only run once
       // if (this.isChartJsInitialized) return;

      //  this.isChartJsInitialized = true;

        // Load ApexCharts
        loadScript(this, apexchartJs + '/dist/apexcharts.js')
            .then(() => {
                 console.log('script loded');
                this.getTemplateIdFromUrl();
                // Defer rendering slightly to ensure DOM is ready
                //setTimeout(() => this.renderBarChart(), 0);
            })
            .catch(error => {
                console.error('Error loading ApexCharts:', error);
            });
    }

    getTemplateIdFromUrl() {
        const url = new URL(window.location.href);
        const templateId = url.searchParams.get('c__recordId');
        if (templateId) {
            this.templateId = templateId;
            console.log('Template ID from nav:', this.templateId);
            //  window.location.reload();
        }

    }

    renderBarChart() {
        this.showBarSpinner = true;
        const barDiv = this.template.querySelector('.bar-chart');

        // if (!barDiv || typeof ApexCharts === 'undefined') {
        //     console.error('Chart container or ApexCharts not ready.');
        //     return;
        // }

        try {
            this.chart = new ApexCharts(barDiv, this.barOptions);
            this.chart.render().then(() => {
                this.showBarSpinner = false;
                console.log('Chart rendered successfully');
            }).catch(e => {
                console.error('Bar chart render failed:', e);
              //  window.location.reload();
            });
        } catch (error) {
            console.error('Error rendering bar chart:', error);
        }
    }


    handleStartDate(event) {

        this.selectedStartDate = event.target.value;
        // console.log(' this.selectedStartDate:'+ this.selectedStartDate);
        // this.selectedStartDate = Math.floor(this.selectedStartDate.getTime() / 1000); // Convert ms to seconds
        console.log('this.selectedStartDate====>', this.selectedStartDate);

        this.getTemplateAnalyticsInsights();
    }

    handleEndDate(event) {
        this.selectedEndDate = event.target.value;
        // this.selectedEndDate = Math.floor(this.selectedEndDate.getTime() / 1000);
        console.log('this.selectedEndDate', this.selectedEndDate);
        this.getTemplateAnalyticsInsights();
    }


    // If you need to convert back for display

    getTemplateAnalyticsInsights() {
        console.log('this.selectedStartDate:' + this.selectedStartDate);
        console.log(' this.selectedEndDate:' + this.selectedEndDate);
        console.log('this.templateId:' + this.templateId);

        if (this.selectedStartDate != null && this.selectedEndDate != null && this.templateId != null) {
            this.getSummedTemplateAnalytics();
            getTemplateAnalytics({ startDate: this.selectedStartDate, endDate: this.selectedEndDate, templateId: this.templateId })
                .then((result) => {
                    console.log('result:' + JSON.stringify(result))

                }).catch((err) => {
                    console.log('err:' + JSON.stringify(err));
                });
        }

    }
    getSummedTemplateAnalytics() {
        getSummedTemplateAnalytics({ templateId: this.templateId })
            .then(result => {
                this.summaryData = result;
                console.log('Summary Data:', JSON.stringify(result));
                this.barOptions = {
                    chart: {
                        type: 'bar',
                        height: 350
                    },
                    series: [{
                        name: 'Metrics',
                        data: [
                            this.summaryData.Sent__c,
                            this.summaryData.Delivered__c,
                            this.summaryData.Read__c,
                            0
                        ]
                    }],
                    xaxis: {
                        categories: ['Sent', 'Delivered', 'Read', 'Clicked']
                    },
                    plotOptions: {
                        bar: {
                            horizontal: true,
                            borderRadius: 4
                        }
                    }
                };

                this.renderBarChart();

            })
            .catch(error => {
                this.error = error;
                console.error('Error fetching data:', error);
            });
           // this.renderBarChart()
             console.log('barOptions:' + JSON.stringify(this.barOptions));
    }
    handleScriptLoad(){
         loadScript(this, apexchartJs + '/dist/apexcharts.js')
            .then(() => {
               
                this.getTemplateIdFromUrl();
                // Defer rendering slightly to ensure DOM is ready
                //setTimeout(() => this.renderBarChart(), 0);
            })
            .catch(error => {
                console.error('Error loading ApexCharts:', error);
            });
    }
}