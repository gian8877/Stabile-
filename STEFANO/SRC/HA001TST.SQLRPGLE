**free
ctl-opt option(*srcstmt:*nodebugio)  decedit('0,') Datedit(*DMY/) alwnull(*usrctl) DFTACTGRP(*no) ;

dcl-s vallib char(10); //libreria del valore di sistema
dcl-s valpgm char(10); //programma di strup

exec sql SET OPTION COMMIT=*NONE,CLOSQLCSR=*ENDMOD,DATFMT=*ISO,NAMING = *SYS;

exec sql CALL SYSTOOLS.LPRINTF('** Fase 13 - ' ||  char(current_timestamp) || ' Salvataggio QSTRUP' );
exec sql call qsys2.qcmdexc('crtsavf file(HORSAHAOBJ/HASTRUP)');
exec sql    SELECT SUBSTRING(current_character_value, 11, 10) AS libreria,
       SUBSTRING(current_character_value, 1, 10) AS programa
       into :vallib, :valpgm
    FROM qsys2.system_value_info
    WHERE SYSTEM_VALUE_NAME = 'QSTRUPPGM';

exec sql    call qsys2.qcmdexc('SAVOBJ OBJ(' || trim(:valpgm)  ||') LIB(' ||trim(:vallib)|| ') DEV(*SAVF) SAVF(HORSAHAOBJ/HASTRUP)');

*inlr = *on;

