**free
ctl-opt option(*srcstmt:*nodebugio)  decedit('0,') Datedit(*DMY/) alwnull(*usrctl) DFTACTGRP(*no) ;
dcl-f wwepv  workstn  ;

dcl-pr run extpgm(programma) end-pr;
dcl-s programma char(10);  // nome del programma da chiamare
dcl-s testo char(100);
dcl-s wweattivo int(5);


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

dcl-s sbsnam char(20) inz('WWE       WWE      ');
dcl-s sbssts char(9);
dcl-s SBSSTSC char(12);
dcl-s rcv char(244);
dcl-s rcvl bindec(4)  inz(244);
dcl-s SBSFMT char(8) inz('SBSI0200');
dcl-s err bindec(4:0);

dcl-pr QWDRSBSD extpgm('QWDRSBSD');
rcv char(244);
rcvl bindec(4);
SBSFMT char(8);
sbsnam char(20) ;
err bindec(4);
end-pr;

  dcl-pr pg003 extpgm('PG003'); // controll l'esistenza del file di work creato dal programma di controllo
    pa_lib char(10);  // Nome libreria
    pa_obj char(10);  // Nome Oggetto
    pa_typ char(10);  // tipo Oggetto
    pa_fla char(1);   // Flag 1 = Esiste 0 = Non c'è
  END-PR;

  dcl-s pa_lib char(10);  // Nome libreria
  dcl-s pa_obj char(10);  // Nome Oggetto
  dcl-s pa_typ char(10);  // tipo Oggetto
  dcl-s pa_fla char(1);   // Flag 1 = Esiste 0 = Non c'è

dcl-s ndrive int(5);
dcl-s HA int(5);

//- Modifiche per gestire la versione del prodotto ---------------------------------------------------------------------------------------
dcl-s wwegeneral char(512) dtaara('PG901'); // data area parametri generali WWE
in wwegeneral;
release = 'Rel.'+%subst(wwegeneral:1:2)+'.'+%subst(wwegeneral:3:2)+'.'+%subst(wwegeneral:5:2)+
          '-'+%subst(wwegeneral:15:2)+'/'+%subst(wwegeneral:12:2)+'/'+%subst(wwegeneral:09:2);
//- Modifiche per gestire la versione del prodotto ---------------------------------------------------------------------------------------


 exec sql SET OPTION COMMIT=*NONE,CLOSQLCSR=*ENDMOD,DATFMT=*ISO,NAMING = *SYS;


// Controllo se è installato il power ha
 exec sql  select coalesce(COUNT(*), 0) AS Nodi  into :ha   FROM QHASM.CLUSTER_NODES;

if sqlcode <> 0 or ha = 0;
*in67 = *off;
else;
*in67 = *on;
endif;

dow 1=1;

  exsr controllaweb; // controlla la presenza di wwew e in caso affermativo ne abilila le funzioni

  wsscel = 0;
  exsr getinfo;
  exfmt w01;

  if *in03 = *on;
    leave;
  ENDIF;

select;
  when wsscel = 1;     // gestione sonde
       testo= 'Recupero stauts sonde... ' ;
       exsr msg;
       programma='PG004';
       callp(e) run ();
  when wsscel = 21 ;     // Analisi attività di sistema
       programma='PG017A';
       callp(e) run  ();
   //    programma='PG018';
   //    callp(e) run  ();
  when wsscel = 22  ;     // Gestione link
       programma='PG020';
       callp(e) run () ;
  when wsscel = 23  ;     // analisi eventi non classificati

       programma='PG045';
       callp(e) run () ;
  when wsscel = 31  ;     // Manutenzione Azioni
       programma='PG019';
       callp(e) run () ;
  when wsscel = 32  ;     // Manutenzione Azioni
       programma='PG013';
       callp(e) run () ;
  when wsscel = 41  ;     // Analisi coda decisionale
       programma='PG027';
       callp(e) run () ;
  when wsscel = 42  ;     // Analisi coda decisionale
       programma='PG028';
       callp(e) run () ;
  when wsscel = 43  ;     // Console delle sonde
       programma='PG004';
       callp(e) run () ;
  when wsscel = 44  ;     // Filtro eventi
       programma='PG030';
       callp(e) run () ;
  when wsscel = 51 and *in41 = *on  ;     // Interrogazione e Start e Stop Interfaccia
       programma='PG037';
       callp(e) run () ;
  when wsscel = 52 and *in41 = *on  ;     // Gestione abilitazione Utenti
       programma='WEBWWES';
       callp(e) run () ;
  when wsscel = 53 and *in41 = *on  ;     // Gestione One Time Password
       programma='WEBWWET';
       callp(e) run () ;
  when wsscel = 54 and *in41 = *on  ;     // Manutenzione Executer
       programma='WEBWWEU';
       callp(e) run () ;
  when wsscel = 55 and *in41 = *on  ;     // Manutenzione Executer
       programma='WEBWWE97';
       callp(e) run () ;

  when wsscel = 61  ;     // Valutazione metriche performances
       programma='PG074';
       callp(e) run () ;
  when wsscel = 62  ;     // Generazione codice per Sonde
       programma='PG034';
       callp(e) run () ;
  when wsscel = 63  ;     // Gestione giorni per azioni
       programma='PG033';
       callp(e) run () ;
  when wsscel = 64  ;     // Gestione abilitazioni
       programma='PG042';
       callp(e) run ()      ;
  when wsscel = 65  ;     // Lancio personalizzazioni parametri sonde
       programma='PG049';
       callp(e) run ()      ;
  when wsscel = 66  ;     // Green Dashboard
       programma='PG069';
       callp(e) run ()      ;
  when wsscel = 83  ;     // Analisi del power HA Solo se presente
       if *in67 = *on;
       programma='PG082';
       callp(e) run ()      ;
       endif;
ENDSL;

ENDDO;


*inlr =*on;

//==================================================================================================
begsr msg; // invio messaggi di status
// =================================================================================================
        QMHSNDPM ('CPA2401': 'QCPFMSG   *LIBL': testo: %size(testo): '*STATUS': '*EXT': 1: MsgKey: ErrorDS ) ;
ENDSR;

//==================================================================================================
begsr getinfo; // invio messaggi di status
// =================================================================================================

rcvl = 244;
sbsfmt = 'SBSI0200';
sbsnam = 'WWE       WWE      ';


xsyst = *blanks;
xperf = *blanks;
xprob = *blanks;
xanali = *blanks;
xnum = 0;

// controllo se il sottosistema è attivo-----------------------------------------------------------

exec sql SELECT count(*)into :wweattivo FROM TABLE(QSYS2.ACTIVE_JOB_INFO(  subsystem_list_filter => 'WWE')) where job_type = 'SBS';

      if wweattivo > 0;
        xmon = '*ATTIVO';
        *in51 = *on;
      else;
        xmon = '*DOWN' ;
        *in51 = *off;
      ENDIF;


//CALLp(e)    QWDRSBSD (RCV: RCVL: SBSFMT: SBSNAM:  ERR) ;
//      SBSSTSC = %subst(RCV:53:12);
//      SBSSTS=SBSSTSC;
//      xmon = sbsstsc ;
//
//      if SBSSTSC = '*ACTIVE';
//        *in51 = *on;
//      else;
//        *in51 = *off;
//      ENDIF;

// controllo se la Sonda di sistema è operativa   -----------------------------------------------------------
 exec sql SELECT JOB_STATUS into :xsyst FROM TABLE(QSYS2.ACTIVE_JOB_INFO(SUBSYSTEM_LIST_FILTER => 'WWE')) A WHERE job_name LIKE '%/SYS000%';

 if xsyst = *blanks or xsyst = 'END' or xsyst = 'EOJ' or  xsyst = 'HLD' or xsyst = 'LCKW' or  xsyst = 'MSGW';
    *in52 = *off;
    xsyst = 'DOWN';
 else;
   *in52 =*ON;
 ENDIF;

// controllo se la Sonda di Performances è operativa   -----------------------------------------------------------
 exec sql SELECT JOB_STATUS into :xperf FROM TABLE(QSYS2.ACTIVE_JOB_INFO(SUBSYSTEM_LIST_FILTER => 'WWE')) A WHERE job_name LIKE '%/SYS001%';

 if xperf = *blanks or  xperf = 'END' or xperf = 'EOJ' or  xperf = 'HLD' or xperf = 'LCKW' or  xperf = 'MSGW';
    *in53 = *off;
   xperf = 'DOWN';
 else;
   *in53=*ON;
 ENDIF;

// controllo se la Sonda di Problemi è operativa   -----------------------------------------------------------
 exec sql SELECT JOB_STATUS into :xprob FROM TABLE(QSYS2.ACTIVE_JOB_INFO(SUBSYSTEM_LIST_FILTER => 'WWE')) A WHERE job_name LIKE '%/SYS002%';

 if xprob = *blanks or xprob = 'END' or xprob = 'EOJ' or  xprob = 'HLD' or xprob = 'LCKW' or  xprob = 'MSGW';
    *in54 = *off;
   xprob = 'DOWN';
 else;
   *in54=*ON;
 ENDIF;
// controllo se la Sonda di Analisi  è operativa   -----------------------------------------------------------
 exec sql SELECT JOB_STATUS into :xanali FROM TABLE(QSYS2.ACTIVE_JOB_INFO(SUBSYSTEM_LIST_FILTER => 'WWE')) A WHERE job_name LIKE '%/SYS003%';

 if xanali = *blanks or  xanali = 'END' or xanali = 'EOJ' or  xanali = 'HLD' or xanali = 'LCKW' or  xanali = 'MSGW';
    *in55 = *off;
   xanali = 'DOWN';
 else;
   *in55=*ON;
 ENDIF;

 exec sql select count(*) into :xnum from wweev00f  where evsend = 'N' ;

 exec sql select count(*) into :ndrive from dbdrive where TIPOEVE = 'NEW';

 if ndrive = 0;
   *in61 = *off;
 else;
   *in61 = *on;
 ENDIF;


 endsr;

 // ------------------------------------------------------------------------------------------------------------
 begsr controllaweb; // controlla la presenza della componente web
 // ------------------------------------------------------------------------------------------------------------
    pa_lib='*LIBL';  // Controllo se la sonda ha creato il file di lavoro       Pa_fla = '1' = creato
    pa_obj='WWEW';
    pa_typ='*LIB';
    pa_fla='0';
    callp(e) pg003 (pa_lib:pa_obj:pa_typ:pa_fla);
    if pa_fla = '1'; // trovato ambiente web
      *in41 = *on;
       exec sql CALL QSYS2.QCMDEXC('addlible wwew *last');
      else;
      *in41 = *off;

    ENDIF;


 ENDSR;



