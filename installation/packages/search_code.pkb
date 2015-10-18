create or replace package body search_code
as

    -----------------------------
    -- PRIVATE package members --
    -----------------------------
    
    procedure check_trigger_event
    (
        i_trigger_name in dba_triggers.trigger_name%type,
        i_table_owner in dba_triggers.table_owner%type,
        i_table_name in dba_triggers.table_name%type,
        o_create out crud_matrices.create_flag%type,
        o_read out crud_matrices.read_flag%type,
        o_update out crud_matrices.update_flag%type,
        o_delete out crud_matrices.delete_flag%type,
        o_event out boolean
    )
    is
    --
    -- If i_trigger_name is a trigger on i_table_owner.i_table_name then 
    -- output the appropriate CRUD settings to the out parameters.
    -- Otherwise, set all out parameters to 'N'
    --
        lc_proc_name constant application_logs.member_name%type := 'CHECK_TRIGGER_EVENT';

        l_read_flag crud_matrices.read_flag%type;
        l_create_flag crud_matrices.create_flag%type;
        l_update_flag crud_matrices.update_flag%type;
        l_delete_flag crud_matrices.delete_flag%type;
        
    begin
        logs.write(lc_proc_name, 'Parameters : i_trigger_name => '||i_trigger_name
            ||', i_table_owner => '||i_table_owner||', i_table_name => '||i_table_name, 'D');
        
        -- Assume that a DML trigger on the table is NOT doing a read on that table
        select 'N' as read_flag, 
            case instr(triggering_event, 'INSERT') when 0 then 'N' else 'Y' end as create_flag,
            case instr(triggering_event, 'UPDATE') when 0 then 'N' else 'Y' end as update_flag,
            case instr(triggering_event, 'DELETE') when 0 then 'N' else 'Y' end as delete_flag
        into l_read_flag, l_create_flag, l_update_flag, l_delete_flag
        from dba_triggers
        where trigger_name = i_trigger_name
        and table_owner = i_table_owner
        and table_name = i_table_name;

        if l_create_flag = 'N' and l_update_flag = 'N' and l_delete_flag = 'N'
        then
            o_event := false;
            return;
        end if;
        o_read := l_read_flag;
        o_create := l_create_flag;
        o_update := l_update_flag;
        o_delete := l_delete_flag;
        o_event := true;
    
    exception
        when no_data_found then
            -- Trigger is not on this table
            o_create := 'N';
            o_read := 'N';
            o_update := 'N';
            o_delete := 'N';
            o_event := false;
    end check_trigger_event;

    function get_source
    (
        i_owner dba_source.owner%type,
        i_name dba_source.name%type,
        i_type dba_source.type%type
    )
        return clob
    is
    --
    -- Retrieve the source for this object from the data dictionary.
    -- Using DBA_SOURCE rather than DBMS_METADATA because the former is less susceptible to
    -- unexpected complication arising from the role based nature of DBMS_METADATA security.
    -- Also, in testing, this method was a bit quicker.
    --
        lc_proc_name constant application_logs.member_name%type := 'GET_SOURCE';
        l_source clob;
    begin
        logs.write( lc_proc_name, 'Parameters : i_owner => '||i_owner||', i_name =>'||i_name
            ||', i_type => '||i_type, 'D');    
        for r_text in
        (
            select text
            from dba_source
            where owner = i_owner
            and name = i_name
            and type = i_type
            order by line
        )
        loop
            l_source := l_source||r_text.text;
        end loop;
        return l_source;
    end get_source;

    function is_wrapped
    (
        i_owner all_source.owner%type, 
        i_type all_source.type%type, 
        i_name all_source.name%type
    )
        return boolean
    is
    --
    -- Check to see if this object is wrapped in the data dictionary.
    --
        l_wrapped varchar2(1);
        
    begin
        select case when instr(text, lower(type||' '||name||' wrapped')) > 0 then 'Y' else 'N' end
        into l_wrapped
        from dba_source
        where owner = upper(i_owner)
        and name = upper(i_name)
        and type = upper(i_type)
        and line = 1;

        -- Below statement evaluates to TRUE if l_wrapped = 'Y' or FALSE if it isn't.        
        return l_wrapped = 'Y';
    end is_wrapped;

    procedure find_dml
    (
        i_source in clob,
        i_table in user_tables.table_name%type,
        o_create out crud_matrices.create_flag%type,
        o_read out crud_matrices.read_flag%type,
        o_update out crud_matrices.update_flag%type,
        o_delete out crud_matrices.delete_flag%type
    )
    is
    --
    -- Parse the code in i_source to find DML statements against i_table
    -- 
        lc_proc_name constant application_logs.member_name%type := 'FIND_DML';
        l_source clob;
    
    begin
        logs.write( lc_proc_name, 'Parameters : i_table => '||i_table, 'D');
        
        -- Initialize the OUT parameters
        o_create := 'N';
        o_read := 'N';
        o_update := 'N';
        o_delete := 'N';
        
        -- Find INSERT statements. To filter out INSERT/SELECT statements we need
        -- to retain the word boundaries at the moment so do this check
        -- before stripping spaces...
        
        if regexp_instr
        (
            i_source,
            'INSERT[^;][^\SELECT\]*INTO[^;_]*'||i_table||'[^_]',1,1,0,'i'
        ) > 0
        then
            logs.write( lc_proc_name, 'Found INSERT statement on '||i_table, 'D');
            o_create := 'Y';
        end if;

        -- strip all the spaces.
        l_source := replace(i_source,' ');
  
        -- Search for MERGE statements
        if regexp_instr
        ( 
            l_source,
            'MERGE[^;]*INTO[^;_]*'||i_table||'[^_]',1,1,0,'i'
        ) > 0
        then
            logs.write( lc_proc_name, 'Found MERGE statement on '||i_table, 'D');
            o_create := 'Y';
            o_update := 'Y';
        end if;

        -- Search for SELECT statements
        if regexp_instr
        ( 
            l_source, 
            'SELECT[^;]*[FROM JOIN][^;_]*'||i_table||'[^_]',1,1,0,'i'
        ) > 0
        then
            logs.write( lc_proc_name, 'Found SELECT statement on '||i_table, 'D');
            o_read := 'Y';
        end if;
        
        -- Search for UPDATE statements unless we've already found a MERGE statement
        if o_update = 'N' then
            if regexp_instr
            (
                l_source,
                'UPDATE[^;_]*'||i_table||'[^_]',1,1,0,'i'
            ) > 0
            then
                logs.write( lc_proc_name, 'Found UPDATE statement on '||i_table, 'D');
                o_update := 'Y';
            end if;
        end if;
        
        -- Search for DELETE statements
        if regexp_instr
        (
            l_source,
            'DELETE[^;_]*'||i_table||'[^_]',1,1,0,'i'
        ) > 0
        then
            logs.write( lc_proc_name, 'Found DELETE statement on '||i_table, 'D');
            o_delete := 'Y';
        end if;
    end find_dml;
    
    ------------------------------------------------------
    --                                                  --
    -- PUBLIC package members                           --
    -- See package header for general comments on each. --
    --                                                  --
    ------------------------------------------------------

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
    )
    is

        lc_proc_name constant application_logs.member_name%type := 'TABLE_OBJECT_CRUD';

        l_create_flag crud_matrices.create_flag%type := 'N';
        l_read_flag crud_matrices.read_flag%type := 'N';
        l_update_flag crud_matrices.update_flag%type := 'N';
        l_delete_flag crud_matrices.delete_flag%type := 'N';
        l_event boolean;
        
        l_source clob;
    begin
        logs.write( lc_proc_name, 'Parameters : '
            ||'i_table_owner => '||i_table_owner||', '
            ||'i_table_name => '||i_table_name||', '
            ||'i_object_owner => '||i_object_owner||', '
            ||'i_object_name => '||i_object_name||', '
            ||'i_object_type => '||i_object_type,
            'D');

        if i_object_type = 'TRIGGER' then
            -- If this is a trigger ON the table (as opposed to one that references it in it's body)
            -- then skip any code search and base the crud off it's triggering event
            check_trigger_event
            (
                i_trigger_name => i_object_name,
                i_table_owner => i_table_owner,
                i_table_name => i_table_name,
                o_create => l_create_flag,
                o_read => l_read_flag,
                o_update => l_update_flag,
                o_delete => l_delete_flag,
                o_event => l_event
            );
    
            if l_event then
            
                -- CRUD is done, set the out parameters and stop
                logs.write( lc_proc_name, 'CRUD based on triggering event', 'D');
                o_create := l_create_flag;
                o_read := l_read_flag;
                o_update := l_update_flag;
                o_delete := l_delete_flag;
                return;
            end if;

        elsif i_object_type in ('VIEW', 'MATERIALIZED VIEW') then

            -- Assume that this is a read.
            -- Set the out parameters and then stop processing
            logs.write( lc_proc_name, 'CRUD based on object type', 'D');
            o_create := 'N';
            o_read := 'Y';
            o_update := 'N';
            o_delete := 'N';
            return;
        end if;

        -- If we're still here then the object is something other than a view or a DML trigger on the table itself.
        -- Make sure that the code is not wrapped. 
        -- If it is then we can't read it to build the CRUD Matrix...
        --
        if is_wrapped( i_owner => i_object_owner, i_name => i_object_name, i_type => i_object_type)
        then
            raise_application_error( -20011, 'Source Code is Wrapped. Unable to generate matrix');
        end if;
        
        l_source :=  get_source( i_owner => i_object_owner, i_name => i_object_name, i_type => i_object_type);
        
        -- Strip both single-line and multi-line comments from the source code
        l_source := regexp_replace( regexp_replace( l_source, '--[[:print:]]*.'), '/\*([^*]|[\r\n]|(\*+([^*/])))*\*+/');

        find_dml
        (
            i_source => l_source,
            i_table => i_table_name,
            o_create => l_create_flag,
            o_read => l_read_flag,
            o_update => l_update_flag,
            o_delete => l_delete_flag
        );
        o_create := l_create_flag;
        o_read := l_read_flag;
        o_update := l_update_flag;
        o_delete := l_delete_flag;
    end table_object_crud;   
end search_code;
/
