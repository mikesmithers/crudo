define crudo_owner = crudo
define crudo_ts = users
define temp_ts = temp
accept crudo_owner char default &crudo_owner prompt 'Enter the name of the new crudo Application Owner schema [&crudo_owner] : '
accept crudo_ts char default &crudo_ts prompt 'Default tablespace for the new schema [&crudo_ts] : ' 
accept temp_ts char default &temp_ts prompt 'Temporary tablespace for the new schem [&temp_ts] : '
accept passwd prompt 'Enter a password for the new schema [] : ' hide

create user &crudo_owner identified by &passwd
default tablespace &crudo_ts temporary tablespace &temp_ts
/

grant select any dictionary, 
    create session, alter session, 
    create procedure, create table, create sequence to &crudo_owner
/

alter user &crudo_owner quota unlimited on &crudo_ts
/
