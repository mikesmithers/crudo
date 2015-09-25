create or replace package generate_matrices
as

---------------------------------------------------------------------------------
--
-- The MIT License (MIT)
--
-- Copyright (c) 2015 Mike Smithers
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--
---------------------------------------------------------------------------------

    ------------------------------------
    -- Global Variables and Constants --
    ------------------------------------
     
    -- Current Application Version
    gc_version constant varchar2(10) := '1.0.0';

    -- The value of the limit clause for the bulk collect of dependent objects on a table.
    g_bulk_collect_limit pls_integer := 1000;    

    ---------------------
    -- Package Members --
    ---------------------
    
    -- Returns the current application version
    function get_version return varchar2;
    
    -- Returns the current log level for this session
    -- NOTE - the corresponding package variable is in the LOGS  package.
    function get_log_level return varchar2;
    
    -- Returns the current bulk_collect_limit for the session    
    function get_bulk_collect_limit return pls_integer;

    -- Sets the bulk collect limit for the current session
    procedure set_bulk_collect_limit( i_limit in pls_integer);

    -- Set the application log level for the current session
    -- Valid levels are :
    -- ERROR - log only error messages
    -- INFO  - log ERROR and INFO messages
    -- DEBUG - log all messages
    procedure set_log_level( i_level in varchar2);

    -- Set an override record in the application.
    procedure set_override
    (
        i_table_owner in crud_matrices.table_owner%type,
        i_table_name in crud_matrices.table_name%type,
        i_object_owner in crud_matrices.object_owner%type,
        i_object_name in crud_matrices.object_name%type,
        i_object_type in crud_matrices.object_type%type,
        i_create in crud_matrices.create_flag%type,
        i_read in crud_matrices.read_flag%type,
        i_update in crud_matrices.update_flag%type,
        i_delete in crud_matrices.delete_flag%type
    );

    -- Unset an override record
    -- NOTE - the record will remain in the table with a last_updated date of 01-JAN-1970
    -- Until the application is run against the table again.
    procedure remove_override
    (
        i_table_owner in crud_matrices.table_owner%type,
        i_table_name in crud_matrices.table_name%type,
        i_object_owner in crud_matrices.object_owner%type,
        i_object_name in crud_matrices.object_name%type,
        i_object_type in crud_matrices.object_type%type
    );
    
    -- Generate crud matrices for the dependent objects on a table    
    procedure crud_table
    ( 
        i_owner in dba_tables.owner%type, 
        i_table_name in dba_tables.table_name%type, 
        i_refresh_type in varchar2 default 'DELTA'
    );

    -- Generate crud matrices for all tables in a schema
    procedure crud_schema( i_schema in dba_tables.owner%type, i_refresh_type in varchar2 default 'DELTA');

end generate_matrices;
/
