/*
  @description       : Green Box OSA Approval Information
  @author            : Keerthan N
  @last modified on  : 08-24-2023
  @User Story : Created as part of BIZ-46553,BIZ-47960
*/
import { LightningElement, wire,track, api  } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import Initial_Term_Discount from '@salesforce/schema/SBQQ__Quote__c.Initial_Term_Discount__c';
import Free_Months from '@salesforce/schema/SBQQ__Quote__c.Free_Months__c';
import Billing_Frequency from '@salesforce/schema/SBQQ__Quote__c.SBQQ__BillingFrequency__c';
import Payment_Terms from '@salesforce/schema/SBQQ__Quote__c.SBQQ__PaymentTerms__c';
import Renewal_Payment_Terms from '@salesforce/schema/SBQQ__Quote__c.Renewal_Payment_Terms__c';
import Renewal_Billing_Frequency from '@salesforce/schema/SBQQ__Quote__c.Renewal_Billing_Frequency__c';
import Minimum_year_approver_level from '@salesforce/schema/SBQQ__Quote__c.Minimum_year_approver_level__c';
import InitialTermapproverLevel from '@salesforce/schema/SBQQ__Quote__c.InitialTermapproverLevel__c';
import Free_month_approver_Level from '@salesforce/schema/SBQQ__Quote__c.Free_month_approver_Level__c';
import Billing_Frequency_approval_level from '@salesforce/schema/SBQQ__Quote__c.Billing_Frequency_approval_level__c';
import Payment_Term_Approver_Level from '@salesforce/schema/SBQQ__Quote__c.Payment_Term_Approver_Level__c';
import SFA_Level from '@salesforce/schema/SBQQ__Quote__c.SFA_Level__c';
import Min_year_on_year_committed_spend from '@salesforce/schema/SBQQ__Quote__c.Min_year_on_year_committed_spend__c';
import Highest_Approver_level from '@salesforce/schema/SBQQ__Quote__c.Highest_Approver_level__c';
import Approval_Level_Name from '@salesforce/schema/SBQQ__Quote__c.Approval_Level_Name__c';
import Services_Discount_Percentage__c from '@salesforce/schema/SBQQ__Quote__c.Services_Discount_Percentage__c';
import Fr_maximum_service_Level__c from '@salesforce/schema/SBQQ__Quote__c.Fr_maximum_service_Level__c';
import Retainer_percent__c from '@salesforce/schema/SBQQ__Quote__c.Retainer_percent__c';
import Retainerlevel__c from '@salesforce/schema/SBQQ__Quote__c.Retainerlevel__c';
import Product_Related_Approval__c from '@salesforce/schema/SBQQ__Quote__c.Product_Related_Approval__c';
import Non_Standard_Approvals__c from '@salesforce/schema/SBQQ__Quote__c.Non_Standard_Approvals__c';
import Non_standard_Level__c from '@salesforce/schema/SBQQ__Quote__c.Non_standard_Level__c';
import ROR__c from '@salesforce/schema/SBQQ__Quote__c.ROR__c';
import Development_Obligation__c from '@salesforce/schema/SBQQ__Quote__c.Development_Obligation__c';
import Platform_Conversion__c from '@salesforce/schema/SBQQ__Quote__c.Platform_Conversion__c';
import Product_level__c from '@salesforce/schema/SBQQ__Quote__c.Product_level__c';
import SFA_Cap_Time_Horizon__c from '@salesforce/schema/SBQQ__Quote__c.SFA_Cap_Time_Horizon__c';
import Renewal_Increase_SFA_Cap__c from '@salesforce/schema/SBQQ__Quote__c.Renewal_Increase_SFA_Cap__c';
import getCustomMetadata from '@salesforce/apex/GreenBoxController.getCustomMetadata';
import Services_Discount_Percentag_Prime__c from '@salesforce/schema/SBQQ__Quote__c.Services_Discount_Percentag_Prime__c';
import Payment_term_level_exception__c from '@salesforce/schema/SBQQ__Quote__c.Payment_term_level_exception__c';
import Prime_discount_level__c from '@salesforce/schema/SBQQ__Quote__c.Prime_discount_level__c';

export default class GreenBoxDisplay extends NavigationMixin(LightningElement) {
    @api recordId;
    @track quote;
    @track mapData = [];
    metadataRecs;
    records;
    error;
    metadataRetrieved = false;


    @wire(getRecord, { recordId: '$recordId', fields: [Renewal_Payment_Terms,Renewal_Billing_Frequency,Initial_Term_Discount,Free_Months,
        Billing_Frequency,Payment_Terms,Minimum_year_approver_level,InitialTermapproverLevel,
        Free_month_approver_Level,Billing_Frequency_approval_level,Payment_Term_Approver_Level,
        SFA_Level,Min_year_on_year_committed_spend,Highest_Approver_level,Approval_Level_Name,
        Services_Discount_Percentage__c,Retainer_percent__c,Fr_maximum_service_Level__c,Retainerlevel__c,
        Product_Related_Approval__c,Non_standard_Level__c,Non_Standard_Approvals__c,ROR__c,Development_Obligation__c,Platform_Conversion__c,Product_level__c,Renewal_Increase_SFA_Cap__c,SFA_Cap_Time_Horizon__c,Services_Discount_Percentag_Prime__c,Prime_discount_level__c,Payment_term_level_exception__c]})
    quote;

    @wire(getCustomMetadata)
    wiredRecs(value){
        console.log('getCustomMetadata');
        this.metadataRecs = value;
        const {data, error} = value;
        if( data ){
            console.log('data',data);
            this.records = data;
            this.metadataRetrieved = true;
            this.error = undefined;
            //console.log(this.mapData[1.0]);
        }
        else if ( error ){
            this.records = undefined;
            this.error = data;
            console.log('this.error',this.error);
        }
    }

    get initialTermDiscount() {
        return getFieldValue(this.quote.data, Initial_Term_Discount);
    }

    get additionalFreeMonths() {
        return getFieldValue(this.quote.data, Free_Months);
    }

    get billingFrequency() {
        return getFieldValue(this.quote.data, Billing_Frequency);
    }

    get paymentTerms() {
        return getFieldValue(this.quote.data, Payment_Terms);
    }
    get RenewalpaymentTerms() {
        return getFieldValue(this.quote.data,Renewal_Payment_Terms);
    }
    get RenewalBillingFrequency() {
        return getFieldValue(this.quote.data,Renewal_Billing_Frequency);
    }
    
    get minyearonyearcommittedspend() {
        return getFieldValue(this.quote.data, Min_year_on_year_committed_spend);
    }
    get ServicesDiscountPercentage() {
        return getFieldValue(this.quote.data, Services_Discount_Percentage__c);
    }

    get ProductRelatedApproval() {
        return getFieldValue(this.quote.data, Product_Related_Approval__c);
    }
    get NonStandardApprovals() {
        return getFieldValue(this.quote.data, Non_Standard_Approvals__c);
    }
    get RenewalIncreaseSFACap() {
        return getFieldValue(this.quote.data, Renewal_Increase_SFA_Cap__c);
    }
    get SFACapTimeHorizon() {
        return getFieldValue(this.quote.data, SFA_Cap_Time_Horizon__c);
    }
    get ServicesDiscountPercentagPrime() {
        return getFieldValue(this.quote.data, Services_Discount_Percentag_Prime__c);
    }


    //Level
    get minimumYearApproverLevel() {
        for(let i=0; i < this.records.length;i++){
            if(this.records[i].Approval_Level__c==getFieldValue(this.quote.data, Minimum_year_approver_level)){
                return this.records[i].Approver_Title__c;
            }
        }
        return null;
    }

    get Paymenttermlevelexception() {
        for(let i=0; i < this.records.length;i++){
            if(this.records[i].Approval_Level__c==getFieldValue(this.quote.data,Payment_term_level_exception__c)){
                return this.records[i].Approver_Title__c;
            }
        }
        return null;
    }

    get sfaLevel() {
        for(let i=0; i < this.records.length;i++){
            if(this.records[i].Approval_Level__c==getFieldValue(this.quote.data, SFA_Level)){
                return this.records[i].Approver_Title__c;
            }
        }
        return null;
    }

    get billingFrequencyapprovallevel() {
        for(let i=0; i < this.records.length;i++){
            if(this.records[i].Approval_Level__c==getFieldValue(this.quote.data, Billing_Frequency_approval_level)){
                return this.records[i].Approver_Title__c;
            }
        }
        return null;
    }

    get freemonthapproverLevel() {
        for(let i=0; i < this.records.length;i++){
            if(this.records[i].Approval_Level__c==getFieldValue(this.quote.data, Free_month_approver_Level)){
                return this.records[i].Approver_Title__c;
            }
        }
        return null;
    }

    get initialTermapproverLevel() {
        for(let i=0; i < this.records.length;i++){
            if(this.records[i].Approval_Level__c==getFieldValue(this.quote.data, InitialTermapproverLevel)){
                return this.records[i].Approver_Title__c;
            }
        }
        return null;
    }
    get FrmaximumserviceLevel() {
        for(let i=0; i < this.records.length;i++){
            if(this.records[i].Approval_Level__c==getFieldValue(this.quote.data, Fr_maximum_service_Level__c)){
                return this.records[i].Approver_Title__c;
            }
        }
        return null;
    }
    get NonstandardLevel() {
        for(let i=0; i < this.records.length;i++){
            if(this.records[i].Approval_Level__c==getFieldValue(this.quote.data, Non_standard_Level__c)){
                return this.records[i].Approver_Title__c;
            }
        }
        return null;
    }
    get Productlevel() {
        for(let i=0; i < this.records.length;i++){
            if(this.records[i].Approval_Level__c==getFieldValue(this.quote.data, Product_level__c)){
                return this.records[i].Approver_Title__c;
            }
        }
        return null;
    }
    get Primediscountlevel() {
        for(let i=0; i < this.records.length;i++){
            if(this.records[i].Approval_Level__c==getFieldValue(this.quote.data, Prime_discount_level__c)){
                return this.records[i].Approver_Title__c;
            }
        }
        return null;
    }
    
    

    get getApprovalName() {
        console.log('getFieldValue(this.quote.data, Approval_Level_Name)',getFieldValue(this.quote.data, Approval_Level_Name));
        for(let i=0; i < this.records.length;i++){
            if(this.records[i].Approval_Level__c==getFieldValue(this.quote.data, Approval_Level_Name)){
                return this.records[i].Approver_Title__c;
            }
        }
        return null;
    }

    get getHighestApprover() {
        for(let i=0; i < this.records.length;i++){
            if(this.records[i].Approval_Level__c==getFieldValue(this.quote.data, Highest_Approver_level)){
                if(this.records[i].Approval_Level__c == 5){
                    return 'CRO/COO/SVP Finance'
                }
                else{
                    return this.records[i].Approver_Title__c;
                }
            }
        }
        return null;
    }
 }