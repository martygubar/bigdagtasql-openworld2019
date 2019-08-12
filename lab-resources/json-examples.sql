set define off;

--PLSQL for creating a view based on a data guide
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

-- Create a view based on JSON_TABLE
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

