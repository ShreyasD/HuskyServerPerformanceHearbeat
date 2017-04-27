global class Husky_ServiceNowAvailabilityService{
     /** Return Codes **/
    global final static Integer STATUS_OK = 200;
      global final static Integer STATUS_CREATED = 201;
      global final static Integer STATUS_ACCEPTED = 202;
      global final static Integer STATUS_BAD = 400;
      global final static Integer STATUS_FORBIDDEN = 403;
      global final static Integer STATUS_NOTFOUND = 404;
      global final static Integer STATUS_NOTALLOWED = 405;
      global final static Integer STATUS_ISE = 500;

    global class APIServerAvailability {
      webservice String User {get; set;}
      webservice String Access {get; set;}
      webservice String Name {get; set;}
      webservice String Asset {get; set;}
      webservice String Application {get; set;}
      webservice String PollingInterval {get; set;}
      webservice String Status {get; set;}
      webservice String PlannedFlag {get; set;}
      webservice String CRNumber {get; set;}
      webservice String AppFlag {get; set;}
    }

    global class Response {
      webservice Integer returnCode;
      webservice List<Result> results;
    }

    global class Result {

    }

    /************************* SOAP Interface ************************************/
    webservice static Response pushRecords (List<APIServerAvailability> availabilityRecords) {
      Response response = new Response();

      return response;
    }
    /*****************************************************************************/
}