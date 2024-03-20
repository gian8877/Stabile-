**free
ctl-opt option(*srcstmt:*nodebugio)  decedit('0,') Datedit(*DMY/) alwnull(*usrctl) DFTACTGRP(*no) ;

dcl-pr QCMDEXC extpgm ('QCMDEXC');
  comando char(4000) options(*varsize) const ;
  luncmd packed(15:5) const ;
end-pr ;

dcl-s comando char(4000);
dcl-s isql char(3800);
dcl-s a    char(1) inz(x'7d');
dcl-s rec int(5);

exec sql SET OPTION COMMIT=*NONE,CLOSQLCSR=*ENDMOD,DATFMT=*ISO,NAMING = *SYS;

 isql = 'SELECT * FROM qtemp.dbdata';

  exec sql drop table qtemp.dummy;

  comando=*blanks;  // reindirizzo l'output dello schermo
  comando='crtpf  qtemp/dummy rcdlen(300)';
  callp(e) QCMDEXC(Comando:%len(%trimr(comando))) ;


  comando=*blanks;  // reindirizzo l'output dello schermo
  comando='ovrdbf stdout qtemp/dummy ovrscope(*job) ';
  callp(e) QCMDEXC(Comando:%len(%trimr(comando))) ;

  comando=*blanks;  // seleziono tutto il file per avere un output flat (con i capi decimali formattati)
  comando='strqsh cmd('+a+'DB2 " '+ %trim(isql) +'"'+a+')';
  callp(e) QCMDEXC(Comando:%len(%trimr(comando))) ;

  comando=*blanks;  // cancello le override
  comando='dltovr *all';
  callp(e) QCMDEXC(Comando:%len(%trimr(comando))) ;

  exec sql select count(*) into :rec from qtemp.dummy;

  exec sql delete qtemp.dummy a  where rrn(a) = 1;
  exec sql delete qtemp.dummy a  where rrn(a) = :rec - 1;
  exec sql delete qtemp.dummy a  where rrn(a) = :rec - 2;
  exec sql delete qtemp.dummy a  where rrn(a) = :rec - 3;



  *inlr =*on;

