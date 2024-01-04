import { LightningElement,api } from 'lwc';
import updateQuote from '@salesforce/apex/QuoteSaveAndForecastController.updateQuote';

export default class QuoteSaveAndForecast extends LightningElement {

    @api recordId;

    connectedCallback(){
        this.updateQuoteJs();
    }

    renderedCallback(){
        this.updateQuoteJs();
    }

    updateQuoteJs(){
        updateQuote({recordId :this.recordId})
        .then(data => {
            console.log(data);
            if(data=='Success'){
                window.location.reload();
            }
        })
        .catch(error => {
            console.log(error);
        })
    }

}