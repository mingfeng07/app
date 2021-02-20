/*********************************************************************    
***  Study Name: BGB-3111-205                                                          
***  Program: v_t_ae_eoipt.sas                                             
***  Programmer: qiong liu
 ***  Date: 14JAN2019                                                   
***                                                                  
***  Description: QC T_AE_SOCPT TABLES
***                                                                  
*********************************************************************
***  MODIFICATIONS: adapted from 205 csr_20181112                                                   
***  Programmer: Qiong Liu                                                       
***  Date: 14JAN2019                                                             
***  Reason:                                                         
***                                                                  
*********************************************************************/ 
%inc '/usrfiles/bgcrh/support/utilities/init/init_global.sas';

proc format;
	value $ eoilbl 
	'SMQ01NAM'='Hemorrhage'
	'CQ09NAM'='Major hemorrhage'
	'CQ01NAM'='Atrial fibrillation and flutter'
	'SMQ04NAM'='Hypertension'
	'SMQ03NAM'='Second primary malignancies'
	'CQ05NAM'='Diarrhea'
	'SMQ02NAM'='Tumor lysis syndrome'
	'CQ04NAM'='Infections'
	'CQ06NAM'='Neutropenia'
	'CQ07NAM'='Thrombocytopenia'
	'CQ08NAM'='Anemia'
	'CQ12NAM'='Opportunistic infection'
	
	'SMQ07NAM'='Ventricular tachyarrhythmia'
	

	'OSO01NAM'='Infectious hepatic events'
	'OSO02NAM'='Non-infectious hepatic events'
	'OSO03NAM'='All hepatic events'
	'OSO04NAM'='Diarrhea'
	'OSO05NAM'='Ventricular tachyarrhythmia'

	'_CQ02NAM'='Vision disorders'
	'_CQ03NAM'='Pleural effusion'
	'SMQ08NAM'='Skin malignant tumours'
/*	'OSO11NAM'='Cardiac arrhythmia'*/
;
run;
*Get d_pop;
proc sort data=adam.adsl out=adsl;
	by usubjid;
run;

data adsl;
	set adsl;
	by usubjid;
	where saffl='Y';

	trtgrp=1;
	distype=''; * replaced if distype is defined ;

	* Generate groups for tables;
	grp_1=cats("_",distype);

	if ^missing(trtgrp) then
		do;
			grp_2=cats("_", trtgrp);
			grp_3=cats("_", trtgrp, "_",distype);
		end;

	output;
	grp_1="Overall";

	if ^missing(trtgrp) then
		do;
			grp_2="Overall";
			grp_3="Overall";
		end;

	output;
run;

%macro aetable(grpvar=, cond=, _filename=, term= );
	* AE records.;
	data adam_adae_1;
		set adam.adae(drop=cq11nam);
		%if %index(%upcase(&_filename),OSO) <=0 %then %do;
			CQ11NAM="";	
			%end;
        
	    IF RELGR1 IN ('RELATED') THEN
		AREL='Y';

		IF saffl='Y' and &cond;
		aeterm_soc=aebodsys;
		aeterm_pt=aedecod;

		if missing(aeterm_soc) then
			aeterm_soc="Missing";

		if missing(aeterm_pt) then
			aeterm_pt=aeterm;

		if smq05nam ^= '' or smq06nam ^='' then oso03nam='All hepatic events';

		if atoxgrn=. then atoxgrn=0;

		output;

		if aedecod in ('Petechiae' 'Purpura' 'Contusion') then do;
				aeterm_pt="Petechiae/Purpura/Contusion^{style[font_size=12pt]^{super a}}";
				output;
			end;


		*** exclude CQ02NAM, CQ03NAM from all AESI tables, separate SMQ05NAM, SMQ06NAM to Other Safety Observation Category ***;
				rename /*cq02nam=_cq02nam cq03nam=_cq03nam*/ smq05nam=oso01nam smq06nam=oso02nam cq05nam=oso04nam smq07nam=oso05nam
                       /*CQ11NAM=oso11nam*/;
	run;

	data adam_adae_eoi;
		set adam_adae_1;

			%if %scan(&_filename,3,%str(_)) eq plvd %then %do;
				array eoi [*] _cq:;
			%end;
			%else %if %index(%upcase(&_filename),OSO) >0 %then %do;
				array eoi [*] oso:;
			%end;
			%else %do;
				array eoi [*] smq01nam smq02nam smq03nam smq04nam /* smq07nam */ SMQ08NAM cq:;
			%end;

			do i=1 to dim(eoi);
				if eoi[i]^='' then do; 
					aeterm_soc=put(upcase(vname(eoi[i])),$eoilbl.); 
					eoi_ord=i; 
					output; 
				end;
			end;

	run;

	proc sql;
		create table adam_adae as
			select distinct l.*, r.grp_1, r.grp_2, r.grp_3
				from adam_adae_eoi as l
					left join adsl as r
						on l.usubjid=r.usubjid;
	quit;

	%global filename;
	%let filename=&_filename;

	proc sql;
		create table bign as 
			select distinct &grpvar as grp, count(distinct usubjid) as bign
				from adsl
					where saffl='Y' and ^missing(&grpvar)
						group by &grpvar;
	quit;

	/*proc print data=bign;run;*/
	%symdel _1 _2 overall _1_nhl _1_cll _2_nhl _2_cll _2_wm _wm _cll _nhl/nowarn;

	data _null_;
		set bign;
		call symputx(grp,bign);
	run;

	/***For Toxgrade >=3***/
%macro grade(grade= );

	data adae;
		set adam_adae;
		where ^missing(&grpvar);

		if atoxgrn>= &grade;
		grp=&grpvar;
	run;

	* Count subjnum by SOC and Preferred Term;
	proc sql;
		create table subjnum as
			select distinct aeterm_soc,aeterm_pt,grp,count(distinct usubjid) as subjnum
				from adae where ^missing(aeterm_pt)
					group by aeterm_soc,aeterm_pt,grp
						union
					select distinct aeterm_soc," " as aeterm_pt,grp,count(distinct usubjid) as subjnum
						from adae where ^missing(aeterm_pt)
							group by aeterm_soc,grp
								union
							select distinct " " as aeterm_soc, " " as aeterm_pt,grp,count(distinct usubjid) as subjnum
								from adae where ^missing(aeterm_pt)
									group by grp
										order by grp;
	quit;

	data subjnum;
		merge subjnum bign;
		by grp;
		length col $75;

		if ^missing(subjnum) then
			do;
				pct=subjnum/bign;
				col=strip(put(subjnum,best.))||" ("||strip(put(round(pct*100,0.1),5.1))||")";
			end;
		else if missing(subjnum) then
			col="0 (0.0)";
		grpord=(grp="Overall");
	run;

	proc sort data=subjnum;
		by aeterm_soc aeterm_pt descending grpord;
	run;

	data subjnum1;
		set subjnum;
		by aeterm_soc aeterm_pt descending grpord;
		retain order1;

		if first.aeterm_soc then
			do;
				if grp="Overall" then
					order1=subjnum;
				else order1=0;
			end;
	run;
	PROC SORT DATA=SUBJNUM1;
		BY aeterm_soc DESCENDING ORDER1 DESCENDING SUBJNUM AETERM_PT;
	RUN;
	proc transpose data=subjnum1 out=subjnum2;
		by aeterm_soc DESCENDING ORDER1 DESCENDING SUBJNUM AETERM_PT;
		var col;
		id grp;
	run;

	data subjnum&grade;
		length text $200;
		set subjnum2;
		by aeterm_soc DESCENDING ORDER1 DESCENDING SUBJNUM AETERM_PT;
		order2=input(scan(overall,1),best.);

		if missing(aeterm_soc) then
			Text="Patients with at least 1 &term";
		else if missing(aeterm_pt) then
			text=aeterm_soc;
		else text="  "||aeterm_pt;

		if first.aeterm_soc then
			grpn+1;
	run;

	/***END For Toxgrade >=3***/
%mend grade;

%grade(grade=0);

data subjnum0/*(keep= aeterm_soc aeterm_pt text _1 )*/;
	set subjnum0/*(rename=(_2=_3))*/;
/*	if aeterm_soc='Opportunistic infection' then aeterm_soc=catx(': ','Infections1',aeterm_soc);*/
/*	else if aeterm_soc='Major hemorrhage' then aeterm_soc=catx(': ','Hemorrhage1',aeterm_soc);*/
run;

%*grade(grade=3);

/*data subjnum3(keep= aeterm_soc aeterm_pt text _2 );
	set subjnum3;
	_2=_1;
run;*/

data subjnum_all;
	SET subjnum0 /*subjnum3*/;
	by aeterm_soc DESCENDING ORDER1 DESCENDING SUBJNUM AETERM_PT;

	array cvar (*)  _: overall;

	do i=1 to dim(cvar);
		if missing(cvar(i)) then
			cvar(i)="0 (0.0)";
	end;
run;


*** modify EOIPT order ***;
data subjnum_all_; 
	set subjnum_all; 
	if aeterm_soc in ('Opportunistic infection') then aeterm_soc='Infections1: Opportunistic infection';
	else if aeterm_soc in ('Major hemorrhage') then aeterm_soc='Hemorrhage1: Major hemorrhage';
run;
proc sort data=subjnum_all_ out=subjnum_all;
	by aeterm_soc DESCENDING ORDER1 DESCENDING SUBJNUM AETERM_PT;
run;


%if &_filename=T_TEAE_grd3_oso_us or &_filename=T_TEAE_sae_oso_us or &_filename=T_TEAE_oso_us %then %do;
data subjnum_all;
  set subjnum_all;
  if aeterm_soc="Cardiac arrhythmia" then delete;
  run;
%end;

data qc(keep=c:);
	set subjnum_all;
	text=compress(text);
	_1  =compress(_1);

		%if %scan(_filename,3,%str(_)) eq plvd %then %do;
			rename text = col1 _1 = col2;
		%end;
		%else %do;
			rename text= c1 _1 = c2 ;
		%end;

run;

options replace;
DATA VDTABLES.V_&_FILENAME.;
	SET SUBJNUM_ALL;
RUN;
options noreplace;

PROC SORT DATA=QC;
	BY C1 C2;
RUN;

DATA SOURCE(KEEP=C1 c2);
	SET DTABLES.&_FILENAME.;
/*	IF _1='' THEN DELETE;*/
	LENGTH C1 $200 C2 $75;
	C2=COMPRESS(col2);
	C1=STRIP(COMPRESS(TRANWRD(col1,"^{style[font_size=10pt]^{nbspace 3}}^R'\fi-160\li160 '","")));
	C1=STRIP(COMPRESS(TRANWRD(c1,"^{style[font_size=10pt]^{nbspace5}}^R'\fi-260\li260'","")));
RUN;

PROC SORT DATA=SOURCE;
	BY C1 C2;
RUN;

title "&_filename &_filename";

PROC COMPARE base=SOURCE COMPARE=QC LISTALL WARNING listequalvar
outnoequal outbase outcompare out=compout;
RUN;

%mend aetable;

*** AESI category ***;
%aetable(grpvar=grp_2, COND=%STR(TRTEMFL='Y'), _filename=T_TEAE_eoiPT, term= TEAE of special interest);


%aetable(grpvar=grp_2, COND=%STR(TRTEMFL='Y' AND atoxgrn>=3), _filename=T_TEAE_grd3_eoiPT, term= %STR(grade 3 or higher TEAE of special interest));
%aetable(grpvar=grp_2, COND=%STR(TRTEMFL='Y' AND aeser='Y'), _filename=T_TEAE_sae_eoiPT, term= %STR(serious TEAE of special interest));

*** Other Safety Observation Category ***;
/*%aetable(grpvar=grp_2, COND=%STR(TRTEMFL='Y'), _filename=T_TEAE_oso, term= %str(TEAE related to Liver, Arrhythmia, and Diarrhea));*/
/*%aetable(grpvar=grp_2, COND=%STR(TRTEMFL='Y' AND atoxgrn>=3), _filename=T_TEAE_grd3_oso, term= %STR(grade 3 or higher TEAE related to Liver, Arrhythmia, and Diarrhea));*/
/*%aetable(grpvar=grp_2, COND=%STR(TRTEMFL='Y' AND aeser='Y'), _filename=T_TEAE_sae_oso, term= %STR(serious TEAE related to Liver, Arrhythmia, and Diarrhea));*/


%aetable(grpvar=grp_2, COND=%STR(TRTEMFL='Y'), _filename=T_TEAE_oso_us, term= %str(TEAE related to Liver, Arrhythmia, and Diarrhea));

%aetable(grpvar=grp_2, COND=%STR(TRTEMFL='Y' AND atoxgrn>=3), _filename=T_TEAE_grd3_oso_us, term= %STR(grade 3 or higher TEAE related to Liver, Arrhythmia, and Diarrhea));
%aetable(grpvar=grp_2, COND=%STR(TRTEMFL='Y' AND aeser='Y'), _filename=T_TEAE_sae_oso_us, term= %STR(serious TEAE related to Liver, Arrhythmia, and Diarrhea));

/**** Separate Table for the 2 remaining AESIs) ***;*/
/*%aetable(grpvar=grp_2, COND=%STR(TRTEMFL='Y' AND (cq02nam ^='' or cq03nam ^='')), _filename=T_TEAE_plvd_eoiPT, term= %STR(TEAE of special interest));*/
