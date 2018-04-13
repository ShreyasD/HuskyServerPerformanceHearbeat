@isTest
private class Husky_ServiceNowChangeRequestServiceTest {

	@isTest static void changeRequestSoapWebserviceTest() {
		Test.startTest();
			List<Husky_ServiceNowChangeRequestService.APIChangeRequest> chRequests =
				new List<Husky_ServiceNowChangeRequestService.APIChangeRequest>();
			Integer num = 10;
			for (Integer i = 0; i < num; i++) {
				Husky_ServiceNowChangeRequestService.APIChangeRequest request =
					new Husky_ServiceNowChangeRequestService.APIChangeRequest();
				request.active = '';
				request.application = 'Test application ' + i;
				request.approval = '';
				request.approvers = 'jschon';
				request.changeRequestNumber = 'change request number ' + i;
				request.endDate = String.valueOf((DateTime.now().format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'')));
				request.hyperlink = 'www.google.com';
				request.implementationReviewers = 'jschon';
				request.openedAt = String.valueOf(DateTime.now().format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
				request.openedBy = 'jschon';
				request.parent = 'parent ' + i;
				request.priority = '';
				request.project = 'project ' + i;
				request.requestedByDate = String.valueOf(DateTime.now().format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
				request.shortDescription = 'Short description for test ' + i;
				request.sourceType = '';
				request.startDate = String.valueOf(DateTime.now().format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
				request.state = '';
				request.urgency = '';
				chRequests.add(request);
			}
			List<Husky_ServiceNowApiUtils.Result> results = Husky_ServiceNowChangeRequestService.pushRecords(chRequests).results;

			for(Husky_ServiceNowApiUtils.Result result : results) {
				for(Husky_ServiceNowApiUtils.Error error : result.errors) {
					System.debug('Error: ' + error.message);
					System.debug('Status Code: ' + error.statusCode);
				}
			}
		Test.stopTest();
		System.assertEquals(num, [SELECT Count() FROM SCOM_Change_Request__c]);
	}

}