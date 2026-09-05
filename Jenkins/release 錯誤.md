


http://ci-master.91dev.tw:8080/view/Production/job/91APP%20Production%20Deploy%20With%20ASG/job/nineyi.sms/job/master/1171/console




## 失敗的

```bash
10:25:46  ========================================
10:25:46  Step 1 - Check first machine
10:25:46  ========================================
10:25:46  Executing task: Step 1 - Check first machine
10:25:46  Executing: IISReset
10:25:57  63904040755998204797848b9a-2adc-49c8-b1fa-7217a61f3d5d - Request: GET https://api.infra.91app.io/v2/Ops/AWSResource/ASG/AutoScalingInstanceState?Market=MY&Role=Web&Service=OSM&Environment=Prod&Group=Green
10:25:57  
10:25:58  63904040755998204797848b9a-2adc-49c8-b1fa-7217a61f3d5d - Response: GET https://api.infra.91app.io/v2/Ops/AWSResource/ASG/AutoScalingInstanceState?Market=MY&Role=Web&Service=OSM&Environment=Prod&Group=Green
10:25:58  {"ReturnCode": "API0002", "Message": "Instance i-03d129c967a970ddc lifecycle is not InService", "Content": null}
10:25:58  AutoScaling Group is not ready: Instance i-03d129c967a970ddc lifecycle is not InService
10:26:11  
10:26:11  Attempting stop...
10:26:11  
10:26:11  Restart attempt failed.
10:26:11  
10:26:11  Access denied, you must be an administrator of the remote computer to use this
10:26:11  
10:26:11  command. Either have your account added to the administrator local group of
10:26:11  
10:26:11  the remote computer or to the domain administrator global group.
10:26:11  
10:26:11  SG-MY-OSMWEB3 Health Checking...
```


## 成功的


```bash
10:54:42  ========================================
10:54:42  Step 1 - Check first machine
10:54:42  ========================================
10:54:42  Executing task: Step 1 - Check first machine
10:54:42  Executing: IISReset
10:54:50  
10:54:50  Attempting stop...
10:54:50  
10:54:50  Internet services successfully stopped
10:54:50  
10:54:50  Attempting start...
10:54:50  
10:54:50  Internet services successfully restarted
10:54:50  
10:54:50  SG-MY-OSMWEB3 Health Checking...
10:55:16  SG-MY-OSMWEB3 Health Checking(http://osm2.91app.com.my/api/health/check)...Pass
10:55:16  SG-MY-OSMWEB3 Health Checking(http://osm2.91app.com.my/api/ops/healthcheck)...Pass
10:55:18  SG-MY-OSMWEB3 Health Checking(http://osm2.91app.com.my/api/translations/fetch)...Pass
10:55:18  Finished executing task: Step 1 - Check first machine
```