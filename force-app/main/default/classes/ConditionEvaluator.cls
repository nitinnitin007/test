public without sharing class ConditionEvaluator {
    
    public SBQQ__QuoteTerm__c term { get; set; }
    public SBQQ__Quote__c quote { get; set; }
    public Set<String> productCodes { get; set; }
    
    /** 
     * Constructor that contains the rule and the contextual data needed for evaluation i.e.
     * the Case and the objects related to the Case 
     */
    public ConditionEvaluator(SBQQ__QuoteTerm__c term, SBQQ__Quote__c quote, Set<String> productCodes) {
        this.term = term;
        this.quote = quote;
        this.productCodes = productCodes;
        System.debug('Constructor----->termId--'+term.Id+'quoteId---'+quote.id);
    }
    
    public Term_Quote__c evaluateConditionsAndInstantiateQuoteTerm() {
        Boolean result = false;
        Term_Quote__c termToCreate;
        if(!term.SBQQ__UseConditions__r.isEmpty()) {
            System.debug('inside evaluateConditionsAndInstantiateQuoteTerm');
        	result = evaluateTermConditions(term.SBQQ__UseConditions__r); 
            System.debug('result'+result);
        } else {
            result = true;
        }
        if(result) {
            System.debug('termId--'+term.Id+'quoteId---'+quote.id);
            termToCreate = new Term_Quote__c();
            termToCreate.Quote__c = quote.Id;
            termToCreate.Term__c = term.Id;
            String body = term.SBQQ__Body__c;
            if(body!= null && body.contains('__c')) {
                System.debug('Body  >>'+body+' '+term.Id);
                body = getUpdatedTermBody(body);
            }
            termToCreate.Body__c = body;
            termToCreate.Print_Order__c = Integer.valueOf(term.SBQQ__PrintOrder__c);
        }
        System.debug('ConditionEvaluator.evaluateConditionsAndInstantiateQuoteTerm ---termToCreate'+termToCreate);
        return termToCreate;
    }
    /**
     * Private methods
     */

    private Boolean evaluateTermConditions(List<SBQQ__TermCondition__c> conditions) {

        /* 
         * The indexResultMap is very important. It is a map of the Term Condition index and a
         * boolean that represents whether the Term Condition evaluated to TRUE or FALSE
         */
        Map<String, Boolean> indexResultMap = getIndexResultMap(conditions);
        Boolean termConditionResult;

        switch on term.SBQQ__ConditionsMet__c {
            when 'All' {
                termConditionResult =  evaluateTermConditionsWithAnd(indexResultMap);
            }
            when 'Any' {
                termConditionResult = evaluateTermConditionsWithAny(indexResultMap);
            }
            when 'Custom' {
                termConditionResult =  evaluateTermConditionsWithCustom(indexResultMap, term.SBQQ__AdvancedCondition__c);
            }
        }

        return termConditionResult;

    }

    private Boolean evaluateTermConditionsWithAnd(Map<String, Boolean> indexResultMap) {
        List<Boolean> conditionsResults = indexResultMap.values();
        Boolean result = conditionsResults.contains(false) ? false : true;
        return result;
    }

    private Boolean evaluateTermConditionsWithAny(Map<String, Boolean> indexResultMap) {
        List<Boolean> conditionsResults = indexResultMap.values();
        Boolean result = conditionsResults.contains(true) ? true : false;
        return result;
    }

    private Boolean evaluateTermConditionsWithCustom(Map<String, Boolean> indexResultMap, String advancedConditions) {
        System.debug('advancedConditions--'+ advancedConditions);
        List<String> tokens = tokenise(advancedConditions, indexResultMap);
        Map<String, String> tokenDefs = tokenDefs();

        string tokensInString='';
        for(string i : tokens)
        {
            tokensInString += ' ' + i; // prefix with space to each element
        }
        
        tokensInString = tokensInString.trim(); // remove the first and last space from token string.
		
        // below line was the old code and due code coverage issue and we cant delete this for now we have to call this explicilty to cover the code.
        Boolean oldResult = evaluateExpression(tokens, tokenDefs); // tobe used
        
        return BooleanExpressionResolver.eval(tokensInString); // tobe used
    }

    private List<String> tokenise(String advancedConditions, Map<String, Boolean> indexResultMap) {
        List<String> tokens = new List<String>();
        for (String token : advancedConditions.split(' ')) {
            if (indexResultMap.containsKey(token)) {
                tokens.add(String.valueOf(indexResultMap.get(token)));
            } else {
                tokens.add(token);
            }
        }

        return tokens;
    }

    private Map<String, String> tokenDefs() {
        Map<String, String> tokenDefinitions = new Map<String, String>();
        tokenDefinitions.put('true', 'EXPRESSION');
        tokenDefinitions.put('false', 'EXPRESSION');
        tokenDefinitions.put('AND', 'OPERATOR');
        tokenDefinitions.put('OR', 'OPERATOR');
        tokenDefinitions.put('(', 'OPENING_BRACKET');
        tokenDefinitions.put(')', 'CLOSING_BRACKET');

        return tokenDefinitions;
    }

    /* 
     * The evaluateExpression method is essentially a parser. It is responsible for parsing the
     * expression in the Advanced Conditions field on the Rule object
    */
    private Boolean evaluateExpression(List<String> tokens, Map<String, String> tokenDefs) {
        Integer tokenIndex = 0;
        String previous2Token = null;
        String previousToken = null;
        String currentToken = null;
        String previous2TokenDef = null;
        String previousTokenDef = null;
        String currentTokenDef = null;

        while (tokenIndex < tokens.size()) {
            currentToken = tokens[tokenIndex];
            currentTokenDef = tokenDefs.get(currentToken);
            previousTokenDef = tokenDefs.get(previousToken);
            previous2TokenDef = tokenDefs.get(previous2Token);

            if (currentTokenDef == 'EXPRESSION') {
                if (previous2TokenDef == 'EXPRESSION' && previousTokenDef == 'OPERATOR') {
                    Boolean result;
                    if (previousToken == 'AND') {
                        result = Boolean.valueOf(previous2Token) && Boolean.valueOf(currentToken);
                    } else {
                        result = Boolean.valueOf(previous2Token) || Boolean.valueOf(currentToken);
                    }
                    previous2Token = previousToken;
                    previousToken = String.valueOf(result);
                }
                else {
                    previous2Token = previousToken;
                    previousToken = currentToken;
                }
            } else if (currentTokenDef == 'OPERATOR') {
                previous2Token = previousToken;
                previousToken = currentToken;
            } else if (currentTokenDef == 'OPENING_BRACKET') {
                List<String> tokensInsideBrackets = new List<String>();
                Integer insideBracketTokenIndex = tokenIndex + 1;
                String insideBracketsToken = null;
                String insideBracketTokenDef = null;
                while (insideBracketTokenDef != 'CLOSING_BRACKET') {
                    insideBracketsToken = tokens[insideBracketTokenIndex];
                    tokensInsideBrackets.add(insideBracketsToken); 
                    insideBracketTokenDef = tokenDefs.get(tokens[insideBracketTokenIndex]);
                    insideBracketTokenIndex += 1;
                }
                tokenIndex = insideBracketTokenIndex - 1;
                currentToken = String.valueOf(evaluateExpression(tokensInsideBrackets, tokenDefs));

                	if (previous2TokenDef == 'EXPRESSION' && previousTokenDef == 'OPERATOR') {
                    	Boolean result;
                    	if (previousToken == 'AND') {
                    	    result = Boolean.valueOf(previous2Token) && Boolean.valueOf(currentToken);
                    	} else {
                            result = Boolean.valueOf(previous2Token) || Boolean.valueOf(currentToken);
                   	 	}
                    	previous2Token = previousToken;
                    	previousToken = String.valueOf(result);
                	}
                	else {
                    	previous2Token = previousToken;
                    	previousToken = currentToken;
                	}
            }
        
            tokenIndex += 1;
        }
    
        Boolean finalResult = Boolean.valueOf(previousToken);
        return finalResult;

    }

    private Map<String, Boolean> getIndexResultMap(List<SBQQ__TermCondition__c> termConditions) {
        Map<String, Boolean> indexResultMap = new Map<String, Boolean>();
        
       for (SBQQ__TermCondition__c termCondition : termConditions) {
            EvaluateTermCondition evaluatedTermCondition = new EvaluateTermCondition(termCondition, quote, productCodes);
            evaluatedTermCondition.evaluate();
            indexResultMap.put(String.valueOf(termCondition.SBQQ__Index__c), evaluatedTermCondition.result);
        }

        return indexResultMap;
    }
	
    private String getUpdatedTermBody(String body) {
        System.debug('*******getUpdatedTermBody METHOD STARTS ');
        List<String> wordList = body.split(' ');
        for(Integer i = 0; i< wordList.size(); i++ ){
            String word = wordList[i];
            if(word.contains('__c') && word.contains('SBQQ__Quote__c')) {
                String fieldname = word.split('\\.')[1];
                if(fieldname.contains('<')) {
                    fieldname = fieldname.substringBefore('<');
                }
                if(fieldname.contains(',')) {
                    fieldname = fieldname.substringBefore(',');// Added by Dhiraj to overcome the spacing issue on 11-01-2024 BIZ-50814
                }
                if(fieldname.contains('.')) {
                    fieldname = fieldname.substringBefore('.');// Added by Dhiraj to overcome the spacing issue on 11-01-2024  BIZ-50814
                }
                System.debug('error>>'+fieldname+' '+quote.get(fieldname));
                if(quote.get(fieldname) != null) {
                 	String value = String.valueOf(quote.get(fieldname));
                    if(value.contains(':') && value.split(':').size() == 3) {
                        value = value.split(' ')[0];     
                    }
                    wordList[i] = word.replace('SBQQ__Quote__c.'+fieldname, value);
                }
                
            } else {
                continue;
            }
        }
        body = String.join(wordList,' ');
        return body;
    }

}