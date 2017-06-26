public class Husky_SCOMUtilities {
	public static Boolean executeTriggerCode = true;

	public static void TriggerBeforeInsertSCOMChangeRequest(List<SCOM_Change_Request__c> changeRequestList) {
		updateServerOnChangeRequest(changeRequestList);
	}

	public static void TriggerBeforeUpdateSCOMChangeRequest(List<SCOM_Change_Request__c> changeRequestList) {
		updateServerOnChangeRequest(changeRequestList);
	}

	public static void updateServerOnChangeRequest(List<SCOM_Change_Request__c> changeRequestList) {
		
	}

	public static void TriggerAfterInsertSCOMAvailability(List<SCOM_Availability__c> availabilityList) {
		sendNotificationOnMissionCriticalDown(availabilityList, null);
	}

	public static void TriggerAfterUpdateSCOMAvailability(List<SCOM_Availability__c> availabilityList, Map<Id,SCOM_Availability__c> oldMap) {
		sendNotificationOnMissionCriticalDown(availabilityList, oldMap);
	}

	public static void sendNotificationOnMissionCriticalDown(List<SCOM_Availability__c> availabilityList, Map<Id,SCOM_Availability__c> oldMap) {
		Set<Id> serverIds = new Set<Id>();
		Boolean isMissionCriticalServerDown = false;
		Messaging.SingleEmailMessage[] emailList = new Messaging.SingleEmailMessage[]{};

		for(SCOM_Availability__c availability : availabilityList) {
			if(availability.Status__c == 'Down' && (oldMap.get(availability.Id) == null || oldMap.get(availability.Id).Status__c == 'Up')) {
				serverIds.add(availability.Server__c);
			}
		}

		//Compile email body
		for(SCOM_Server__c server : [Select Id, Name, Type__c, Criticality__c, Short_Description__c,
											Applications__c, Environment__c, System_Created_By__c,
											Operating_System__c
									 From SCOM_Server__c
									 Where Id In :serverIds]) {
			if(server.Criticality__c == '(5) Mission Critical') {
				Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
				String messageBodyHtml = '<p>The following mission critical servers are reported as down: </p><br/>';
				email.setSubject('Mission Critical Servers Down: ' + server.Name + ' (' + server.Applications__c + ')');
				email.setToAddresses(new String[] {'shreyas.dhond@huskyenergy.com', 'amit.banerjee@huskyenergy.com'});
				messageBodyHtml += '<table>';
				messageBodyHtml += '<tr><td><a target="SCOM_Server__c" href="https://' + System.URL.getSalesforceBaseUrl().getHost() + '/' + server.Id + '">' + server.Name + '</a>';
				messageBodyHtml += '<tr><td>Applications:</td><td>' + server.Applications__c + '<td/></tr>';
				messageBodyHtml += '<tr><td>Environment:</td><td>' + server.Environment__c + '<td/></tr>';
				messageBodyHtml += '<tr><td>Description:</td><td>' + server.Short_Description__c + '<td/></tr>';
				messageBodyHtml += '<tr><td>Created By:</td><td>' + server.System_Created_By__c + '<td/></tr>';
				messageBodyHtml += '<tr><td>Operating System:</td><td>' + server.Operating_System__c + '<td/></tr>';
				messageBodyHtml += '<table>';
				messageBodyHtml += '<br/><br/><a target="SCOM_Server__c" href="https://' + System.URL.getSalesforceBaseUrl().getHost() + '/apex/Husky_SCOMDashboard">View Dashboard</a>';
				email.setHtmlBody(messageBodyHtml);
				isMissionCriticalServerDown = true;
				emailList.add(email);
			}
		}

		//Create Email
		if(isMissionCriticalServerDown)
			Messaging.sendEmail(emailList);
	}
}