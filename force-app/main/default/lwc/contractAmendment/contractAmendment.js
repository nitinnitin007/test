/*
  @description       : ContractAmendment
  @author            : Vivek Singh Jadaun
  @last modified on  : 09-12-2023
  @User Story : Created as part of BIZ-46098
*/
import { LightningElement,wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import updateContract from '@salesforce/apex/ContractAmendController.updateContract';
import { NavigationMixin } from 'lightning/navigation';

export default class ContractAmend extends NavigationMixin(LightningElement) {

contractId;
dealId;
dealType;

message='Redirecting to Contract';
@wire(CurrentPageReference)
currentPageReference;

connectedCallback() {
    
    if ( this.currentPageReference.state.c__contractId ) {
        this.contractId = this.currentPageReference.state.c__contractId;
    }
    if ( this.currentPageReference.state.c__dealId ) {
        this.dealId = this.currentPageReference.state.c__dealId;
    }
    if ( this.currentPageReference.state.c__DealType ) {
        this.dealType = this.currentPageReference.state.c__DealType;
        this.AmendContract();
    }

}

AmendContract(){
    updateContract({contractId : this.contractId, dealId : this.dealId, dealType : this.dealType})
            .then(data => {
                //console.log(data);
                var result = data.split(';');
                console.log('result',result);
                if(result[0]=='Success'){
                    this.navigateToRecordPage(result[1]);
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

navigateToRecordPage(contractId) {
    this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: {
            recordId: contractId,
            objectApiName: 'Contract',
            actionName: 'view'
        }
    });
}

}