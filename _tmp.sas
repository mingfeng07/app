/*********************************************************************    
 ***  Study Name: BGB_3111_205
 ***  Program: adae.sas                                             
 ***  Programmer: Qiong Liu
 ***  Date: 14MAY2019                                                      
 ***                                                                  
 ***  Description: Create ADAE dataset
 ***                                                                  
 *********************************************************************

 *********************************************************************/
%global cutoffdtc;
%let cutoffdtc=31MAR2020;

/*get adsl*/
libname sxpt xport "/usrfiles/bgcrh/build/bgb_3111/bgb_3111_205/csr_20200331/dev/define/analysis/adam/datasets/adsl.xpt" access=readonly;
* libname sxpt xport "../datasets/adsl.xpt"  access=readonly;
proc copy inlib=sxpt outlib=work;
run;

/* Convert the requited XPT SDTM data to SAS datasets */

%macro docvt(ads=);                        
libname sxpt xport "/usrfiles/bgcrh/build/bgb_3111/bgb_3111_205/csr_20200331/dev/define/tabulations/sdtm/&ads..xpt" access=readonly;                   
* libname sxpt xport "../../../tabulations/&ads..xpt"  access=readonly;
proc copy inlib=sxpt outlib=work;
run;
%mend docvt;

%docvt(ads=ae);
%docvt(ads=suppae);
%docvt(ads=ec);
%docvt(ads=suppec);
%docvt(ads=relrec);

*get ae of interest;
libname sxpt xport "/usrfiles/bgcrh/build/bgb_3111/bgb_3111_205/csr_20200331/dev/define/misc/aesi230.xpt" access=readonly;
* libname sxpt xport "../../../misc/aesi230.xpt"  access=readonly;
proc copy inlib=sxpt outlib=work;
run;



%macro m_sdtmmerge(dom=,seq=);
proc sort data = &dom out = &dom; by usubjid &seq; run;
data supp1;
  set supp&dom;
  &seq = input(idvarval, best.);
run;
proc sort data = supp1; by usubjid &seq; run;
proc transpose data = supp1 out = supp2(drop = _name_ _label_);
  by usubjid &seq;
  id qnam;
  var qval;
run;

data &dom;
  merge &dom supp2;
  by usubjid &seq;
run;
%mend;

%m_sdtmmerge(dom=ae, seq=aeseq);
data adae;
  length usubjid $25;
  merge ae(in=a drop=studyid) adsl(in=b);
  by usubjid;
  if a and b;
run;

***date imputation: ASTDT/AENDT***;
data adae;
  set adae;
  length ASTDTF AENDTF  $1;

  if aestdtc ne '' and index(aestdtc,'--')=0 then do;
    aestdat_yy=input(substr(aestdtc,1,4),best.);
    aestdat_mm=input(substr(aestdtc,6,2),best.);
    aestdat_dd=input(substr(aestdtc,9,2),best.);
  end;

  *** ASTDT/ASTDTF ***;
  if nmiss(aestdat_yy, aestdat_mm, aestdat_dd)=0 then ASTDT=mdy(aestdat_mm, aestdat_dd, aestdat_yy);
  else if nmiss(aestdat_yy, aestdat_mm, aestdat_dd)=1 and aestdat_dd=. then do;
    if aestdat_yy=year(trtsdt) and aestdat_mm=month(trtsdt) then ASTDT=trtsdt;
    else astdt=mdy(aestdat_mm, 1, aestdat_yy);
    ASTDTF='D';
  end;
  else if nmiss(aestdat_yy, aestdat_mm, aestdat_dd)=2 and aestdat_dd=. and aestdat_mm=. then do;
    if aestdat_yy=year(trtsdt) then ASTDT=trtsdt;
    else ASTDT=mdy(1,1,aestdat_yy);
    ASTDTF='M';
  end;
  else do;
    if .z<trtsdt<=input(aeendtc,yymmdd10.) or aeenrf='ONGOING' then do;
	astdt=trtsdt; astdtf='Y';
	end;
  end;

  if aeendtc ne '' and index(aeendtc,'--')=0 then do;
    aeendat_yy=input(substr(aeendtc,1,4),best.);
    aeendat_mm=input(substr(aeendtc,6,2),best.);
    aeendat_dd=input(substr(aeendtc,9,2),best.);
  end;

  *** AENDT/AENDTF ***;
  if nmiss(aeendat_yy, aeendat_mm, aeendat_dd)=0 then AENDT=mdy(aeendat_mm, aeendat_dd, aeendat_yy);
  else if nmiss(aeendat_yy, aeendat_mm, aeendat_dd)=1 and aeendat_dd=. then do;
    AENDT=intnx('month',mdy(aeendat_mm,1,aeendat_yy),0,'E');	* get last day of the month *;
    AENDTF='D';
  end;
  else if nmiss(aeendat_yy, aeendat_mm, aeendat_dd)=2 and aeendat_dd=. and aeendat_mm=. then do;
    AENDT=mdy(12,31,aeendat_yy);  ** 31st DEC  **;
    AENDTF='M';
  end;

  format ASTDT  AENDT date9.;
  drop aestdat_: aeendat_:;
run;

 
data _adae;
  length acn3 $200;
  acn3="";
  set adae;
  length atoxgr aduru $20 RELGR1 RELGR2 $11 arel $30;
  if aestdtc='' and aeendtc='' then do;
    astdtf = ''; aendtf = ''; astdt = .; aendt=.; 
  end;

  if astdtf ne '' then astdtf=substr(astdtf,1,1);
  if aendtf ne '' then aendtf=substr(aendtf,1,1);
  if n(astdt, aendt)=2 then adurn = aendt - astdt + (aendt>=astdt);
  if adurn>.z then aduru='DAYS';
  if n(aendt,trtsdt)=2 then aendy = aendt - trtsdt + (aendt >= trtsdt);
  if n(astdt,trtsdt)=2 then astdy = astdt - trtsdt + (astdt >= trtsdt);

  atoxgr = aetoxgr;
  
  atoxgrn = input(atoxgr,??best.);
  aetoxgrn = input(atoxgr,??best.);

  if eotstt='DISCONTINUED' and NCTXSDT^=. and TRTSDT <= ASTDT <= min(TRTEDT+30, NCTXSDT) then trtemfl='Y';
  else if EOTSTT='DISCONTINUED' and NCTXSDT=. and TRTSDT <= ASTDT <= TRTEDT+30 then trtemfl='Y';
  else if EOTSTT ^='DISCONTINUED' and TRTSDT <= ASTDT then trtemfl='Y';

  if aerel="" then arel="RELATED";
  else arel=aerel;

  if AREL in ('RELATED', 'PROBABLY RELATED', 'POSSIBLY RELATED') then RELGR1='RELATED';
  else if AREL in ('UNLIKELY RELATED', 'NOT RELATED') then RELGR1='NOT RELATED';

  if AREL in ('RELATED', 'PROBABLY RELATED', 'POSSIBLY RELATED', 'UNLIKELY RELATED') then RELGR2='RELATED';
  else if AREL in ('NOT RELATED') then RELGR2='NOT RELATED';

  if AEACN='DRUG INTERRUPTED' or ACN1='DRUG INTERRUPTED'  or acn2='DRUG INTERRUPTED' or acn3='DRUG INTERRUPTED'
    then AEDINTFL="Y";
  if AEACN='DRUG WITHDRAWN' or ACN1='DRUG WITHDRAWN'  or acn2='DRUG WITHDRAWN' or acn3='DRUG WITHDRAWN'
    then AEDISCFL="Y";
  if AEACN='DOSE REDUCED' or ACN1='DOSE REDUCED'  or acn2='DOSE REDUCED' or acn3='DOSE REDUCED'
    then AEREDUFL="Y";

  if AEREDUFL='Y' or AEDINTFL='Y' then AEDOSMFL="Y";

  length trtp $100;
  trtp=trt01p;
run;

*************************;
* derive FUPWRSFL       *;
*************************;
proc sort data=_adae; 
	by usubjid aedecod astdt aetoxgr;
run;
data _adae0;
	format lag_aendt date9.;
	set _adae;
	by usubjid aedecod astdt aetoxgr;
	lag_aedecod=lag(aedecod);
	lag_aendt=lag(aendt);
	if lag_aedecod ne aedecod or astdt-1>lag_aendt then aeserial+1;
run;
proc sort data=_adae0; 
	by usubjid aeserial;
run;

proc sort data=_adae0(where=(trtemfl="Y")) out=_adae0_nodup(keep=usubjid aeserial) nodupkey; 
	by usubjid aeserial;
run;

data _adae00;
	merge _adae0(in=a) _adae0_nodup(in=b);
	by usubjid aeserial;
	if a;
	if b then trtemfl_="Y";
run;
proc sort data=_adae00; 
	by usubjid aeserial astdt aetoxgr;
run;

data _adae000;
	set _adae00;
	by usubjid aeserial astdt aetoxgr;
	if last.aeserial and aetoxgr="5" and trtemfl_="Y" and trtemfl ne "Y" and TRTEDT+30 < ASTDT < NCTXSDT then FUPWRSFL="Y";
	if not missing(aendt) then aendt_=aendt;
	else aendt_=cutoffdt;
	if last.aeserial and aetoxgr="5" and trtemfl_="Y" and trtemfl = "Y" and TRTEDT+30 < AENDT_ < NCTXSDT then FUPWRSFL="Y";
	if FUPWRSFL ne "Y" then FUPWRSFL="N";
run;
proc sort data=_adae000; 
	by usubjid AESPID AETERM AESTDTC;
run;


*************************;
* derive DOSR01DT       *;
*************************;
%m_sdtmmerge(dom=ec,seq=ecseq);

data ec1;
	length AETERM $200. AESPID $20.;
	format DOSR01DT date9.;
	set ec(keep=usubjid ECAENUM1 ECSTDTC ECADJ ECCHANGE rename=(ECAENUM1=ECAENUM))
		ec(keep=usubjid ECAENUM2 ECSTDTC ECADJ ECCHANGE rename=(ECAENUM2=ECAENUM))
		ec(keep=usubjid ECAENUM3 ECSTDTC ECADJ ECCHANGE rename=(ECAENUM3=ECAENUM));
	if ECADJ='ADVERSE EVENT' and ECCHANGE='REDUCED' and not missing(ECAENUM);
	AESPID="0"||strip(substr(strip(scan(ECAENUM,1,">")),2));
	AETERM=strip(scan(ECAENUM,3,">"));
	if length(strip(scan(ECAENUM,2,">")))=11 then AESTDTC_=compress(scan(ECAENUM,2,">"));
	else if length(strip(scan(ECAENUM,2,">")))=10 then AESTDTC_="0"||compress(scan(ECAENUM,2,">"));
	AESTDTC=put(input(AESTDTC_,date9.),yymmdd10.);
	DOSR01DT=input(ECSTDTC,yymmdd10.);
	keep usubjid ECAENUM ECSTDTC AESPID AETERM AESTDTC DOSR01DT;
	proc sort nodupkey; by usubjid AESPID AETERM AESTDTC;
run;

data _adae0001;
	merge _adae000(in=a) ec1(in=b);
	by usubjid AESPID AETERM AESTDTC;
	if a;
	if (AEACN='DOSE REDUCED' or ACN1='DOSE REDUCED' or ACN2='DOSE REDUCED') and b then DOSR01DT=DOSR01DT;
	else DOSR01DT=.;
run;

*************************;
* derive SMQs           *;
*************************;
data smq;
  length term $200;
  set aesi230(rename=(term=_term));
  term=strip(compbl(upcase(_term)));
run;


data adae1;
  set _adae0001;
  length term $200;
  term=strip(compbl(upcase(aedecod)));
run;


proc sort data=adae1 out=adae2; by term; run;

***SMQ0xXX***;
%macro derv_smq(qname=,aein=,aeout=,qn=);
proc sort data=smq(where=(querynam="&qname")) out=smq&qn; 
  by term; 
run;
data ck0&qn; set smq&qn; by term; if not (first.term and last.term); run;

%if &qn=6 %then %do;
proc freq data=smq&qn; table querynam*smqscope*smqcd/list missing; run;
proc sort data=smq&qn nodupkey; 
  by term;
run;
%end;

data &aeout.(drop=query: smqscope smqcd);
  merge smq&qn(in=smq keep=term querynam smqscope smqcd) &aein.(in=ae);
  by term;
  if ae;

  %if &qn=6 %then %do; length SMQ0&qn.NAM $60; %end;
  %else %do; length SMQ0&qn.NAM $50; %end;
  length SMQ0&qn.SC $6 ;
  if smq then do;
    smq0&qn.nam=strip(querynam);
	smq0&qn.sc=strip(upcase(smqscope));
	SMQ0&qn.CD=smqcd;
  end;
run;
%mend;

%derv_smq(qname=%str(Haemorrhage terms (excl laboratory terms) (SMQ)),aein=adae2,aeout=adae2a,qn=1);
%derv_smq(qname=%str(Tumour lysis syndrome (SMQ)),aein=adae2a,aeout=adae2b,qn=2);
%derv_smq(qname=%str(Malignant tumours (SMQ)),aein=adae2b,aeout=adae2c,qn=3);
%derv_smq(qname=%str(Hypertension (SMQ)),aein=adae2c,aeout=adae2d,qn=4);
%derv_smq(qname=%str(Liver infections (SMQ)),aein=adae2d,aeout=adae2e,qn=5);
%derv_smq(qname=%str(Drug related hepatic disorders - comprehensive search (SMQ)),aein=adae2e,aeout=adae2f,qn=6);
%derv_smq(qname=%str(Ventricular tachyarrhythmia),aein=adae2f,aeout=adae2g,qn=7);
%derv_smq(qname=%str(Skin malignant tumours (SMQ)),aein=adae2g,aeout=adae2h,qn=8);
%derv_smq(qname=%str(Opportunistic infections (SMQ)),aein=adae2h,aeout=adae3,qn=9);

************************;
* derive CQs           *;
************************;
%macro derv_cq(qname=,aein=,aeout=,qn=);
proc sort data=smq(where=(querynam="&qname")) out=cq0&qn;
  by term;
run;
data ck0&qn; set cq0&qn; by term; if not (first.term and last.term); run;

data &aeout.(drop=querynam level);
  merge cq0&qn.(in=cq keep=term querynam level)
		&aein.(in=ae);
  by term;
  if ae;

  length CQ0&qn.NAM $50;

  if cq and level='HLGT' then do;
    if aehlgt="&qname" then cq0&qn.nam=strip(querynam);
  end;
  if cq and level='SOC' then do;
    if aesoc="&qname" then cq0&qn.nam=strip(querynam);
  end;
  if cq and level='PT' then do;
    cq0&qn.nam=strip(querynam);
  end;
run;
%mend;

%derv_cq(qname=%str(Atrial fibrillation),aein=adae3,aeout=adae3a,qn=1);
%derv_cq(qname=%str(Vision disorders),aein=adae3a,aeout=adae3b,qn=2);
%derv_cq(qname=%str(Pleural effusion),aein=adae3b,aeout=adae3c,qn=3);
%derv_cq(qname=%str(Infections and infestations),aein=adae3c,aeout=adae3d,qn=4);
%derv_cq(qname=%str(Diarrhoea),aein=adae3d,aeout=adae3e,qn=5);
%derv_cq(qname=%str(Neutropenia),aein=adae3e,aeout=adae3f,qn=6);
%derv_cq(qname=%str(Thrombocytopenia),aein=adae3f,aeout=adae3g,qn=7);
%derv_cq(qname=%str(Anemia),aein=adae3g,aeout=adae3h,qn=8);

data adae4;
  length CQ09NAM CQ11NAM $50;
  set adae3h;
  if (smq01nam ne '' and aesoc='Nervous system disorders') or
     (aedecod in ('Subdural haematoma', 'Subdural haemorrhage')) or 
	 (smq01nam ne '' and (atoxgrn>=3 or aeser='Y') and aesoc ne 'Nervous system disorders')
    then cq09nam='Major Haemorrhage';

  if smq07nam ne '' or cq01nam ne '' then cq11nam='Cardiac arrhythmia';
run;

data final;
  set adae4;
run;


/** obtain AE related CMSEQ **/
data relrec;
  set relrec;
  where index(relid,'AE') and index(relid,'CM');
  _idvarval = input(idvarval,best.);
run;

proc sort data=relrec;
  by usubjid relid idvar _idvarval;
run;

data relrec;
  set relrec;
  by usubjid relid idvar _idvarval;
  if first.idvar then seq=1;
  else seq+1;
  seq0= put(seq,z2.);
run;

proc transpose data=relrec out= relrec1;
  by usubjid relid;
  id idvar seq0;
  var idvarval;
run;

data relrec1;
  set relrec1;
  length RELID1 $400;
  RELID1=catx(",",of cmseq:);
  len=length(relid1);
  if length(relid1)>200 then put 'USER ER'   'ROR: length of RELID1 is >200' relid1=len=;
  keep usubjid RELID1 aespid01;
  rename aespid01=aespid;
run;
/** End: obtain AE related CMSEQ **/

proc sql undo_policy=none;
  create table final as
  select final.*,relid1,case when relid1^='' then 'Y' else '' end as ANL01FL
  from final
  left join relrec1
  on final.usubjid=relrec1.usubjid and final.aespid=relrec1.aespid
  ;
quit;

/**** add anl03fl for commed treatment for ae****/

data final;
set final;
if AECONTRT='Y' or AEACNO1 ne '' or aeacnoth='NON-MEDICATION CONCOMITANT THERAPY OR PROCEDURE' then anl03fl='Y';
else anl03fl='';
run;

***ASEQ***;
proc sort data=final; by STUDYID USUBJID AETERM ASTDT AESEQ; run;

data final;
  set final;
  by STUDYID USUBJID AETERM ASTDT AESEQ;
  if first.usubjid then ASEQ=1;
  else ASEQ + 1;
run;

******************************;
* output data                *;
******************************;
proc sql;
	create table adae(label="Adverse Events Analysis Dataset") 
	as select STUDYID as STUDYID as STUDYID label="Study Identifier" length=12,
	USUBJID as USUBJID label="Unique Subject Identifier" length=21,
	SUBJID as SUBJID label="Subject Identifier for the Study" length=8,
	SITEID as SITEID label="Study Site Identifier" length=5,
	AGE as AGE label="Age" length=8,
	AGEU as AGEU label="Age Units" length=5,
	AGEGR1 as AGEGR1 label="Pooled Age Group 1" length=11,
	AGEGR1N as AGEGR1N label="Pooled Age Group 1 (N)" length=8,
	AGEGR2 as AGEGR2 label="Pooled Age Group 2" length=19,
	AGEGR2N as AGEGR2N label="Pooled Age Group 2 (N)" length=8,
	SEX as SEX label="Sex" length=1,
	SEXN as SEXN label="Sex (N)" length=8,
	RACE as RACE label="Race" length=5,
	RACEN as RACEN label="Race (N)" length=8,
	SAFFL as SAFFL label="Safety Population Flag" length=1,
	PPROTFL as PPROTFL label="Per-Protocol Population Flag" length=1,
	ARM as ARM label="Description of Planned Arm" length=12,
	ARMCD as ARMCD label="Planned Arm Code" length=4,
	ACTARM as ACTARM label="Description of Actual Arm" length=12,
	ACTARMCD as ACTARMCD label="Actual Arm Code" length=4,
	TRT01P as TRT01P label="Planned Treatment for Period 01" length=12,
	TRT01A as TRT01A label="Actual Treatment for Period 01" length=12,
	TRTSDT as TRTSDT label="Date of First Exposure to Treatment" length=8 format=DATE9.,
	TRTEDT as TRTEDT label="Date of Last Exposure to Treatment" length=8 format=DATE9.,
	TRTEDY as TRTEDY label="Day of Last Exposure to Treatment" length=8,
	TR01SDT as TR01SDT label="Date of First Exposure in Period 01" length=8 format=DATE9.,
	TR01EDT as TR01EDT label="Date of Last Exposure in Period 01" length=8 format=DATE9.,
	CANCRTYP as CANCRTYP label="Cancer Type" length=3,
	ASEQ as ASEQ label="Analysis Sequence Number" length=8,
	AESEQ as AESEQ label="Sequence Number" length=8,
	TRTP as TRTP label="Planned Treatment" length=12,
	AETERM as AETERM label="Reported Term for the Adverse Event" length=101,
	AEDECOD as AEDECOD label="Dictionary-Derived Term" length=47,
	AEBODSYS as AEBODSYS label="Body System or Organ Class" length=67,
	AEBDSYCD as AEBDSYCD label="Body System or Organ Class Code" length=8,
	AELLT as AELLT label="Lowest Level Term" length=49,
	AELLTCD as AELLTCD label="Lowest Level Term Code" length=8,
	AEPTCD as AEPTCD label="Preferred Term Code" length=8,
	AEHLT as AEHLT label="High Level Term" length=74,
	AEHLTCD as AEHLTCD label="High Level Term Code" length=8,
	AEHLGT as AEHLGT label="High Level Group Term" length=86,
	AEHLGTCD as AEHLGTCD label="High Level Group Term Code" length=8,
	AESOC as AESOC label="Primary System Organ Class" length=67,
	AESOCCD as AESOCCD label="Primary System Organ Class Code" length=8,
	AESTDTC as AESTDTC label="Start Date/Time of Adverse Event" length=10,
	AESTDY as AESTDY label="Study Day of Start of Adverse Event" length=8,
	ASTDT as ASTDT label="Analysis Start Date" length=8 format=DATE9.,
	ASTDTF as ASTDTF label="Analysis Start Date Imputation Flag" length=1,
	AEENDTC as AEENDTC label="End Date/Time of Adverse Event" length=10,
	AEENDY as AEENDY label="Study Day of End of Adverse Event" length=8,
	AENDT as AENDT label="Analysis End Date" length=8 format=DATE9.,
	AENDTF as AENDTF label="Analysis End Date Imputation Flag" length=1,
	ASTDY as ASTDY label="Analysis Start Relative Day" length=8,
	AENDY as AENDY label="Analysis End Relative Day" length=8,
	ADURN as ADURN label="Analysis Duration (N)" length=8,
	ADURU as ADURU label="Analysis Duration Units" length=4,
	AEENRF as AEENRF label="End Relative to Reference Period" length=7,
	TRTEMFL as TRTEMFL label="Treatment Emergent Analysis Flag" length=1,
	AETRTEM as AETRTEM label="Treatment Emergent Flag" length=1,
	FUPWRSFL as FUPWRSFL label="Fatal On-Study AE in FUP Flag" length=1,
	AEDISCFL as AEDISCFL label="AE Leading to Discontinuation Flag" length=1,
	AEREDUFL as AEREDUFL label="AE Leading to Dose Reduction Flag" length=1,
	DOSR01DT as DOSR01DT label="Dose Reduced Study Drug 01 Date" length=8 format=DATE9.,
	AEDINTFL as AEDINTFL label="AE Leading to Dose Interruption Flag" length=1,
	AEDOSMFL as AEDOSMFL label="AE Leading to Dose Modification Flag" length=1,
	AESER as AESER label="Serious Event" length=1,
	AEOUT as AEOUT label="Outcome of Adverse Event" length=32,
	AEREL as AEREL label="Causality" length=16,
	AREL as AREL label="Analysis Causality" length=16,
	RELGR1 as RELGR1 label="Pooled Causality Group 1" length=11,
	RELGR2 as RELGR2 label="Pooled Causality Group 2" length=11,
	AETOXGR as AETOXGR label="Standard Toxicity Grade" length=1,
	AETOXGRN as AETOXGRN label="Standard Toxicity Grade (N)" length=8,
	ATOXGR as ATOXGR label="Analysis Toxicity Grade" length=1,
	ATOXGRN as ATOXGRN label="Analysis Toxicity Grade (N)" length=8,
	AEACN as AEACN label="Action Taken with Study Treatment" length=16,
	ACN1 as ACN1 label="Action Taken 1" length=16,
	ACN2 as ACN2 label="Action Taken 2" length=16,
	ACN3 as ACN3 label="Action Taken 3" length=14,
	AEACNOTH as AEACNOTH label="Other Action Taken" length=47,
	AECONTRT as AECONTRT label="Concomitant or Additional Trtmnt Given" length=1,
	AEACNO1 as AEACNO1 label="Other Action Taken 1" length=47,
	AESCONG as AESCONG label="Congenital Anomaly or Birth Defect" length=1,
	AESDISAB as AESDISAB label="Persist or Signif Disability/Incapacity" length=1,
	AESDTH as AESDTH label="Results in Death" length=1,
	AESHOSP as AESHOSP label="Requires or Prolongs Hospitalization" length=1,
	AESLIFE as AESLIFE label="Is Life Threatening" length=1,
	AESMIE as AESMIE label="Other Medically Important Serious Event" length=1,
	RELID1 as RELID1 label="Relationship Identifier1 to CM" length=176,
	ANL01FL as ANL01FL label="Analysis Flag 01 (Concomitant TRT.)" length=1,
	ANL03FL as ANL03FL label="Analysis Flag 03 (ConMed Trt. AE CRF.)" length=1,
	SMQ01NAM as SMQ01NAM label="SMQ 01 Name" length=47,
	SMQ01CD as SMQ01CD label="SMQ 01 Code" length=8,
	SMQ01SC as SMQ01SC label="SMQ 01 Scope" length=6,
	SMQ02NAM as SMQ02NAM label="SMQ 02 Name" length=1,
	SMQ02CD as SMQ02CD label="SMQ 02 Code" length=8,
	SMQ02SC as SMQ02SC label="SMQ 02 Scope" length=1,
	SMQ03NAM as SMQ03NAM label="SMQ 03 Name" length=23,
	SMQ03CD as SMQ03CD label="SMQ 03 Code" length=8,
	SMQ03SC as SMQ03SC label="SMQ 03 Scope" length=6,
	SMQ04NAM as SMQ04NAM label="SMQ 04 Name" length=18,
	SMQ04CD as SMQ04CD label="SMQ 04 Code" length=8,
	SMQ04SC as SMQ04SC label="SMQ 04 Scope" length=6,
	SMQ05NAM as SMQ05NAM label="SMQ 05 Name" length=22,
	SMQ05CD as SMQ05CD label="SMQ 05 Code" length=8,
	SMQ05SC as SMQ05SC label="SMQ 05 Scope" length=6,
	SMQ06NAM as SMQ06NAM label="SMQ 06 Name" length=59,
	SMQ06CD as SMQ06CD label="SMQ 06 Code" length=8,
	SMQ06SC as SMQ06SC label="SMQ 06 Scope" length=6,
	SMQ07NAM as SMQ07NAM label="SMQ 07 Name" length=27,
	SMQ07CD as SMQ07CD label="SMQ 07 Code" length=8,
	SMQ07SC as SMQ07SC label="SMQ 07 Scope" length=6,
	SMQ08NAM as SMQ08NAM label="SMQ 08 Name" length=1,
	SMQ08CD as SMQ08CD label="SMQ 08 Code" length=8,
	SMQ08SC as SMQ08SC label="SMQ 08 Scope" length=1,
	SMQ09NAM as SMQ09NAM label="SMQ 09 Name" length=30,
	SMQ09CD as SMQ09CD label="SMQ 09 Code" length=8,
	SMQ09SC as SMQ09SC label="SMQ 09 Scope" length=6,
	CQ01NAM as CQ01NAM label="Customized Query 01 Name" length=19,
	CQ04NAM as CQ04NAM label="Customized Query 04 Name" length=27,
	CQ05NAM as CQ05NAM label="Customized Query 05 Name" length=9,
	CQ06NAM as CQ06NAM label="Customized Query 06 Name" length=11,
	CQ07NAM as CQ07NAM label="Customized Query 07 Name" length=16,
	CQ08NAM as CQ08NAM label="Customized Query 08 Name" length=6,
	CQ09NAM as CQ09NAM label="Customized Query 09 Name" length=17,
	CQ11NAM as CQ11NAM label="Customized Query 11 Name" length=18
	from final order by STUDYID,USUBJID,AETERM,ASTDT,AESEQ ;
quit;

proc sql noprint;
  select distinct(memname) into :deldata separated by " " from dictionary.tables 
  where upcase(libname)="WORK" and upcase(memname) ^="ADAE";
quit;
proc datasets lib=work nolist;
  delete &deldata;
run;



*compare original dataset;
data adaex(label="Adverse Events Analysis Dataset"); set adae; run;
libname sxpt xport "/usrfiles/bgcrh/build/bgb_3111/bgb_3111_205/csr_20200331/dev/define/analysis/adam/datasets/adae.xpt" access=readonly;
* libname sxpt xport "../datasets/adae.xpt"  access=readonly;
proc copy inlib=sxpt outlib=work;
run;
proc compare data=adae comp=adaex warning;
run;




