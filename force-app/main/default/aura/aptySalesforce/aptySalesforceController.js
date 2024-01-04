/*({
    doInit : function(component, event, helper) {
        var action = component.get("c.fetchUser");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var storeResponse = response.getReturnValue();
                var user = storeResponse.user[0];
                var profile = storeResponse.profile[0];
                var userInfo = {
                    id: user.Id,
                    profile: profile.Name,
                    role: user.UserRole ? user.UserRole.Name : undefined,
                    department: user.Department,
                    division: user.Division,
                    createdDate: user.CreatedDate,
                    lastLoginDate: user.LastLoginDate
                }
                component.set("v.userInfo", JSON.stringify(userInfo));
            }
        });
        $A.enqueueAction(action);
    }
})*/

({
    doInit: function (component, event, helper) {
        var action = component.get("c.fetchUser");
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var storeResponse = response.getReturnValue();
                var user = storeResponse.user[0];
                var profile = storeResponse.profile[0];
                var permissionSets = storeResponse.permissionSets || []; // Add null check

                // Extracted parameters from SOQL response
                var userInfo = {
                    id: user.Id,
                    profile: profile.Name,
                    role: user.UserRole ? user.UserRole.Name : undefined,
                    department: user.Department,
                    division: user.Division,
                    createdDate: user.CreatedDate,
                    lastLoginDate: user.LastLoginDate,
                    localeSidKey: user.LocaleSidKey,
                    manager: user.Manager ? user.Manager.Name : undefined,
                    timeZoneSidKey: user.TimeZoneSidKey,
                    email: user.Email,
                    firstName: user.FirstName,
                    lastName: user.LastName,
					Name: user.Name,
                    // Extract permission sets with null check
                    permissionSets: permissionSets.map(function (permissionSetAssignment) {
                        return permissionSetAssignment.PermissionSet.Label;
                    })
                }

                // Set the individual attributes in the component
                component.set("v.userId", userInfo.id);
                component.set("v.userProfile", userInfo.profile);
                component.set("v.userRole", userInfo.role);
                component.set("v.userDepartment", userInfo.department);
                component.set("v.userDivision", userInfo.division);
                component.set("v.userCreatedDate", userInfo.createdDate);
                component.set("v.userLastLoginDate", userInfo.lastLoginDate);
                component.set("v.userLocaleSidKey", userInfo.localeSidKey);
                component.set("v.userManager", userInfo.manager);
                component.set("v.userTimeZoneSidKey", userInfo.timeZoneSidKey);
                component.set("v.userEmail", userInfo.email);
                component.set("v.userFirstName", userInfo.firstName);
                component.set("v.userLastName", userInfo.lastName);
                component.set("v.userName", userInfo.Name);
                component.set("v.userPermissionSets", userInfo.permissionSets);

                component.set("v.userInfo", JSON.stringify(userInfo));
            }
        });
        $A.enqueueAction(action);
    }
})