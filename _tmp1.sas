/*********************************************************************
***  Program: v_t_ex.sas
***  Programmer: Tingho Huang
***  Date: 30Oct2018
***  Study: BGB_3111_ISSMCL_US
***
***  Description: Program to validate demographic table
***
*********************************************************************
***  MODIFICATIONS:
***  Programmer:
***  Date:
***  Reason:
***
*********************************************************************/
%m_start(env=val,folder=tlfs,pgmname=v_t_ex);

%let tbid=t_ex_saffl;

%m_tflstyle(fnt=small);  ** Standard call for standard report **;

/******************************************************
*** BRING IN ADSL, CREATE MACRO VARIABLES FOR TABLEE HEAD COUNTER AND DENOMITER OF PERCENT;
******************************************************/
%m_pop_qc;

data adsl;
   set adsl;
   **SAFETY POPULATION;
   where saffl='Y' ;
   trgr=put(trtn,1.);
run;

proc freq data=adsl noprint;
 tables trgr/out=cntgr  missing;
run;

data _null_;
  set cntgr;
  call symput('tot'||strip(trgr),strip(put(count,best.)));
run;
%put &tot1 &tot2 &tot3 &tot4 &tot5 &tot6;

data adexsum;
 set adam.adexsum;
 if avalc='Y' then aval=.Y;
 else if avalc='N' then aval=.N;
 else if lowcase(compress(avalc))='<3months' then aval=0;
 else if lowcase(compress(avalc))='>=48months' then aval=999;
 else if avalc^='' then aval=input(scan(avalc,1,"-"),best.);

run;

proc transpose data=adexsum out=adexsum_t;
  by usubjid;
  id paramcd;
  idlabel param;
  var  aval;
run;

data adexsum_t;
  merge adexsum_t(in=in1) adsl(in=in2);
  by usubjid;
  if in1 and in2;
run;

%macro num(inds=,outds=,var=,grouplabel=,decimal=1,lnbreak=,filter=1);
    proc means data=&inds nway;
      where &filter;
      class trgr;
      var &var;
      output out=_temp_out n=n sum=sum mean=mean std=sd min=min max=max median=median q1=q1 q3=q3;
    run;

data _temp_out;
  set _temp_out;
  by trgr;
  lnbreak=&lnbreak;
  length stat stat_label $200;
  if first.trgr then do;
     order=0;
     stat ='';
     stat_label="&grouplabel";
     output;
  end;
  order =1;
  stat =strip(put(n, 3.));
  stat_label="&ods_indent5.n";
  output;

   order =2;
   if n>1 then  stat = strip(put(mean,12.%eval(&decimal.+1)))||" ("||strip(put(sd,12.%eval(&decimal.+2)))||")";
   else if n>0 then  stat = strip(put(mean,12.%eval(&decimal.+1)))||" (NE)"; else stat='';
   stat_label="&ods_indent5.Mean (SD)";

   output;

  order =3;
  if n>0 then    stat = strip(put(median,12.%eval(&decimal.+1)));  else stat='';
  stat_label="&ods_indent5.Median";

   output;

  order =4;
   if n>0 then    stat = strip(put(q1,12.%eval(&decimal.+1)))||", "||strip(put(q3,12.%eval(&decimal.+1)));  else stat='';
  stat_label="&ods_indent5.Q1, Q3";

  output;

  order =5;
   if n>0 then   stat = strip(put(min,12.%eval(&decimal.)))||", "||strip(put(max,12.%eval(&decimal.)));  else stat='';
  stat_label="&ods_indent5.Min, Max";

   output;
%if &var.=TRTDURM %then %do;
  order =6;
   if n>0 then   stat = strip(put(sum,12.%eval(&decimal.+1)));
  stat_label="Total exposure (patient-months)";
  output;
%end;
run;
proc sort data=_temp_out;
  by order stat_label;
run;

proc transpose data=_temp_out out=&outds(rename=stat_label=col1) prefix=cpct;
  by lnbreak order stat_label;
  id trgr;
  var stat;
run;

%mend;
%num(inds=adexsum_t,outds=final01,var=TRTDURM,grouplabel=Duration of Exposure (months)  ,decimal=1,lnbreak=10);
%num(inds=adexsum_t,outds=final03,var=TOTDOSG,grouplabel=Cumulative Dose Administered (g)  ,decimal=1,lnbreak=30);
%num(inds=adexsum_t,outds=final04,var=ACTDOSIN,grouplabel=Average Daily Dose (mg/day)  ,decimal=1,lnbreak=40);
%num(inds=adexsum_t,outds=final05,var=RDOSINT,grouplabel=Relative Dose Intensity (%) &ods_supa.,decimal=1,lnbreak=50);
%*num(inds=adexsum_t,outds=final08,var=NUMDOSI,grouplabel=Number of Dose Interruptions &ods_supd,decimal=0,lnbreak=80,filter=NUMDOSI>0);
%num(inds=adexsum_t,outds=final10,var=NDOSRED,grouplabel=Number of Dose Reductions,decimal=0,lnbreak=100,filter=NDOSRED>0 );

%let miss=%str(0 (0.0));

%macro pct(inds,idx,idx2,col1,where,denom) ;
    %if %quote(&denom) ^= %then %do;
         proc freq data=&denom;
            table trgr/list missing out=denom;
        run;

        data _null_;
          set denom;
          call symputx('tot'||strip(put(_n_,best.)),strip(put(count,best.)),'l');
         run;

    %end;
    %if %quote(&where) ^= %then %do;
        proc freq data=&inds;
             where &where;
             table trgr/list missing out=num&idx;
        run;

        data _null_;
          set num&idx;
          call symputx('NMISS','Y','L');
        run;

            %if not %symexist(NMISS) %then %do;
                data num&idx;
                  call missing(trgr,count);
                run;
                proc sql;
                  create table final&idx._&idx2 as
                     select    distinct &idx2 as order
                               ,&idx as lnbreak
                               ,&col1 as col1 label='#' length = 200
                               ,"&miss" as CPCT1 length=200
                               ,"&miss" as CPCT2 length=200
                               ,"&miss" as CPCT3 length=200
                               ,"&miss" as CPCT4 length=200
                               ,"&miss" as CPCT5 length=200
                               ,"&miss" as CPCT6 length=200
/*                               ,"&miss" as CPCT7 length=200 */
                     from &inds
                  ;
                 quit;
            %end;
            %else %do;
            proc sql;
              create table final&idx._&idx2 as
                 select  distinct &idx2 as order
                           ,&idx as lnbreak
                           ,&col1 as col1 label='#' length = 200
                           ,max(case when trgr='1' then strip(put(count ,4.))|| " ("||strip(put(count/&tot1*100,5.1))||")" else "&miss" end) as CPCT1
                           ,max(case when trgr='2' then strip(put(count ,4.))|| " ("||strip(put(count/&tot2*100,5.1))||")" else "&miss" end) as CPCT2
                           ,max(case when trgr='3' then strip(put(count ,4.))|| " ("||strip(put(count/&tot3*100,5.1))||")" else "&miss" end) as CPCT3
                           ,max(case when trgr='4' then strip(put(count ,4.))|| " ("||strip(put(count/&tot4*100,5.1))||")" else "&miss" end) as CPCT4
                           ,max(case when trgr='5' then strip(put(count ,4.))|| " ("||strip(put(count/&tot5*100,5.1))||")" else "&miss" end) as CPCT5
                           ,max(case when trgr='6' then strip(put(count ,4.))|| " ("||strip(put(count/&tot6*100,5.1))||")" else "&miss" end) as CPCT6
/*                           ,max(case when trgr='7' then strip(put(count ,4.))|| " ("||strip(put(count/&tot7*100,5.1))||")" else "&miss" end) as CPCT7 */
                 from num&idx
              ;
             quit;
          %end;
      %end;
      %else %do;
        proc sql;
              create table final&idx._&idx2 as
                 select    distinct &idx2 as order
                           ,&idx as lnbreak
                           ,&col1 as col1 label='#' length = 200
                           ,' ' as CPCT1
                           ,' ' as CPCT2
                           ,' ' as CPCT3
                           ,' ' as CPCT4
                           ,' ' as CPCT5
                           ,' ' as CPCT6
/*                           ,' ' as CPCT7 */
                 from &inds
              ;
             quit;

      %end;

%mend pct;

/** Duration of Exposure (months) **/
%pct(adexsum_t,20,0,%str("Duration of Exposure, n (%%)") ) ;
%pct(adexsum_t,20,1,%str("&ods_indent5.<3 months") , %str(TRTDMGR=0)) ;
%pct(adexsum_t,20,2,%str("&ods_indent5.3 - <6 months") , %str(TRTDMGR=3)) ;
%pct(adexsum_t,20,3,%str("&ods_indent5.6 - <9 months") , %str(TRTDMGR=6)) ;
%pct(adexsum_t,20,4,%str("&ods_indent5.9 - <12 months") , %str(TRTDMGR=9)) ;
%pct(adexsum_t,20,5,%str("&ods_indent5.12 - <18 months") , %str(TRTDMGR=12)) ;
%pct(adexsum_t,20,6,%str("&ods_indent5.18 - <24 months") , %str(TRTDMGR=18)) ;
%pct(adexsum_t,20,7,%str("&ods_indent5.24 - <30 months") , %str(TRTDMGR=24)) ;
%pct(adexsum_t,20,8,%str("&ods_indent5.30 - <36 months") , %str(TRTDMGR=30)) ;
%pct(adexsum_t,20,9,%str("&ods_indent5.36 - <48 months") , %str(TRTDMGR=36)) ;
%pct(adexsum_t,20,10,%str("&ods_indent5.&ods_ge_rep. 48 months") , %str(TRTDMGR=999)) ;
/*%pct(adexsum_t,20,10,%str("&ods_indent5.Missing") , %str(TRTDMGR=.)) ;*/

/**Patients with Dose Modification, n (%) [2]      **/
%*pct(adexsum_t,60,1,%str("Patients with Dose Modification &ods_supc , n (%%)") ,%str(DOSEMOD=.Y) ) ;

/**Patients with Dose Interruption, n (%)          **/
%*pct(adexsum_t,70,1,%str("Patients with Dose Interruption &ods_supd , n (%%)") , %str(DOSINTER=.Y) ) ;

/** Number of Dose Interruption **
%pct(adexsum_t,85,0,%str("Number of Dose Interruptions &ods_supd") ) ;
%pct(adexsum_t,85,2,%str("&ods_indent5.1") , %str(NUMDOSI=1)) ;
%pct(adexsum_t,85,3,%str("&ods_indent5.2") , %str(NUMDOSI=2)) ;
%pct(adexsum_t,85,4,%str("&ods_indent5.3") , %str(NUMDOSI=3)) ;
%pct(adexsum_t,85,5,%str("&ods_indent5.4") , %str(NUMDOSI=4)) ;
%pct(adexsum_t,85,6,%str("&ods_indent5.5") , %str(NUMDOSI=5)) ;
%pct(adexsum_t,85,7,%str("&ods_indent5.>5") , %str(NUMDOSI>5)) ;
*/
/**Patients with Dose Reduction, n (%)  **/
%pct(adexsum_t,90,1,%str("Patients with Dose Reduction, n (%%)") , %str(DOSRED=.Y) ) ;

/** Number of Dose Reduction **/
%pct(adexsum_t,105,0,%str("Number of Dose Reductions, n (%%)") ) ;
%pct(adexsum_t,105,2,%str("&ods_indent5.1") , %str(NDOSRED=1)) ;
%pct(adexsum_t,105,3,%str("&ods_indent5.2") , %str(NDOSRED=2)) ;
%pct(adexsum_t,105,4,%str("&ods_indent5.3") , %str(NDOSRED=3)) ;
%pct(adexsum_t,105,5,%str("&ods_indent5.4") , %str(NDOSRED=4)) ;
%pct(adexsum_t,105,6,%str("&ods_indent5.5") , %str(NDOSRED=5)) ;
%pct(adexsum_t,105,7,%str("&ods_indent5.&ods_ge_rep. 6") , %str(NDOSRED>=6)) ;

/**Patients with Dose Reduction, n (%)  **/
%pct(adexsum_t,200,1,%str("Patients with Dose Interruptions due to Adverse Event &ods_supb., n (%%)") , %str(DOSINTAE=.Y) ) ;

data final_t1;
  length col1 $200;
  set final:;
run;

data final_t;
    set final_t1;
    array arr cpct:;
/*  if lnbreak=100 then do; if order=1 and cpct1='' then do; cpct1='NA'; cpct5='NA';  end; end;*/
    do over arr;
        if col1="&ods_indent5.n" and missing(arr) then arr='0';
    end;
  rename col1=stat1 cpct1-cpct6 = trt1-trt6;*cpct1=trt1  cpct2=trt2  cpct3=trt3  cpct4=trt4  ;
run;
proc sort data=final_t;
  by lnbreak order;
run;

data vdtables.v_&tbid;
  set final_t;
run;

/*proc delete data=_all_;*/
/*run;*/

data  base;
  set dtables.&tbid;

  keep stat1 trt1-trt6;
 run;

data cmp;
  set vdtables.v_&tbid;

  keep stat1 trt1-trt6 ;
 run;
ods listing;

proc compare base=base comp=cmp out=chk listall listvar outbase outcomp outnoeq;
run;

