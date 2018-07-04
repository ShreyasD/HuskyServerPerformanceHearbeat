public with sharing class Husky_HeartbeatApplicationStatusCtrl {

	public List<SCOM_Application_Status__c> applicationStatusList {get; private set;}

	public Husky_HeartbeatApplicationStatusCtrl() {
		initialize();
		populateApplicationStatusList();
	}

	private void initialize() {
		applicationStatusList = new List<SCOM_Application_Status__c>();
	}

	private void populateApplicationStatusList() {
		applicationStatusList = [Select Id, Name, Date__c, Kbase_Article__c,
									    Message__c, Status__c
							     From SCOM_Application_Status__c];
	}
}