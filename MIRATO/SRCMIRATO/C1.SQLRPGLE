**free
ctl-opt option(*srcstmt:*nodebugio)  decedit('0,') Datedit(*DMY/) alwnull(*usrctl) DFTACTGRP(*no) ;

 DCL-S arr CHAR(92) DIM(200) ctdata ;
 dcl-s isql char(4000);
 dcl-s i int(5);

dcl-pr gendata extpgm ('GIAN/A1');
  *N char(4000);
end-pr ;

 for i = 1 to 200;
   isql = %trim(isql) + ' ' + ' ' + %trim(arr(i));
 Endfor;

 callp(e) gendata(isql);


 *inlr = *on;
** CTDATA arr
SELECT '004' AS id,
       'Risorse Non Monitorate' AS item,
       COUNT(*) AS ERRORS
    FROM (
            SELECT JOBD.OBJNAME AS "Unmonitored Resource",
                   '*JOBD' AS "Resource Type",
                   JOBD.OBJLONGSCHEMA AS "Resource Library"
                FROM TABLE (
                        QSYS2.OBJECT_STATISTICS('*ALL', '*JOBD', '*ALLSIMPLE')
                    ) JOBD
                WHERE jobd.objname NOT LIKE 'Q%'
                      AND JOBD.OBJLONGSCHEMA != 'QSYS'
                      AND JOBD.OBJLONGSCHEMA != 'QINSYS'
                      AND JOBD.OBJLONGSCHEMA != 'QINPRIOR'
                      AND JOBD.OBJLONGSCHEMA != 'QINMEDIA'
                      AND NOT EXISTS (
                              SELECT MONITORED_RESOURCE
                                  FROM TABLE (
                                          QHASM.ADMIN_DOMAIN_MRE_LIST(RESOURCE_TYPE => '*JOBD')
                                      ) MRE
                                  WHERE MRE.MONITORED_RESOURCE = JOBD.OBJNAME)
            UNION
            SELECT SBSD.OBJNAME AS "Unmonitored Resource",
                   '*SBSD' AS "Resource Type",
                   SBSD.OBJLONGSCHEMA AS "Resource Library"
                FROM TABLE (
                        QSYS2.OBJECT_STATISTICS('*ALL', '*SBSD', '*ALLSIMPLE')
                    ) SBSD
                WHERE sbsd.objname NOT LIKE 'Q%'
                      AND SBSD.OBJLONGSCHEMA != 'QSYS'
                      AND SBSD.OBJLONGSCHEMA != 'QINSYS'
                      AND SBSD.OBJLONGSCHEMA != 'QINPRIOR'
                      AND SBSD.OBJLONGSCHEMA != 'QINMEDIA'
                      AND NOT EXISTS (
                              SELECT MONITORED_RESOURCE
                                  FROM TABLE (
                                          QHASM.ADMIN_DOMAIN_MRE_LIST(RESOURCE_TYPE => '*SBSD')
                                      ) MRE
                                  WHERE MRE.MONITORED_RESOURCE = SBSD.OBJNAME)
            UNION
            SELECT USRPRF.OBJNAME AS "Unmonitored Resource",
                   '*USRPRF' AS "Resource Type",
                   USRPRF.OBJLONGSCHEMA AS "Resource Library"
                FROM TABLE (
                        QSYS2.OBJECT_STATISTICS('QSYS', '*USRPRF', '*ALLSIMPLE')
                    ) USRPRF
                WHERE usrprf.objname NOT LIKE 'Q%'
                      AND NOT EXISTS (
                              SELECT MONITORED_RESOURCE
                                  FROM TABLE (
                                          QHASM.ADMIN_DOMAIN_MRE_LIST(RESOURCE_TYPE => '*USRPRF')
                                      ) MRE
                                  WHERE MRE.MONITORED_RESOURCE = USRPRF.OBJNAME)
            UNION
            SELECT AUTL.OBJNAME AS "Unmonitored Resource",
                   '*AUTL' AS "Resource Type",
                   AUTL.OBJLONGSCHEMA AS "Resource Library"
                FROM TABLE (
                        QSYS2.OBJECT_STATISTICS('QSYS', '*AUTL', '*ALLSIMPLE')
                    ) AUTL
                WHERE autl.objname NOT LIKE 'Q%'
                      AND NOT EXISTS (
                              SELECT MONITORED_RESOURCE
                                  FROM TABLE (
                                          QHASM.ADMIN_DOMAIN_MRE_LIST(RESOURCE_TYPE => '*AUTL')
                                      ) MRE
                                  WHERE MRE.MONITORED_RESOURCE = AUTL.OBJNAME)
            UNION
            SELECT CLS.OBJNAME AS "Unmonitored Resource",
                   '*CLS' AS "Resource Type",
                   CLS.OBJLONGSCHEMA AS "Resource Library"
                FROM TABLE (
                        QSYS2.OBJECT_STATISTICS('*ALL', '*CLS', '*ALLSIMPLE')
                    ) CLS
                WHERE cls.objname NOT LIKE 'Q%'
                      AND CLS.OBJLONGSCHEMA != 'QSYS'
                      AND CLS.OBJLONGSCHEMA != 'QINSYS'
                      AND CLS.OBJLONGSCHEMA != 'QINPRIOR'
                      AND CLS.OBJLONGSCHEMA != 'QINMEDIA'
                      AND NOT EXISTS (
                              SELECT MONITORED_RESOURCE
                                  FROM TABLE (
                                          QHASM.ADMIN_DOMAIN_MRE_LIST(RESOURCE_TYPE => '*CLS')
                                      ) MRE
                                  WHERE MRE.MONITORED_RESOURCE = CLS.OBJNAME)
        );
