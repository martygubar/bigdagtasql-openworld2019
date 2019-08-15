# Lab 200: Gather Station Details

  ![](images/200/Title-200.png)
  

## Introduction

In Lab 200, you will create an oracle table out of a file stored in hdfs. This file contains station details data in JSON format. You will use Oracle JSON dot notation to parse the fields and create a station details table.

## Lab 200 Objectives

- Connect to HUE and check the data file stored in the HDFS filesystem
- Create a table called "bikes.station_ext" out of this file
- Create a table called "bikes.stations" out of "bikes.stations_ext" using JSON dot notation

## Steps

### **STEP 1:** Check the data files in hdfs

 * From your browser, connect to HUE : http://localhost:8888 and login using `oracle / welcome1`
 
 ![](images/200/001.png)
 
* Browse the content of the file "station_information.json"

![](images/200/002.png)

Notice that the file format is JSON

![](images/200/003.png)


### **STEP 2:** Create an oracle table called "bikes.station_ext" 

run the following statement from sql developper

notice the "TYPE ORACLE_HDFS" statement 


### **STEP 3:** Create an oracle table called "bikes.station" using JSON dot notation 


**This completes the Lab!**

**You are ready to proceed to [Lab 300](LabGuide300.md)**
