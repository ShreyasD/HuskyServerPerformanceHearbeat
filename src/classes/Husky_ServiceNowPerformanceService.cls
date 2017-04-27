global class Husky_ServiceNowPerformanceService {

	/** Return Codes **/
	global final static Integer STATUS_OK = 200;
    global final static Integer STATUS_CREATED = 201;
    global final static Integer STATUS_ACCEPTED = 202;
    global final static Integer STATUS_BAD = 400;
    global final static Integer STATUS_FORBIDDEN = 403;
    global final static Integer STATUS_NOTFOUND = 404;
    global final static Integer STATUS_NOTALLOWED = 405;
    global final static Integer STATUS_ISE = 500;

	global class APIServerPerformance {
		webservice String User {get; set;}
		webservice String Access {get; set;}
		webservice String Name {get; set;}
		webservice String Asset {get; set;}
		webservice String Application {get; set;}
		webservice String MetricName {get; set;}
		webservice String MonitoringInstance {get; set;}
		webservice String KeyTime {get; set;}
		webservice String AverageValue {get; set;}
		webservice String MinimumValue {get; set;}
		webservice String MaxValue {get; set;}
		webservice String CurrentValue {get; set;}
		webservice String Unit {get; set;}
		webservice String Assettype {get; set;}
		webservice String App_flag {get; set;}
	}

	global class Response {
		webservice Integer returnCode;
		webservice List<Result> results;
	}

	global class Result {

	}

	/************************* SOAP Interface ************************************/
	webservice static Response pushRecords (List<APIServerPerformance> performanceRecords) {
		Response response = new Response();

		return response;
	}
	/*****************************************************************************/
}