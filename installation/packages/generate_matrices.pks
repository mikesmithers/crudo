create or replace package generate_matrices
as

--
-- This is the main application package
--

    --
    -- Current Application Version
    --
    gc_version constant varchar2(10) := '1.0.0';

    
    --
    -- G_BULK_COLLECT_LIMIT - determines the value of the limit
    -- clause for the bulk collect of dependent objects on a table.
    --
    g_bulk_collect_limit pls_integer := 1000;    
    --
    -- GET_VERSION
    -- Return the current application version
    --
    function get_version return varchar2;
    
    --
    -- GET_LOG_LEVEL
    -- Return the current log level for this session
    --
    
    function get_log_level return varchar2;
    
    --
    -- SET_LOG_LEVEL
    -- Set the application log level for the current session
    --
    
    function get_bulk_collect_limit return pls_integer;
    
    procedure set_bulk_collect_limit( i_limit in pls_integer);
    procedure set_log_level( i_level in varchar2);

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

    procedure remove_override
    (
        i_table_owner in crud_matrices.table_owner%type,
        i_table_name in crud_matrices.table_name%type,
        i_object_owner in crud_matrices.object_owner%type,
        i_object_name in crud_matrices.object_name%type,
        i_object_type in crud_matrices.object_type%type
    );
    
    procedure crud_table
    ( 
        i_owner in dba_tables.owner%type, 
        i_table_name in dba_tables.table_name%type, 
        i_refresh_type in varchar2 default 'DELTA'
    );

    procedure crud_schema( i_schema in dba_tables.owner%type, i_refresh_type in varchar2 default 'DELTA');

end generate_matrices;
/
