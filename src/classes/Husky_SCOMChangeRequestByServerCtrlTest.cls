@isTest
public class Husky_SCOMChangeRequestByServerCtrlTest {
	@isTest
	static void testController() {
		List<SCOM_Server__c> servers = [Select Id, Name 
										From SCOM_Server__c];

		Test.startTest();
			Test.setCurrentPage(Page.Husky_SCOMChangeRequestByServer);
			ApexPages.currentPage().getParameters().put('serverId', servers.get(0).Id);

			Husky_SCOMChangeRequestByServerCtrl controller = new Husky_SCOMChangeRequestByServerCtrl();
			System.assert(!controller.changeRequestList.isEmpty());
		Test.stopTest();
	}


	@testSetup
	static void prepareData() {
		List<SCOM_Server__c> servers = Husky_SCOM_TestData.createServers(9);
		List<SCOM_Availability__c> availabilities = Husky_SCOM_TestData.createAvailabilitiesForServers(servers);
		List<SCOM_Performance__c> performances = Husky_SCOM_TestData.createPerformanceForServers(servers);
		List<SCOM_Change_Request__c> chRequests = Husky_SCOM_TestData.createChangeRequests(30);
	}
}