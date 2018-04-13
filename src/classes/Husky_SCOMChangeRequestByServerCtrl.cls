public with sharing class Husky_SCOMChangeRequestByServerCtrl {

    public SCOM_Server__c server {get; private set;}
    public List<String> applications {get; private set;}

    private String serverId;
    private String retUrl;

	public Husky_SCOMChangeRequestByServerCtrl() {
        serverId = ApexPages.currentPage().getParameters().get('serverId');
        retUrl = ApexPages.currentPage().getParameters().get('retURL');
    }

    public List<SCOM_Change_Request__c> changeRequestList {
        get {
            try {
                if(changeRequestList == null || changeRequestList.isEmpty()) {
                    server = [Select Id, Name, Applications__c
                                             From SCOM_Server__c
                                             Where Id = :serverId];
                    applications = server.Applications__c.split(',');
                    changeRequestList = [Select Id, Name, Active__c, Application__c, Approval__c, Approvers__c,
                                                Hyperlink__c, Priority__c, State__c, Urgency__c, Short_Description__c,
                                                Opened_By__c, Opened_At__c, End_Date__c
                                         From SCOM_Change_Request__c
                                         Where Application__c In :applications
                                         Order By End_Date__c DESC NULLS FIRST];
                }
                return changeRequestList;
            } catch (QueryException ex) {
                Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
                return null;
            }
        }
        private set;
    }
}