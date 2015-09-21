create or replace package body logs 
as

    --
    -- Private
    --
    procedure save_log
    (
        i_name in application_logs.package_name%type,
        i_line in application_logs.location%type,
        i_message in application_logs.message%type,
        i_message_type in application_logs.message_type%type,
        i_member in application_logs.member_name%type
    )
    is
    --
    -- Called from the WRITE and ERR procedures. Here we get the remaining required information
    -- and then insert the message into the logs
    -- Use an autonomous transaction to prevent interference with the
    -- calling transaction.
    
        pragma autonomous_transaction;
    begin
        
        insert into application_logs
        (
            username, log_ts,
            package_name, member_name, location,
            message_type, message
        )
        values
        (
            user, systimestamp,
            i_name, i_member, i_line,
            i_message_type, i_message
        );
        commit;
    exception when others then
        rollback;
        -- NOTE - an error writing to the log table is non-fatal in this application.
        -- therefore the lack of a RAISE here is deliberate.
    end save_log;
    
    --
    -- Public
    --
    
    procedure write
    ( 
        i_member in application_logs.member_name%type, 
        i_message in application_logs.message%type, 
        i_log_level in varchar2 default 'I'
    )
    is
    --
    -- Logging procedure for the application.
    -- Determine whether the message should be recorded based on the current
    -- debug level in the session ( GENERATE_MATRICES.G_DEBUG_LEVEL).
    -- 
        l_message_level pls_integer;
        l_log_level pls_integer;
        
        -- owa_util out parameter variables
        l_owner user_users.username%type;
        l_name user_objects.object_name%type;
        l_line user_source.line%type;
        l_type user_objects.object_type%type;
        
        
        l_dummy pls_integer := 0;
    begin
        --
        -- Work out if we need to record a message of this level.
        -- Simplest way to do this is to convert the incoming message level and
        -- the current debug level to integers and compare them...
        -- NOTE - E(rror) level messages are logged via the err procedure in this package
         
        l_message_level := case i_log_level when 'I' then 2 else 3 end;
        l_log_level := case g_log_level when 'ERROR' then 1 when 'INFO' then 2 else 3 end;
        if l_message_level > l_log_level then
            -- nothing to do
            return;
        end if;

        -- Get the details of the caller
        -- NOTE - this call must be in-line as invoking it in another
        -- package member would simply return details of this procedure.
        --
        
        owa_util.who_called_me
        (
            owner => l_owner,
            name => l_name,
            lineno => l_line,
            caller_t => l_type
        );

        -- and log the message...
        
        save_log
        (
            i_name => l_name,
            i_line => l_line,
            i_message => i_message,
            i_message_type => i_log_level,
            i_member => i_member
        );
    end write;

    procedure err( i_member application_logs.member_name%type)
    is
    --
    -- Get the current error stack log it
    --
    
        -- owa_util out parameter variables
        l_owner user_users.username%type;
        l_name user_objects.object_name%type;
        l_line user_source.line%type;
        l_type user_objects.object_type%type;

        l_message application_logs.message%type;
    begin
    
        l_message := sqlerrm||' '||dbms_utility.format_error_backtrace;

        -- See comment on call to OWA_UTIL in the WRITE procedure
        
        owa_util.who_called_me
        (
            owner => l_owner,
            name => l_name,
            lineno => l_line,
            caller_t => l_type
        );
        
        save_log
        (
            i_name => l_name,
            i_line => l_line,
            i_message => l_message,
            i_message_type => 'E',
            i_member => i_member
        );
    end err;        
end logs;
/
