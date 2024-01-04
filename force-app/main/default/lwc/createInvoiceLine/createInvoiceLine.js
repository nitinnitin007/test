import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import  createInvoiceLines from '@salesforce/apex/ServiceBillingProcess.createInvoiceLinesFromOASlipRecords'
export default class CreateInvoiceLine extends LightningElement {
    connectedCallback() {
        createInvoiceLines().
        then((result) => {
            console.log("Result:", result);
            this.showToast()
          }).
        catch((error) => {
            throw new Error("Unexpected Error , Not able to create Invoice lines ");
          })
          console.log('invoked')
        
    }
    showToast() {
        const evt = new ShowToastEvent({
            title: 'Success!',
            message: 'Invocie lines created successfully!',
            variant: 'success',
        });
        this.dispatchEvent(evt);
    }

}