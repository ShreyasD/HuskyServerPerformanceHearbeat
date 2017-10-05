public class Husky_SCOM_TestData {

	public static User createUser() {
		List<Profile> lProfiles = [SELECT Id FROM Profile WHERE Name = 'Standard HOG - General User' LIMIT 1];

        //Test USER
        User oUser = new User();
        oUser.FirstName = 'Test';
        oUser.LastName = 'User';
        oUser.Email = oUser.FirstName.toLowerCase() + '.' + oUser.LastName.toLowerCase() + '@testjschon.com';
        oUser.UserName = oUser.Email;
        oUser.Alias = 'tester';
        oUser.TimeZoneSidKey = 'America/New_York';
        oUser.LocaleSidKey = 'en_US';
        oUser.EmailEncodingKey = 'ISO-8859-1';
        oUser.LanguageLocaleKey='en_US';
        oUser.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard HOG - General User'].Id;
        oUser.IsActive = true;
        insert oUser;

		return oUser;
	}

	public static List<SCOM_Server__c> createServers(Integer numOfServers) {
		List<SCOM_Server__c> servers = new List<SCOM_Server__c>();
		if (numOfServers != null && numOfServers > 0) {
			List<Schema.PicklistEntry> criticalities = SCOM_Server__c.Criticality__c.getDescribe().getPicklistValues();
			for (Integer i = 0; i < numOfServers; i++) {
				servers.add(new SCOM_Server__c(Applications__c = 'Test application management_' + i,
												Criticality__c = criticalities.get(Math.mod(i, criticalities.size())).getValue(),
												Data_Center__c = 'Test data center - ' + i,
												Environment__c = 'Production',
												External_Id__c = 'linxubttestrunsrv' + i,
												Host_Name__c = 'linxubttestrunsrv' + i,
												Name = 'linxubttestrunsrv' + i,
												Manufacturer__c = 'Dell',
												Model_Id__c = 'Unknown',
												Operating_System__c = 'Linux Ubuntu Server 15 LTS',
												Operating_System_Version__c = '15.2',
												Short_Description__c = 'Just server instance for testing purpose.',
												System_Created_By__c = 'jschon',
												System_Created_On__c = DateTime.now(),
												Type__c = 'Linux Server'));
			}
		}
		insert servers;
		return servers;
	}

	public static List<SCOM_Performance__c> createPerformanceForServers(List<SCOM_Server__c> servers) {
		List<SCOM_Performance__c> performances = new List<SCOM_Performance__c>();
		Integer counter = 0;
		Integer countLimit = 3;
		for (SCOM_Server__c server : servers) {
			if (counter == countLimit) counter = 0;
			performances.add(generatePerformanceForServer(server,
														Husky_SCOMUtilities.PERFORMANCE_TYPE_REALTIME,
														Husky_SCOMUtilities.PERFORMANCE_METRIC_CPU,
														Husky_SCOMUtilities.PERFORMANCE_UNIT_CPU,
														counter));
			performances.add(generatePerformanceForServer(server,
														Husky_SCOMUtilities.PERFORMANCE_TYPE_REALTIME,
														Husky_SCOMUtilities.PERFORMANCE_METRIC_MEMORY,
														Husky_SCOMUtilities.PERFORMANCE_UNIT_MEMORY,
														counter));
			performances.add(generatePerformanceForServer(server,
														Husky_SCOMUtilities.PERFORMANCE_TYPE_BASELINE,
														Husky_SCOMUtilities.PERFORMANCE_METRIC_CPU,
														Husky_SCOMUtilities.PERFORMANCE_UNIT_CPU,
														counter));
			performances.add(generatePerformanceForServer(server,
														Husky_SCOMUtilities.PERFORMANCE_TYPE_BASELINE,
														Husky_SCOMUtilities.PERFORMANCE_METRIC_MEMORY,
														Husky_SCOMUtilities.PERFORMANCE_UNIT_MEMORY,
														counter));
			System.debug('SERVER: ' + server.Id);
			System.debug(performances.get(performances.size()-4));
			System.debug(performances.get(performances.size()-3));
			System.debug(performances.get(performances.size()-2));
			System.debug(performances.get(performances.size()-1));
			counter += 1;
		}
		insert performances;
		return performances;
	}

	public static SCOM_Performance__c generatePerformanceForServer(SCOM_Server__c server, String type,
															String metric, String unit, Integer counter) {
		String monitorInstance = metric == Husky_SCOMUtilities.PERFORMANCE_METRIC_CPU ? '_Total' : '_self';
		List<Integer> baselineAvg = new List<Integer>{60, 70, 80};
		List<Integer> baselineMax = new List<Integer>{70, 80, 90};
		List<Integer> realtimeCurrent = new List<Integer>{50, 75, 99};
		Integer maxValue = type == Husky_SCOMUtilities.PERFORMANCE_TYPE_BASELINE ? baselineMax.get(counter) : realtimeCurrent.get(counter);
		Integer avgValue = type == Husky_SCOMUtilities.PERFORMANCE_TYPE_BASELINE ? baselineAvg.get(counter) : maxValue;
		return new SCOM_Performance__c(Server__c = server.Id,
										Avg_Metric_Value__c = avgValue,
										Current_Metric_Value__c = 0.0,
										Min_Metric_Value__c = 0.0,
										Max_Metric_Value__c = maxValue,
										External_Key__c = server.Name + '-' + metric + '-' + monitorInstance + '-' + type,
										Metric__c = metric,
										Monitor_Instance__c = monitorInstance,
										Time__c = DateTime.now(),
										Type__c = type,
										Unit__c = unit);
	}

	public static List<SCOM_Change_Request__c> createChangeRequests(Integer numOfChRequests) {
		List<SCOM_Change_Request__c> changeRequests = new List<SCOM_Change_Request__c>();
		List<Schema.PicklistEntry> approvals = SCOM_Change_Request__c.Approval__c.getDescribe().getPicklistValues();
		List<Schema.PicklistEntry> priorities = SCOM_Change_Request__c.Priority__c.getDescribe().getPicklistValues();
		List<Schema.PicklistEntry> sources = SCOM_Change_Request__c.Source_Type__c.getDescribe().getPicklistValues();
		List<Schema.PicklistEntry> states = SCOM_Change_Request__c.State__c.getDescribe().getPicklistValues();
		List<Schema.PicklistEntry> urgencies = SCOM_Change_Request__c.Urgency__c.getDescribe().getPicklistValues();
		for (Integer i = 0; i < numOfChRequests; i++) {
			changeRequests.add(new SCOM_Change_Request__c(Active__c = String.valueOf(Math.mod(i, 2)),
														Application__c = 'Test application management_' + i,
														Approval__c = approvals.get(Math.mod(i, approvals.size())).getValue(),
														Approvers__c = 'jschon',
														Change_Request_Number__c = 'CHG000' + i,
														End_Date__c = DateTime.now(),
														Hyperlink__c = 'www.google.com',
														// Implementation_Reviewers__c = '',
														Opened_At__c = DateTime.now()-1,
														Opened_By__c = 'jschon',
														Parent__c = 'RLSE000' + i,
														Priority__c = priorities.get(Math.mod(i, priorities.size())).getValue(),
														// Project__c = '',
														Requested_By_Date__c = DateTime.now(),
														Short_Description__c = 'Test change request ' + i,
														Source_Type__c = sources.get(Math.mod(i, sources.size())).getValue(),
														Start_Date__c = DateTime.now(),
														State__c = states.get(Math.mod(i, states.size())).getValue(),
														Urgency__c = urgencies.get(Math.mod(i, urgencies.size())).getValue()));
		}
		insert changeRequests;
		return changeRequests;
	}

}