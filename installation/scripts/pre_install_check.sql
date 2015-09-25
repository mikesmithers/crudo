set serveroutput on size unlimited
rem
rem Run this script as the prospective application owner to
rem determine which privileges (if any) are required
rem
declare
    l_dummy pls_integer;
begin
    --
    -- Check the privileges required when executing the installation script.
    -- Because installation does not entail executing packaged procedures, it doesn't
    -- matter if these privileges are granted directly to the user or granted via a role
    --
    for r_reqd_privs in
    (
        with reqd_privs as
        (
            select 'CREATE SESSION' as priv from dual
            union
            select 'CREATE SEQUENCE' as priv from dual
            union
            select 'CREATE TABLE' as priv from dual
            union
            select 'CREATE PROCEDURE' as priv from dual
        )
        select reqd_privs.priv
        from reqd_privs
        minus
        select privilege
        from session_privs
    ) 
    loop
        dbms_output.put_line('Additional Privilege : '||r_reqd_privs.priv||' required');
    end loop;
    --
    -- SELECT ANY DICTIONARY needs to be granted directly as it's required when the application
    -- packages are executed ...
    --
    begin
        select 1
        into l_dummy
        from user_sys_privs
        where privilege = 'SELECT ANY DICTIONARY';
    exception
        when no_data_found then
            dbms_output.put_line('Additional Privilege SELECT ANY DICTIONARY must be granted directly to user');
    end;
    --
    -- Finally, make sure that the user has a quota on their default tablespace...
    --
    begin
        select 1
        into l_dummy
        from user_ts_quotas ts
        inner join user_users usr
            on ts.tablespace_name = usr.default_tablespace;
    exception
        when no_data_found then
            dbms_output.put_line('User requires a quota on the Default Tablespace');
    end;
    dbms_output.put_line('Pre-requisite checks complete.');
end;
/

