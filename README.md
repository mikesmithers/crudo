- [What is CRUDO ?] (#what-is-cruddo)
- [Installation] (#installation)
- [Usage] (#usage)
- [SQLDeveloper Integration] (#sqldeveloper-integration)
- [License] (#license)

#What is CRUDO ?

Is it a bird, is it a plane, is it a domestic cleaning product ?
Actually, it's a PL/SQL utility for generating a CRUD matrix for stored PL/SQL program units against database tables.
Incidentally CRUD stands for Create Read Update Delete and represents the possible DML operations on a table in a Relational Database.
The "O" stands for Oracle. I couldn't come up with a recursive acronym.

For a given table ( or all tables in a given schema), CRUDO will identify any dependent packages, procedures, functions, triggers etc.
It will then generate and store crud matrices of those objects against the table.
Optionally, you can make use of SQLDeveloper extensions to generate and review the matrices generated by the application :


<img alt="SQLDeveloper CRUD Matrix Tab" border="0" src="sqld_tab.png">


#Installation

Full installation instructions are included in installation_instructions.txt in the installation directory.
As CRUDO relies solely on meta data in the data dictionary, you can run it on any environment that contains the application code that you want to analyse.

The quickest way to do this is as follows :

##Create a schema called CRUDO :

```sql
@scripts/crud_owner.sql
```

Accept the default application owner name (CRUDO) and set the default and temporary tablespaces for this user as appropriate.

##Connect to the database as CRUDO and run :

```sql
@crudo_deploy.sql
```

#Usage

##Generate or Update CRUD Matrices for a table

```plsql
begin
    crudo.generate_matrices.crud_table('HR', 'EMPLOYEES');
end;
/
commit;
```

To see the results :

```sql
select object_owner, object_name, object_type,
    create_flag, read_flag, update_flag, delete_flag
from crudo.crud_matrices
where table_owner = 'HR'
and table_name = 'EMPLOYEES'
/
```

##Generate Matrices for all tables in a Schema

```plsql
begin
    crudo.generate_matrices.crud_schema('HR');
end;
/
```

##Set or remove an override record

If, for example, you have a function called GET_EMP_RECS which references the EMPLOYEES table in a dynamic sql statement, it may well not show up in DBA_DEPENDENCIES.
In such cases, you can create an override CRUD, which the application will respect during refreshes.

To create an override record :

```plsql
begin
    crudo.generate_matrices.set_override
    (
        i_table_owner => 'HR',
        i_table_name => 'EMPLOYEES'
        i_object_owner => 'HR',
        i_object_name => 'GET_EMP_RECS',
        i_object_type => 'FUNCTION',
        i_create => 'N',
        i_read => 'Y',
        i_update => 'N',
        i_delete  => 'N'
    );
    commit;
end;
/
```

Override records will persist until you unset them. Once unset, the record will be overwritten then next time CRUD matrices are generated for the table.

To remove an override record :

```plsql
begin
    crudo.generate_matrices.remove_override
    (
        i_table_owner => 'HR',
        i_table_name => 'EMPLOYEES'
        i_object_owner => 'HR',
        i_object_name => 'GET_EMP_RECS',
        i_object_type => 'FUNCTION',
    );
    commit;
end;
/
```

##Application Settings

There are three application settings that can be queried, two of which can be changed.

To check which version of the application is currently installed :

```sql
select crudo.generate_matrices.get_version
from dual
/
```

The application runs at one of three logging levels, which determine which types of message are written to the APPLICATION_LOGS table.
    ERROR - just log error messages (the default)
    INFO  - Information and error messages
    DEBUG - all messages
    
To see what the current session setting is :

```sql
select crudo.generate_matrices.get_log_level
from dual
/
```

To change the log level for the current session :

```plsql
begin
    crudo.generate_matrices.set_log_level('INFO');
end;
/
```

The processing of the search of dependent objects on a table is done using a BULK COLLECT. You can amend the limit setting for this statement.
To find the current setting :

```sql
select crudo.generate_matrices.get_bulk_collect_limit
from dual
/
```

To amend the Bulk Collect limit for this session :

```plsql
begin
    crudo.generate_matrices.set_bulk_collect_limit(10000);
end;
/
```

#SQLDeveloper Integration

If you use SQLDeveloper, there are two extensions available for CRUDO.
The first creates an additional tab in the Table View which displays the CRUD for the table in context.
The second is on the right-click menu in the table node and lets you generate a matrix for, or manage override records on the table in focus.

To add these extensions :

    1. Open SQLDeveloper.
    2. Go to the Tools Menu and Select Preferences.
    3. In the Preferences Tree, Expand the database node and click on User Defined Extensions.
    4. Click on the Add Row button.
    5. For the CRUD Tab 
        Select a type of Editor.
        Specify the location as the path and filename for crud_tab.xml

    6. For the Crud Table Menu 
        Specify a type of Action
        Specify the location as the path and filename for crud_table_action.xml

    7. Re-start SQLDeveloper
    
When you bring select a table in the connections tree you should now see a tab called CRUD Matrix added at the end of the list of tabs for the table.

If you right-click on the table, you should see a sub-menu called CRUDO Table Menu.

#License

This project is uses the [MIT license](LICENSE).
