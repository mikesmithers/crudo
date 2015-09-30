create or replace package body generate_matrices
as

    -----------------------------
    -- PRIVATE package members --
    -----------------------------
    
    function table_exists( i_owner in dba_tables.owner%type, i_table_name dba_tables.table_name%type)
        return boolean
    is
    --
    -- Check to see i_owner.i_table_name exists in DBA_TABLES
    -- 

        l_dummy pls_integer;
        
    begin
        select 1 into l_dummy
        from dba_tables
        where owner = i_owner
        and table_name = i_table_name;
        
        return true;
                
    exception when no_data_found then
        return false;
    
    end table_exists;
    
    function schema_exists( i_schema in dba_users.username%type)
        return boolean
    is
    --
    -- Check to see if i_schema exists in DBA_USERS
    -- 
    
        l_dummy pls_integer;
    
    begin
        select 1 into l_dummy
        from dba_users
        where username = upper( i_schema);
        
        return true;
    
    exception when no_data_found then
        return false;
    
    end schema_exists;
    
    procedure set_app_info( i_module in varchar2, i_action in varchar2)
    is
    --
    -- Maintain the application info for this session.
    -- Values set here will be visible in the module and action columns of v$SESSION
    --
    
        l_current_module varchar2(48);
        l_current_action varchar2(32);
        
        l_module varchar2(48);
        l_action varchar2(32);

    begin
        dbms_application_info.read_module( l_current_module, l_current_action);
        
        if i_action = 'DONE' then
            -- the caller has finished. If the calling module is the same as
            -- the current module value in the session then clear down all information
            -- Otherwise, just clear the action.
            --
            l_action := null;
            
            if i_module = l_current_module then
                l_module := null;
            else
                l_module := l_current_module;
            end if;        
            
            dbms_application_info.set_module( l_module, l_action);
            return;
        end if; -- End of processing for i_action = 'DONE'
        
        if l_current_module is null
            or l_current_module not like $$plsql_unit||'%'
        then
            -- This is the first call from this application in this session.
            l_module := substr(i_module, 1, 48);
            l_action := substr(i_action, 1, 32);
        else
            -- second or subsequent call from this application
            l_module := l_current_module;
            l_action := substr(i_action,1, 32);
        end if;
        
        dbms_application_info.set_module( l_module, l_action);
    
    end set_app_info;
            
    ------------------------------------------------------
    --                                                  --
    -- PUBLIC package members                           --
    -- See package header for general comments on each. --
    --                                                  --
    ------------------------------------------------------
    
    function get_version return varchar2
    is
    begin
        return gc_version;
    end get_version;
    
    function get_log_level return varchar2
    is
    begin
        return logs.g_log_level;
    end get_log_level;
    
    procedure set_log_level( i_level in varchar2) 
    is
    begin
        if upper(i_level) not in ('ERROR', 'INFO', 'DEBUG') then
            raise_application_error( -20000, q'[ERROR : the Log Level must be set to one of 'ERROR', 'INFO', or 'DEBUG']');
        end if;
        
        logs.g_log_level := upper( i_level);
        
    end set_log_level;

    function get_bulk_collect_limit 
        return pls_integer
    is
    begin
        return g_bulk_collect_limit;
    
    end get_bulk_collect_limit;
    
    procedure set_bulk_collect_limit( i_limit in pls_integer)
    is
    begin
        if i_limit < 1 then
            raise_application_error(-20001, 'Bulk Collect Limit must be greater than zero');
        end if;
        
        g_bulk_collect_limit := i_limit;
    
    end set_bulk_collect_limit;
    
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
    )
    is
    begin
        -- Parameter check - table and object details are mandatory.
        -- Also, there must be at least one crud action specified
        if i_table_owner is null or i_table_name is null
            or i_object_owner is null or i_object_name is null or i_object_type is null
            or coalesce( i_create, i_read, i_update, i_delete) is null 
        then
            raise_application_error( -20002, 'Must provide table and object details and at least one crud action value');
        end if;
        
        merge into crud_matrices
        using dual
        on
        (
            table_owner = i_table_owner
            and table_name = i_table_name
            and object_owner = i_object_owner
            and object_name = i_object_name
            and object_type = i_object_type
        )
        when matched then update
            set create_flag = nvl(i_create, 'N'),
                read_flag = nvl( i_read, 'N'),
                update_flag = nvl( i_update, 'N'),
                delete_flag = nvl( i_delete, 'N'),
                override_flag = 'Y',
                last_updated = sysdate,
                last_updated_user = user
        when not matched then insert        
        (
            table_owner, table_name,
            object_owner, object_name, object_type,
            create_flag, read_flag, update_flag, delete_flag,
            override_flag, last_updated, last_updated_user
        )
        values
        (
            i_table_owner, i_table_name,
            i_object_owner, i_object_name, i_object_type,
            nvl(i_create, 'N'), nvl(i_read, 'N'), nvl(i_update, 'N'), nvl(i_delete, 'N'),
            'Y', sysdate, user
        );

    end set_override;    


    procedure remove_override
    (
        i_table_owner in crud_matrices.table_owner%type,
        i_table_name in crud_matrices.table_name%type,
        i_object_owner in crud_matrices.object_owner%type,
        i_object_name in crud_matrices.object_name%type,
        i_object_type in crud_matrices.object_type%type
    )
    is
    begin
        if i_table_owner is null or i_table_name is null
            or i_object_owner is null or i_object_name is null or i_object_type is null
        then
            raise_application_error( -20003, 'Table and object details must be provided.');
        end if;
        
        --
        -- Unset the override flag and set the last_updated date to 1st January 1970
        -- to ensure that the record is overwritten next time a crud is done on this
        -- table.
        --
        update crud_matrices
        set override_flag = 'N',
        last_updated = to_date('01011970', 'DDMMYYYY'),
        last_updated_user = user
        where table_owner = i_table_owner
        and table_name = i_table_name
        and object_owner = i_object_owner
        and object_name = i_object_name
        and object_type = i_object_type
        and override_flag = 'Y';
    end remove_override;
    
    procedure crud_table
    ( 
        i_owner in dba_tables.owner%type, 
        i_table_name in dba_tables.table_name%type, 
        i_refresh_type in varchar2 default 'DELTA'
    )
    is
        lc_proc_name constant application_logs.member_name%type := 'CRUD_TABLE';
        l_module varchar2(48);
        
        l_dummy pls_integer;
    
        type rec_dep_objects is record
        (
            owner dba_dependencies.owner%type,
            name  dba_dependencies.name%type,
            type  dba_dependencies.type%type,
            synonym_name dba_synonyms.synonym_name%type
        );
        
        type typ_dep_objects is table of rec_dep_objects
            index by pls_integer; 

        tbl_dep_objects typ_dep_objects;
        
        type typ_crud_matrix is table of crud_matrices%rowtype
            index by pls_integer;
        
        tbl_crud_matrix typ_crud_matrix;
            
        cursor c_dependencies is
            with dep_objs as
            (
                -- Objects with a dependency on the table
                select dep.owner, dep.name, dep.type, 
                    null as synonym_name,
                    dep.referenced_owner, dep.referenced_name,
                    obj.last_ddl_time
                from dba_dependencies dep
                inner join dba_objects obj
                    on obj.owner = dep.owner
                    and obj.object_name = dep.name  
                    and obj.object_type = dep.type
                and dep.referenced_owner = i_owner
                and dep.referenced_name = i_table_name
                and dep.referenced_type = 'TABLE'
                union
                -- and objects that have a dependency on a synonym pointing to the table
                select dep.owner, dep.name, dep.type,
                    syn.synonym_name,
                    dep.referenced_owner, dep.referenced_name,
                    obj.last_ddl_time
                from dba_dependencies dep
                inner join dba_synonyms syn
                    on dep.referenced_owner = syn.owner
                    and dep.referenced_name = syn.synonym_name
                inner join dba_objects obj
                    on obj.owner = dep.owner
                    and obj.object_name = dep.name
                    and obj.object_type = dep.type
                where dep.referenced_type = 'SYNONYM'
                and dep.type in
                (
                    'FUNCTION', 'PROCEDURE', 'PACKAGE',
                    'PACKAGE BODY', 'TRIGGER', 'VIEW'
                )
                and syn.table_owner = i_owner
                and syn.table_name = i_table_name
            )
                select dep_objs.owner, dep_objs.name, dep_objs.type, 
                    dep_objs.synonym_name
                from dep_objs
                -- exclude any override records
                -- or, if this is not a FULL refresh, any records that were last updated
                -- later than the last_ddl_time on the object
                where not exists
                (
                    select 1
                    from crud_matrices mat
                    where mat.table_owner = dep_objs.referenced_owner
                    and mat.table_name = dep_objs.referenced_name
                    and mat.object_owner = dep_objs.owner
                    and mat.object_type = dep_objs.type
                    and mat.object_name = dep_objs.name
                    and 
                    (
                        mat.override_flag = 'Y'
                    or
                        case i_refresh_type 
                            when 'DELTA' then mat.last_updated 
                            else dep_objs.last_ddl_time - 1 
                        end > dep_objs.last_ddl_time
                    )
                );
                
        l_create crud_matrices.create_flag%type;
        l_read crud_matrices.read_flag%type;
        l_update crud_matrices.update_flag%type;
        l_delete crud_matrices.update_flag%type;
        
        l_success boolean := true;

    begin
        logs.write( lc_proc_name, 'Parameters : i_owner => '||i_owner||', i_table_name => '||i_table_name
            ||', i_refresh_type => '||i_refresh_type, 'I');
        
        if not table_exists(i_owner, i_table_name)
        then
            raise_application_error(-20003, 'Table does not exist '||i_owner||'.'||i_table_name);
        end if;
        
        l_module := $$plsql_unit||'.'||lc_proc_name;
        set_app_info( l_module, i_owner||'.'||i_table_name);

        
        -- Find the dependent stored program units 
        open c_dependencies;
        loop -- Bulk Collect Loop
            fetch c_dependencies bulk collect into tbl_dep_objects limit g_bulk_collect_limit;
            exit when tbl_dep_objects.count = 0;
            for i in 1..tbl_dep_objects.count loop -- Process Objects Loop
                begin -- process object block
                    
                    -- process each dependent object in a nested block.
                    -- so that, if we get an error back we can log it and move on to the next one.

                    logs.write(lc_proc_name, 'Processing '||tbl_dep_objects(i).type||' '||tbl_dep_objects(i).name, 'D');

                    search_code.table_object_crud
                    (
                        i_table_owner => i_owner,
                        i_table_name => nvl(tbl_dep_objects(i).synonym_name, i_table_name),
                        i_object_owner => tbl_dep_objects(i).owner,
                        i_object_name => tbl_dep_objects(i).name,
                        i_object_type => tbl_dep_objects(i).type,
                        o_create => l_create,
                        o_read => l_read,
                        o_update => l_update,
                        o_delete => l_delete
                    );
                    l_success := true;
                exception when others then
                    l_success := false;
                    logs.err( lc_proc_name);
                end; -- end process object block
                
                if not l_success then
                    -- skip the rest of the loop and
                    -- move onto the next object
                    continue;
                end if;          
                
                tbl_crud_matrix(i).table_owner := i_owner;
                tbl_crud_matrix(i).table_name := i_table_name;
                tbl_crud_matrix(i).object_owner := tbl_dep_objects(i).owner;
                tbl_crud_matrix(i).object_name := tbl_dep_objects(i).name;
                tbl_crud_matrix(i).object_type := tbl_dep_objects(i).type;
                tbl_crud_matrix(i).create_flag := l_create;
                tbl_crud_matrix(i).read_flag := l_read;
                tbl_crud_matrix(i).update_flag := l_update;
                tbl_crud_matrix(i).delete_flag := l_delete;
                tbl_crud_matrix(i).override_flag := 'N';
                tbl_crud_matrix(i).last_updated := sysdate;
                tbl_crud_matrix(i).last_updated_user := user;
            
                logs.write(lc_proc_name, 'Matrix generated for '||tbl_dep_objects(i).type||' '||tbl_dep_objects(i).name, 'D');
            end loop; -- Process objects loop
            
            -- save the new records
            
            forall j in 1..tbl_crud_matrix.count
                merge into crud_matrices
                using dual
                on
                (
                    table_owner = tbl_crud_matrix(j).table_owner
                    and table_name = tbl_crud_matrix(j).table_name
                    and object_owner = tbl_crud_matrix(j).object_owner
                    and object_name  = tbl_crud_matrix(j).object_name
                    and object_type  = tbl_crud_matrix(j).object_type
                )
                when matched then
                    update
                    set create_flag  = tbl_crud_matrix(j).create_flag,
                        read_flag = tbl_crud_matrix(j).read_flag,
                        update_flag  = tbl_crud_matrix(j).update_flag,
                        delete_flag = tbl_crud_matrix(j).delete_flag,
                        override_flag  = tbl_crud_matrix(j).override_flag,
                        last_updated  = tbl_crud_matrix(j).last_updated,
                        last_updated_user = tbl_crud_matrix(j).last_updated_user
                when not matched then
                    insert values tbl_crud_matrix(j);
        end loop; -- Bulk collect loop
        close c_dependencies;

        set_app_info( l_module, 'Remove Deleted Objects');
        
        -- Remove crud records for this table where the dependent objects no longer exist
        delete from crud_matrices
        where table_owner = i_owner
        and table_name = i_table_name
        and (object_owner, object_name, object_type) not in
        (
            select owner, object_name, object_type
            from dba_objects
        );
        
        set_app_info( l_module, 'DONE');
    
    exception
        when others then
            logs.err(lc_proc_name);
            raise;
    end crud_table;     

    procedure crud_schema( i_schema in dba_tables.owner%type, i_refresh_type in varchar2 default 'DELTA')
    is
    
        lc_proc_name constant application_logs.member_name%type := 'CRUD_SCHEMA';
        l_module varchar2(48);
    
    begin
        logs.write( lc_proc_name, 'Parameters : i_schema => '||i_schema||', i_refresh_type => '||i_refresh_type, 'I');

        if i_schema is null then
              raise_application_error(-20004, 'i_schema cannot be null');
        end if;

        if not schema_exists( i_schema) then
            raise_application_error(-20004, 'Schema '||i_schema||' does not exist');
        end if;

        l_module := $$plsql_unit||'.'||lc_proc_name;
        set_app_info(l_module, i_schema);

        for r_tabs in
        (
            select table_name
            from dba_tables
            where owner = i_schema
        )
        loop
            begin -- CRUD_TABLE block
                -- Make this call in a nested block so that a failure on one table does not
                -- cause everything to fail
                
                crud_table
                (
                    i_owner => i_schema,
                    i_table_name => r_tabs.table_name,
                    i_refresh_type => i_refresh_type
                );

            exception when others then
                logs.err( lc_proc_name);
            end; -- CRUD_TABLE block
        end loop;
        
        -- remove crud records for tables which no longer exist
        set_app_info(l_module, 'Removing deleted Tables');
        
        delete from crudo.crud_matrices
        where table_owner = i_schema
        and table_name not in (select table_name from dba_tables where table_owner = i_schema);
        
        set_app_info(l_module, 'DONE');

    exception when others then
        logs.err( lc_proc_name);
        raise;
    end crud_schema;        
end generate_matrices;
/
