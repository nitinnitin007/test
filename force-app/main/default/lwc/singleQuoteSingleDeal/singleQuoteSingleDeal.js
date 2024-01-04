/*
  @description       : Single Quote Single Deal
  @author            : Keerthan N
  @last modified on  : 07-24-2023
  @User Story : Created as part of BIZ-45097,BIZ-46504
*/
import { LightningElement,wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import checkAndCreateQuote from '@salesforce/apex/SingleQuoteSingleDealController.checkAndCreateQuote';
import { NavigationMixin } from 'lightning/navigation';

export default class SingleQuoteSingleDeal extends NavigationMixin(LightningElement) {

accId;
dealId;
dealType;
currencyIso='';
existingClient;
message='Redirecting to Record';
@wire(CurrentPageReference)
currentPageReference;

connectedCallback() {
    
    if ( this.currentPageReference.state.c__accId ) {
        this.accId = this.currentPageReference.state.c__accId;
    }
    if ( this.currentPageReference.state.c__DealType ) {
        this.dealType = this.currentPageReference.state.c__DealType;
    }
    if ( this.currentPageReference.state.c__currencyIso ) {
        this.currencyIso = this.currentPageReference.state.c__currencyIso;
    }
    if ( this.currentPageReference.state.c__existingClient ) {
        this.existingClient = this.currentPageReference.state.c__existingClient;
    }
    if ( this.currentPageReference.state.c__dealId ) {
        this.dealId = this.currentPageReference.state.c__dealId;
        this.checkAndCreateQuoteJs();
    }

}

checkAndCreateQuoteJs(){
        checkAndCreateQuote({dealId : this.dealId, accId : this.accId, dealType : this.dealType, currencyIso : this.currencyIso, existingClient : this.existingClient})
            .then(data => {
                //console.log(data);
                var result = data.split(';');
                console.log('result',result);
                if(result[0]=='Success'){
                    this.navigateToRecordPage(result[1],result[2]);
                }
                else{
                    this.message = result[1];
                }
            })
            .catch(error => {
                console.log(error);
                this.message = error;
            })
}

navigateToRecordPage(objName,recId) {
    this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: {
            recordId: recId,
            objectApiName: objName,
            actionName: 'view'
        }
    });
}

}