# Lab 500: Secure the data

  ![](images/500/Title-500.png)

## Introduction

## Lab 500 Objectives
In this lab you will apply Oracle security policies on the big data sql tables you have created. 

## Steps
- Define and use a VPD (Virtual Private Database) policy
- Define and use a Data Redaction policy

### **STEP 1:** Apply a VPD policy to the `bikes` user
- Create a policy called `BDS_VPD_STATION` to limit to station_id 3186 as starting or ending station 
![](images/500/001.png)
- Add this policy to the `bikes` user
![](images/500/002.png)
- Query the `trips` table and notice the change
![](images/500/003.png)

### **STEP 2:** Apply a data redaction policy to `birth_year` column the `trips` table 
- Query the `trips` table and notice the `birth_year` column
![](images/500/004.png)
- Run the data redaction statement on the `trips` table
![](images/500/005.png)
- Query the `trips`table showing the `birth_year` column being redacted
![](images/500/006.png)

## Summary
In this lab you have applied Oracle security on tables created with big data sql like you would have for any other table.

**This completes the Lab!**
