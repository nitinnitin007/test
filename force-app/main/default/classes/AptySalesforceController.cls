public with sharing class AptySalesforceController {
    @AuraEnabled 
    public static Map<String, List<Object>> fetchUser(){
        Map<String, List<Object>> oUserInfo = new Map<String, List<Object>>();
        List<SObject> oProfile = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1];
        oUserInfo.put('profile',oProfile);
        List<SObject> oUser = [SELECT CreatedDate,UserRole.Name,LastLoginDate,LocaleSidKey,Manager.Name,TimeZoneSidKey,Department,Id,Division, 
                               Name, firstName, lastName, Email, 
                               (Select PermissionSet.Label from PermissionSetAssignments)
                               FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        oUserInfo.put('user',oUser);
        system.debug('oUserInfo = '+oUserInfo);
        if (!oUser.isEmpty()) 
        {
    		User user = (User) oUser[0];
    		// Access user fields
    		System.debug('User Id: ' + user.Id);
    		System.debug('User Name: ' + user.Name);
            List<Object> permissionSets = new List<Object>();
    		// Access Permission Set information
    		for (PermissionSetAssignment psa : user.PermissionSetAssignments) 
            {
                permissionSets.add(psa);
    		}
            oUserInfo.put('permissionSets', permissionSets);
		}
        return oUserInfo;  
    }
}