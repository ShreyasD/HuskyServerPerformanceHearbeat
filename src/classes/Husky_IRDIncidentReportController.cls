public with sharing class Husky_IRDIncidentReportController {

    public List<String> yearSelections {get; set;}
    public String yearSelected {get; private set;}
    public Integer maxMonthOfYear {get; private set;}
    public List<String> assignmentGroups {get; private set;}
    public List<String> months {get; private set;}
    public String xlsHeader{
        get{
            String strHeader = '';
            strHeader += '<?xml version="1.0"?>';
            strHeader += '<?mso-application progid="Excel.Sheet"?>';
            return strHeader;
        }
    }
    public String reportName {
        get {
            return 'Incident_Export_' + yearSelected + '_' + DateTime.now().format();
        }
    }
    
    //To reduce view state size
    transient Map<String, DataGroupingRow> dataGroupingMonthMap;
    public Map<String, DataGroupingRow> getDataGroupingMonthMap() {
        return dataGroupingMonthMap;
    }

    private DateRange dateRangeSelected;
    private Integer startYear = 2014;

    public Husky_IRDIncidentReportController() {
        initialize();
    }

    public void setDateRange() {
        yearSelected = ApexPages.currentPage().getParameters().get('yearSelected');
        String currentYear = String.valueOf(Date.today().year());
        yearSelected = (yearSelected == null) ? currentYear : yearSelected;
        Integer selectedYear = Integer.valueOf(yearSelected);
        Date startDate, endDate;
        if(yearSelected == currentYear) {
            startDate = Date.newInstance(selectedYear, 1, 1);
            endDate = Date.newInstance(selectedYear, Date.today().month(), Date.daysInMonth(selectedYear, Date.today().month()));
            maxMonthOfYear = endDate.month();
        } else {
            startDate = Date.newInstance(selectedYear, 1, 1);
            endDate = Date.newInstance(selectedYear, 12, 31);
            maxMonthOfYear = 12;
        } 
        System.debug('setDateRange->startDate: ' + startDate + ' setDateRange->endDate: ' + endDate);
        dateRangeSelected = new DateRange(startDate, endDate);
        getDataForReport();
    }

    public PageReference exportData() {
        return Page.Husky_IRDIncidentReportExcel;
    }

    public void getDataForReport() {
        List<IRD_Incident__c> incidentList = [SELECT Actual_Elapsed_Percentage_Resolution__c,Actual_Elapsed_Percentage_Response__c,
            Actual_Elapsed_Time_Resolution__c,Actual_Elapsed_Time_Response__c,Actual_End_Date_Resolution__c,
            Actual_End_Date_Response__c,Actual_Start_Date_Resolution__c,Actual_Start_Date_Response__c,
            Actual_Time_Left_Resolution__c,Actual_Time_Left_Response__c,Assigned_to__c,Assignment_Group__c,
            Business_Duration_Resolution__c,Business_Duration_Response__c,Calc_Result_Resolution__c,Calc_Result_Response__c,
            Caller__c,Case_Type__c,Category__c,Caused_By_Change__c,Configuration_Item__c,Created_Resolution__c,
            Created_Response__c,Duration_Resolution__c,Duration_Response__c,Id,Impact__c,Incident_Number__c,IsDeleted,LastModifiedById,
            LastModifiedDate,LastReferencedDate,LastViewedDate,Location__c,Name,Opened_by__c,Opened__c,Priority__c,Requested_for__c,
            Resolved_By__c,Resolved_Date_Resolution__c,Resolved_Date_Response__c,Resolved_Date__c,Responded_Resolution__c,
            Responded_Response__c,Short_Description__c,SLA_Definition_Resolution__c,SLA_Definition_Response__c,Source__c,
            Stage_Resolution__c,Stage_Response__c,Start_Time_Resolution__c,Start_Time_Response__c,State__c,Subcategory__c,
            SystemModstamp,Time_Worked_Resolution__c,Time_Worked_Response__c,Urgency__c, Business_Elapsed_Time_Resolution__c,
            Business_Elapsed_Time_Response__c
            FROM IRD_Incident__c
            Where (Opened__c >= :dateRangeSelected.startDate And Opened__c <= :dateRangeSelected.endDate.addDays(1))
            Or (Resolved_Date__c >= :dateRangeSelected.startDate And Resolved_Date__c <= :dateRangeSelected.endDate.addDays(1))
            Order By Opened__c Desc];

        //Create DataGroupingRow containers
        dataGroupingMonthMap = new Map<String, DataGroupingRow>();
        for(String assignmentGroup : assignmentGroups) {
            for(String month : months) {
                //Get Range
                DateRange range = getDateRange(Integer.valueOf(yearSelected),
                    months.indexOf(month)+1);

                String key = assignmentGroup + '-' + month;
                dataGroupingMonthMap.put(key, new DataGroupingRow(assignmentGroup,
                    range));
            }
        }

        //Assign each incident to grouping
        for(IRD_Incident__c incident : incidentList) {
            String assignmentGroup = incident.Assignment_Group__c;
            for(String month : months) {
                String key = assignmentGroup + '-' + month;
                DataGroupingRow currentDataGroupingRow = dataGroupingMonthMap.get(key);

                if(currentDataGroupingRow <> null) {
                    //Opening Backlog
                    if((incident.Opened__c.date() < currentDataGroupingRow.range.startDate) &&
                        (incident.Resolved_Date__c == null || 
                            incident.Resolved_Date__c.date() >= currentDataGroupingRow.range.startDate)) {
                        currentDataGroupingRow.openingBalanceIncidents.add(incident.Id);
                    }

                    //Created
                    if(incident.Opened__c.date() >= currentDataGroupingRow.range.startDate &&
                        incident.Opened__c.date() <= currentDataGroupingRow.range.endDate) {
                        currentDataGroupingRow.createdIncidents.add(incident.Id);
                        currentDataGroupingRow.totalResponseTime += ((incident.Actual_Elapsed_Time_Response__c <> null) ? 
                            incident.Actual_Elapsed_Time_Response__c : 0);
                        currentDataGroupingRow.totalSLAResponseTime += ((incident.Business_Elapsed_Time_Response__c <> null) ? 
                            incident.Business_Elapsed_Time_Response__c : 0);
                    }

                    //Closing Backlog
                    if(incident.Opened__c.date() <= currentDataGroupingRow.range.endDate &&
                        (incident.Resolved_Date__c == null || 
                            incident.Resolved_Date__c.date() > currentDataGroupingRow.range.endDate)) {
                        currentDataGroupingRow.openingBacklogIncidents.add(incident.Id);
                        currentDataGroupingRow.totalAgeOfBacklogInDays += (incident.Opened__c.date().daysBetween(Date.today()));
                    }

                    //Resolved
                    if(incident.Resolved_Date__c <> null) {
                        if(incident.Resolved_Date__c.date() >= currentDataGroupingRow.range.startDate &&
                            incident.Resolved_Date__c.date() <= currentDataGroupingRow.range.endDate) {
                            currentDataGroupingRow.resolvedIncidents.add(incident.Id);
                            currentDataGroupingRow.totalResolutionTime += ((incident.Actual_Elapsed_Time_Resolution__c <> null) ? 
                                incident.Actual_Elapsed_Time_Resolution__c : 0);
                            currentDataGroupingRow.totalSLAResolutionTime += ((incident.Business_Elapsed_Time_Resolution__c <> null) ? 
                                incident.Business_Elapsed_Time_Resolution__c : 0);
                        }
                    }
                }
            }
        }
    }

    private void initialize() {
        yearSelections = new List<String>();
        for(Integer i=startYear; i <= Date.today().year(); i++) {
            yearSelections.add(String.valueOf(i));
        }
        assignmentGroups = new List<String> {
            'Partner SAP FICO', 'Partner SAP Portal', 'Partner SAP MM', 
            'Partner SAP Basis', 'Partner SAP HR', 'Partner SAP Security',
            'Partner SAP PM', 'Partner SAP ABAP', 'Partner SAP PI', 
            'Partner SAP BI', 'Partner SAP Support'
        };
        months = new List<String> {
            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        };
        dataGroupingMonthMap = new Map<String, DataGroupingRow>();
        setDateRange();
    }

    private class DateRange {
        public Date startDate {get; set;}
        public Date endDate {get; set;}

        public DateRange(Date startDate, Date endDate) {
            this.startDate = startDate;
            this.endDate = endDate;
        }
    }

    public class DataGroupingRow {
        public String assignmentGroup {get; set;}
        public DateRange range {get; set;}

        public Set<Id> openingBalanceIncidents {get; set;}
        public Set<Id> openingBacklogIncidents {get; set;}
        public Set<Id> createdIncidents {get; set;}
        public Set<Id> resolvedIncidents {get; set;}
        public Decimal totalResponseTime {get; set;}
        public Decimal totalResolutionTime {get; set;}
        public Decimal totalAgeOfBacklogInDays {get; set;}
        public Decimal totalSLAResponseTime {get; set;}
        public Decimal totalSLAResolutionTime {get; set;}

        public DataGroupingRow(String assignmentGroup, DateRange range) {
            this.assignmentGroup = assignmentGroup;
            this.range = range;

            clear();
        }

        public void clear() {
            openingBalanceIncidents = new Set<Id>();
            openingBacklogIncidents = new Set<Id>();
            createdIncidents = new Set<Id>();
            resolvedIncidents = new Set<Id>();
            totalResponseTime = 0.0;
            totalResolutionTime = 0.0;
            totalAgeOfBacklogInDays = 0.0;
            totalSLAResponseTime = 0.0;
            totalSLAResolutionTime = 0.0;
        } 

        public Integer getOpeningBalanceSize() {
            return openingBalanceIncidents.size();
        }

        public Integer getOpeningBacklogSize() {
            return openingBacklogIncidents.size();
        }

        public Integer getCreatedSize() {
            return createdIncidents.size();
        }

        public Integer getResolvedSize() {
            return resolvedIncidents.size();
        }

        public Decimal getAvgResponseTime() {
            if(createdIncidents.size() > 0)
                return (totalResponseTime/(createdIncidents.size()*3600));
            return 0.0;
        }

        public Decimal getAvgResolutionTime() {
            if(resolvedIncidents.size() > 0)
                return (totalResolutionTime/(resolvedIncidents.size()*3600));
            return 0.0;
        }

        public Decimal getAvgAgeOfBacklogInDays() {
            if(openingBacklogIncidents.size() > 0)
                return (totalAgeOfBacklogInDays/(openingBacklogIncidents.size()));
            return 0.0;
        }

        public Decimal getAvgSLAResponseTime() {
            if(createdIncidents.size() > 0)
                return (totalSLAResponseTime/(createdIncidents.size()*3600));
            return 0.0;
        }

        public Decimal getAvgSLAResolutionTime() {
            if(resolvedIncidents.size() > 0)
                return (totalSLAResolutionTime/(resolvedIncidents.size()*3600));
            return 0.0;
        }

        public String getOpeningBalanceIdSet() {
            return getIdList(openingBalanceIncidents);
        }

        public String getOpeningBacklogIdSet() {
            return getIdList(openingBacklogIncidents);
        }

        public String getCreatedIdSet() {
            return getIdList(createdIncidents);
        }

        public String getResolvedIdSet() {
            return getIdList(resolvedIncidents);
        }
    }

    private static DateRange getDateRange(Integer year, Integer month) {
        //Get Date Range
        Date startOfMonth = Date.newInstance(year, month, 1);
        Date endOfMonth = Date.newInstance(year, month, 
            Date.daysInMonth(year, month));
        return new DateRange(startOfMonth, endOfMonth);
    }

    private static String getIdList(Set<Id> idSet) {
        String idStr = '';
        for(String s:idSet) {
           idStr += (idStr == ''?'':',')+s;
        }
        return idStr;
    }
}