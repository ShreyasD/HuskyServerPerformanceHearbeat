public class Husky_SCOMUtilities {

	/******************************
	Performance Dashboard constants
	******************************/
	public static final String PERFORMANCE_UNIT_CPU 	= '%';
	public static final String PERFORMANCE_UNIT_MEMORY 	= 'MB';

	public static final String PERFORMANCE_METRIC_CPU 			= 'CPU Utilization';
	public static final String PERFORMANCE_METRIC_MEMORY 		= 'Memory Utilization';
	public static final String PERFORMANCE_METRIC_FREESPACE 	= 'Free Space';
	public static final String PERFORMANCE_METRIC_TOTALSPACE 	= 'Total Space';
	public static final String PERFORMANCE_METRIC_USEDSPACE 	= 'Used Space';

	public static final String PERFORMANCE_TYPE_REALTIME = 'Realtime';
	public static final String PERFORMANCE_TYPE_BASELINE = 'Baseline';

	public static final String PERFORMANCE_GREEN 	= 'green';
	public static final String PERFORMANCE_ORANGE	= 'orange';
	public static final String PERFORMANCE_RED 		= 'red';

	public static String PERFORMANCE_LIST_QUERY_STRING = 'SELECT Avg_Metric_Value__c, Current_Metric_Value__c, Max_Metric_Value__c'
														+ ', External_Key__c, Metric__c, Type__c, Unit__c, Server__c, Server__r.Id'
														+ ', Server__r.Criticality__c, Server__r.Applications__c, Server__r.Name'
														+ ' FROM SCOM_Performance__c'
														+ ' WHERE (Metric__c = \'' + PERFORMANCE_METRIC_CPU + '\''
														+ ' OR Metric__c = \'' + PERFORMANCE_METRIC_MEMORY + '\')'
														+ ' ORDER BY Type__c ASC';


	/****************
	Trigger constants
	****************/
	public static Boolean executeTriggerCode = true;

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
			if(availability.Status__c == 'Down' && (oldMap != null && oldMap.get(availability.Id) != null && oldMap.get(availability.Id).Status__c == 'Up')) {
				serverIds.add(availability.Server__c);
			}
		}

		//Get Assigned Org-wide email address
		OrgWideEmailAddress[] csrOrgWideEmail;
		if(!Test.isRunningTest()) {
			csrOrgWideEmail = [select Id from OrgWideEmailAddress where DisplayName = 'Husky Server Heartbeat Email'];
		} else {
			csrOrgWideEmail = new List<OrgWideEmailAddress>{new OrgWideEmailAddress()};
			csrOrgWideEmail[0].DisplayName = 'Husky Server Heartbeat Email';
			csrOrgWideEmail[0].Address = 'list-sappi@huskyenergy.com';
			csrOrgWideEmail[0].IsAllowAllProfiles = true;
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
				email.setOrgWideEmailAddressId(csrOrgWideEmail.get(0).Id);
				email.setToAddresses(new String[] {'shreyas.dhond@huskyenergy.com', 'amit.banerjee@huskyenergy.com', 'khaled.rafih@huskyenergy.com', 'Chris.Payne@huskyenergy.com', 'Bernie.Carroll@huskyenergy.com'});
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