-- Drop any tables (just in case)
drop table stations_ext;
drop table gender;
drop table trips;
drop table bike_trip_stream;
drop MATERIALIZED VIEW mv_station_users;
drop table stations;
create table gender (
  gender number,
  gender_name varchar2(20)
);

CREATE TABLE trips_ext
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

insert into gender (gender, gender_name) values (0, 'Unknown');
insert into gender (gender, gender_name) values (1, 'Male');
insert into gender (gender, gender_name) values (2, 'Female');
commit;
create table weather as select * from bdsql_bikes.weather;
create table mv_station_users as
  select start_station_id,
         start_station_name,
         end_station_id,
         end_station_name,
         gender_name,
         user_type,
         count(*) as num_trips
  from trips_ext t, gender g
  where t.gender = g.gender
  group by start_station_id,
         start_station_name,
         end_station_id,
         end_station_name,
         gender_name,
         user_type;

alter session set QUERY_REWRITE_INTEGRITY = stale_tolerated;
exit;
