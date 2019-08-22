# Lab 500: Secure the data

  ![](images/500/Title-500.png)

## Introduction

## Lab 500 Objectives



## Steps

### **STEP 1:** Your Oracle Cloud Trial Account
- Create a function `BDS_VPD_STATION` to limit to station_id 3186 as starting or ending station
![](images/500/001.png)
- Add a policy to the `bikes` table
![](images/500/002.png)
- Query the `bikes` table and notice the change
![](images/500/003.png)
- Query the `trips` table 
notice the `birth_year` column
![](images/500/004.png)
- Run the data redaction statement on the `trips` table
![](images/500/005.png)
- Query the `trips`table showing the `birth_year` column being redacted
![](images/500/006.png)


**This completes the Lab!**
