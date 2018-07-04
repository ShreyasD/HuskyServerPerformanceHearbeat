public with sharing class Husky_IRDIncidentListCtrl {

    private List<String> incidentIds;
    private String retUrl;

	public Husky_IRDIncidentListCtrl() {
        incidentIds = ApexPages.currentPage().getParameters().get('idSet').split(',');
        retUrl = ApexPages.currentPage().getParameters().get('retURL');
    }

    public List<IRD_Incident__c> incidentList {
        get {
            try {
                if(incidentList == null || incidentList.isEmpty()) {
                    incidentList = [SELECT Id, Name, Assignment_Group__c,
                    	Opened_By__c, State__c, Urgency__c, Priority__c,
                    	Opened__c, Category__c, Short_Description__c,
                    	Hyper_Link__c, Resolved_By__c, Resolved_Date__c
			            FROM IRD_Incident__c
			            Where Id In :incidentIds];
                }
                return incidentList;
            } catch (QueryException ex) {
                Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
                return null;
            }
        }
        private set;
    }
}