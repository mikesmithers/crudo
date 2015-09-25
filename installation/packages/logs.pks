create or replace package logs as
    
    ----------------------
    -- Package Variable --
    ----------------------
        
    g_log_level varchar2(5) := 'ERROR';

    ---------------------
    -- Package Members --
    ---------------------

    -- Write a message to the APPLICATION_LOGS table
    procedure write
    ( 
        i_member in application_logs.member_name%type, 
        i_message in application_logs.message%type, 
        i_log_level in varchar2 default 'I'
    );
    
    -- Write an ERROR message to the APPLICATION_LOGS table
    procedure err( i_member application_logs.member_name%type);

end logs;
/
