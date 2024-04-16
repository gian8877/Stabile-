**free
ctl-opt option(*srcstmt:*nodebugio)  decedit('0,') Datedit(*DMY/) alwnull(*usrctl) DFTACTGRP(*no) ;

 dcl-pr  QMHSNDPM     extpgm('QMHSNDPM');
   MsgID              char(7)      const;
   MsgFile            char(20)     const;
   MsgDta             char(32767)  const   options(*varsize);
   MsgDtaLen          int(10)      const;
   MsgType            char(10)     const;
   MsgQ               char(10)     const;
   MsgQNbr            int(10)      const;
   MsgKey             char(4);
   ErrorDs            char(200);
end-pr;
dcl-s   MsgKey             char(4);
dcl-s   ErrorDs            char(200);
dcl-s   testo char(100);


exec sql SET OPTION COMMIT=*NONE,CLOSQLCSR=*ENDMOD,DATFMT=*ISO,NAMING = *SYS;

testo= '... Verifica funzionalità Power HA in esecuzione!';
 QMHSNDPM ('CPA2401': 'QCPFMSG   *LIBL': testo: %size(testo): '*STATUS': '*EXT': 1: MsgKey: ErrorDS ) ;

// Nodi in errore
exec sql create or replace table qtemp.dbpowerha as(
SELECT '001' as id, 'Nodi                                                     ' as item,
  COUNT(*) AS ERRORS  FROM QHASM.CLUSTER_NODES   WHERE NODE_STATUS != 'ACTIVE') with data on replace delete rows;
// Dominio amministrativo in errore
exec sql insert into qtemp.dbpowerha
SELECT '002' as id, 'Dominio Amministrativo' as item, COUNT(*) AS ERRORS    FROM QHASM.ADMIN_DOMAIN_LIST   WHERE DOMAIN_STATUS != 'ACTIVE';
// Monitored resource in errore
exec sql  insert into qtemp.dbpowerha
SELECT '003' as id, 'Risorse monitorate ' as item, COUNT(*) AS ERRORS
     FROM TABLE(QHASM.ADMIN_DOMAIN_MRE_LIST()) LIST   WHERE LIST.GLOBAL_STATUS = '*INCONSISTENT' OR LIST.GLOBAL_STATUS = '*FAILED';
// Risorse Non monitorate
exec sql insert into qtemp.dbpowerha
SELECT '004' as id, 'Risorse Non Monitorate' as item, COUNT(*) AS ERRORS  FROM
(SELECT JOBD.OBJNAME AS "Unmonitored Resource", '*JOBD' as "Resource Type", JOBD.OBJLONGSCHEMA as "Resource Library"
    FROM TABLE(QSYS2.OBJECT_STATISTICS('*ALL','*JOBD','*ALLSIMPLE')) JOBD
    WHERE jobd.objname not like 'Q%' and JOBD.OBJLONGSCHEMA != 'QSYS' AND JOBD.OBJLONGSCHEMA != 'QINSYS' AND JOBD.OBJLONGSCHEMA != 'QINPRIOR' AND JOBD.OBJLONGSCHEMA != 'QINMEDIA' AND
        NOT EXISTS (
        SELECT MONITORED_RESOURCE
        FROM TABLE(QHASM.ADMIN_DOMAIN_MRE_LIST(RESOURCE_TYPE => '*JOBD')) MRE
        WHERE MRE.MONITORED_RESOURCE = JOBD.OBJNAME)
UNION
SELECT SBSD.OBJNAME AS "Unmonitored Resource", '*SBSD' as "Resource Type", SBSD.OBJLONGSCHEMA as "Resource Library"
    FROM TABLE(QSYS2.OBJECT_STATISTICS('*ALL','*SBSD','*ALLSIMPLE')) SBSD
    WHERE sbsd.objname not like 'Q%' and SBSD.OBJLONGSCHEMA != 'QSYS' AND SBSD.OBJLONGSCHEMA != 'QINSYS' AND SBSD.OBJLONGSCHEMA != 'QINPRIOR' AND SBSD.OBJLONGSCHEMA != 'QINMEDIA' AND
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
    WHERE cls.objname not like 'Q%' and  CLS.OBJLONGSCHEMA != 'QSYS' AND CLS.OBJLONGSCHEMA != 'QINSYS' AND CLS.OBJLONGSCHEMA != 'QINPRIOR' AND CLS.OBJLONGSCHEMA != 'QINMEDIA' AND
        NOT EXISTS (
        SELECT MONITORED_RESOURCE
        FROM TABLE(QHASM.ADMIN_DOMAIN_MRE_LIST(RESOURCE_TYPE => '*CLS')) MRE
        WHERE MRE.MONITORED_RESOURCE = CLS.OBJNAME));
// Cluster resource Group
exec sql  insert into qtemp.dbpowerha
SELECT '005' as id, 'Cluster Resources Group in errore' as item, COUNT(*) AS ERRORS
  FROM QHASM.CLUSTER_RESOURCE_GROUP_LIST
  WHERE CRG_STATUS != 'ACTIVE';
// Recovery domain in errore
exec sql   insert into qtemp.dbpowerha
  SELECT '006' as id, 'Recovery domain  ' as item , COUNT(*) AS ERRORS
  FROM QHASM.CLUSTER_RESOURCE_GROUP_LIST LIST,
       TABLE(QHASM.CRG_RECOVERY_DOMAIN(LIST.CLUSTER_RESOURCE_GROUP)) RCYDMN
  WHERE NODE_STATUS != 'ACTIVE';

//  Sessioni in errore
exec sql   insert into qtemp.dbpowerha
  SELECT '007' as id, 'Sessioni  ' as item, COUNT(*) AS ERRORS
FROM QHASM.SESSION_LIST SESSION_LIST,
     TABLE(QHASM.SESSION_INFO(SESSION => SESSION_LIST.SESSION_NAME)) SESSION_INFO
WHERE SESSION_INFO.COPY_STATUS != 'ACTIVE';


testo= '                                   ' ;
 QMHSNDPM ('CPA2401': 'QCPFMSG   *LIBL': testo: %size(testo): '*STATUS': '*EXT': 1: MsgKey: ErrorDS ) ;

//  select * from qtemp.dbpowerha

*inlr =*on;

