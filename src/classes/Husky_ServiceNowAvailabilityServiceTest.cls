@isTest
private class Husky_ServiceNowAvailabilityServiceTest {

	@isTest static void availabilitySOAPWebserviceTest() {
		List<Husky_ServiceNowAvailabilityService.APIServerAvailability> availabilities =
			new List<Husky_ServiceNowAvailabilityService.APIServerAvailability>();
		Integer num = 4;
		List<SCOM_Server__c> servers = Husky_SCOM_TestData.createServers(num);
		for (SCOM_Server__c server : servers) {
			Husky_ServiceNowAvailabilityService.APIServerAvailability record
				= new Husky_ServiceNowAvailabilityService.APIServerAvailability();
			record.PollingInterval = '10';
			record.Asset = server.Name + '.test';
			record.Status = Math.mod(num, 2) == 0 ? 'Up': 'Down';
			availabilities.add(record);
			num -= 1;
		}
		Husky_ServiceNowAvailabilityService.pushRecords(availabilities);
		System.assertEquals(4, [SELECT Count() FROM SCOM_Availability__c]);

		//Test after update trigger
		List<SCOM_Availability__c> availabilitiesToUpdate = new List<SCOM_Availability__c>();
		for(SCOM_Availability__c availability : [Select Id, Name, Status__c
												 From SCOM_Availability__c]) {
			availability.Status__c = (availability.Status__c == 'Up') ? 'Down' : 'Up';
			availabilitiesToUpdate.add(availability);
		}
		update availabilitiesToUpdate;
	}

	@isTest static void availabilitySOAPWebserviceTestError() {
		List<Husky_ServiceNowAvailabilityService.APIServerAvailability> availabilities =
			new List<Husky_ServiceNowAvailabilityService.APIServerAvailability>();
		Integer num = 4;
		List<SCOM_Server__c> servers = Husky_SCOM_TestData.createServers(num);
		for (SCOM_Server__c server : servers) {
			Husky_ServiceNowAvailabilityService.APIServerAvailability record
				= new Husky_ServiceNowAvailabilityService.APIServerAvailability();
			//record.Asset = server.Name + '.test';
			record.PollingInterval = '10';
			record.Status = Math.mod(num, 2) == 0 ? 'Up': 'Down';
			availabilities.add(record);
			num -= 1;
		}
		List<Husky_ServiceNowApiUtils.Result> results = Husky_ServiceNowAvailabilityService.pushRecords(availabilities).results;
		for(Husky_ServiceNowApiUtils.Result result : results) {
			System.assertEquals(Husky_ServiceNowApiUtils.STATUS_ERROR_PARSE, result.statusCode);
		}
	}
}