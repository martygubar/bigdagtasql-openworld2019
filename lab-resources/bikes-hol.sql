-- Reset
drop table bikes.stations_ext;
drop table bikes.trips;
drop table bikes.station_status;
drop materialized view mv_station_users;
drop table bikes.stations;
drop function bikes.bds_vpd_station;
drop table weather;

-- Have Jersey City Data - region_id=73

-- 
select * from ridership;
desc ridership;

-- How is ridership impacted by changes in the weather?
-- Weather data in Object Store
-- Object Store
-- https://swiftobjectstorage.uk-london-1.oraclecloud.com/v1/adwc4pm/weather/weather-newark-airport.html

-- view object store data
CREATE TABLE weather
  ( WEATHER_STATION_ID      VARCHAR2(20),
    WEATHER_STATION_NAME    VARCHAR2(100),
    REPORT_DATE             VARCHAR2(20),
    AVG_WIND                NUMBER,
    PRECIPITATION           NUMBER,
    SNOWFALL                NUMBER,
    SNOW_DEPTH              NUMBER,
    TEMP_AVG                NUMBER,
    TEMP_MAX                NUMBER,
    TEMP_MIN                NUMBER,
    WDF2                    NUMBER,
    WDF5                    NUMBER,
    WESD                    NUMBER,
    WESF                    NUMBER,
    WSF2                    NUMBER,
    WSF5                    NUMBER,
    FOG                     NUMBER,
    HEAVY_FOG               NUMBER(1),
    THUNDER                 NUMBER(1),
    SLEET                   NUMBER(1),
    HAIL                    NUMBER(1),
    GLAZE                   NUMBER(1),
    HAZE                    NUMBER(1),
    DRIFTING_SNOW           NUMBER(1),
    HIGH_WINDS              NUMBER(1)
  )
  ORGANIZATION EXTERNAL
  (TYPE ORACLE_BIGDATA
   DEFAULT DIRECTORY DEFAULT_DIR
   ACCESS PARAMETERS
   (
    com.oracle.bigdata.fileformat = textfile 
    com.oracle.bigdata.csv.skip.header=1
    com.oracle.bigdata.csv.rowformat.fields.terminator = '|'
   )
   location ('https://swiftobjectstorage.uk-london-1.oraclecloud.com/v1/adwc4pm/weather/*.csv')
  )  REJECT LIMIT UNLIMITED;
  
select * from weather;

-- Look at the impact of weather.  When it's hotter, no one has a problem with a little rain!
with rides_by_weather as (
    select case 
          when w.temp_avg < 32 then '32 and below'
          when w.temp_avg between 32 and 50 then '32 to 50'
          when w.temp_avg between 51 and 75 then '51 to 75'
          else '75 and higher'
        end temp_range,            
        case
          when w.precipitation = 0 then 'clear skies'
          else 'rain or snow'
        end weather,
        r.num_trips num_trips, 
        r.passes_24hr_sold,
        r.passes_3day_sold 
      from ridership r , weather w
      where r.day = w.report_date
    )
    select temp_range,
           weather,
           round(avg(num_trips)) num_trips,
           round(avg(passes_24hr_sold)) passes_24hr,
           round(avg(passes_3day_sold)) passes_3day
    from rides_by_weather
    group by temp_range, weather
    order by temp_range, weather;



-- Let's get information about Stations and how bikes are used across them.
-- We'll want to know which stations are
-- Look at data stored in HDFS.  Station data feed.
-- Station data over JSON source.  Details about each station.
-- Hue:  http://bds1.localdomain:8888/hue/filebrowser/view=/user/bikes#/data/bike-stations

CREATE TABLE bikes.stations_ext (
    doc varchar2(4000)     	   
 ) 
   ORGANIZATION EXTERNAL 
    ( TYPE ORACLE_HDFS
      DEFAULT DIRECTORY DEFAULT_DIR
      LOCATION ('/data/bike-stations')
    )
REJECT LIMIT UNLIMITED;

select count(*) from stations_ext;
-- Query station data. Use Oracle JSON syntax to 
select s.doc,
       s.doc.station_id,
       s.doc.name,
       s.doc.short_name,
       s.doc.lon as longitude,
       s.doc.lat as latitude,
       s.doc.region_id,
       s.doc.capacity,
       s.doc.eightd_station_services.service_type as service_type,
       s.doc.eightd_station_services.bikes_availability as bike_availability,
       s.doc.rental_methods,
       s.doc.rental_methods[0],
       s.doc.rental_methods[1]
from stations_ext s
where rownum < 100
;

-- Want to load the data into Oracle?  Perform some simple ETL
CREATE TABLE bikes.stations AS
SELECT to_number(s.doc.station_id) as station_id,
       s.doc.name as station_name,
       to_number(s.doc.lon) as longitude,
       to_number(s.doc.lat) as latitude,
       s.doc.region_id,
       s.doc.eightd_station_services.service_type as service_type,
       s.doc.eightd_station_services.bikes_availability as bike_availability,       
       to_number(s.doc.capacity) as capacity,
       s.doc.rental_methods
FROM stations_ext s
WHERE s.doc.name not like '%Don''t%';

select * from bikes.stations;

-- What is available in Hive?  Bring up Hue to review


-- Create table over the trips data
CREATE TABLE bikes.trips 
(
  trip_duration number,
  start_time date,
  start_hour number,
  stop_time  date,
  start_station_id number,
  start_station_name varchar2(100),
  start_station_latitude number,
  start_station_longitude number,
  end_station_id number,
  end_station_name varchar2(100),
  end_station_latitude number,
  end_station_longitude number,
  bike_id number,
  user_type varchar2(50),
  birth_year number,
  gender number,
  start_month varchar2(10)
)  
  ORGANIZATION EXTERNAL 
    ( TYPE ORACLE_HIVE
      DEFAULT DIRECTORY DEFAULT_DIR
      ACCESS PARAMETERS
      (     
        com.oracle.bigdata.tablename = bikes.trips
      )
    );


-- Query it.
select * 
from trips
where rownum < 100;


-- Look at bikes and how the are deployed.
-- How many bikes were moved?  Use SQL Analytic Functions
-- Their drop off station is not the same as their starting station

with bike_start_dest as (
  select bike_id,
         start_station_name,
         end_station_name,
         lag(end_station_name, 1) over (partition by bike_id order by start_time) as prev_end_station,
         to_char(start_time, 'MM/DD') as start_day,
         to_char(start_time, 'HH24:MI') as start_time,
         to_char(stop_time, 'HH24:MI') as stop_time
  from trips
  where start_month = '2019-06'
)
select prev_end_station as moved_from,
       start_station_name as moved_to,
       start_day,
       count(*) as num_bikes_moved
from bike_start_dest
where prev_end_station != start_station_name
group by prev_end_station, start_station_name, start_day
order by start_day;


-- Create an MV
CREATE MATERIALIZED VIEW bikes.mv_station_users 
ON PREBUILT TABLE 
ENABLE QUERY REWRITE AS (
  select start_station_id,
         start_station_name,
         end_station_id,
         end_station_name,
         gender_name,
         user_type,
         count(*) as num_trips
  from trips t, gender g
  where t.gender = g.gender
  group by start_station_id,
         start_station_name,
         end_station_id,
         end_station_name,
         gender_name,
         user_type
  );
  
-- Rewrite to an MV
select start_station_name,
       gender_name,
       count(*)
from trips t, gender g
where t.gender = g.gender
group by start_station_name, gender_name
order by 1,2
    ;

--
-- Kafka - Go to Zeppelin to do the work ...
--
CREATE TABLE bikes.station_status
(
  topic varchar2(50),
  partitionid number,
  value clob,
  offset integer,
  timestamp tidisplays
  mestamp,
  timestamptype integer
)  
  ORGANIZATION EXTERNAL 
    ( TYPE ORACLE_HIVE
      DEFAULT DIRECTORY DEFAULT_DIR
      ACCESS PARAMETERS
      (     
        com.oracle.bigdata.tablename = bikes.station_status
      )
    );

-- Security
-- Row level security
-- Create a VPD Policy
-- Only look at the station information that you are in charge of

CREATE OR REPLACE FUNCTION BIKES.BDS_VPD_STATION (obj_schema varchar2, obj_name VARCHAR2) RETURN VARCHAR2 AS 
  p_emp varchar2(100);
  p_retval varchar2(200);
BEGIN
  -- Bikes user is only allowed to see station info for Grove Street (3186)
  p_emp := sys_context('USERENV','AUTHENTICATED_IDENTITY');
  
  p_retval := case when p_emp = 'BIKES' then 'start_station_id=3186 or end_station_id=3186'
              else '1=1'
              end;
  
  
  RETURN p_retval;
END BDS_VPD_STATION;
/

-- Add the VPD Policy
BEGIN
  dbms_rls.add_policy(object_schema => 'BIKES',
    object_name     => 'TRIPS',
    policy_name     => 'FILTER_TRIPS',
    function_schema => 'BIKES',
    policy_function => 'BDS_VPD_STATION',
    statement_types => 'select');
END;
/

select start_station_name, 
       end_station_name, 
       start_time,
       stop_time       
from trips 
where rownum < 100;

-- Redact age
select start_station_name, 
       end_station_name, 
       start_time,
       bike_id,
       birth_year       
from trips 
where rownum < 100;

BEGIN
  DBMS_REDACT.ADD_POLICY(
    object_schema => 'BIKES',
    object_name => 'TRIPS',
    column_name => 'BIRTH_YEAR',
    policy_name => 'redact_birth_year',
    function_type => DBMS_REDACT.FULL,
    expression => q'[SYS_CONTEXT('USERENV','AUTHENTICATED_IDENTITY') = 'BIKES']'
  );
  
END;
/

select start_station_name, 
       end_station_name, 
       start_time,
       bike_id,
       birth_year       
from trips 
where rownum < 100;

----- dataguide  -------
create table station_stream as select * from bikes.station_status;
select * from station_stream;
desc station_stream;
04-AUG-19 09.09.11.476226000 PM AMERICA/NEW_YORK
select current_timestamp from dual;

SELECT JSON_DATAGUIDE(value, DBMS_JSON.format_flat, DBMS_JSON.pretty) dg_doc
FROM   station_stream;
SELECT JSON_DATAGUIDE(value, DBMS_JSON.format_hierarchical, DBMS_JSON.pretty) dg_doc
FROM   station_stream;

select * from station_stream order by timestamp desc;
drop view station_stream_view;
set define off;
declare
   dataguide clob;
BEGIN
  select json_dataguide(value, dbms_json.format_hierarchical,dbms_json.pretty) 
  into dataguide 
  from station_stream
  where rownum < 30;
  
  DBMS_JSON.create_view(
    viewname  => 'station_stream_view',
    tablename => 'station_stream',
    jcolname   => 'value',
    dataguide  => dataguide);
END;
/

select * from station_stream_view where offset != 31;



select station_status.*
from station_stream ss,
     json_table(ss.value, '$.data.stations[*]'
       COLUMNS (
        station_id          VARCHAR2(10) PATH'$.station_id',
        is_renting          NUMBER(1) PATH '$.is_renting',
        num_bikes_disabled  NUMBER(2) PATH '$.num_bikes_disabled',
        num_docks_disabled  NUMBER(2) PATH '$.num_docks_disabled',
        num_bikes_available NUMBER(2) PATH '$.num_bikes_available'     
       )
     ) as station_status
;
select timestamp, current_timestamp, (current_timestamp - interval '7200' second) as thelag
from station_status
where rownum =1;

-- JSON Data Guide
"[
  {
    "o:path" : "$.ttl",
    "type" : "number",
    "o:length" : 2
  },
  {
    "o:path" : "$.data",
    "type" : "object",
    "o:length" : 32767
  },
  {
    "o:path" : "$.data.stations",
    "type" : "array",
    "o:length" : 32767
  },
  {
    "o:path" : "$.data.stations.is_renting",
    "type" : "number",
    "o:length" : 1
  },
  {
    "o:path" : "$.data.stations.station_id",
    "type" : "string",
    "o:length" : 4
  },
  {
    "o:path" : "$.data.stations.is_installed",
    "type" : "number",
    "o:length" : 1
  },
  {
    "o:path" : "$.data.stations.is_returning",
    "type" : "number",
    "o:length" : 1
  },
  {
    "o:path" : "$.data.stations.last_reported",
    "type" : "number",
    "o:length" : 16
  },
  {
    "o:path" : "$.data.stations.num_bikes_disabled",
    "type" : "number",
    "o:length" : 2
  },
  {
    "o:path" : "$.data.stations.num_docks_disabled",
    "type" : "number",
    "o:length" : 2
  },
  {
    "o:path" : "$.data.stations.num_bikes_available",
    "type" : "number",
    "o:length" : 2
  },
  {
    "o:path" : "$.data.stations.num_docks_available",
    "type" : "number",
    "o:length" : 2
  },
  {
    "o:path" : "$.data.stations.num_ebikes_available",
    "type" : "number",
    "o:length" : 1
  },
  {
    "o:path" : "$.data.stations.eightd_has_available_keys",
    "type" : "boolean",
    "o:length" : 8
  },
  {
    "o:path" : "$.data.stations.eightd_active_station_services",
    "type" : "array",
    "o:length" : 64
  },
  {
    "o:path" : "$.data.stations.eightd_active_station_services.id",
    "type" : "string",
    "o:length" : 64
  },
  {
    "o:path" : "$.last_updated",
    "type" : "number",
    "o:length" : 16
  }
]"

;
-- Object Store
CREATE TABLE weather
  (WEATHER_STATION_ID        VARCHAR2(20),
   WEATHER_STATION_NAME     VARCHAR2(50),
   REPORTED_DATE            DATE,
    AVG_WIND    NUMBER(3,2),
    PRECIPITATION     NUMBER(3,2),
    SNOWFALL    NUMBER(3,2),
    SNOW_DEPTH    NUMBER(3,2),
    TEMP_AVG    NUMBER(3,2),
    TEMP_MAX    NUMBER(3,2),
    TEMP_MIN    NUMBER(3,2),
    WDF2    NUMBER(3,2),
    WDF5    NUMBER(3,2),
    WESD    NUMBER(3,2),
    WESF    NUMBER(3,2),
    WSF2    NUMBER(3,2),
    WSF5    NUMBER(3,2),
    FOG    NUMBER(3,2),
    HEAVY_FOG    NUMBER(1),
    THUNDER    NUMBER(1),
    SLEET    NUMBER(1),
    HAIL    NUMBER(1),
    GLAZE    NUMBER(1),
    HAZE    NUMBER(1),
    DRIFTING_SNOW    NUMBER(1),
    HIGH_WINDS  NUMBER(1)
  )
  ORGANIZATION EXTERNAL
  (TYPE ORACLE_BIGDATA
   DEFAULT DIRECTORY DEFAULT_DIR
   ACCESS PARAMETERS
   (
     com.oracle.bigdata.debug=TRUE
     com.oracle.bigdata.fileformat=textfile
   )
   location ('https://swiftobjectstorage.uk-london-1.oraclecloud.com/v1/adwc4pm/weather/*.csv')
  )  REJECT LIMIT UNLIMITED;
