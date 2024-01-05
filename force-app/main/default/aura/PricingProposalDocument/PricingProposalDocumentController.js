({
	init : function (component) {
        var recordId = component.get("v.recordId");
    },
     recordUpdate: function(component, event, helper) {
        var recordId = component.get("v.recordId");
        var status = component.get("v.Quote").Pricing_Proposal_Approval__c;
        var stage = component.get("v.Quote").Quote_Stage__c;
        var quoteNumber = component.get("v.Quote").Name;
        var accountName = component.get("v.Quote").Account_Name__c;
        console.log('in init');
        if(stage == "Pricing Proposal" && status == "Approved") {
            console.log('in yes');
            $A.get("e.force:closeQuickAction").fire();
            var urlEvent = $A.get("e.force:navigateToURL");
    		urlEvent.setParams({
                "url": '/apex/APXTConga4__Conga_Composer?SolMgr=1&serverUrl={!API.Partner_Server_URL_520}&Id='+recordId+'&QueryId=[MDQOneTimeDiscount]0Q_001MAQ106508%3Fpv0%3D'+recordId+',[NonMDQQuoteLines]0Q_003MAQ133545%3Fpv0%3D'+recordId+',[MDQQuoteLines]0Q_002MAQ228749%3Fpv0%3D'+recordId+',[QuoteLineMDQYear1]0Q_000MAQ991196%3Fpv0%3D'+recordId+',[ServiceOneTimeCredit]0Q_060MAQ489742%3Fpv0%3D'+recordId+',[TermConditions]0Q_061MAQ603651%3Fpv0%3D'+recordId+'&TemplateId=0T_000MAQ969716&DS7=11&DefaultPDF=1&FP0=1&OFN=Pricing%20Proposal%20-'+accountName+'-'+quoteNumber,
                "width" : "700",
                "height" : "1000",
                "scrollbars" : "yes"
            });
        
    		urlEvent.fire();
        } else {
            console.log('in else');
            $A.get("e.force:closeQuickAction").fire();
            var showToastMessage = $A.get("e.force:showToast");
            showToastMessage.setParams({
                "message" : "Please submit Pricing Proposal for Approval before generating Document",
                "type" : "warning",
                "duration" : "50000ms"
           	});
           	showToastMessage.fire();
        }
    }
})