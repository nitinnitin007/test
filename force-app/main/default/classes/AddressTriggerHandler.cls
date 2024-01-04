/**
* @description       : This class is a handler class for AddressTrigger.
* @author            : Pankaj Kumar
* @last modified on  : 09-11-2023
* @last modified by  : Pankaj Kumar
* Modifications Log
* Ver   Date         Author         Modification
* 1.0   07-07-2023   Pankaj Kumar   Initial Version
**/
public without Sharing class AddressTriggerHandler {
       /**
* @description : This method will handle before insert event of Address object. 
* @author Pankaj Kumar | 09-11-2023 
* @param List<Address__c> newAddressList 
**/    
    public static boolean beforeInsertFirstRun=true;
    public static void beforeInsert(List<Address__c> newAddressList){
        if(beforeInsertFirstRun){
            defaultAddressDeselection(newAddressList,null,true);
            beforeInsertFirstRun=false; 
        }
    }
    /**
* @description : This method will handle before update event of Address object.
* @author Pankaj Kumar | 09-11-2023 
* @param List<Address__c> newAddressList 
* @param Map<Id Address__c> oldMap 
**/    
    public static boolean beforeUpdateFirstRun=true;
    public static void beforeUpdate(List<Address__c> newAddressList,Map<Id,Address__c> oldMap){
        if(beforeUpdateFirstRun){
            addressStatusInactive(newAddressList,oldMap,false);
            defaultAddressDeselection(newAddressList,oldMap,false);         
            beforeUpdateFirstRun=false;
        }
    }
 /**
* @description : This method will handle after insert event of Address object. 
* @author Pankaj Kumar | 09-11-2023 
* @param List<Address__c> newAddressList 
**/    
    public static boolean afterInsertFirstRun=true;
    public static void afterInsert(List<Address__c> newAddressList){
        if(afterInsertFirstRun){
            afterInsertFirstRun=false;
            addressNameUpdate(newAddressList,null,true);
            defaultAddressPopulation(newAddressList,null,true);   
        }
    }
 /**
* @description : This method will handle after update event of Address object. 
* @author Pankaj Kumar | 09-11-2023 
* @param List<Address__c> newAddressList 
**/    
    public static boolean afterUpdateFirstRun=true;
    public static void afterUpdate(List<Address__c> newAddressList,Map<Id,Address__c> oldMap){
        if(afterInsertFirstRun){
            afterUpdateFirstRun=false;
            addressNameUpdate(newAddressList,oldMap,false);            
            defaultAddressPopulation(newAddressList,oldMap,false);   
        }
    }   
/**
* @description : This method will handle Address Name update on Address object.
* @author Pankaj Kumar | 10-20-2023 
* @param List<Address__c> newAddressList 
* @param Map<Id Address__c> oldMap 
**/    
    public static void addressNameUpdate(List<Address__c> newAddressList,Map<Id,Address__c> oldMap,boolean isInsert){       
        
        try{
        List<Address__c> addList = new List<Address__c>();
        Set<id> newAddIds = new Set<id>();
        for(Address__c addr: newAddressList){
            if(addr.Id!=null){
                newAddIds.add(addr.Id);
            }           
        }
        Map<id,Address__c> mapIdAddress= new Map<id,Address__c>([SELECT Id, Address__c,Account__c,Default_Billing_Address__c,Default_Shipping_Address__c
                                                                     FROM Address__c WHERE ID =:newAddIds]);
        for(Address__c addr: newAddressList){
                Account acc = new Account();                
                acc.Id = addr.Account__c;
                Address__c ad=mapIdAddress.get(addr.id);
                Address add = (Address)ad.Address__c;
                if((isInsert && (addr.Address__City__s!=null || addr.Address__PostalCode__s!=null || addr.Address__StateCode__s!=null ||addr.Address__CountryCode__s!=null)) ||
                   (!isInsert && (addr.Address__City__s!=oldMap.get(addr.Id).Address__City__s || addr.Address__CountryCode__s!=oldMap.get(addr.Id).Address__CountryCode__s || addr.Address__PostalCode__s!=oldMap.get(addr.Id).Address__PostalCode__s || addr.Address__StateCode__s!=oldMap.get(addr.Id).Address__StateCode__s))){
                       Address__c a = new Address__c();
                       a.Name = addr.Address__City__s + '-' + add.getState() + '-' + addr.Address__PostalCode__s;
                       a.Country__c = add.getCountry();
                       a.Id = addr.Id;
                       addList.add(a);
                }
        }
            if(addList!=null && !addList.isEmpty()){
                Database.update(addList);
            }
        }catch(Exception ex) {
            System.debug('Exception Caught at : ' + ex.getLineNumber() + '** Exception Message : '+ ex.getMessage() + '  *Exception Cause : ' +ex.getCause());
        } 
    }

    /**
* @description : This method will handle RestrictInactiveStatusForDefaultAddress on Address object.
* @author Pankaj Kumar | 10-20-2023 
* @param List<Address__c> newAddressList 
* @param Map<Id Address__c> oldMap 
**/    
    public static void addressStatusInactive(List<Address__c> newAddressList,Map<Id,Address__c> oldMap,boolean isInsert){
        try{
            Set<id> accIds = new Set<id>();
            Set<Id> newAddrId = new Set<Id>();
            Map<id,id> mapAccAddress = new Map<id,id>();
            for(Address__c addr: newAddressList){
                if(addr.Default_Billing_Address__c== false && addr.Default_Billing_Address__c==false 
                && oldMap.get(addr.id).Status__c!=addr.Status__c && addr.Status__c=='Inactive'){
                    accIds.add(addr.Account__c);
                    newAddrId.add(addr.Id);
                }
            }
            List<Address__c> adrList = [Select id,Default_Billing_Address__c,Default_Shipping_Address__c,Account__c from Address__c 
                                    where Account__c=:accIds AND (Default_Billing_Address__c=true OR Default_Shipping_Address__c=true) AND id!=:newAddrId];
            
            if(adrList!=null){
                for(Address__c adr:adrList){
                    if(adr!=null){
                        mapAccAddress.put(adr.Account__c,adr.Id);
                    }
                }
            }
            for(Address__c addr: newAddressList){
                if(addr.Default_Billing_Address__c== false && addr.Default_Shipping_Address__c==false 
                && oldMap.get(addr.id).Status__c!=addr.Status__c && addr.Status__c=='Inactive' && mapAccAddress.get(addr.Account__c)==null){
                    addr.addError('Please create a new address with Default Billing / Shipping Address checked before updating the Status to Inactive.');
                }
            }   
        }catch(Exception ex) {
            System.debug('Exception Caught at : ' + ex.getLineNumber() + '** Exception Message : '+ ex.getMessage() + '  *Exception Cause : ' +ex.getCause());
        }   
    }   
    /**
* @description : Created as part of BIZ-45061. This method will handle default billing address & default shipping address type selection/deselection automation.
* @author Pankaj Kumar | 07-07-2023 
* @param List<Address__c> newAddressList 
* @param Map<Id Address__c> oldMap 
* @param boolean isInsert 
**/
    public static void defaultAddressDeselection(List<Address__c> newAddressList,Map<Id,Address__c> oldMap,boolean isInsert){
        
        try{
            Set<id> accIds = new Set<id>();
            Set<id> addId = new Set<Id>();
            List<Address__c> oldAddressUpdateList = new List<Address__c>();
            List<Address__c> addList = new List<Address__c>();
            List<Address__c> addrList=null;
            Map<String,List<Address__c>> mapAccAddressList = new Map<String,List<Address__c>>();
            for(Address__c addr: newAddressList){
                if(isInsert && addr.Account__c!=null && (addr.Default_Billing_Address__c==true || addr.Default_Shipping_Address__c==true)){
                    accIds.add(addr.Account__c);
                    addId.add(addr.Id);
                }else if(!isInsert && ((addr.Default_Billing_Address__c!=oldMap.get(addr.Id).Default_Billing_Address__c) 
                                       ||(addr.Default_Shipping_Address__c!=oldMap.get(addr.Id).Default_Shipping_Address__c))
                         && addr.Account__c!=null){
                             accIds.add(addr.Account__c);
                             addId.add(addr.Id);
                         }
            }
            if(accIds!=null && !accids.isEmpty()){
                addrList = [SELECT id,Account__c,Default_Billing_Address__c,Default_Shipping_Address__c 
                            FROM Address__c 
                            WHERE Account__c=:accIds AND (Default_Billing_Address__c=true OR Default_Shipping_Address__c=true) AND Id NOT IN:addId];
            }
            if(addrList!=null && !addrList.isEmpty()){ 
                for(Address__c addr: addrList){
                    if(mapAccAddressList.containsKey(addr.Account__c)){
                        addList = mapAccAddressList.get(addr.Account__c);
                        addList.add(addr);
                        mapAccAddressList.put(addr.Account__c,addList);
                    }else{                
                        mapAccAddressList.put(addr.Account__c,new List<Address__c>{addr});
                    }
                }
                for(Address__c addr: newAddressList){
                    if(mapAccAddressList.get(addr.Account__c)!=null){
                        for(Address__c addres:mapAccAddressList.get(addr.Account__c)){
                            if((isInsert || (!isInsert && (addr.Default_Billing_Address__c!=oldMap.get(addr.Id).Default_Billing_Address__c)))
                               && addr.Account__c!=null && addr.Default_Billing_Address__c==true && addres.Default_Billing_Address__c==true){
                                   addres.Default_Billing_Address__c = false;
                                   
                               }
                            if((isInsert || (!isInsert && (addr.Default_Shipping_Address__c!=oldMap.get(addr.Id).Default_Shipping_Address__c)))
                               && addr.Account__c!=null && addr.Default_Shipping_Address__c==true && addres.Default_Shipping_Address__c==true){
                                   addres.Default_Shipping_Address__c = false;
                               }
                            oldAddressUpdateList.add(addres);
                        } 
                    }                
                }
                if(oldAddressUpdateList!=null && !oldAddressUpdateList.isEmpty()){
                    Database.update(oldAddressUpdateList);
                }
            }
        }catch(Exception ex) {
            System.debug('Exception Caught at : ' + ex.getLineNumber() + '** Exception Message : '+ ex.getMessage() + '  *Exception Cause : ' +ex.getCause());
        } 
    } 
    
    /**
* @description :  Created as part of BIZ-45062. This method will handle billing & shipping address population on Account object.
* @author Pankaj Kumar | 07-07-2023 
* @param List<Address__c> newAddressList 
* @param Map<Id Address__c> oldMap 
* @param boolean isInsert 
**/
    
    public static void defaultAddressPopulation(List<Address__c> newAddressList,Map<Id,Address__c> oldMap,boolean isInsert){
        try{
            List<Account> accList = new List<Account>();
            List<Address__c> addList = new List<Address__c>();
            Set<id> newAddIds = new Set<id>();
            for(Address__c addr: newAddressList){
                if(addr.Id!=null){
                    newAddIds.add(addr.Id);
                }           
            }
            Map<id,Address__c> mapIdAddress= new Map<id,Address__c>([SELECT Id, Address__c,Account__c,Default_Billing_Address__c,Default_Shipping_Address__c FROM Address__c WHERE ID =:newAddIds]);

            for(Address__c addr: newAddressList){                
            	Account acc=new Account();           
                acc.Id = addr.Account__c;
                Address__c ad=mapIdAddress.get(addr.id);
                Address add = (Address)ad.Address__c;
                if((isInsert || (!isInsert && ((addr.Default_Billing_Address__c!=oldMap.get(addr.Id).Default_Billing_Address__c)
                                               ||(addr.Default_Shipping_Address__c!=oldMap.get(addr.Id).Default_Shipping_Address__c))))
                   && addr.Account__c!=null && (addr.Default_Billing_Address__c==true || addr.Default_Shipping_Address__c==true)){
                        if(addr.Default_Billing_Address__c==true){
                           acc.Id = addr.Account__c;
                           acc.BillingCity = addr.Address__City__s;
                           acc.BillingCountry = add.getCountry();
                           acc.BillingPostalCode = addr.Address__PostalCode__s;
                           acc.BillingState = add.getState();
                           acc.BillingStreet = addr.Address__Street__s;                
                        }
                        if(addr.Default_Shipping_Address__c==true){
                           acc.Id = addr.Account__c;
                           acc.ShippingCity = addr.Address__City__s;
                           acc.ShippingCountry = add.getCountry();
                           acc.ShippingPostalCode = addr.Address__PostalCode__s;
                           acc.ShippingState = add.getState();
                           acc.ShippingStreet = addr.Address__Street__s;
                       }                
                }
                if((!isInsert && addr.Account__c!=null && (((addr.Default_Billing_Address__c!=oldMap.get(addr.Id).Default_Billing_Address__c) && addr.Default_Billing_Address__c==false)
                                                           ||((addr.Default_Shipping_Address__c!=oldMap.get(addr.Id).Default_Shipping_Address__c) && addr.Default_Shipping_Address__c==false)))){
                                                               acc.Id = addr.Account__c;
                                                               if(oldMap.get(addr.Id).Default_Billing_Address__c==true && addr.Default_Billing_Address__c==false){
                                                                   acc.Id = addr.Account__c;
                                                                   acc.BillingCity = '';
                                                                   acc.BillingCountry = '';
                                                                   acc.BillingPostalCode = '';
                                                                   acc.BillingState = '';
                                                                   acc.BillingStreet = '';                
                                                               }
                                                               if(oldMap.get(addr.Id).Default_Shipping_Address__c==true && addr.Default_Shipping_Address__c==false){
                                                                   acc.Id = addr.Account__c;
                                                                   acc.ShippingCity = '';
                                                                   acc.ShippingCountry = '';
                                                                   acc.ShippingPostalCode = '';
                                                                   acc.ShippingState = '';
                                                                   acc.ShippingStreet = '';
                                                               }                
                                                           }
                 if(acc!=null){
                    accList.add(acc);
                 }
            }
            if(!accList.isEmpty()){
                Database.update(accList,false);
            }
        }catch(Exception ex) {
            System.debug('Exception Caught at : ' + ex.getLineNumber() + '** Exception Message : '+ ex.getMessage() + '  *Exception Cause : ' +ex.getCause());
        } 
    }
}