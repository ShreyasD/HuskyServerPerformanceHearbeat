public with sharing class Husky_SCOMDashboardController {

	//Both
	public List<String> criticalityCategories {get; private set;}
	public Map<String, List<SCOM_Change_Request__c>> serverToChangeRequestMap {get; private set;}

	//Availability Dashboard
	public Map<String, String> criticalityStatusMap {get; private set;}
	public Map<String, List<SCOM_Availability__c>> availabilityRecordsByCriticalityMap {get; private set;}

	//Performance Dashboard
	public Map<String, String> performanceToStatusMap {get; private set;}
	public Map<String, List<PerformanceWrapper>> 	performanceRecordsByCriticalityMap	{get; private set;}

	private Set<String> serverNames;

	public Husky_SCOMDashboardController() {
		initialize();
		queryAndGroupAvailabilityRecords();
		queryAndGroupPerformanceRecords();
	}

	public void initialize() {
		availabilityRecordsByCriticalityMap = new Map<String, List<SCOM_Availability__c>>();
		performanceRecordsByCriticalityMap = new Map<String, List<PerformanceWrapper>>();
		performanceToStatusMap = new Map<String, String>();
		criticalityStatusMap = new Map<String, String>();
		criticalityCategories = new List<String>();
		serverNames = new Set<String>();
		populateCriticalityStatusMap();
	}

	private void populateCriticalityStatusMap() {
		Schema.DescribeFieldResult fieldResult =
			SCOM_Server__c.Criticality__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

		for( Schema.PicklistEntry f : ple) {
			criticalityCategories.add(f.getLabel().substringAfter(' '));
			criticalityStatusMap.put(f.getLabel().substringAfter(' '), 'Up');
			performanceToStatusMap.put(f.getLabel().substringAfter(' ') + Husky_SCOMUtilities.PERFORMANCE_METRIC_CPU, Husky_SCOMUtilities.PERFORMANCE_GREEN);
			performanceToStatusMap.put(f.getLabel().substringAfter(' ') + Husky_SCOMUtilities.PERFORMANCE_METRIC_MEMORY, Husky_SCOMUtilities.PERFORMANCE_GREEN);
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

	private void queryAndGroupPerformanceRecords() {
		List<SCOM_Performance__c> performanceList = Database.query(Husky_SCOMUtilities.PERFORMANCE_LIST_QUERY_STRING);
		Map<String, PerformanceWrapper> performanceMergeMap = new Map<String, PerformanceWrapper>();
		for (SCOM_Performance__c performanceRecord : performanceList) {
			String key = performanceRecord.Server__r.Criticality__c + performanceRecord.Server__c;
			if (performanceMergeMap.containsKey(key))
				performanceMergeMap.get(key).addPerformanceValues(performanceRecord);
			else performanceMergeMap.put(key, new PerformanceWrapper(performanceRecord));
		}
		buildPerformanceRecordsByCriticalityMap(performanceMergeMap);
	}

	private void buildPerformanceRecordsByCriticalityMap(Map<String, PerformanceWrapper> performanceMergeMap) {
		performanceRecordsByCriticalityMap.clear();
		for (PerformanceWrapper performanceWrapper : performanceMergeMap.values()) {
			String key = performanceWrapper.server.Criticality__c == null ? 'Not Specified' : performanceWrapper.server.Criticality__c.substringAfter(' ');
			if (performanceWrapper.server.Criticality__c <> null && performanceRecordsByCriticalityMap.containsKey(key)) {
				performanceRecordsByCriticalityMap.get(key).add(performanceWrapper);
			} else {
				List<PerformanceWrapper> tmpList = new List<PerformanceWrapper>();
				tmpList.add(performanceWrapper);
				performanceRecordsByCriticalityMap.put(key, tmpList);
			}
			setPerformanceCriticalityStatus(key, performanceWrapper);
		}
	}

	private void setPerformanceCriticalityStatus(String key, PerformanceWrapper performanceWrapper) {
		String cpuKey = key + Husky_SCOMUtilities.PERFORMANCE_METRIC_CPU;
		String memKey = key + Husky_SCOMUtilities.PERFORMANCE_METRIC_MEMORY;
		if (performanceWrapper.getCPUPerformanceStatus() == Husky_SCOMUtilities.PERFORMANCE_ORANGE
			&& performanceToStatusMap.get(cpuKey) != Husky_SCOMUtilities.PERFORMANCE_RED)
			performanceToStatusMap.put(cpuKey, Husky_SCOMUtilities.PERFORMANCE_ORANGE);
		else if (performanceWrapper.getCPUPerformanceStatus() == Husky_SCOMUtilities.PERFORMANCE_RED)
			performanceToStatusMap.put(cpuKey, Husky_SCOMUtilities.PERFORMANCE_RED);
		if (performanceWrapper.getMemPerformanceStatus() == Husky_SCOMUtilities.PERFORMANCE_ORANGE
			&& performanceToStatusMap.get(memKey) != Husky_SCOMUtilities.PERFORMANCE_RED)
			performanceToStatusMap.put(memKey, Husky_SCOMUtilities.PERFORMANCE_ORANGE);
		else if (performanceWrapper.getMemPerformanceStatus() == Husky_SCOMUtilities.PERFORMANCE_RED)
			performanceToStatusMap.put(memKey, Husky_SCOMUtilities.PERFORMANCE_RED);
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
			else changeRequestMapByApplication.put(cr.Application__c, new List<SCOM_Change_Request__c>{cr});
		}

		for(SCOM_Server__c server : serverList) {
			for(String application : changeRequestMapByApplication.keySet()) {
				if(server.Applications__c.contains(application)) {
					if(serverToChangeRequestMap.containsKey(server.Name))
						serverToChangeRequestMap.get(server.Name).addAll(changeRequestMapByApplication.get(application));
					else {
						serverToChangeRequestMap.put(server.Name, new List<SCOM_Change_Request__c>());
						serverToChangeRequestMap.get(server.Name).addAll(changeRequestMapByApplication.get(application));
					}
				}
			}
		}
	}

	public String getPerformanceMetricCPU() {
		return Husky_SCOMUtilities.PERFORMANCE_METRIC_CPU;
	}

	public String getPerformanceMetricMEM() {
		return Husky_SCOMUtilities.PERFORMANCE_METRIC_MEMORY;
	}

	public String getGreen() {
		return Husky_SCOMUtilities.PERFORMANCE_GREEN;
	}

	public String getOrange() {
		return Husky_SCOMUtilities.PERFORMANCE_ORANGE;
	}

	public String getRed() {
		return Husky_SCOMUtilities.PERFORMANCE_RED;
	}

	public class PerformanceWrapper{

		public SCOM_Server__c server {get; private set;}
		public Double cpuAvg 		{get; private set;}
		public Double cpuThreshold	{get; private set;}
		public Double cpuActual		{get; private set;}
		public Double memAvg		{get; private set;}
		public Double memThreshold	{get; private set;}
		public Double memActual		{get; private set;}

		PerformanceWrapper(SCOM_Performance__c performance) {
			this.server = performance.Server__r;
			addPerformanceValues(performance);
		}

		public void addPerformanceValues(SCOM_Performance__c performance) {
			if (performance.Metric__c == Husky_SCOMUtilities.PERFORMANCE_METRIC_CPU)
				setPerformanceValuesForCPU(performance);
			else if (performance.Metric__c == Husky_SCOMUtilities.PERFORMANCE_METRIC_MEMORY)
				setPerformanceValuesForMemory(performance);
		}

		private void setPerformanceValuesForCPU(SCOM_Performance__c performance) {
			if (performance.Type__c == Husky_SCOMUtilities.PERFORMANCE_TYPE_BASELINE) {
				cpuAvg = performance.Avg_Metric_Value__c;
				cpuThreshold = performance.Max_Metric_Value__c;
			} else if (performance.Type__c == Husky_SCOMUtilities.PERFORMANCE_TYPE_REALTIME) {
				cpuActual = performance.Max_Metric_Value__c; //NOTE current values are not stored in Current_Metric_Value__c
			}
		}

		private void setPerformanceValuesForMemory(SCOM_Performance__c performance) {
			if (performance.Type__c == Husky_SCOMUtilities.PERFORMANCE_TYPE_BASELINE) {
				memAvg = performance.Avg_Metric_Value__c;
				memThreshold = performance.Max_Metric_Value__c;
			} else if (performance.Type__c == Husky_SCOMUtilities.PERFORMANCE_TYPE_REALTIME) {
				memActual = performance.Max_Metric_Value__c; //NOTE current values are not stored in Current_Metric_Value__c
			}
		}

		public String getCPUPerformanceStatus() {
			if (cpuAvg != null && cpuThreshold != null && cpuActual != null) {
				if (cpuActual <= cpuAvg) return Husky_SCOMUtilities.PERFORMANCE_GREEN;
				if (cpuActual <= cpuThreshold) return Husky_SCOMUtilities.PERFORMANCE_ORANGE;
				return Husky_SCOMUtilities.PERFORMANCE_RED;
			}
			return null;
		}

		public String getMemPerformanceStatus() {
			if (memAvg != null && memThreshold != null && memActual != null) {
				if (memActual < memAvg) return Husky_SCOMUtilities.PERFORMANCE_GREEN;
				if (memActual < memThreshold) return Husky_SCOMUtilities.PERFORMANCE_ORANGE;
				return Husky_SCOMUtilities.PERFORMANCE_RED;
			}
			return null;
		}

	}
}