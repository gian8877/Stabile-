**free
ctl-opt option(*srcstmt:*nodebugio)  decedit('0,') Datedit(*DMY/) alwnull(*usrctl) DFTACTGRP(*no) ;

dcl-f pg077v  workstn extfile('PG077V')  Maxdev(*file);

dcl-pr pg076 extpgm('PG076') end-pr;

dcl-s id char(3);
dcl-s item char(50);
dcl-s error int(5);

dcl-s y char(1);
dcl-s r char(1);


exec sql SET OPTION COMMIT=*NONE,CLOSQLCSR=*ENDMOD,DATFMT=*ISO,NAMING = *SYS;


 dow 1=1;

  exsr getdata;


    write w01 ;
    read(e) PG077v ;
    IF *IN03 = *ON;
      leave;
    Endif;


ENDDO;



  *inlr = *on;


//=================================================================================================
begsr getdata;
//=================================================================================================

callp(e) pg076();

exsr getinfo; // Acquisisce informazioni da power ha

*in21 = *off;
*in22 = *off;
*in23 = *off;
*in24 = *off;
*in25 = *off;
*in26 = *off;
*in27 = *off;
y='0';
r='0';

exec sql declare lista cursor for select * from qtemp.dbpowerha;

exec sql open lista;

dow 1=1;
  exec sql fetch lista into :id, :item, :error;
  if sqlcode <> 0;
    leave;
  Endif;

select;
  when id = '001' and error > 0 ;
    *in21 = *on;
    r='1';
  when id = '002' and error > 0 ;
    *in22 = *on;
    r='1';
  when id = '003' and error > 0 ;
    *in23 = *on;
    y='1';
  when id = '004' and error > 0 ;
    *in24 = *on;
    y='1';
  when id = '005' and error > 0 ;
    *in25 = *on;
    r='1';
  when id = '006' and error > 0 ;
    *in26 = *on;
    r='1';
  when id = '007' and error > 0 ;
    *in27 = *on;
    r='1';
Endsl;


select;
   when id = '001';
     n1=error;
   when id = '002';
     n2=error;
   when id = '003';
     n3=error;
   when id = '004';
     n4=error;
   when id = '005';
     n5=error;
   when id = '006';
     n6=error;
   when id = '007';
     n7=error;
Endsl;

Enddo;

exec sql close lista;

if y='1';
  *in91 = *on;
  *in92 = *off;
Endif;

if r='1';
  *in91 = *off;
  *in92 = *on;
Endif;

endsr;

begsr getinfo;

exec sql
SELECT
(select primary_node  from QHASM.CLUSTER_RESOURCE_GROUP_LIST) as NodoPrimario,
coalesce(TO_CHAR(TIMESTAMPDIFF( 4, CHAR(current_timestamp - SSN.FREEZE_TIME)),'999G999G999G999'), 0)  AS Minuti_ritardo,
        coalesce(char(SSN.FREEZE_TIME), ' ')  as freeze ,
           SSN.COPY_STATUS,
       SSN.COPY_PROGRESS,
       SSN.STORAGE_STATE into :nodo, :minuti, :data, :stato,  :PROG,  :STATOCOP
    FROM TABLE (
            QHASM.SESSION_INFO(SESSION => (SELECT  SESSION_NAME   FROM QHASM.SESSION_LIST limit 1))
        ) SSN;




Endsr;
