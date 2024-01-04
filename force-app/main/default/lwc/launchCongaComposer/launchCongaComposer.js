import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import addSelectLines from '@salesforce/apex/AddSelectBundleLines.createSelectLineRecords';
import generateCongaURL from '@salesforce/apex/AddSelectBundleLines.generateCongaURL';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import NAME_FIELD from "@salesforce/schema/SBQQ__Quote__c.Name";
import ACCOUNT_NAME_FIELD from "@salesforce/schema/SBQQ__Quote__c.Account_Name__c";

const fields = [NAME_FIELD, ACCOUNT_NAME_FIELD];
export default class OpenAccountQuickAction  extends NavigationMixin( LightningElement ) {
 
  // @api recordId;
   recordId;
   message
   @track isLoading = false;

    @wire(getRecord, { recordId: '$recordId', fields })
    quote;

    get name() {
        return getFieldValue(this.quote.data, NAME_FIELD);
    }

    get accountName() {
        return getFieldValue(this.quote.data, ACCOUNT_NAME_FIELD);
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
        this.recordId = currentPageReference.state.recordId;
        }
    }
    connectedCallback() {
        console.log('recordId**',this.recordId);              
        this.invokeApexClass();
        
    }
 
    invokeApexClass(){
        this.isLoading = true;
        addSelectLines({quoteId :this.recordId })
        .then(result => {
        this.message = result;
        this.generateCongaURL(); 
        })
        .catch(error => {
            this.error = error.message;
        });
    }

    generateCongaURL(){
        generateCongaURL({quoteId :this.recordId })
        .then(result => {
        this.message = result;
        this.redirectToConga(this.message);
        })
        .catch(error => {
            this.error = error.message;
        });
    }
 
    redirectToConga(message){
        this.isLoading = false;
        var recId = this.recordId;
        let url = message;
        console.log('recId',recId);
        //let url = '/apex/APXTConga4__Conga_Composer?SolMgr=1&serverUrl={!API.Partner_Server_URL_520}&Id='+recId+'&QueryId=[NonMDQQuoteLines]0Q_007MAI278240%3Fpv0%3D'+recId+',[MDQOneTimeDiscount]0Q_012MAI831841%3Fpv0%3D'+recId+',[TermConditions]0Q_028MAI721907%3Fpv0%3D'+recId+',[ServiceOneTimeCredit]0Q_036MAI301730%3Fpv0%3D'+recId+',[QuoteLineMDQYear1]0Q_013MAI932474%3Fpv0%3D'+recId+',[QuoteLineMDQYear2]0Q_058MAI446362%3Fpv0%3D'+recId+',[QuoteLineMDQYear3]0Q_059MAI983299%3Fpv0%3D'+recId+',[QuoteLineMDQYear4]0Q_066MAI677051%3Fpv0%3D'+recId+',[QuoteLineMDQYear5]0Q_067MAI907860%3Fpv0%3D'+recId+',[QuoteLineMDQYear6]0Q_068MAI964597%3Fpv0%3D'+recId+',[StaticBundleYear1]0Q_072MAI300644%3Fpv0%3D'+recId+',[StaticBundleYear3]0Q_076MAI729331%3Fpv0%3D'+recId+',[StaticBundleYear4]0Q_077MAI766911%3Fpv0%3D'+recId+',[StaticBundleYear5]0Q_078MAI234996%3Fpv0%3D'+recId+',[StaticBundleYear6]0Q_080MAI028699%3Fpv0%3D'+recId+',[SelectBundleYear1]0Q_081MAI288032%3Fpv0%3D'+recId+',[SelectBundleYear2]0Q_082MAI375682%3Fpv0%3D'+recId+',[SelectBundleYear3]0Q_083MAI722853%3Fpv0%3D'+recId+',[SelectBundleYear4]0Q_088MAI420265%3Fpv0%3D'+recId+',[SelectBundleYear5]0Q_089MAI420264%3Fpv0%3D'+recId+',[SelectBundleYear6]0Q_090MAI420264%3Fpv0%3D'+recId+',[StaticBundleYear2]0Q_074MAI800953%3Fpv0%3D'+recId+',[TableHideQueryYear2]0Q_087MAI466322%3Fpv0%3D'+recId+',[TableHideQueryYear3]0Q_091MAI698950%3Fpv0%3D'+recId+',[TableHideQueryYear4]0Q_092MAI322965%3Fpv0%3D'+recId+',[TableHideQueryYear5]0Q_093MAI508787%3Fpv0%3D'+recId+',[TableHideQueryYear6]0Q_094MAI545567%3Fpv0%3D'+recId+',[TableHideQueryYear1]0Q_095MAI787141%3Fpv0%3D'+recId+'&TemplateId=0T_003MAI505642&defaultpdf=1&DS7=1&SC0=1&SC1=Attachments&zipfiles=0&OFN=Pricing Proposal-'+recId+'';        console.log('url',url);
        this.navigateToRecordPage(url);
    }
 
    navigateToRecordPage(urlRedirect) {
        const config = {
            type: 'standard__webPage',
            attributes: {
                url: urlRedirect
            }
        };
        this[NavigationMixin.Navigate](config);
    }
 
}