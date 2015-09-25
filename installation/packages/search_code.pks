create or replace package search_code
as
----------------------------------------------------------------------
-- Called from the GENERATE_MATRICES package, this package
-- retrieves the program units from the data dictionary and
-- searches them to identify CRUD relationships with a given table
----------------------------------------------------------------------

    procedure table_object_crud
    (
        i_table_owner in crud_matrices.table_owner%type,
        i_table_name in crud_matrices.table_name%type,
        i_object_owner in crud_matrices.object_owner%type,
        i_object_name in crud_matrices.object_name%type,
        i_object_type in crud_matrices.object_type%type,
        o_create out crud_matrices.create_flag%type,
        o_read out crud_matrices.read_flag%type,
        o_update out crud_matrices.update_flag%type,
        o_delete out crud_matrices.delete_flag%type
    );

end search_code;
/
