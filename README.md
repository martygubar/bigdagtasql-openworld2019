# Oracle Big Data SQL

Welcome to the Big Data SQL Workshop!  The goal for the workshop is to give you an understanding of how Big Data SQL works.  Specifically, the focus is on Big Data SQL functional capabilities:  how to access data from different sources (object store, hdfs, hive and Kafka), running queries and applying security.  

#### Background ####
The workshop is based on information from the NYC Citi Bikes Ridesharing program - [you can see the data here](https://data.cityofnewyork.us/NYC-BigApps/Citi-Bike-System-Data/vsnr-94wk).  A rider picks up a bike from a station anywhere in  the city - takes a trip - and then drops off his/her bike at another station.  The ending station may or may not be the same.  We combine this information with weather data - and then ask questions like:

- Who is using bikes?  
- Where are they going?  
- How much time do they spend riding?  
- Are bikes optimally distributed across stations? 
- How do we ensure that the right bicycle inventory is deployed to various stations? 
 
##### Why Zeppelin? #####
We'll answer these questions using this Zeppelin Note.  Why Zeppelin?  Because it makes it easy to jump between different technologies from within a single UI.  You will be running shell scripts, sql scripts, connect to HDFS and running interactive SQL commands.  Zeppelin may not be the best for any one of the tasks (e.g. I would much rather be using SQL Developer for running/debugging SQL) - but it works well for this instructional workshop

#### Workshop Contents ####
Here are the tasks that you will perform during the workshop:

- Review Bike Station data that was downloaded from NYC OpenData into HDFS.
- Access this data using Big Data SQL's ORACLE_HDFS driver + Oracle Database 12c JSON features
- Perform "mini-ETL" - save the transformed data as an Oracle Database internal table
- Bike trips data was downloaded from NYC OpenData into Hive as a partitioned table.  Access that data using Big Data SQL's ORACLE_HIVE driver
- Use Oracle SQL to answer different q's - seamlessly combining data from the different sources
- Create an MV and use query rewrite to provide superfast performance
- Create a Kafka stream to see what is happening with the distribution of bikes at this moment!  Combine the stream with data in Oracle Database
- Secure data - using Oracle Database row-level security and redaction
