/*
Class Name: OrderHeaderService
Description: 
Author/Date: Megan Buonaiuto
Release: 
Purpose: Serves the order header buttons on OPCs and Opps. Invoked through AJAX.
Change History:
Date			Author			Description
----------------------------------------------------------------------------------------------------------------------------
1/30/2018	    Venkat			Changed input parameter to Opp Product Component ID - Ticket #14307
				Venkat			Queried Opp ID from the Opp PC Id - Ticket #14307
				Venkat			Code optimization - Merged the two functions and reduced redundancy
*/
global class OrderHeaderService {
	 
	webService static String CreateKeyAndMedia(id recID, Boolean keyAndMedia){
		Opportunity_Product_Component__c oppProdComp = new Opportunity_Product_Component__c();
		Intapp_Settings__c settings = Intapp_Settings__c.getInstance();

		Id oppID;
		String description = '';
		Boolean isOPC = false;
		
		//If the TRY block fails it means the recId is not OPC Id. Hence it has to be Opp ID
		try{
			oppProdComp = [Select Opportunity__c, Opportunity__r.Id, Product_Line__c, Product_LineNew__c, Product_LineNew__r.Name 
							FROM Opportunity_Product_Component__c
							WHERE Id =: recID
							];
			// Use OppId to lookup Opportunity (id, contract, Product Line)
			oppID = oppProdComp.Opportunity__r.Id;
			isOPC = true;						
		}
		catch(Exception e){
			oppID = recID; // In case the button is active in oppt and not on oppt PC
		}

		Opportunity Opp = [SELECT Id, Client_Contact__c, Name,
								  Associated_Contract_OSA__c, Package__c,
								  Product_Line__c, Cloud_System_Administrator__c,
								  Cloud_Location__c, Cloud_Name__c,
								  (SELECT  Id, Product_Line__c, Product_LineNew__c, Product_LineNew__r.Name 
                                   FROM Opportunity_Product_Components__r
                                   WHERE Product_LineNew__c != null)
						     FROM Opportunity 
						    WHERE Id = :oppID 
							LIMIT 1];
		
		//Check whether the oppt has multiple OPCs under it
		Boolean hasMultipleOPCs = hasMultipleOPCs(Opp, settings.Multiple_OPC_Check__c);
		
		//If it has multiple OPCs but they have the same Product Line, display error
		if(hasMultipleOPCs && areProductLinesSame(Opp, settings.Different_Product_Line_Check__c)){
			return settings.Different_Product_Line_Error__c != null ? settings.Different_Product_Line_Error__c : 'Product Lines are similar on the OPCs.';
		}

		//Check whether its created from the Oppt & whether it has multiple OPCs 
		//If true, display error - "It has to be done from OPC"
		if(!isOPC && hasMultipleOPCs) {
			return settings.Multiple_OPC_Error_Message__c != null ? settings.Multiple_OPC_Error_Message__c : 'Please create Order Headers from individual OPC.';
		} 
		
		
		
		//If Client contact or Contract OSA not filled, display error
		if (Opp.Client_Contact__c == null || Opp.Associated_Contract_OSA__c == null){
			return 'There was an error processing your request. Please verify that the related Opportunity has both a Client Contact and an OSA populated.';
		}
		
		//If the button was clicked from OPC, ensure that the product line is appended to the description
		if(isOPC && oppProdComp.Product_LineNew__c != null)
            description = Opp.Name + ' - ' + oppProdComp.Product_LineNew__r.Name; 
        else if(Opp.Opportunity_Product_Components__r != null && Opp.Opportunity_Product_Components__r.size() > 0)
            description = Opp.Name + ' - ' + Opp.Opportunity_Product_Components__r[0].Product_LineNew__r.Name;
        else
            description = Opp.Name;
        
		// Lookup Contract (Account Id, contract number)
		Contract Con = [SELECT Id, ContractNumber, CompanySignedDate, Account.id, 
							   Account.License_Band__c, Account.License_Band_Timekeepers__c, 
							   Account.NumberOfEmployees, Recipient__c 
						  FROM Contract 
						 WHERE Id = :Opp.Associated_Contract_OSA__c LIMIT 1];
		
		// Lookup Contact
		Contact contact = [SELECT Id, Email 
							 FROM Contact 
							WHERE Id = :Opp.Client_Contact__c LIMIT 1];
		
		// Create an OrderHeader for media (Account, Contract, Tech_Contact, Description = product line
		//ordersystemstatus = pending, ordertype = Purchase
		//no instance type)
		
		List<Order_Header__c> list_keyMedia = new List<Order_Header__c>();
		String returnMessage = 'Media Order Headers created.';
		
		Id KeyRecordType, MediaRecordType;

		for(RecordType rType: [SELECT Id, DeveloperName 
								 FROM RecordType
								WHERE sObjectType = 'Order_header__c' 
								  AND isActive = true]){
			if(rType.DeveloperName.toLowerCase().contains('key')){
				KeyRecordType = rType.Id;	
			}
			else if(rType.DeveloperName.toLowerCase().contains('media')){
				MediaRecordType = rType.Id;
			}
		}
        
		Id CloudSystemAdmin =  Opp.Cloud_System_Administrator__c == null? Opp.Client_Contact__c: Opp.Cloud_System_Administrator__c;
		
        //need some key consistency for instance type
		if(keyAndMedia){
			Order_Header__c keyType = new Order_Header__c(Account__c = Con.Account.Id, Contract__c = Con.Id, Tech_Contact__c = Opp.Client_Contact__c
															, RecordTypeId = KeyRecordType
															, Contract_Signed_Date__c = Con.CompanySignedDate, Contact_Email__c = contact.Email, License_Band_Lawyers__c = Con.Account.License_Band__c
															, License_Band_Timekeepers__c=Con.Account.License_Band_Timekeepers__c, Employee__c=Con.Account.NumberOfEmployees
															, Description__c = description, Order_Type__c = 'Purchase', Order_System_Status__c = 'Pending');

			//insert the key Order Header
			list_keyMedia.add(keyType);
			returnMessage = 'Key and Media Order Headers created.';
		}

		Order_Header__c mediaType = new Order_Header__c(Account__c = Con.Account.Id, Contract__c = Con.Id, Tech_Contact__c = Opp.Client_Contact__c
			                                            , RecordTypeId = MediaRecordType
														, Contract_Signed_Date__c = Con.CompanySignedDate, Contact_Email__c = contact.Email, License_Band_Lawyers__c = Con.Account.License_Band__c
														, License_Band_Timekeepers__c=Con.Account.License_Band_Timekeepers__c, Employee__c=Con.Account.NumberOfEmployees
			                                            , Description__c = description, Order_Type__c = 'Purchase', Order_System_Status__c = 'Pending'
														, Cloud_System_Administrator__c = CloudSystemAdmin, Cloud_Location__c = Opp.Cloud_Location__c, Cloud_Name__c = Opp.Cloud_Name__c );
		//insert the media Order Header
		list_keyMedia.add(mediaType);
		
		try{
			insert list_keyMedia;
			return returnMessage;
		}
		catch(Exception e){
			return 'There was an error processing your request. ' + e.getMessage();
		}
		
	}

	private static Boolean hasMultipleOPCs(Opportunity Opp, Boolean isValidError){
		if(!isValidError) return false;

		if(Opp.Opportunity_Product_Components__r != null && Opp.Opportunity_Product_Components__r.size() > 1) return true;
		
		return false;
	}

	/*
	private static Boolean areProductLinesSame(Opportunity Opp, Boolean isValidError){
		if(!isValidError) return false;

		String productLine = '';
		Boolean firstElement = true;
		Boolean isError = false;
		for(Opportunity_Product_Component__c opc: Opp.Opportunity_Product_Components__r){
			if(firstElement){ 
				productLine = opc.Product_Line__c;
			}
			else if(opc.Product_Line__c !=  null && productLine == opc.Product_Line__c){
				isError = true;
				break;
			} 
			firstElement = false;
		}

		return isError;
	}
	*/
    
    private static Boolean areProductLinesSame(Opportunity Opp, Boolean isValidError){
		if(!isValidError) return false;

		Set<String> productLines = new Set<String>();
		for(Opportunity_Product_Component__c opc: Opp.Opportunity_Product_Components__r){
			if(opc.Product_LineNew__c ==  null)
                continue;
            
            if(!productLines.isEmpty() && productLines.contains(opc.Product_LineNew__r.Name))
				return true;

            productLines.add(opc.Product_LineNew__r.Name);
		}

		return false;
	}
}