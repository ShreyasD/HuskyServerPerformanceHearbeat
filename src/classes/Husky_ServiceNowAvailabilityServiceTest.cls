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
		System.assertEquals(num, [SELECT Count() FROM SCOM_Availability__c]);
	}

}
