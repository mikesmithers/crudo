create or replace package logs as
--
-- Logging package for the CRUDO application
--

    --
    -- G_LOG_LEVEL - package variable to determine the level at which application
    -- messages are logged in the current session.
    -- There are three levels :
    -- ERROR - (level 1) - only log error messages
    -- INFO - (2) - Log error and Information messages
    -- DEBUG - (3) - log all messages
    
    g_log_level varchar2(5) := 'ERROR';
    --
    -- Write a message to the APPLICATION_LOGS table
    --
    procedure write
    ( 
        i_member in application_logs.member_name%type, 
        i_message in application_logs.message%type, 
        i_log_level in varchar2 default 'I'
    );
    
    --
    -- Write an error message to the APPLICATION_LOGS table
    --
    procedure err( i_member application_logs.member_name%type);
end logs;
/
