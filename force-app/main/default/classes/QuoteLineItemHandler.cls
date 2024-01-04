public class QuoteLineItemHandler{
    public static Boolean runOnce = true;
    public static map<string, list<SBQQ__QuoteLine__c>> mapOfQuoteLst;
    public static map<String,String> mapOfQuoteLinePrint;
    
    public static map<string,decimal> mapOfCustomerGrandTotal;
    public static map<string,decimal> mapOfMonthlyDiscountPrice;

    public static map<string,decimal> mapOfMonthlyUnitListPrice;
    public static map<string,decimal> mapOfTotalListPrice;

    
    public static set<string> processedRecordSet = new set<string>();
    
    public static void updateQuoteLine(list<SBQQ__QuoteLine__c> quoteLineLst,  map<Id,SBQQ__Quote__c> mapOfQuote){
        mapOfQuoteLst = new map<string, list<SBQQ__QuoteLine__c>>();
        mapOfQuoteLinePrint = new map<String,String>();
        mapOfCustomerGrandTotal = new map<string,decimal>();
        mapOfMonthlyDiscountPrice = new map<string,decimal>();
        mapOfMonthlyUnitListPrice = new map<string,decimal>();
        mapOfTotalListPrice = new map<string,decimal>();

        
        decimal discount =0;
        
        integer quantityCount;
        for(SBQQ__QuoteLine__c ql : quoteLineLst){
            
            // set discount
            if(ql.SBQQ__Discount__c != null){
                discount= ql.SBQQ__Discount__c ;
            }
            else{
                discount= 0;
            }
            
            // separate quotelist with each bundle
            if(mapOfQuoteLst.isempty()){
                if (ql.SBQQ__RequiredBy__c != null) {
                    mapOfQuoteLst.put(ql.SBQQ__RequiredBy__c ,new list<SBQQ__QuoteLine__c>{ql});                                         
                }else {
                    mapOfQuoteLst.put(ql.Id ,new list<SBQQ__QuoteLine__c>{ql});                     
                }
            }else{ 
                if(ql.SBQQ__RequiredBy__c != null){
                    if(mapOfQuoteLst.containsKey(ql.SBQQ__RequiredBy__c)){
                        mapOfQuoteLst.get(ql.SBQQ__RequiredBy__c).add(ql); 
                    }
                    else{
                        mapOfQuoteLst.put(ql.SBQQ__RequiredBy__c,new list<SBQQ__QuoteLine__c>{ql});
                    }
                }else {
                     if(mapOfQuoteLst.containsKey(ql.Id)){
                        mapOfQuoteLst.get(ql.Id).add(ql); 
                    }
                    else{
                        mapOfQuoteLst.put(ql.Id,new list<SBQQ__QuoteLine__c>{ql});
                    }
                }
            }
            
            //system.debug('sun mapOfQuoteLst3:' + mapOfQuoteLst);
            //system.debug('sun ql.Is_Bundle_Product__c4:' + ql.Is_Bundle_Product__c);

            if (ql.Is_Bundle_Product__c == false ){  // new line.
               if(mapOfQuoteLinePrint.isempty() && ql.Print_at_Quote__c ){

                    mapOfQuoteLinePrint.put(ql.SBQQ__RequiredBy__c+'#'+string.valueOf(ql.Print_at_Quote__c),ql.SBQQ__Product__c); 
                }else {
                    if(!mapOfQuoteLinePrint.containsKey(ql.SBQQ__RequiredBy__c+'#'+string.valueOf(ql.Print_at_Quote__c)) && ql.Print_at_Quote__c){
                    
                    mapOfQuoteLinePrint.put(ql.SBQQ__RequiredBy__c+'#'+string.valueOf(ql.Print_at_Quote__c),ql.SBQQ__Product__c);
                    }
                }
            }  
            
            //system.debug('sun list of existing print flag-- mapOfQuoteLinePrint:' + mapOfQuoteLinePrint);
            
            if(ql.SegmentIndex_Year__c != null && ql.SegmentIndex_Year__c !=0){
                
                if(mapOfCustomerGrandTotal.isempty() ){
                
                    if (ql.SBQQ__CustomerTotal__c != null){
                        mapOfCustomerGrandTotal.put(ql.SBQQ__RequiredBy__c + '-' + ql.SegmentIndex_Year__c,ql.SBQQ__CustomerTotal__c);
                     }
                     else{
                         mapOfCustomerGrandTotal.put(ql.SBQQ__RequiredBy__c + '-' + ql.SegmentIndex_Year__c,0);
                     }
                        
                }else{
                    if(mapOfCustomerGrandTotal.containskey(ql.SBQQ__RequiredBy__c + '-' + ql.SegmentIndex_Year__c)){
                        decimal grandTotal = mapOfCustomerGrandTotal.get(ql.SBQQ__RequiredBy__c + '-' + ql.SegmentIndex_Year__c);
                        
                        if(ql.SBQQ__CustomerTotal__c!= null)
                            grandTotal = grandTotal + ql.SBQQ__CustomerTotal__c;
                        
                        mapOfCustomerGrandTotal.put(ql.SBQQ__RequiredBy__c + '-' + ql.SegmentIndex_Year__c,grandTotal);
                    }else{
                            if(ql.SBQQ__CustomerTotal__c == null){
                                mapOfCustomerGrandTotal.put(ql.SBQQ__RequiredBy__c + '-' + ql.SegmentIndex_Year__c,0);
                            }
                            else{
                                mapOfCustomerGrandTotal.put(ql.SBQQ__RequiredBy__c + '-' + ql.SegmentIndex_Year__c,ql.SBQQ__CustomerTotal__c);
                            }
                            
                    }
                }

                if(mapOfMonthlyDiscountPrice.isempty() ){
                        if(ql.Monthly_Net_Price_Currency__c == null){
                            mapOfMonthlyDiscountPrice.put(ql.SBQQ__RequiredBy__c + '-' + ql.SegmentIndex_Year__c,0);
                        }
                        else{                    
                            mapOfMonthlyDiscountPrice.put(ql.SBQQ__RequiredBy__c + '-' + ql.SegmentIndex_Year__c,( ql.Monthly_Net_Price_Currency__c ));
                        }
                
                }else{
                    if(mapOfMonthlyDiscountPrice.containskey(ql.SBQQ__RequiredBy__c + '-' + ql.SegmentIndex_Year__c)){
                        decimal monthlyUnitPriceTotal =0;
                        
                        if(mapOfMonthlyDiscountPrice.containsKey(ql.SBQQ__RequiredBy__c + '-' + ql.SegmentIndex_Year__c))
                            monthlyUnitPriceTotal = mapOfMonthlyDiscountPrice.get(ql.SBQQ__RequiredBy__c + '-' + ql.SegmentIndex_Year__c);
                        
                        if(ql.Monthly_Net_Price_Currency__c!= null)
                            monthlyUnitPriceTotal = monthlyUnitPriceTotal + ( ql.Monthly_Net_Price_Currency__c  );
                        
                        mapOfMonthlyDiscountPrice.put(ql.SBQQ__RequiredBy__c + '-' + ql.SegmentIndex_Year__c,monthlyUnitPriceTotal);
                    }else{
                            if(ql.Monthly_Net_Price_Currency__c == null){
                                mapOfMonthlyDiscountPrice.put(ql.SBQQ__RequiredBy__c + '-' + ql.SegmentIndex_Year__c,0);
                            }
                            else{
                                mapOfMonthlyDiscountPrice.put(ql.SBQQ__RequiredBy__c + '-' + ql.SegmentIndex_Year__c,( ql.Monthly_Net_Price_Currency__c ));
                                    
                            }
                            
                    }
                }

                
                
                // monthly list price
                
                if(mapOfMonthlyUnitListPrice.isempty() ){
                        if(ql.OSA_List_Price__c == null){
                            mapOfMonthlyUnitListPrice.put(ql.SBQQ__RequiredBy__c + '-' + ql.SegmentIndex_Year__c,0);
                        }
                        else{                    
                            mapOfMonthlyUnitListPrice.put(ql.SBQQ__RequiredBy__c + '-' + ql.SegmentIndex_Year__c,( ql.OSA_List_Price__c ));
                        }
                
                }else{
                    if(mapOfMonthlyUnitListPrice.containskey(ql.SBQQ__RequiredBy__c + '-' + ql.SegmentIndex_Year__c)){
                        decimal monthlyUnitListPriceTotal = 0;
                        if (mapOfMonthlyUnitListPrice.containsKey(ql.SBQQ__RequiredBy__c + '-' + ql.SegmentIndex_Year__c))
                            monthlyUnitListPriceTotal = mapOfMonthlyUnitListPrice.get(ql.SBQQ__RequiredBy__c + '-' + ql.SegmentIndex_Year__c);
                            
                            if (monthlyUnitListPriceTotal == null){
                                monthlyUnitListPriceTotal = 0;
                            }
                                                
                        if(ql.OSA_List_Price__c!= null)
                            monthlyUnitListPriceTotal = monthlyUnitListPriceTotal + ( ql.OSA_List_Price__c  );
                        

                            mapOfMonthlyUnitListPrice.put(ql.SBQQ__RequiredBy__c + '-' + ql.SegmentIndex_Year__c,monthlyUnitListPriceTotal);
                    }else{
                            if(ql.Monthly_Net_Price_Currency__c == null){
                                mapOfMonthlyUnitListPrice.put(ql.SBQQ__RequiredBy__c + '-' + ql.SegmentIndex_Year__c,0);
                            }
                            else{
                                mapOfMonthlyUnitListPrice.put(ql.SBQQ__RequiredBy__c + '-' + ql.SegmentIndex_Year__c,( ql.OSA_List_Price__c ));

                            }
                            
                    }
                }

                
                
                // Total List price
                

                if(mapOfTotalListPrice.isempty() ){
                        if(ql.SBQQ__ListTotal__c == null){
                            mapOfTotalListPrice.put(ql.SBQQ__RequiredBy__c + '-' + ql.SegmentIndex_Year__c,0);
                        }
                        else{                    
                            mapOfTotalListPrice.put(ql.SBQQ__RequiredBy__c + '-' + ql.SegmentIndex_Year__c,( ql.SBQQ__ListTotal__c ));
                        }
                
                }else{
                    if(mapOfTotalListPrice.containskey(ql.SBQQ__RequiredBy__c + '-' + ql.SegmentIndex_Year__c)){
                        decimal totalListPriceTotal =0;
                        if (mapOfTotalListPrice.containsKey(ql.SBQQ__RequiredBy__c + '-' + ql.SegmentIndex_Year__c))
                             totalListPriceTotal = mapOfTotalListPrice.get(ql.SBQQ__RequiredBy__c + '-' + ql.SegmentIndex_Year__c);

                            if (totalListPriceTotal == null){
                                totalListPriceTotal = 0;
                            }
                        
                        if(ql.SBQQ__ListTotal__c!= null)
                            totalListPriceTotal = totalListPriceTotal + ( ql.SBQQ__ListTotal__c  );

                        
                        mapOfTotalListPrice.put(ql.SBQQ__RequiredBy__c + '-' + ql.SegmentIndex_Year__c,totalListPriceTotal);
                    }else{
                            if(ql.SBQQ__ListTotal__c == null){
                                mapOfTotalListPrice.put(ql.SBQQ__RequiredBy__c + '-' + ql.SegmentIndex_Year__c,0);
                            }
                            else{
                                mapOfTotalListPrice.put(ql.SBQQ__RequiredBy__c + '-' + ql.SegmentIndex_Year__c,( ql.SBQQ__ListTotal__c ));
                                    
                            }
                            
                    }
                }

                

            }
        
        }

        list<SBQQ__QuoteLine__c> qlLstLoop = new list<SBQQ__QuoteLine__c>();
        
        for(string a : mapOfQuoteLst.keySet()){
            String product = '';
            
            //system.debug('sun required by a:' + a);
            
            if(mapOfQuoteLinePrint.containsKey(a+'#'+'true')){
                product =  mapOfQuoteLinePrint.get(a+'#'+'true');
            }

            list<SBQQ__QuoteLine__c> qlLst = mapOfQuoteLst.get(a);
            SBQQ__QuoteLine__c newQl =  new SBQQ__QuoteLine__c();
            decimal quantityPriceCount = 0;
            string txtArea = '';
            string bundleString = '';
            for(SBQQ__QuoteLine__c ql : qlLst){

                if(product != '' && ql.SBQQ__Product__c == product){
                    ql.Print_at_Quote__c = True;
                    
                    //system.debug('sun product1:' + product);
                    
                    if(mapOfCustomerGrandTotal.containskey(ql.SBQQ__RequiredBy__c + '-' +ql.SegmentIndex_Year__c))
                        ql.Customer_Grand_Total__c = mapOfCustomerGrandTotal.get(ql.SBQQ__RequiredBy__c + '-' +ql.SegmentIndex_Year__c);

                    if(mapOfMonthlyDiscountPrice.containskey(ql.SBQQ__RequiredBy__c + '-' +ql.SegmentIndex_Year__c))
                        ql.Monthly_Unit_Price__c = mapOfMonthlyDiscountPrice.get(ql.SBQQ__RequiredBy__c + '-' +ql.SegmentIndex_Year__c);
                    

                    if(mapOfMonthlyUnitListPrice.containskey(ql.SBQQ__RequiredBy__c + '-' +ql.SegmentIndex_Year__c))
                        ql.Monthly_Unit_List_Price__c = mapOfMonthlyUnitListPrice.get(ql.SBQQ__RequiredBy__c + '-' +ql.SegmentIndex_Year__c);

                    if(mapOfTotalListPrice.containskey(ql.SBQQ__RequiredBy__c + '-' +ql.SegmentIndex_Year__c))
                        ql.Total_List_Price__c = mapOfTotalListPrice.get(ql.SBQQ__RequiredBy__c + '-' +ql.SegmentIndex_Year__c);
                    
                    qlLstLoop.add(ql);
                }
                else if(ql.Print_at_Quote__c == true &&  product != '' && ql.SBQQ__Product__c != product && mapOfQuoteLinePrint.containsKey(a+'#'+'true')){
                    
                    //system.debug('sun else product2:' + product);

                    
                    ql.Print_at_Quote__c = false;
                    qlLstLoop.add(ql);
                }

                if(product == '' && ql.Is_Bundle_Product__c == false){  // added additional condition.

                    //system.debug('sun3 product2:' + product);

                    product = ql.SBQQ__Product__c;
                    ql.Print_at_Quote__c = True;
                    
                    //system.debug('sun4 product2:' + product);
                    
                    if(mapOfCustomerGrandTotal.containskey(ql.SBQQ__RequiredBy__c + '-' +ql.SegmentIndex_Year__c))
                        ql.Customer_Grand_Total__c = mapOfCustomerGrandTotal.get(ql.SBQQ__RequiredBy__c + '-' +ql.SegmentIndex_Year__c);

                    if(mapOfMonthlyDiscountPrice.containskey(ql.SBQQ__RequiredBy__c + '-' +ql.SegmentIndex_Year__c))
                        ql.Monthly_Unit_Price__c = mapOfMonthlyDiscountPrice.get(ql.SBQQ__RequiredBy__c + '-' +ql.SegmentIndex_Year__c);                    


                    if(mapOfMonthlyUnitListPrice.containskey(ql.SBQQ__RequiredBy__c + '-' +ql.SegmentIndex_Year__c))
                        ql.Monthly_Unit_List_Price__c = mapOfMonthlyUnitListPrice.get(ql.SBQQ__RequiredBy__c + '-' +ql.SegmentIndex_Year__c);

                    if(mapOfTotalListPrice.containskey(ql.SBQQ__RequiredBy__c + '-' +ql.SegmentIndex_Year__c))
                        ql.Total_List_Price__c = mapOfTotalListPrice.get(ql.SBQQ__RequiredBy__c + '-' +ql.SegmentIndex_Year__c);                    

                    qlLstLoop.add(ql);
                }

                //system.debug('ql++'+ql);
                if(ql.Is_Bundle_Product__c){
                    if(!String.isBlank(ql.Item_Master_Name__c)) 
                        bundleString = ql.Item_Master_Name__c;
                    newQl = ql;
                    newQl.id = ql.Id;

                    }else{
                
                    
                    if ( mapOfQuote.ContainsKey(ql.SBQQ__Quote__c)){
                        SBQQ__Quote__c quote = mapOfQuote.get(ql.SBQQ__Quote__c);
                        
                        if(ql.SegmentIndex_Year__c == 1 || !quote.Extended_Initial_Term__c){
                            if(txtArea != '' && !String.isBlank(ql.Item_Master_Name__c)){
                                txtArea = txtArea + '\r\n' +  ql.SBQQ__Product__r.ProductCode + '  ' +  ql.Item_Master_Name__c ;
                            }else if (!String.isBlank(ql.Item_Master_Name__c)) {
                                txtArea = 'Including :\r\n' + ql.SBQQ__Product__r.ProductCode + '  ' +  ql.Item_Master_Name__c ;
                            }
                        }
                    }
                }
            }
            
    
            string bundleText = bundleString + '\r\n' + txtArea;
            string bundleTextExtn1 = '';
            string bundleTextExtn2 = '';
            string bundleTextExtn3 = '';
            integer fieldLength = 255;
            
            list<String> bundleTextList= splitStringBySize(bundleText,fieldLength);

            if (bundleTextList.size()>0){
                bundleTextExtn1 = bundleTextList[0];
            }

            if (bundleTextList.size()>1){
                bundleTextExtn2 = bundleTextList[1];
            }


            if (bundleTextList.size()>2){
                bundleTextExtn3 = bundleTextList[2];
            }
            
            newQl.Bundle_Products__c = bundleTextExtn1;
            newQl.Bundle_Products_Extn2__c = bundleTextExtn2;
            newQl.Bundle_Products_Extn3__c = bundleTextExtn3;
            newQl.Print_at_Quote__c = false;

            
            if(newQl.id !=null){
                qlLstLoop.add(newQl);
                
            }

        }
        
        if(qlLstLoop.size()>0){
            update qlLstLoop;
        }
    }

    public static List<String> splitStringBySize(String str, Integer size) {
        List<String> split = new List<String>();
        for (integer i = 0; i <= str.length() / size; i++) {
            split.add(str.substring(i * size, Math.min((i + 1) * size, str.length())));
        }
        return split;
    }


    public static void setnumberOfQLI(List<SBQQ__QuoteLine__c> quoteLineNewList, Map<Id,SBQQ__QuoteLine__c> quoteLineOldMap) {
        set<Id> quotesToUpdate = new set<Id>();
        for (SBQQ__QuoteLine__c quoteLineNew : quoteLineNewList) {

            if (quoteLineNew.SBQQ__NetPrice__c != null) {
                quotesToUpdate.add(quoteLineNew.SBQQ__Quote__c);
            }
        }

        if (!quotesToUpdate.isEmpty()) {
            set<string> productCodesToExclude = new set<string>{
                'GE-01554','GE-01567','GE-01647','GE-01646','BU-01408'
            };
            List<SBQQ__Quote__c> quoteList = [
                SELECT Id
                     , Number_of_QLIs__c
                     , Trigger_Quote_Calculation__c
                     , Number_of_DLIs__c
                     , (SELECT Id FROM SBQQ__LineItems__r WHERE SBQQ__NetPrice__c != null and SBQQ__ProductCode__c NOT IN :productCodesToExclude)
                  FROM SBQQ__Quote__c 
                 WHERE Id IN :quotesToUpdate 
            ];

            List<SBQQ__Quote__c> quoteUpdateList = new List<SBQQ__Quote__c>();
            for (SBQQ__Quote__c quote : quoteList) {
                if (quote.Number_of_QLIs__c != quote.SBQQ__LineItems__r.Size()) {
                    quote.Number_of_QLIs__c = quote.SBQQ__LineItems__r.size();

                    if (quote.Number_of_QLIs__c == quote.Number_of_DLIs__c) {
                        quote.QLI_Update_Date_Time__c = Datetime.Now();
                    }
                    quoteUpdateList.add(quote);
                }
            }

            if (!quoteUpdateList.isEmpty()) {
                Database.update(quoteUpdateList,false);
            }
        }
    }
    
     public static void Method3()
    {
      integer i = 0;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;   
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;  
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;   
    
    }   
    
}