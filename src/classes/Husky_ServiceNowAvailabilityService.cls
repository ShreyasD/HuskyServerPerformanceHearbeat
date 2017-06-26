global class Husky_ServiceNowAvailabilityService{
    private static List<SCOM_Server__c> serverRecords; 
    private static List<SCOM_Availability__c> availabilityRecords;

    global class APIServerAvailability {
      webservice String Asset {get; set;}
      webservice String PollingInterval {get; set;}
      webservice String Status {get; set;}
    }

    private static void initialize() {
      availabilityRecords = new List<SCOM_Availability__c>();
      serverRecords = new List<SCOM_Server__c>();
    }

    /************************* SOAP Interface ************************************/
    webservice static Husky_ServiceNowApiUtils.Response pushRecords (List<APIServerAvailability> records) {
      Husky_ServiceNowApiUtils.Response response = new Husky_ServiceNowApiUtils.Response();
      initialize();
      response.addResults(parseRecords(records));
      response.addResults(commitRecords());
      return response;
    }
    /*****************************************************************************/

    private static List<Husky_ServiceNowApiUtils.Result> parseRecords(List<APIServerAvailability> records) {
    List<Husky_ServiceNowApiUtils.Result> results = new List<Husky_ServiceNowApiUtils.Result>();
    Map<String, String> serverMap = new Map<String, String>();

    for(APIServerAvailability availabilityRecord : records) {
      //Get Server Info
      //serverSet.add(availabilityRecord.Asset.subStringBefore('.'));
      serverMap.put(availabilityRecord.Asset.subStringBefore('.'), availabilityRecord.Asset);

      //Get Performance Info
      SCOM_Availability__c record = new SCOM_Availability__c();
      record.External_Key__c = availabilityRecord.Asset;
      record.Polling_Interval__c = (availabilityRecord.PollingInterval.isNumeric()) ? 
        Integer.valueOf(availabilityRecord.PollingInterval) : 0;
      record.Status__c = availabilityRecord.Status;
      record.Server__r = new SCOM_Server__c(
        Name = availabilityRecord.Asset.subStringBefore('.')
      );
      availabilityRecords.add(record);
    }

    //Create Server Records
    for(String key : serverMap.keySet()) {
      SCOM_Server__c server = new SCOM_Server__c();
      server.Name = key;
      server.Host_Name__c = serverMap.get(key);
      server.External_Id__c = key;
      serverRecords.add(server);
    }

    return results;
  }

  private static List<Husky_ServiceNowApiUtils.Result> commitRecords() {
    List<SObject> dmlRecords = new List<SObject>();
    List<Husky_ServiceNowApiUtils.Result> results = new List<Husky_ServiceNowApiUtils.Result>();
    List<Database.UpsertResult> upsertResults = new List<Database.UpsertResult>();

    //Upsert
    upsertResults.addAll(Database.upsert(serverRecords, SCOM_Server__c.fields.Name, false));
    dmlRecords.addAll((List<SObject>) serverRecords);
    upsertResults.addAll(Database.upsert(availabilityRecords, SCOM_Availability__c.fields.External_Key__c, false));
    dmlRecords.addAll((List<SObject>) availabilityRecords);

    for(Integer i=0; i < upsertResults.size(); i++) {
      Database.UpsertResult upsertResult = upsertResults[i];
      String statusCode = upsertResult.isSuccess() ? Husky_ServiceNowApiUtils.STATUS_SUCCESS_UPSERT : 
        Husky_ServiceNowApiUtils.STATUS_ERROR_UPSERT;
      String idString = (String) ((dmlRecords[i] instanceof SCOM_Server__c) ? dmlRecords[i].get('Name') :
        dmlRecords[i].get('External_Key__c'));
      Husky_ServiceNowApiUtils.Result result = new Husky_ServiceNowApiUtils.Result(upsertResult.isCreated(), idString, 
        upsertResult.isSuccess(), statusCode);
      for(Database.Error err : upsertResult.getErrors()) {
        result.addError(new Husky_ServiceNowApiUtils.Error(err.getFields(), err.getMessage(), err.getStatusCode()));
      }
      results.add(result);
    }

    return results;
  }
}