create table crud_matrices
(
    table_owner varchar2(30), 
    table_name varchar2(30),
    object_owner varchar2(30) not null, 
    object_name varchar2(30) not null, 
    object_type varchar2(30) not null,
    create_flag varchar2(1) not null, 
    read_flag varchar2(1) not null, 
    update_flag varchar2(1) not null, 
    delete_flag varchar2(1) not null,
    last_updated date not null,
    last_updated_user varchar2(30) not null,
    override_flag varchar2(1) default 'N' not null
)
/

alter table crud_matrices
    add constraint cm_pk primary key (table_owner, table_name, object_owner, object_name, object_type)
/

comment on table crud_matrices is
    'This is the core table of the application. It holds the CRUD matrix for each table that has been processed by the application'
/

comment on column crud_matrices.table_owner is
    'Owner of the table that is subject of the DML operation. Part of Composite Primary Key'
/

comment on column crud_matrices.table_name is
    'The table that is the subject of the DML operation. Part of Composite Primary Key'
/


comment on column crud_matrices.object_owner
is
    'Owner of the database object that references the table. Part of Composite Primary Key'
/

comment on column crud_matrices.object_name
is
    'Name of the object that references the table. Part of Composite Primary Key'
/

comment on column crud_matrices.object_type
is
    'Type of the object - i.e. stored program unit. Part of Composite Primary Key'
/


comment on column crud_matrices.create_flag
is
    'Y if this object creates records in the table else N'
/

comment on column crud_matrices.read_flag
is
    'Y if this object reads (selects) records in the table else N'
/

comment on column crud_matrices.update_flag
is
    'Y if this object updates records in the table else N'
/

comment on column crud_matrices.delete_flag
is
    'Y if this object deletes records from the table else N'
/

comment on column crud_matrices.last_updated
is
    'The last time this crud matrix was generated. NOTE this column is defined as a date as it is used in the application for comparison with dba_objects.last_ddl_time (also a date as at 11gR2)'
/

comment on column crud_matrices.last_updated_user
is
    'The last user to update this record. Particularly relevant for records where OVERRIDE_FLAG is set to Y'
/

comment on column crud_matrices.override_flag 
is
    'If set to Y then do not CRUD this table/object combination, just leave the existing record in place. Default is N'
/
