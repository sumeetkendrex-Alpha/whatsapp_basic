import { LightningElement,api } from 'lwc';
import CRMChart from '@salesforce/resourceUrl/CRMChart';
import { loadScript } from 'lightning/platformResourceLoader';
export default class Chart extends LightningElement { 
    userRecords = [];
    @api chart;
    SelectedChartType = null;
    ApexChart = null;

    connectedCallback(){        
        this.chart = JSON.parse(JSON.stringify(this.chart));
        this.SelectedChartType = this.chart.chart.type;
    }

    renderedCallback() {               
        Promise.all([
            loadScript(this, CRMChart + '/dist/apexcharts.js')
        ]).then(() => {            
            this.ApexChart = new ApexCharts(this.template.querySelector(".chart"), this.chart);
            console.log('this.ApexChart',JSON.stringify(this.chart));            
            this.ApexChart.render();                            
        }).catch(error => {
            console.log('ERROR: ' + error.message);
        });  
        this.chart.colors = ["#075E54", "#25D366","#34B7F1", "#FF9800", "#FF5722", "#9C27B0", "#673AB7", "#3F51B5", "#2196F3", "#03A9F4", "#00BCD4", "#009688", "#4CAF50", "#8BC34A", "#CDDC39", "#FFEB3B", "#FFC107", "#FF9800", "#FF5722"];                    
    }

    get ChartOptions() {                        
        return [
            { label: 'Bar', value: 'bar' },
            { label: 'Pie', value: 'pie' },
            { label: 'Donut', value: 'donut' },
        ];
    }

    handleChangeChartType(event){                        
        var SelectedChartType = event.target.value;
        if(this.chart.chart.type != SelectedChartType){
            if (SelectedChartType == 'bar') {
                var data = [];
                    for(var i=0;i<this.chart.series.length;i++){
                        data.push(this.chart.series[i]);
                    }                    
                    this.chart.series = [];
                    this.chart.series[0] = {
                        data : data
                    }
            } else if( SelectedChartType == 'donut' || SelectedChartType == 'pie'){
                if(this.chart.chart.type == 'bar'){
                    this.chart.series = JSON.parse(JSON.stringify(this.chart.series[0].data));
                }
            }
            console.log('this.chart : ',JSON.stringify(this.chart));
            this.chart.chart.type = SelectedChartType;
            this.ApexChart.updateOptions(this.chart);
        }        
    }
}