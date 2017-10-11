database sysmaster;
execute procedure ifx_grid_connect('grid1', 'dbaccessdemo', 1);
create database stores with log;
CREATE PROCEDURE informix.sysdbopen() 
execute procedure ifx_grid_connect('grid1', 'dbaccessdemo', 3); 
END PROCEDURE;
