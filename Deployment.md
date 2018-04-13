# Deployment

1) Deploy the main package using the command below from the root directory of the project.
```
ant -DDEST_USERNAME=<username for target org> -DDEST_PASSWD=<password for target org> -DDEST_URL=<url for target org> deploy
```

# Post Deployment
1) Load Application Configuration Data. (Apex Data Loader is required for loads)
	> For 'Server Criticality List.csv' use ServerCriticalityMapping.sdl. Operation: upsert 
	> For 'ServerBaselineValues.csv' use serverbaselinevaluesmapping.sdl. Operation: insert
	> For 'datacenter.csv' use datacentermapping.sdl. Operation: upser'.t
	> For 'changerequest.csv' use changerequestmapping.sdl. Operation: insert

2) Setup Organization Wide Email Address with name 'Husky Server Heartbeat Email' and email 'list-sappi@huskyenergy.com