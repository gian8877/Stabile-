**free
ctl-opt option(*srcstmt:*nodebugio)  decedit('0,') Datedit(*DMY/) alwnull(*usrctl) DFTACTGRP(*no) ;
dcl-ds log extname('WWE/DBHALOG') qualified alias end-ds  ;

dcl-s adesso timestamp;
dcl-s esito_critical char(1); // ha in stato critico
dcl-s esito_warning  char(1); // ha in stato warning

dcl-s  wkid varchar(100);
dcl-s  wkesito varchar(100);
dcl-s  wkmess varchar(200);


dcl-s  fl_ERRORINODI char(1);
dcl-s  fl_ERRORIDOMINIOAMMINISTRATIVO char(1);
dcl-s  fl_ERRORIRISORSEMONITORATE char(1);
dcl-s  fl_ERRORICRG char(1);
dcl-s  fl_ERRORIRESOUCEGROUP char(1);
dcl-s  fl_ERRORISESSIONI char(1);
dcl-s  fl_ERRORIRISORSENONMONITORATE char(1);
dcl-s  fl_MINUTI_RITARDO char(1);

dcl-pi *n;
  pa_sonda char(10);  // nome della sonda
  pa_esit  char(2);   // esito del controllo (OK/KO)
  pa_mess  char(80);  // descrizione esito controllo
  pa_seve char(1); // severità errore esecuzione (RFC5424) 00-07
  pa_avvi char(1); // avvio immediata reazione (S=si  N=No)
  pa_msid char(10); // message id
END-PI;


exec sql SET OPTION COMMIT=*NONE,CLOSQLCSR=*ENDMOD,DATFMT=*ISO,NAMING = *SYS;

adesso=%timestamp();
pa_sonda = 'SYS021';
exsr recupera_info;   // recupera le informazioni dello stato del power HA
Exsr analisi; // Analizza i risultati




*inlr = *on;

//=====================================================================================================================================================================================
begsr analisi;

  exec sql select * into :log from wwe.dbhalog where ora = :adesso ; // recupera l'ultimo recordscritto...

  // Azzeramento flag di errore
  FL_ERRORINODI                     = '0'; // 001
  FL_ERRORIDOMINIOAMMINISTRATIVO    = '0'; // 002
  FL_ERRORICRG                      = '0'; // 003
  FL_ERRORIRESOUCEGROUP             = '0'; // 004
  FL_ERRORISESSIONI                 = '0'; // 005
  FL_ERRORIRISORSEMONITORATE        = '0'; // 006 W
  FL_ERRORIRISORSENONMONITORATE     = '0'; // 007 W
  FL_MINUTI_RITARDO                 = '0'; // 008 W

  // Controllo nodi CRITICAL ----------------------------------------------------------
  if log.ERRORINODI > 0 ;
    fl_ERRORINODI = '1';
    esito_critical = '1';
  ENDIF;
  // Controllo dominio Amministrativo  ----------------------------------------------------------
  if log.ERRORIDOMINIOAMMINISTRATIVO > 0;
    fl_ERRORIDOMINIOAMMINISTRATIVO = '1';
    esito_critical = '1';
  ENDIF;
  // Controllo CRG Critical  ----------------------------------------------------------
  if log.ERRORICRG > 0;
    fl_ERRORICRG = '1';
    esito_critical = '1';
  ENDIF;
  // Controllo Resource Group Critical  ----------------------------------------------------------
  if log.ERRORIRESOUCEGROUP > 0;
    FL_ERRORIRESOUCEGROUP = '1';
    esito_critical = '1';
  ENDIF;
  // Controllo Sessioni  ----------------------------------------------------------
  if log.ERRORISESSIONI  > 0;
    FL_ERRORISESSIONI  = '1';
    esito_critical = '1';
  ENDIF;
  // Controllo Risorse Monitorate  ----------------------------------------------------------
  if log.ERRORIRISORSEMONITORATE  > 0;
    FL_ERRORIRISORSEMONITORATE   = '1';
    esito_warning = '1';
  ENDIF;
  // Controllo Risorse NON Monitorate  ----------------------------------------------------------
  if log.ERRORIRISORSENONMONITORATE  > 0;
    fl_ERRORIRISORSENONMONITORATE   = '1';
    esito_warning = '1';
  ENDIF;
  // Controllo Ritardo  ----------------------------------------------------------
  if log.MINUTI_RITARDO  > 10;
    fl_MINUTI_RITARDO   = '1';
    esito_warning = '1';
  ENDIF;

  pa_mess = 'Repliche completamente operative';
  pa_esit= 'OK';
  pa_seve = '6';
  pa_avvi ='N';

  if esito_warning = '1';
    pa_mess = 'Repliche attive con avvertimenti.';
    pa_esit= 'KO';
    pa_seve = '4';
    pa_avvi ='C';
  ENDIF;

  if esito_critical = '1';
    pa_mess = 'Repliche NON ATTIVE! ';
    pa_esit= 'KO';
    pa_seve = '3';
    pa_avvi ='C';
  ENDIF;

  if esito_critical ='1' or esito_warning = '1';
    exsr creadettaglio;
  ENDIF;


ENDSR;

//=====================================================================================================================================================================================
begsr recupera_info;

  exec sql
  insert into wwe.dbhalog (select :adesso as ora,
  (select COUNT(*) AS ERnodi          FROM QHASM.CLUSTER_NODES   WHERE NODE_STATUS != 'ACTIVE') as ErroriNodi,
  (select COUNT(*) AS ERDominio    FROM QHASM.ADMIN_DOMAIN_LIST   WHERE DOMAIN_STATUS != 'ACTIVE') as ErroriDominioAmministrativo,
  (select  COUNT(*) AS Errismon      FROM TABLE(QHASM.ADMIN_DOMAIN_MRE_LIST()) LIST
           WHERE LIST.GLOBAL_STATUS = '*INCONSISTENT' OR LIST.GLOBAL_STATUS = '*FAILED') as ErroriRisorseMonitorate,
  (select  COUNT(*) AS ERCrg          FROM QHASM.CLUSTER_RESOURCE_GROUP_LIST  WHERE CRG_STATUS != 'ACTIVE') as ErroriCrg,
  (select  COUNT(*) AS ERRecDom   FROM QHASM.CLUSTER_RESOURCE_GROUP_LIST LIST, TABLE(QHASM.CRG_RECOVERY_DOMAIN(LIST.CLUSTER_RESOURCE_GROUP))
           RCYDMN WHERE NODE_STATUS != 'ACTIVE') as ErroriResouceGroup,
  (select COUNT(*) AS ErSess          FROM QHASM.SESSION_LIST SESSION_LIST,TABLE(QHASM.SESSION_INFO(SESSION => SESSION_LIST.SESSION_NAME))
           SESSION_INFO WHERE SESSION_INFO.COPY_STATUS != 'ACTIVE') as ErroriSessioni,
  (select COUNT(*) AS ERRORS  FROM
  (SELECT JOBD.OBJNAME AS "Unmonitored Resource", '*JOBD' as "Resource Type", JOBD.OBJLONGSCHEMA as "Resource Library"
      FROM TABLE(QSYS2.OBJECT_STATISTICS('*ALL','*JOBD','*ALLSIMPLE')) JOBD
      WHERE jobd.objname not like 'Q%' and JOBD.OBJLONGSCHEMA != 'QSYS' AND JOBD.OBJLONGSCHEMA != 'QINSYS' AND JOBD.OBJLONGSCHEMA != 'QINPRIOR'
          AND JOBD.OBJLONGSCHEMA != 'QINMEDIA' AND
          NOT EXISTS (
          SELECT MONITORED_RESOURCE
          FROM TABLE(QHASM.ADMIN_DOMAIN_MRE_LIST(RESOURCE_TYPE => '*JOBD')) MRE
          WHERE MRE.MONITORED_RESOURCE = JOBD.OBJNAME)
  UNION
  SELECT SBSD.OBJNAME AS "Unmonitored Resource", '*SBSD' as "Resource Type", SBSD.OBJLONGSCHEMA as "Resource Library"
      FROM TABLE(QSYS2.OBJECT_STATISTICS('*ALL','*SBSD','*ALLSIMPLE')) SBSD
      WHERE sbsd.objname not like 'Q%' and SBSD.OBJLONGSCHEMA != 'QSYS' AND SBSD.OBJLONGSCHEMA != 'QINSYS'
          AND SBSD.OBJLONGSCHEMA != 'QINPRIOR' AND SBSD.OBJLONGSCHEMA != 'QINMEDIA' AND
          NOT EXISTS (
          SELECT MONITORED_RESOURCE
          FROM TABLE(QHASM.ADMIN_DOMAIN_MRE_LIST(RESOURCE_TYPE => '*SBSD')) MRE
          WHERE MRE.MONITORED_RESOURCE = SBSD.OBJNAME)
  UNION
  SELECT USRPRF.OBJNAME AS "Unmonitored Resource", '*USRPRF' as "Resource Type", USRPRF.OBJLONGSCHEMA as "Resource Library"
      FROM TABLE(QSYS2.OBJECT_STATISTICS('QSYS','*USRPRF','*ALLSIMPLE')) USRPRF
      WHERE usrprf.objname not like 'Q%' and  NOT EXISTS (
          SELECT MONITORED_RESOURCE
          FROM TABLE(QHASM.ADMIN_DOMAIN_MRE_LIST(RESOURCE_TYPE => '*USRPRF')) MRE
          WHERE MRE.MONITORED_RESOURCE = USRPRF.OBJNAME)
  UNION
  SELECT AUTL.OBJNAME AS "Unmonitored Resource", '*AUTL' as "Resource Type", AUTL.OBJLONGSCHEMA as "Resource Library"
      FROM TABLE(QSYS2.OBJECT_STATISTICS('QSYS','*AUTL','*ALLSIMPLE')) AUTL
      WHERE autl.objname not like 'Q%' and NOT EXISTS (
          SELECT MONITORED_RESOURCE
          FROM TABLE(QHASM.ADMIN_DOMAIN_MRE_LIST(RESOURCE_TYPE => '*AUTL')) MRE
          WHERE MRE.MONITORED_RESOURCE = AUTL.OBJNAME)
  UNION
  SELECT CLS.OBJNAME AS "Unmonitored Resource", '*CLS' as "Resource Type", CLS.OBJLONGSCHEMA as "Resource Library"
      FROM TABLE(QSYS2.OBJECT_STATISTICS('*ALL','*CLS','*ALLSIMPLE')) CLS
      WHERE cls.objname not like 'Q%' and  CLS.OBJLONGSCHEMA != 'QSYS' AND CLS.OBJLONGSCHEMA != 'QINSYS'
          AND CLS.OBJLONGSCHEMA != 'QINPRIOR' AND CLS.OBJLONGSCHEMA != 'QINMEDIA' AND
          NOT EXISTS (
          SELECT MONITORED_RESOURCE
          FROM TABLE(QHASM.ADMIN_DOMAIN_MRE_LIST(RESOURCE_TYPE => '*CLS')) MRE
          WHERE MRE.MONITORED_RESOURCE = CLS.OBJNAME))) as ErroriRisorseNonMonitorate,
   coalesce(TO_CHAR(TIMESTAMPDIFF( 4, CHAR(current_timestamp - SSN.FREEZE_TIME)), '999G999G999G999'), 0)  AS Minuti_ritardo,
                  coalesce(SSN.FREEZE_TIME,current_timestamp) as freeze_time, SSN.ASP_DEVICE, SSN.SOURCE_ASP_STATE, SSN.SOURCE_COPY_DESCRIPTION,
                  SSN.TARGET_ASP_STATE, SSN.TARGET_COPY_DESCRIPTION, SSN.COPY_STATUS, SSN.COPY_PROGRESS, SSN.STORAGE_STATE, SSN.DEVICE_DOMAIN
                  FROM TABLE(QHASM.SESSION_INFO(SESSION => (SELECT SESSION_NAME FROM QHASM.SESSION_LIST where SWITCHOVER_REVERSE_REPLICATE = '*YES' limit 1 ))) ssn );

ENDSR;



//=====================================================================================================================================================================================
begsr Creadettaglio;
  exec sql drop table qtemp.dbwork;
  exec sql create or replace table qtemp.dbwork ( item varchar(100), esito varchar(100),  descrizione varchar(200) ) on replace delete rows;

//================================================================================================== Nodi
 if FL_ERRORINODI = '1'; // errore dei nodi
   wkid    = '<b><font color="red">001</b>';
   wkesito = '<b><font color="red">KO</b>';
   wkmess =  '<b><font color="red">I nodi del cluster NON sono operativi</b>';
else;
   wkid    = '<b><font color="00c400">100</b>';
   wkesito = '<b><font color="00c400">OK</b>';
   wkmess =  '<b><font color="00c400">Nodi Operativi</b>';
 ENDIF;
  exec sql insert into qtemp.dbwork values(:wkid,:wkesito,:wkmess) ;
//================================================================================================== Dominio Amministrativo
 if  fl_ERRORIDOMINIOAMMINISTRATIVO = '1'; // Dominio Amministrativo
   wkid    = '<b><font color="red">002</b>';
   wkesito = '<b><font color="red">KO</b>';
   wkmess =  '<b><font color="red">Presenti errori nel dominio amministratico</b>';
else;
   wkid    = '<b><font color="00c400">002</b>';
   wkesito = '<b><font color="00c400">OK</b>';
   wkmess =  '<b><font color="00c400">Dominio Amministrativo funzionante.</b>';
 ENDIF;
  exec sql insert into qtemp.dbwork values(:wkid,:wkesito,:wkmess) ;
  //==================================================================================================  Cluster Resources Group
 if   FL_ERRORICRG = '1'; // Cluster Resources Group
   wkid    = '<b><font color="red">003</b>';
   wkesito = '<b><font color="red">KO</b>';
   wkmess =  '<b><font color="red">Presenti errori nel  Cluster Resources Group</b>';
else;
   wkid    = '<b><font color="00c400">003</b>';
   wkesito = '<b><font color="00c400">OK</b>';
   wkmess =  '<b><font color="00c400">Cluster Resources Group Funzionante</b>';
 ENDIF;
  exec sql insert into qtemp.dbwork values(:wkid,:wkesito,:wkmess) ;
//==================================================================================================  Resource Group
 if   FL_ERRORIRESOUCEGROUP = '1'; // Resource Group
   wkid    = '<b><font color="red">004</b>';
   wkesito = '<b><font color="red">KO</b>';
   wkmess =  '<b><font color="red">Presenti errori nel Resource Group</b>';
else;
   wkid    = '<b><font color="00c400">004</b>';
   wkesito = '<b><font color="00c400">OK</b>';
   wkmess =  '<b><font color="00c400">Resource Group funzionante.</b>';
 ENDIF;
  exec sql insert into qtemp.dbwork values(:wkid,:wkesito,:wkmess) ;
//==================================================================================================  Controllo sessioni
 if   FL_ERRORISESSIONI = '1'; // Controllo sessioni
   wkid    = '<b><font color="red">005</b>';
   wkesito = '<b><font color="red">KO</b>';
   wkmess =  '<b><font color="red">Presenti errori nelle Sessioni</b>';
else;
   wkid    = '<b><font color="00c400">005</b>';
   wkesito = '<b><font color="00c400">OK</b>';
   wkmess =  '<b><font color="00c400">Sessioni completamente operative</b>';
 ENDIF;
  exec sql insert into qtemp.dbwork values(:wkid,:wkesito,:wkmess) ;
 //==================================================================================================  Risorse Monitorate
 if   FL_ERRORIRISORSEMONITORATE = '1'; // Risorse Monitorate
   wkid    = '<b><font color="d9a806">006</b>';
   wkesito = '<b><font color="d9a806">KO</b>';
   wkmess =  '<b><font color="d9a806">Presenti errori nelle Risorse Monitorate </b>';
else;
   wkid    = '<b><font color="00c400">006</b>';
   wkesito = '<b><font color="00c400">OK</b>';
   wkmess =  '<b><font color="00c400">Risorse monitorate completamente operative</b>';
 ENDIF;
  exec sql insert into qtemp.dbwork values(:wkid,:wkesito,:wkmess) ;
 //==================================================================================================  Risorse Non Monitorate
 if   FL_ERRORIRISORSENONMONITORATE = '1'; // Risorse Non Monitorate
   wkid    = '<b><font color="d9a806">007</b>';
   wkesito = '<b><font color="d9a806">KO</b>';
   wkmess =  '<b><font color="d9a806">Presenti risorse non monitorate </b>';
else;
   wkid    = '<b><font color="00c400">007</b>';
   wkesito = '<b><font color="00c400">OK</b>';
   wkmess =  '<b><font color="00c400">Tutte le risorse sono monitorate</b>';
 ENDIF;
  exec sql insert into qtemp.dbwork values(:wkid,:wkesito,:wkmess) ;
   //==================================================================================================  Ritardo delle repliche
 if   FL_MINUTI_RITARDO = '1'; // Ritardo delle repliche
   wkid    = '<b><font color="d9a806">008</b>';
   wkesito = '<b><font color="d9a806">KO</b>';
   wkmess =  '<b><font color="d9a806">Superato il limite dei ritardi delle repliche</b>';
else;
   wkid    = '<b><font color="00c400">008</b>';
   wkesito = '<b><font color="00c400">OK</b>';
   wkmess =  '<b><font color="00c400">Ritardo delle repliche entro i limiti</b>';
 ENDIF;
  exec sql insert into qtemp.dbwork values(:wkid,:wkesito,:wkmess) ;


ENDSR;
