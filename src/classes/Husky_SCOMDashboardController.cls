public with sharing class Husky_SCOMDashboardController {

	public List<String> criticalityCategories {get; private set;}
	public Map<String, String> criticalityStatusMap {get; private set;}
	public Map<String, List<SCOM_Availability__c>> availabilityRecordsByCriticalityMap {get; private set;}
	public Map<String, List<SCOM_Change_Request__c>> serverToChangeRequestMap {get; private set;}

	private Set<String> serverNames;

	public Husky_SCOMDashboardController() {
		initialize();
		process();
	}

	public void initialize() {
		availabilityRecordsByCriticalityMap = new Map<String, List<SCOM_Availability__c>>();
		criticalityStatusMap = new Map<String, String>();
		criticalityCategories = new List<String>();
		serverNames = new Set<String>();
	}

	public void process() {
		populateCriticalityStatusMap();
		queryAndGroupAvailabilityRecords();
	}

	private void populateCriticalityStatusMap() {
		Schema.DescribeFieldResult fieldResult =
			SCOM_Server__c.Criticality__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		    
		for( Schema.PicklistEntry f : ple) {
			criticalityCategories.add(f.getLabel().substringAfter(' '));
			criticalityStatusMap.put(f.getLabel().substringAfter(' '), 'Up');
		}
	}

	private void queryAndGroupAvailabilityRecords() {
		List<SCOM_Availability__c> availabilityList = [Select Id, Name, Polling_Interval__c, Server__c, 
														      Server__r.Name, Server__r.Applications__c, Status__c,
														      Server__r.Criticality__c, Server__r.Data_Center__c
													   From SCOM_Availability__c
													   Order By Status__c Desc];
		for(SCOM_Availability__c availability : availabilityList) {
			serverNames.add(availability.Server__c);
			if(availability.Server__r.Name == 'CGWSCOM350PD') continue;
			if(availability.Server__r.Criticality__c <> null && availabilityRecordsByCriticalityMap.containsKey(availability.Server__r.Criticality__c.substringAfter(' '))) 
				availabilityRecordsByCriticalityMap.get(availability.Server__r.Criticality__c.substringAfter(' ')).add(availability);
			else {
				String key = availability.Server__r.Criticality__c == null ? 'Not Specified' : availability.Server__r.Criticality__c.substringAfter(' ');
				availabilityRecordsByCriticalityMap.put(key, new List<SCOM_Availability__c>{availability});
			}

			if(availability.Status__c == 'Down') criticalityStatusMap.put((availability.Server__r.Criticality__c <> null) ? 
				availability.Server__r.Criticality__c.substringAfter(' ') : 'Not Specified', availability.Status__c);
		}
	}

	private void getChangeRequestToServerMap() {
		List<SCOM_Change_Request__c> changeRequestList = [Select Id, Name, Active__c, Application__c, Approval__c, Approvers__c,
																 Hyperlink__c, Priority__c, State__c, Urgency__c
														  From SCOM_Change_Request__c];
		List<SCOM_Server__c> serverList = [Select Id, Name, Applications__c
										   From SCOM_Server__c
										   Where Name In :serverNames];

		//Map change requests by application
		Map<String, List<SCOM_Change_Request__c>> changeRequestMapByApplication = 
			new Map<String, List<SCOM_Change_Request__c>>();
		for(SCOM_Change_Request__c cr : changeRequestList) {
			if(changeRequestMapByApplication.containsKey(cr.Application__c)) 
				changeRequestMapByApplication.get(cr.Application__c).add(cr);
			else
				changeRequestMapByApplication.put(cr.Application__c, new List<SCOM_Change_Request__c>{cr});
		}

		for(SCOM_Server__c server : serverList) {
			for(String application : changeRequestMapByApplication.keySet()) {
				if(server.Applications__c.contains(application)) {
					if(serverToChangeRequestMap.containsKey(server.Name))
						serverToChangeRequestMap.get(server.Name).addAll(changeRequestMapByApplication.get(application));
					else {
						serverToChangeRequestMap.put(server.Name, 
							new List<SCOM_Change_Request__c>());
						serverToChangeRequestMap.get(server.Name).addAll(changeRequestMapByApplication.get(application));
					}
				}
			}
		}
	}
}