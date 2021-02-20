/*********************************************************************    
***  Study Name: BGB3111_1002                                                        
***  Program: m_t_ae_maxgrd.sas                                             
***  Programmer: tingting.zeng
***  Date: 10DEC2017                                                    
***                                                                  
***  Description: Macro to generate multiple AE tables 
        - Multiple AE tables by System Organ Class, Preferred Term, and Maximum Severity 
        - Multiple AE tables (TEAE of Special Interest) by Category, Preferred Term, and Maximum Severity 

***                                                                  
*********************************************************************
***  MODIFICATIONS: Add the option (SMQCQ_COUNTDES) for specific sort order for AESI tables                                                
***  Programmer: Tingting Zeng                                                      
***  Date: 28Feb2019                                                                
***  Reason: AESI categoried may not be sorted by alphabetics for some sub-categories
***				Use the order of SMQ/CQ in grp_term_selection parameters 
***    
***  MODIFICATIONS: Add the parameter tflstyle_btm                                           
***  Programmer: Tingting Zeng                                                      
***  Date: 04Mar2019                                                                
***  Reason: Per new TFL reporting macros, add new parameter to increase margins for footnotes 
***    
*********************************************************************/  


%macro m_t_ae_maxgrd(
  population_from   =adsl
 ,population_where  =%str(SAFFL='Y' )
 ,observation_from  =adae
 ,observation_where =%str(TRTEMFL="Y")
 ,therapy_des_var   =trt01a
 ,therapy_cd_var    =
 ,aetrt_des_var     =trt01a
 ,aetrt_cd_var      =
 ,subgroup_des_var  =_CANTYP
 ,subgroup_cd_var=

 ,ae_term_selection =aedecod
 ,ae_term_label     =%nrbquote(Preferred Term)
 ,grp_term_selection=aebodsys
 ,grp_term_label    =%nrbquote(System Organ Class)
 ,ae_grade_selection=%str(atoxgr^atoxgrn)
 ,ae_grade_label    =%nrbquote(Maximum Severity)
 ,ae_grade_frame    =
 ,display_soc_grpval=Y 
 ,display_term      =Y
 ,sort_order        =ALPHA
 ,sort_column       =

 ,display_totals    =
 ,display_totals_select_grps=
 ,display_totals_subgroup= Y
 ,display_with_rows =Y
 ,with_withno_row_label=%nrbquote(Patients with at least one adverse event)

 ,percent_incidence =0
 ,create_output_dataset=Y
 ,rel_col_widths    =
 ,page_orientation  =p
 ,therapy_per_page=8
 ,output_lib    =&tables
 ,support_listing_lib=
 ,rename_output     =t_ae_maxgrd
 ,decimal_places_percent=1 
 ,font_size=regular
 ,tflstyle_btm   = 1
 ,debug          = N
);
  

/*---------------------------------------------------------------------------------
 
Macro Parameters:
   Parameter Name                Description

 population_from            | Input dataset name for population.                                | Default = adam.adsl          
 population_where           | valid SAS where statement to subset population_from.              | Default = null.  
 observation_from           | Input dataset name for observation.                               | Default = adam.adae          
 observation_where          | valid SAS where statement to subset observation_from.             | Default = null.                     
 therapy_des_var            | variable name for treatment group description. For 
                              cross-over trial, using trt01a| trt02a.                           | Default=trt01a               
 therapy_cd_var             | variable name for treatment group code . 
                              For cross-over trial, using trt01an| trt02an.                     | Default=&therapy_des_var.n               
 aetrt_des_var              | variable name for treatment group code in observation_from.       | Default=trta                   
 aetrt_cd_var               | variable name for treatment group code in observation_from.       | Default=&aetrt_des_var.n
 subgroup_des_var             | variable name for subgroup description in population_from 
                                & observation_from.                                             | Default=null.
 subgroup_cd_var              | variable name for subgroup group code in population_from 
                                & observation_from.                                             | Default=null.
 ae_term_selection          | The variable in the AE dataset that is used to display the term.  | Default=aedecod
 grp_term_selection         | The variable in the AE dataset that is used to group the term     | Default=aebodsys
 ae_term_label              | Text string displayed in the header for the ae_term_selection     | Default=Preferred Term
 grp_term_label             | Text string displayed in the header for the grp_term_selection    | Default=System Organ Class
 ae_grade_selection         | The variables in the AE dataset that is used to display the 
                                toxicity or severity grade (charater and sort variable split by ^
                                                                                                | Default=ATOXGR^ATOXGRN
 ae_grade_label             | Text string displayed in the header for the ae_grade_selection    | Default=Maximum Severity

 
 display_term               | Display the Term rows                                             | Default= Y
 display_soc_grpval         | Display the grouping values                                       | Default=Y 
 sort_order                 | Sorting order, based on Alphabetics or descending frequency       | Default=ALPHA
                              Valid value: ALPHA, COUNTDES, ALPHA_COUNTDES, SMQCQ_COUNTDES
 sort_column                | Character treatment value used to sort the Table with             | Default = null
                              If there's sort layer based on multiple columns, use "|" to separate treatment value
 display_totals             | if display total column. Y or N.                                  | Default=N                          
 display_totals_select_grps | Display totals for selected treatment groups. List 
                              therapy_cd_var values such as %str(1 2 3|Total).
                              The values listed after "|" is the wording for this 
                              column header.                                                    | Default=null.
 display_totals_subgroup      | if display total culumn for subgroup. Y or N                        | Default=N
 display_with_rows          | Display the rows for 'Patients with at least one TEAE'            | Default = N                

 with_withno_row_label      | Used to override the standard row labels that appear on counts tables that shows 
                              the number of 'Patients with at least one TEAE'.  
                              If no value is specified then the standard row label is used.  
                                                                                                  | Default = Patients with at least one adverse event
 percent_incidence          | Rows where at least one therapy group has a percent incidence greater than or equal to the value specified 
                              are displayed.   Valid values are decimal values between 0 and 100.  The values may contain up to 1 digit 
                              after the decimal.Examples: 0 10 15.5 This parameter is only used if parameter reduction_method_2 is percent.
                              default= 0


 create_output_dataset      | Y or N.                                                            | Default=Y      
 rel_col_widths             | relative column width. This parameter is used to control the 
                              column widths of reports.                       
                                The parameter requires integers be entered separated by space.   | Default=null.
 support_listing_lib        | library name for supporting listing.                               | Default=null 
 rename_output              | rtf file name without extension.                                   | Default=t_ae.            
 output_lib                 | library name reference for output tables.                          | Default=&tables                 
 page_orientation           | Controls page orientation of table.  Valid values are L (Landscape) and P (Portrait)    | Default=P                    
 therapy_per_page           | The number of therapy group columns that are to be displayed on the page.               | Default=8   
 decimal_places_percent     | number of decimal place for percentage                             | Default=1   
 font_size                  | font size used in macro m_tflprep, 'regular' or small              | Default=regular
 debug                      | debug parameter. Valid values are Y. N,                
                               N: delete temporary dataset.
                               Y: keep temporary dataset.                     


---------------------------------------------------------------------------------*/

%m_tflstyle(btm=&tflstyle_btm.);  ** Standard call for standard report **;

%********** check variables exist or not *************;
%macro VarExist(ds=, var=);
  %local rc dsid result;
  %let dsid=%sysfunc(open(&ds));
  %if %sysfunc(varnum(&dsid, &var))>0 %then %do;
    %let result=1;
  %end;
  %else %do;
    %let result=0;
  %end;
  %let rc=%sysfunc(close(&dsid));
  &result
%mend;

%*----------------------------------------------------------------------------------*;
%*- Step 01: Define macro parameters and set up default values, bullet proof         ;                 
%*----------------------------------------------------------------------------------*;
%*** SAS options  - examples ***;

%let err1 = ERR;
%let err2 = OR;
%let war1 = WAR;
%let war2 = NING;

%*** set up default parameter values if the value is not entered;
%if %nrbquote(&population_from)= %nrbquote( )   %then %let population_from  =  %str(adam.adsl);
%if %nrbquote(&observation_from)= %nrbquote( )  %then %let observation_from  =  %str(adam.adae);
%if %nrbquote(&therapy_des_var)= %nrbquote( )   %then %let therapy_des_var  =  %str(trt01a);
%if %nrbquote(&therapy_cd_var)= %nrbquote( )   %then %let therapy_cd_var  =  %str(&therapy_des_var.n);
%if %nrbquote(&aetrt_des_var)= %nrbquote( )   %then %let aetrt_des_var  =  %str(trta);
%if %nrbquote(&aetrt_cd_var)= %nrbquote( )   %then %let aetrt_cd_var  =  %str(&aetrt_des_var.n);
%if %nrbquote(&subgroup_cd_var)= %nrbquote( ) and %nrbquote(&subgroup_des_var) ne %nrbquote( )   %then %let subgroup_cd_var  =  %str(&subgroup_des_var.n);

%if %nrbquote(&ae_term_selection)= %nrbquote( )   %then %let ae_term_selection  =  %str(aedecod);
%if %nrbquote(&grp_term_selection)= %nrbquote( )   %then %let grp_term_selection  =  %str(aebodsys);
%if %nrbquote(&display_totals)= %nrbquote( )    %then %let display_totals  =  %str(N);
%if %nrbquote(&display_with_rows)= %nrbquote( )    %then %let display_with_rows  =  %str(Y);
%if %nrbquote(&with_withno_row_label)= %nrbquote( ) %then %let with_withno_row_label =%nrbquote(Patients with at least 1 adverse events);

%if %nrbquote(&percent_incidence)= %nrbquote( )    %then %let percent_incidence = %str(0);
%if %nrbquote(&display_soc_grpval)= %nrbquote( )        %then %let display_soc_grpval  =  %str(Y);
%if %nrbquote(&display_term)= %nrbquote( )        %then %let display_term  =  %str(Y);
%if %nrbquote(&sort_order)= %nrbquote( )        %then %let sort_order  =  %str(ALPHA);
%else %let sort_order  =  %qupcase(&sort_order);
%if %nrbquote(&rename_output)= %nrbquote( )    %then %let rename_output  =  %str(t_ae);
%if %nrbquote(&create_output_dataset)= %nrbquote( ) %then %let create_output_dataset  =  %str(Y);
%if %nrbquote(&output_lib)= %nrbquote( )   %then %let output_lib  =  %str(&tables);
%if %nrbquote(&decimal_places_percent)= %nrbquote( ) %then %let decimal_places_percent =1;
%if %nrbquote(&font_size)= %nrbquote( ) %then %let font_size =%str(regular);
%else %let font_size =%qlowcase(&font_size);
%if %nrbquote(&debug)= %nrbquote( ) %then %let debug =%str(N);

%if %nrbquote(&page_orientation)= %nrbquote( ) %then %let page_orientation =%str(P);
%if %qupcase(&page_orientation) eq L %then %let _page_orientation=landscape;
%else %if %qupcase(&page_orientation) eq P %then %let _page_orientation=portrait;
%if %nrbquote(&therapy_per_page)= %nrbquote( ) %then %let therapy_per_page =%str(8);
%if %nrbquote(&tflstyle_btm)= %nrbquote( ) %then %let tflstyle_btm =%str(1);


**Check valid value for ae_grade_selection;
%if %index(&ae_grade_selection, ^) eq 0 %then %do;
       %put ====================Usage for Macro &sysmacroname==========================================;
       %put                                                                                            ;
       %put &err1&err2: (&sysmacroname) For AE_GRADE_SECTION, Character and Numberic variables should be defined (e.g. ATOXGR^ATOXGRN)  ;
       %put &err1&err2: (&sysmacroname) Please fix and resubmit.                                       ;
       %put                                                                                            ;
       %put ====================Usage for Macro &sysmacroname==========================================;
   %goto exit;
%end;
%else %do;
    %let _aegrade_var=%qscan(&ae_grade_selection, 1, %str(^));
    %let _aegrade_sort=%qscan(&ae_grade_selection, 2, %str(^));
%end;



%if %VarExist(ds=&observation_from, var=&_aegrade_var) eq 0 or %VarExist(ds=&observation_from, var=&_aegrade_sort) eq 0
       %then %do;
       %put ====================Usage for Macro &sysmacroname=======================================================;
        %put                                                                                                        ;
        %put&err1&err2: (&sysmacroname) Parameter AE analysis grade variables &_aegrade_var and &_aegrade_sort should be in ADAE. ;
        %put&err1&err2: (&sysmacroname) Please fix and resubmit.                                                    ;
        %put                                                                                                        ;
        %put====================Usage for Macro &sysmacroname=======================================================;
        %goto exit;
%end;



*** check if both soc and aeterm is turned off;
%if %quote(%upcase(&display_soc_grpval)) = %quote(N) and %quote(&display_term) = %quote(N) %then %do;
       %put ====================Usage for Macro &sysmacroname==========================================;
       %put                                                                                            ;
       %put &err1&err2: (&sysmacroname) Either the SOC or the AETERM must be displayed, please turn on ;
       %put &err1&err2: (&sysmacroname) at least one of them.                                          ;
       %put                                                                                            ;
       %put ====================Usage for Macro &sysmacroname==========================================;
   %goto exit;
%end;
%if %length(&population_where)=0 %then %let _population_where=;
%else %let _population_where=%str(and (&population_where));
%if %length(&observation_where)=0 %then %let _observation_where=;
%else %let _observation_where=%str(and (&observation_where));
 
%***********If the Group variable starts 'CQ' or 'SMQ', then Missing values in the grouping variable will be removed*****;
%if %substr(%upcase(&grp_term_selection),1,2) = CQ or %substr(%upcase(&grp_term_selection),1,3) = SMQ %then %let _cqvar = Y;
%else %let _cqvar = N;

%***  parse &grp_term_selection***;
%let _cumt=1;
%let _wod=%qscan(%nrbquote(&grp_term_selection),&_cumt,%str(|));
%do %while(&_wod^=);
    %local _grpvar&_cumt ;
    %let _grpvar&_cumt=%unquote(&_wod);
    %let _cumt=%eval(&_cumt+1);
    %let _wod=%qscan(%nrbquote(&grp_term_selection),&_cumt,%str(|));
%end;
%local _grpvar0;
%let _grpvar0 = %eval(&_cumt-1);
%put macro message: _grpvar0=&_grpvar0 _grpvar1=&_grpvar1;


%***  parse &therapy_des_var  ***;
%let _cumt=1;
%let _wod=%qscan(%nrbquote(&therapy_des_var),&_cumt,%str(|));
%do %while(&_wod^=);
    %local _tdesvar&_cumt ;
    %let _tdesvar&_cumt=%unquote(&_wod);
    %let _cumt=%eval(&_cumt+1);
    %let _wod=%qscan(%nrbquote(&therapy_des_var),&_cumt,%str(|));
%end;
%local _tdesvar0;
%let _tdesvar0 = %eval(&_cumt-1);
%put macro message: _tdesvar0=&_tdesvar0 _tdesvar1=&_tdesvar1;


%***  parse &therapy_cd_var  ***;
%if %nrbquote(&therapy_cd_var) ^= %nrbquote( )  %then %do;
%local _tcdvar0;
%let _cumt=1;
%let _wod=%qscan(%nrbquote(&therapy_cd_var),&_cumt,%str(|));
%do %while(&_wod^=);
    %local _tcdvar&_cumt ;
    %let _tcdvar&_cumt=%unquote(&_wod);
    %let _cumt=%eval(&_cumt+1);
    %let _wod=%qscan(%nrbquote(&therapy_cd_var),&_cumt,%str(|));
%end;
%let _tcdvar0 = %eval(&_cumt-1);
%end;
%else %do;
%let _tcdvar0=&_tdesvar0;
%do _i=1 %to &_tdesvar0;
  %local _tcdvar&_i;
  %let _tcdvar&_i=&&_tdesvar&_i..n;
%end;
%end;
%put macro message: _tcdvar0=&_tcdvar0 _tcdvar1=&_tcdvar1;

%*** parse display_totals_select_grps;
%if %length(&display_totals_select_grps) >0 %then %do;
%let _cumt=1;
%let _wod=%qscan(%nrbquote(&display_totals_select_grps),&_cumt,%str(|));
%do %while(&_wod^=);
    %local _select_grps&_cumt ;
    %let _select_grps&_cumt=%unquote(&_wod);
    %let _cumt=%eval(&_cumt+1);
    %let _wod=%qscan(%nrbquote(&display_totals_select_grps),&_cumt,%str(|));
%end;
%local _select_grps0;
%let _select_grps0 = %eval(&_cumt-1);

%if &_select_grps0 ne 2 %then %do;
       %put ====================Usage for Macro &sysmacroname======================================================;
       %put                                                                                                        ;
       %put &err1&err2: (&sysmacroname) Please specify display_totals_select_grps as "1 2 3 | Total for 5 10 20";
       %put &err1&err2: (&sysmacroname) Please fix and resubmit.                                                   ;
       %put                                                                                                        ;
       %put ====================Usage for Macro &sysmacroname======================================================;
   %goto exit;
%end;
%put macro message: _select_grps0=&_select_grps0 _select_grps1=&_select_grps1 _select_grps2=&_select_grps2;

%*** find out the maximum therapy_cd_var specified by display_totals_select_grps;
data _select_grps_ds;
  _i=1;
  _trtcd=input(scan("&_select_grps1", _i, ' '), best.);
  output;
  do while(_trtcd>.);
    _i=_i+1;
    _trtcd=input(scan("&_select_grps1", _i, ' '), best.);
    if _trtcd>. then output;
  end;
run;

proc sort data=_select_grps_ds;
  by _trtcd;
run;

data _null_;
  set _select_grps_ds;
  by _trtcd;
  if last._trtcd;
  _xtrtcode=_trtcd+0.01;
  call symput("_select_grps_max", strip(put(_xtrtcode, best.)));
run;

%put macro message: _select_grps_max=&_select_grps_max;


%end; %*** END %if %length(&display_totals_select_grps) >0 %then %do;

%let _decimal_places_percent=%eval(&decimal_places_percent+4);
%let _decimal_places_percent=&_decimal_places_percent..&decimal_places_percent;
run;


%*Retrieve the libname and filename for output dataset;
%if %index(&output_lib, %str(tables)) %then %let output_ds=dtables;
%else %if %index(&output_lib, %str(listings)) %then %let output_ds=dlists;
/*libname metadata "&metadata.";*/
/*proc sql noprint;*/
/*    select distinct  tranwrd(tranwrd(rtf_out,".rtf",""),"-","_") into: rtf_output*/
/*    from metadata.tracker*/
/*    where compress(tranwrd(base_output_name,".rtf",""))=compress(tranwrd("&rename_output.",".rtf",""))*/
/*    ;*/
/*quit;*/

%*** parse rel_col_widths;
%if %length(&rel_col_widths) >0 %then %do;
    %let _cumt=1;
    %let _wod=%qscan(%nrbquote(&rel_col_widths),&_cumt,%str( ));
    %do %while(&_wod^=);
        %let _cumt2=%eval(&_cumt-1);
        %local _col_widths&_cumt2 ;
        %let _col_widths&_cumt2=%unquote(&_wod);
        %let _cumt=%eval(&_cumt+1);
        %let _wod=%qscan(%nrbquote(&rel_col_widths),&_cumt,%str( ));
    %end;
    %local _col_width_count;
    %let _col_width_count= &_cumt2;
%end;


 
%*----------------------------------------------------------------------------------*;
%*- Step 02: Retrieve subject population from ADSL using where statement             ;      
%*----------------------------------------------------------------------------------*;


****;
**** Retrieve subject population from ADSL using where statement;
****;
proc sql;
  create table _population_extract  as
  select distinct
         1 as _studyid
        ,a.*
    from
         &population_from as a
   where
         1 
         &_population_where
       ;
quit;

%if "&sqlobs"="0" %then %let _data_to_report=N;
%else %let _data_to_report=Y;
%if %qupcase(&_data_to_report)=%quote(N) %then %goto no_data_to_report;
%put macro message: _data_to_report=&_data_to_report;

%*****For cross-over studies, create a record for each treatment group*****;
%if %VarExist(ds=_population_extract, var=&therapy_cd_var)>0 %then %do;
data _population_extract1;
  set _population_extract;
  length decode_1 $200;
    %do _ia=1 %to &_tcdvar0;
/*      if &&_tcdvar&_ia>. then do;*/
        decode_1=strip(&&_tdesvar&_ia);        
        coded_1=&&_tcdvar&_ia;    
        if decode_1="" then decode_1="Unknown";
        if coded_1=. then coded_1=99;    
        output;
/*      end;*/
    %end;
run;
%end;
%else %do;
data _population_extract;
  set _population_extract;
  length decode_1 $200;
    %do _ia=1 %to &_tcdvar0;
/*      if &&_tdesvar&_ia^="" then do;*/
        decode_1=strip(&&_tdesvar&_ia);
        if decode_1="" then decode_1="Unknown";
        output;
/*      end;*/
    %end;
run;
proc sql noprint;
    create table _unidecode
    as select distinct decode_1
    from _population_extract
    where decode_1^="";
quit;
data _unidecode;
    set _unidecode;
    coded_1=_n_;
run;
proc sql noprint;
    create table  _population_extract1
    as select l.*, r.coded_1
    from  _population_extract as l left join _unidecode as r
    on strip(l.&therapy_des_var)=strip(r.decode_1);
quit;

%end;


%if %length(&subgroup_des_var)>0 %then %do;
data _population_extract1a;
  set _population_extract1;
  length decode_2 $200;  
  decode_2=strip(&subgroup_des_var);
  if decode_2="" then decode_2="Unknown";
run;

%if %VarExist(ds=_population_extract, var=&subgroup_cd_var)>0 %then %do;
    data _population_extract1;
      set _population_extract1a;
      coded_2=&subgroup_cd_var;
      if decode_2="Unknown" then coded_2=99;
    run;
%end;
%else %do;
    proc sql noprint;
        create table _unisubgrp
        as select distinct decode_2 
        from _population_extract1a
        where decode_2^="";
    quit;
    data _unisubgrp;
        set _unisubgrp;
        coded_2=_n_;
    run;
    proc sql noprint;
        create table  _population_extract1
        as select l.*, r.coded_2
        from  _population_extract1a as l left join _unisubgrp as r
        on strip(l.&subgroup_des_var)=strip(r.decode_2);
    quit;
%end;
%end;%*** end %length(&subgroup_des_var)>0;
 
****;
**** find maximum of treatment groups in _population_extract;
****;
proc sql noprint;
  select compress(put(count(distinct coded_1),best.)) into: _trt_grps_max
  from _population_extract1
  where coded_1^=.;
quit;
%put macro message: _trt_grps_max=&_trt_grps_max;

%*-----------------------------------------------------------------------------------------------------*;
%*- Step 03: manipulate population data to add overall total and totals for select groups if applicable;                 
%*-----------------------------------------------------------------------------------------------------*;
****;
**** manipulate population data to add overall total and totals for select groups if applicable ;
****;
data _population_extract2;
  set _population_extract1;
  where coded_1>.;
run;

%if %qupcase(&display_totals)=%quote(Y) %then %do;
data _population_extract2;
  set _population_extract1;
  where coded_1>.;
  output;
  coded_1=999;
  decode_1="Total";
  output;
run;
%end;

%if %nrbquote(&display_totals_select_grps)^= %nrbquote( ) %then %do;
data _population_extract2;
  set _population_extract2;
  output;
  if coded_1 in (&_select_grps1) then do;
    coded_1=&_select_grps_max;
    decode_1="&_select_grps2";
    output;
  end;
run;
%end;


%if %length(&subgroup_des_var)>0 %then %do;
%if %qupcase(&display_totals_subgroup)=%quote(Y) %then %do;
data _population_extract2;
  set _population_extract2;
  output;
  coded_2=999;
  decode_2='Total';
  output;
run;
%end;

data _population_extract2(drop=_coded_1 _decode_1 coded_2 decode_2);
  set _population_extract2(rename=(coded_1=_coded_1 decode_1=_decode_1));
  length decode_1 $200.;
  coded_1=_coded_1*1000+coded_2;
  decode_1=strip(_decode_1)||'^'||strip(decode_2);
run;
%end;

%*** pull treatment information from _population_extract;
proc sort data=_population_extract2 out=_uniquetrt(keep=coded_1 decode_1) nodupkey;
  by coded_1;
run;

data _uniquetrt;
  set _uniquetrt end=eof;
  if eof then call symput('notrt', strip(put(_n_, best.)));
  _trtcd=_n_;
run;
%put notrt=&notrt;

%do _ia=1 %to &notrt;
  %local _trtcd&_ia _trtdcd&_ia;  
%end;

data _null_;
  set _uniquetrt end=eof;
  call symput("_trtcd"||strip(put(_n_, best.)), strip(put(coded_1, best.)));
  call symput("_trtdcd"||strip(put(_n_, best.)), strip(decode_1));
run;

%put macro message: notrt=&notrt;

%let _trt0str=;
%do _ia=1 %to &notrt;
  %let _trt0str=&_trt0str &&_trtcd&_ia;
%put &_ia _trt0str=&_trt0str;
%end;
%put macro message: _trtcd1=&_trtcd1 _trtdcd1=&_trtdcd1 _trt0str=&_trt0str;


%if %index(%qupcase(&sort_order),COUNTDES) %then %do; 
%***  parse &grp_term_selection***;
%if %length(&sort_column) >0 %then %do;
    %let _cumt=1;
    %let _wod=%qscan(%nrbquote(&sort_column),&_cumt,%str(|));
    %do %while(&_wod^=);
        %local _sort_column&_cumt ;
        %let _sort_column&_cumt=%unquote(&_wod);
        %let _cumt=%eval(&_cumt+1);
        %let _wod=%qscan(%nrbquote(&sort_column),&_cumt,%str(|));
    %end;
    %local _sort_column_count;
    %let _sort_column_count= &_cumt-1;
%end;

%do _i=1 %to &_sort_column_count;
    %let svar&_i =0;

    data _uniquetrtc;
      set _uniquetrt;
      _flg = _n_;
    run;

    proc sql noprint;
       select _flg into:svar&_i from _uniquetrtc
       where decode_1 = "&&_sort_column&_i..";
    quit;

    *** check valid value for sort_column;
    %if %nrbquote(&&svar&_i) = %nrbquote(0)  %then %do;
           %put ====================Usage for Macro &sysmacroname==========================================;
           %put                                                                                            ;
           %put &err1&err2: (&sysmacroname) Value of  sort_Column should match one of the values of therapy_des_vars;
           %put &err1&err2: (&sysmacroname) Spacing and case should match. Please fix and resubmit.        ;
           %put                                                                                            ;
           %put ====================Usage for Macro &sysmacroname==========================================;
       %goto exit;
    %end;

    %put svar&_i = &&svar&_i..;
%end;

%end;





%*---------------------------------------------------------------------------------------*;
%*- Step 04: Retrieve analysis observation from "&_population_where" using where statement;                   
%*---------------------------------------------------------------------------------------*;
****;
**** Retrieve analysis observation from "&_population_where" using where statement;
****;
proc sql;
  create table _observation_extract as
  select 1 as _studyid
        ,a.*
    from 
         &observation_from a
   where 
         1 
         &_population_where &_observation_where
         ;
quit;


%if %VarExist(ds=_observation_extract, var=&aetrt_cd_var)>0 %then %do;
data _observation_extract1;
  set _observation_extract;
  length decode_1 $200;
  decode_1=strip(&aetrt_des_var);
  coded_1=&aetrt_cd_var;
run;
%end;
%else %do;
proc sql noprint;
    create table _unidecode
    as select distinct decode_1, coded_1
    from _population_extract1
    where decode_1^="";
quit;
proc sql noprint;
    create table  _observation_extract1
    as select l.*, r.decode_1, r.coded_1
    from  _observation_extract as l left join _unidecode as r
    on strip(l.&aetrt_des_var)=strip(r.decode_1);
quit;

%end;


%if %length(&subgroup_des_var)>0 %then %do;
%if %VarExist(ds=_observation_extract, var=&subgroup_des_var)>0 %then %do;
data _observation_extract1a;
  set _observation_extract1;
  length decode_2 $200;  
  decode_2=strip(&subgroup_des_var);
  if decode_2="" then decode_2="Unknown";
run;

    %if %VarExist(ds=_observation_extract, var=&subgroup_cd_var)>0 %then %do;
        data _observation_extract1;
          set _observation_extract1a;
          coded_2=&subgroup_cd_var;
          if decode_2="Unknown" then coded_2=99;
        run;
    %end;
    %else %do;
        proc sql noprint;
            create table _unisubgrp
            as select distinct decode_2, coded_2 
            from _population_extract1
            where decode_2^="";
        quit;
        proc sql noprint;
            create table  _observation_extract1
            as select l.*, r.coded_2
            from  _observation_extract1a as l left join _unisubgrp as r
            on strip(l.&subgroup_des_var)=strip(r.decode_2);
        quit;
    %end;
%end;
%else %do;
    proc sort data=_observation_extract1 out=_observation_extract1a;
        by usubjid;
    run;
    proc sort data=_population_extract1;
        by usubjid;
    run;
    data _observation_extract1;
        merge _observation_extract1a(in=a) _population_extract1(keep=usubjid decode_2 coded_2);
        by usubjid;
        if a;
    run;
%end;
%end;%*** end %length(&subgroup_des_var)>0;

%****;
%**** manipulate observation data to add overall total and totals for select groups if applicable ;
%****;
data _data_for_counting2;
  set _observation_extract1;
  where coded_1>.;
run;

%*** check if user select population and observation period consistently;
proc sql;
  create table _observation_extract_trt
  as select distinct usubjid, coded_1
  from _data_for_counting2
  order by usubjid, coded_1
  ;
  create table _population_extract1_trt
  as select distinct usubjid, coded_1
  from _population_extract1
  order by usubjid, coded_1
  ;
quit;

data _pop_obs_extract_diff;
  merge _population_extract1_trt(in=a) _observation_extract_trt(in=b);
  by usubjid coded_1;
  if b and not a;
run;

%let _trtdiff=0;
data _null_;
  set _pop_obs_extract_diff end=eof;
  if eof then call symput("_trtdiff", strip(put(_n_, best.))); 
run;
%put macro message: _trtdiff=&_trtdiff;
%if "&_trtdiff"> "0" %then %do;
       %put ====================Usage for Macro &sysmacroname==================================;
       %put                                                                                    ;
       %put &war1&war2: (&sysmacroname) There are treatment group values in ADAE not in ADSL   ;
       %put &war1&war2: (&sysmacroname) for some subjects. Please make sure observation_where  ;
       %put &war1&war2: (&sysmacroname) and therapy_des_var parameters are selected correctly. ;
       %put                                                                                    ;
       %put ====================Usage for Macro &sysmacroname==================================;
%end;


%if %qupcase(&display_totals)=%quote(Y) %then %do;
data _data_for_counting2;
  set _observation_extract1;
  where coded_1>.;
  output;
  coded_1=999;
  decode_1="Total";
  output;
run;
%end;

%if %nrbquote(&display_totals_select_grps)^= %nrbquote( ) %then %do;
data _data_for_counting2;
  set _data_for_counting2;
  output;
  if coded_1 in (&_select_grps1) then do;
    coded_1=&_select_grps_max;
    decode_1="&_select_grps2";
    output;
  end;
run;
%end;


%if %length(&subgroup_des_var)>0 %then %do;
%if %qupcase(&display_totals_subgroup)=%quote(Y) %then %do;
data _data_for_counting2;
  set _data_for_counting2;
  output;
  coded_2=999;
  decode_2='Total';
  output;
run;
%end;
data _data_for_counting2(drop=_coded_1 _decode_1 coded_2 decode_2);
  set _data_for_counting2(rename=(coded_1=_coded_1 decode_1=_decode_1));
  length decode_1 $200.;
  coded_1=_coded_1*1000+coded_2;
  decode_1=strip(_decode_1)||'^'||strip(decode_2);
run;
%end;
%*** pull treatment infor from _data_for_counting2;
proc sql;
  create table _uniquetrt0ae as
  select distinct coded_1, 
         decode_1 as decode_1_ae
  from _data_for_counting2
  order by coded_1
;
quit;

data _uniquetrt0chk_err1;
  merge _uniquetrt(in=a) _uniquetrt0ae(in=b);
  by coded_1;
  if a and b and decode_1 ne decode_1_ae;
run;

%let _trtchkerr=0;
data _null_;
  set _uniquetrt0chk_err1 end=eof;
  if eof then call symput("_trtchkerr", compress(put(_n_, best.)));
run;

%put _trtchkerr=&_trtchkerr;
%if "&_trtchkerr"> "0" %then %do;
       %put ====================Usage for Macro &sysmacroname============================;
       %put                                                                              ;
       %put &err1&err2: (&sysmacroname) Some treatment description in ADSL are different ;
       %put &err1&err2: (&sysmacroname) from ADAE with same treatment code.              ;
       %put &err1&err2: (&sysmacroname) Please fix and resubmit.                         ;
       %put                                                                              ;
       %put ====================Usage for Macro &sysmacroname============================;
   %goto exit;
%end;

data _uniquetrt0chk_note1;
  merge _uniquetrt(in=a) _uniquetrt0ae(in=b);
  by coded_1;
  if not (a and b);
run;

%let _trtchknote=0; 
data _null_;
  set _uniquetrt0chk_note1 end=eof;
  if eof then call symput("_trtchknote", compress(put(_n_, best.)));
run;
%put macro message: _trtchknote=&_trtchknote;

%if "&_trtchknote"> "0" %then %do;
       %put ====================Usage for Macro &sysmacroname=======================================;
       %put                                                                                         ;
       %put Note: (&sysmacroname) Some treatments are not in both ADSL and ADAE. This may           ;
       %put Note: (&sysmacroname) or may not be issue. Please check value of teartment variables.   ;
       %put                                                                                         ;
       %put ====================Usage for Macro &sysmacroname=======================================;
%end;


%*----------------------------------------------------------------------------------*;
%*- Step 06: Duplicate data_for_counting for all cases;                  
%*----------------------------------------------------------------------------------*;
****;
**** Duplicate data_for_counting for all CQzzNAM variables;
****;

data _data_for_counting3;
  set _data_for_counting2;
  length _bodysmq _aeterm $200;
  _aeterm=strip(&ae_term_selection);
  if _aeterm = "" then _aeterm = 'ZZZNull: '||strip(propcase(aeterm,'@'));
  %do _ic=1 %to &_grpvar0;
     _bodysmq=strip(&&_grpvar&_ic);
	 _bodysmqn=&_ic.;
     output;
 %end;
run;


%*--------------------------------------------------------------------------------*;
%*- Step 07: Determine the Maximum Intenstity for the subject for overall,       -*;
%*           by AE Term Group and AE term.                                       -*;
%*--------------------------------------------------------------------------------*;
 
%*--------------------------------------------------------------------------------------*;
%* - If AE Term Group  or TERM_SELECTED is blank set so it displays NULL in the report. *;  
%*     Note: I set it to zzNULL temporarily so they will sort last.                     *; 
%* - If aegrade is blank set so it displays UNKNOWN in the report.                        *;
%* - Set variable aegrade_rating so we can identify the AE with the                       *;
%*   maximum grade.                                                                 *;
%* - If there is an AE Grade value that is not one of the expected give an err0r.          *;
%*--------------------------------------------------------------------------------------*;

data _data_for_counting3;
  set _data_for_counting3;

  %if "&_cqvar" = "Y" %then %do; 
      if compress(_bodysmq)="" then delete; 
  %end;
  %else %if "&_cqvar" ~= "Y" %then %do; 
      if compress(_bodysmq)="" then _bodysmq="ZZZNull";
  %end;

  aegrade_rating=&_aegrade_sort;
  aegrade_c=strip(&_aegrade_var);

  if upcase(compress(aegrade_c)) eq ("") then aegrade_rating=aegrade_rating-800; 

run;

   %* Determine for each subject their maximum aegrade value.             *;
   %* This is used to generate the the With One or More AEs count rows. *;
proc sql;
  create table _ae1_max_aegrade_by_subject as
      select _studyid, usubjid, coded_1, max(aegrade_rating) as max_aegrade_rating
      from _data_for_counting3
      group by coded_1, usubjid;
quit;

   %* Determine for each subject the maximum aegrade value by body system.  *;
   %* This is used to generate the Body System count rows.                *;
proc sql;
  create table _ae2_max_aegrade_by_aebodsys as
      select _studyid, usubjid, coded_1, _bodysmq, max(aegrade_rating) as max_aegrade_rating
      from _data_for_counting3
      group by coded_1, usubjid, _bodysmq;
quit;

   %* Determine for each subject the maximum aegrade value by aeterm. *;
   %* This is used to generate the AE Term count rows.              *;
proc sql;
  create table _ae3_max_aegrade_by_aeterm as
      select _studyid, usubjid, coded_1, _bodysmq, _aeterm, max(aegrade_rating) as max_aegrade_rating
      from _data_for_counting3
      group by coded_1,usubjid, _bodysmq, _aeterm;
quit;

   %* Create one dataset that contains all the rows needed to generate the *;
   %* AE counts.                                                           *;
data _ae4_max_aegrade_ratings;
  set _ae1_max_aegrade_by_subject (in=inSubject)
      _ae2_max_aegrade_by_aebodsys (in=inAebodsys)
      _ae3_max_aegrade_by_aeterm (in=inAeTerm);
  length rec_type $10;

  if inSubject then rec_type="WITHCNT";
  else if inAeBodsys then rec_type="BODSYSCNT";
  else if inAeTerm then rec_type="AETERMCNT";
run;

   %* Creates a list of the aegrade values.  I will use this to merge *;
   %* in the aegrade term, based on the aegrade_rating                  *;
proc sql;
  create table _aegrade_rating_list as
     select distinct aegrade_rating, aegrade_c
     from _data_for_counting3;
quit;

   %* Merge in the aegrade value to displays as well as the display order *;
proc sql;
  create table _ae5_max_aegrade_ratings as
     select a._studyid, a.usubjid, a.coded_1, a._bodysmq, a._aeterm, 
            a.max_aegrade_rating, a.rec_type,
            b.aegrade_c
     from _ae4_max_aegrade_ratings a,
          _aegrade_rating_list b
     where a.max_aegrade_rating=b.aegrade_rating;
quit;


%*--------------------------------------------------------------------------------*;
%*- Step 08: Create the support dataset.  This is used to generate all counts    -*;
%*           and produce the support listing.                                    -*;
%*--------------------------------------------------------------------------------*;

proc sort data=_ae5_max_aegrade_ratings;
  by _bodysmq _aeterm;
run;

data _data_for_counting4;
  set _ae5_max_aegrade_ratings;
  by _bodysmq _aeterm;
  if upcase(compress(aegrade_c)) eq "" then do;
    max_aegrade_rating=sum(max_aegrade_rating,9999); 
    aegrade_c="Missing";
  end;
run;


data _data_for_counting5;
  set _data_for_counting4;
  length _col $200.;
  if _bodysmq="" and _aeterm="" then do;
      _col="&with_withno_row_label.";
	_bodysmqn=-888;
    _bodysmq="0Any AE Bodysys"; 
    _aeterm="0Any AE Term"; 
  end;

  else if _bodysmq~="" and _aeterm="" then do;
    _col=_bodysmq; 
    _aeterm="0Any AE Term";
  end;

  if _bodysmq~="" and _aeterm~="" then do;
    _col=_aeterm; 
  end;

  output;

  max_aegrade_rating=-999;
  aegrade_c="0Any AE Grade";
  output;
run;

%******create a dataset to generate Support Listing,********************************************; 
%*******by combining all the datasets that goes into calcultion*******************************;
%*******Output will include all the Events, duplicates will not removed*************************;

data support;
  length _col $200;
  set _population_extract2(in=b) _data_for_counting5 ;
  if coded_1 ne 999; %***Remove the records that belongs to 'Total' group****;
  if b then do;
     _col="Subjects in Population";
     ord = 1;
  end;
  else do;
       _col = strip(_bodysmq);
       ord=3;
  end;
run;


%*----------------------------------------------------------------------------------*;
%*- Step 09: Count Denominator            ;             
%*----------------------------------------------------------------------------------*;

proc sql noprint;
    create table _n01_denomds0
    as select distinct _studyid, coded_1, count(distinct usubjid) as denom
    from _population_extract2
    group by _studyid, coded_1;

    create table _n01_denomds1
    as select distinct l.*, r._trtcd
    from _n01_denomds0 as l full join _uniquetrt as r
    on l.coded_1=r.coded_1
    order by _studyid;
quit;

proc transpose data=_n01_denomds1 out=_n01_denomds prefix=denom;
    by _studyid;
    var denom;
    id _trtcd;
run;


%*----------------------------------------------------------------------------------*;
%*- Step 07: Count numerator for all cases               
%*----------------------------------------------------------------------------------*;
 
***** with various adverse events, Body system and Preferred Term ***** ;                                        
proc sql noprint;
    create table _n02_bods0
    as select distinct _studyid, _bodysmqn, _bodysmq, _aeterm, max_aegrade_rating, aegrade_c, coded_1, count(distinct usubjid) as tot
    from _data_for_counting5 
    group by _studyid, _bodysmqn, _bodysmq, _aeterm, max_aegrade_rating, aegrade_c, coded_1
    ;
quit;

proc sql noprint;
    create table _n02_bods1
    as select distinct l.*, r._trtcd
    from _n02_bods0 as l left join _uniquetrt as r
    on l.coded_1=r.coded_1
    order by _studyid, _bodysmqn, _bodysmq, _aeterm;
quit;

proc transpose data=_n02_bods1 out=_n02_bods2 prefix=tot;
    by _studyid _bodysmqn _bodysmq _aeterm max_aegrade_rating aegrade_c;
    var tot;
    id _trtcd;
run;



%*----------------------------------------------------------------------------------*;
%*- Step 08: Create the Frame and sorting for output dataset                  
%*----------------------------------------------------------------------------------*; 
data _frameds;
  length _col1 $200;
  lnbreak = 1;
  _col1="&with_withno_row_label"; 
  seq=20; 
  output;      
run;

%if %length(&ae_grade_frame) ne 0 %then %do;
    proc sql noprint;
        create table _frameds2
        as select distinct l._bodysmq, l._aeterm, r.&_aegrade_sort as max_aegrade_rating, r.&_aegrade_var as aegrade_c,
            case
                when _bodysmq = "0Any AE Bodysys" then 20
                  when _aeterm='0Any AE Term' then 40
                  else 50 
            end as seq
        from _n02_bods2 as l, &ae_grade_frame as r
        order by seq, _bodysmq, _aeterm, max_aegrade_rating;
    quit;

%end;
data _totaeds;
  set _n02_bods2 ;

  if _bodysmq = "0Any AE Bodysys" then seq=20;
  else if _aeterm='0Any AE Term' then seq=40;
  else seq=50;
run;

proc sort data=_totaeds;
  by seq _bodysmq _aeterm max_aegrade_rating;
run;

%*----------------------------------------------------------------------------------*;
%*- Remove the non display rows optionally                                           ;                 
%*----------------------------------------------------------------------------------*; 

data _totaeds1;
  merge _totaeds(in=a) _frameds(in=b);
  by seq;
 
run;

%if %length(&ae_grade_frame) ne 0 %then %do;
data _totaeds1;
    merge _totaeds1 _frameds2;
    by seq _bodysmq _aeterm max_aegrade_rating;
run;
%end;

data _totaeds1;
  set _totaeds1;
  %*******Set the line break for the report*******;
  if seq in (10,20,30) then lnbreak = 1;
  else lnbreak = 2;

  if upcase("&display_with_rows") = "N" then do;
    if seq in (20,30) then delete;
  end;
  %*****Delete the rows for Missing CQzzNAM values*************************;
  %*******If any other variable is used missing values will be displayed****;
  %if "&_cqvar" = "Y" %then %do; 
      if seq in (40,50) and compress(_bodysmq) in ("","ZZZNull") then delete; 
  %end;
run;

%*----------------------------------------------------------------------------------*;
%*- Step 10: Calculate percentage                                                    ;                
%*----------------------------------------------------------------------------------*; 

data _totaeds2;
  if _n_=1 then set _n01_denomds(keep=denom1-denom&notrt); 
  set _totaeds1;
  length ctot1-ctot&notrt cpct1-cpct&notrt _col1 $200;
  array cont{*} tot1-tot&notrt;
  array dnom{*} denom1-denom&notrt;
  array pct{*} pct1-pct&notrt;
  array contp{*} $ cpct1-cpct&notrt;
  array contt{*} $ ctot1-ctot&notrt;
  do i=1 to &notrt;
    if cont{i}=. then cont{i}=0;
    if dnom{i}=0 then pct{i}=0;
    else pct{i}= cont{i}/dnom{i}*100; 

    if cont{i}>9999 then put "&war1.&war2.: Lengthen the w.d. format for study specific";
    contt{i}=put(cont{i}, 4.0);
    if seq ne 10 then contp{i}=put(cont{i}, 4.0)||' (' || strip(put(pct{i}, &_decimal_places_percent))||')';
  end;  
  if aegrade_c="0Any AE Grade" then do;
        if _bodysmq = "0Any AE Bodysys" then _col1=_col1;
      else if _aeterm="0Any AE Term" then _col1 =  trim(_bodysmq);
      else _col1 = "&ods_indent3." || trim(_aeterm);
	  if index(_bodysmq,'&ods_indent3.') or index(_bodysmq,"&ods_indent3.") then _col1=tranwrd(_col1,"&ods_indent3.","&ods_indent5.");
  end;
  else do;
      if _bodysmq = "0Any AE Bodysys" then delete;
    else _col1 = "&ods_indent5." || trim(aegrade_c); 
	if index(_bodysmq,'&ods_indent3.') or index(_bodysmq,"&ods_indent3.") then _col1=tranwrd(_col1,"&ods_indent5.","&ods_indent7.");
  end;


  drop i ;
run;

proc sort data=_totaeds2;
  by seq _bodysmq _aeterm max_aegrade_rating;
run;
%*----------------------------------------------------------------------------------*;
%*- Step 11: Keep the Rows that satisfies the incidence count based on reduction method ;                 
%*----------------------------------------------------------------------------------*; 


data _totaeds3;
  set _totaeds2;
  by seq _bodysmq _aeterm max_aegrade_rating;
  retain maxpct flg;
     if seq in (40,50,60) and first._aeterm then do;
         flg=0;
         maxpct=round(max(of pct:),10**(%eval(0-&decimal_places_percent)));
            if maxpct >= &percent_incidence and flg ne 1 then do;
                 flg = 1;
            end;
     end;
  if seq in (10,20,30) or flg=1 then output;
run;

proc sort data=_totaeds3;
  by lnbreak _bodysmq _aeterm max_aegrade_rating;
run;

data _totaeds4;
  set _totaeds3;
  by lnbreak _bodysmq _aeterm max_aegrade_rating;
  order=seq;

  %if %index(%qupcase(&sort_order), COUNTDES) %then %do; 
      %do _i=1 %to &_sort_column_count;
      retain grptot%eval(&&svar&_i) termtot%eval(&&svar&_i);

      if seq not in (10,20,30) then do;
          if strip(_aeterm)='0Any AE Term' and strip(aegrade_c)='0Any AE Grade' then grptot%eval(&&svar&_i)=tot%eval(&&svar&_i);
          if strip(aegrade_c)='0Any AE Grade' then termtot%eval(&&svar&_i)=tot%eval(&&svar&_i);
      end;
    %end;
  %end;

  %***Depending on &display_soc_grpval and display_term choose what you need to display***;
  if "&sort_order" = "ALPHA" then do;
      if upcase("&display_soc_grpval") = "Y" and upcase("&display_term") = "Y"  then do;
          if seq in (40,50) then order=40;
          else order=seq;
          output;
      end; 
      else if upcase("&display_soc_grpval") = "Y" then do;
          order = seq;
         if seq in (10,20,30,40) then output;
      end; 
      else if upcase("&display_term") = "Y" then do;
         order = seq;
         if seq in (10,20,30,50) then output;
      end;    
  end;

  else if index("&sort_order", "COUNTDES") then do;
  if upcase("&display_soc_grpval") = "Y" and upcase("&display_term") = "Y"  then do;
      if seq in (40,50) then order=40;
      else order=seq;
    output;
  end; 
  else if upcase("&display_soc_grpval") = "Y" then do;
     order = seq;
     if seq in (10,20,30,40) then output;
  end; 
  else if upcase("&display_term") = "Y" then do;
     order = seq;
     if seq in (10,20,30,50) then output;
  end; 
  end;
run;

data _totaeds4;
    set _totaeds4;
    %do _i=1 %to &_sort_column_count;
        if strip(_bodysmq)='ZZZNull' then grptot%eval(&&svar&_i)=-888; *Put missing as last one;
        if index(strip(_aeterm),'ZZZNull') then termtot%eval(&&svar&_i)=termtot%eval(&&svar&_i)-888; *Put missing as last one;
    %end;
run;

%*****Manipulate the Sorting variables*****************
******Pick the numeric value of the sorting variable**;
%if %length(&sort_column)>0 %then %do;
    %local grptot_sort tot_sort;
    %let grptot_sort=;
    %let termtot_sort=;
    %do _i=1 %to &_sort_column_count;
        %let grptot_sort=&grptot_sort descending grptot%eval(&&svar&_i);
        %let termtot_sort=&termtot_sort descending termtot%eval(&&svar&_i);
    %end;
%end;
%if %nrbquote(&sort_order)= %quote(COUNTDES) %then %do; 

    %if %nrbquote(&display_soc_grpval)= %quote(Y) and %nrbquote(&display_term) = %quote(Y) %then %do; 
        %let _vsort = &grptot_sort _bodysmq &termtot_sort _aeterm max_aegrade_rating;
    %end;

    %else %if %nrbquote(&display_term) = %quote(Y) %then %do; 
        %let _vsort = &termtot_sort _aeterm max_aegrade_rating;
    %end;

    %else %if %nrbquote(&display_soc_grpval) = %quote(Y) %then %do; 
        %let _vsort = &grptot_sort _bodysmq max_aegrade_rating;
    %end;

%end;

%else %if %nrbquote(&sort_order)= %quote(ALPHA) %then %do;

    %if %nrbquote(&display_soc_grpval)= %quote(Y) and %nrbquote(&display_term)= %quote(Y) %then %do; 
          %let _vsort = _bodysmq _aeterm max_aegrade_rating;
    %end;

    %else %if %nrbquote(&display_term)= %quote(Y)  %then %do; 
          %let _vsort = _aeterm max_aegrade_rating;
    %end;

    %else %if %nrbquote(&display_soc_grpval)= %quote(Y) %then %do; 
          %let _vsort = _bodysmq max_aegrade_rating;
    %end;

%end;


%else %if %nrbquote(&sort_order)= %quote(ALPHA_COUNTDES) %then %do;

    %if %nrbquote(&display_soc_grpval)= %quote(Y) and %nrbquote(&display_term)= %quote(Y) %then %do; 
          %let _vsort = _bodysmq &termtot_sort _aeterm max_aegrade_rating;
    %end;

    %else %if %nrbquote(&display_term)= %quote(Y)  %then %do; 
          %let _vsort = &termtot_sort _aeterm max_aegrade_rating;
    %end;

    %else %if %nrbquote(&display_soc_grpval)= %quote(Y) %then %do; 
          %let _vsort = _bodysmq max_aegrade_rating;
    %end;

%end;


%else %if %nrbquote(&sort_order)= %quote(SMQCQ_COUNTDES) %then %do;

    %if %nrbquote(&display_soc_grpval)= %quote(Y) and %nrbquote(&display_term)= %quote(Y) %then %do; 
          %let _vsort = _bodysmqn _bodysmq &termtot_sort _aeterm max_aegrade_rating;
    %end;

    %else %if %nrbquote(&display_term)= %quote(Y)  %then %do; 
          %let _vsort = &termtot_sort _aeterm max_aegrade_rating;
    %end;

    %else %if %nrbquote(&display_soc_grpval)= %quote(Y) %then %do; 
          %let _vsort = _bodysmqn _bodysmq max_aegrade_rating;
    %end;

%end;

proc sort data=_totaeds4;
  by order lnbreak &_vsort;
run;

%***Bold the Body System organ class/grouping variable values***********;
data _totaeds5(drop=order rename=(_order=order));
  length _skvar $200;
  set _totaeds4;
  by order lnbreak &_vsort ;
/*    if order=40 and first._bodysmq then do;*/
/*           style_variable="B";*/
/*           carry_over_fg=1;*/
/*           end;*/
/*      else do;*/
           style_variable="";
           carry_over_fg=0;
/*      end;*/
		   %*weibin added;
%if %index(%upcase(&_vsort),'') %then %do;
  _skvar=compress(put(seq,best.))||strip(_bodysmq)||strip(_aeterm);
%end;
%else %do;
  _skvar=compress(put(seq,best.))||strip(_aeterm);
%end;
 
  _order=_n_;
  pageorder=ceil(_order/26);
run;

data _totaeds6;
    set _totaeds5(drop=lnbreak rename=(_col1=col1));
    by /*_skvar*/_bodysmq notsorted;
    retain lnbreak;
    *Add Lnbreak for each group (e.g. SOC/ PT);
    if _n_=1 then lnbreak=1;
    else if first._bodysmq then lnbreak=lnbreak+1;

    %if %upcase(&display_soc_grpval) ne Y or %upcase(&display_term) ne Y %then %do;
      col1=left(tranwrd(col1,"&ods_indent3.",""));
      col1=left(tranwrd(col1,"&ods_indent5.","&ods_indent3."));
	  col1=left(tranwrd(col1,"&ods_indent7.","&ods_indent5."));
  %end;

  col1=tranwrd(col1,"ZZZNull","Uncoded");

run;

proc sql noprint;
    create table _totaeds_grdcnt
    as select distinct _bodysmq, _aeterm, count(distinct aegrade_c) as _cnt_grd
    from _totaeds6
    group by _bodysmq, _aeterm;

    create table _totaeds7
    as select l.*, r._cnt_grd
    from _totaeds6 as l left join _totaeds_grdcnt as r
    on l._bodysmq=r._bodysmq and l._aeterm=r._aeterm;
quit;

proc sort data=_totaeds7;
    by lnbreak order;
run;

data _totaeds7;
    set _totaeds7;
    by lnbreak;
    order=order*1000;
    output;

    array c_disp{*} col1 cpct:;
    if last.lnbreak then do;
        order=order+5;
        do _ii=1 to dim(c_disp);
            c_disp{_ii}="";
        end;
        _dummy_row='Y';
        output;
    end;
run;

proc sort data=_totaeds7;
    by lnbreak order;
run;
 
data _totaeds8;
    set _totaeds7;
    by _bodysmq _aeterm notsorted;
    retain _cum_line;
    if _n_=1 then _cum_line=1;
/*    else if first._bodysmq then _cum_line=_cum_line+2;*/
    else _cum_line=_cum_line+1;
    
    if first._aeterm and _cum_line+_cnt_grd>12 then _cum_line=1;
run;
 

data _final;
    set _totaeds8;
    retain pagebreak 1;
    if _cum_line=1 and _n_^=1 then pagebreak=pagebreak+1;
run;



%*----------------------------------------------------------------------------------*;
%*- Step 11: produce output dataset that will be used to create rtf table            ;                  
%*----------------------------------------------------------------------------------*;  

%if %qupcase(&create_output_dataset)=%quote(Y) %then %do;

data _null_;
    set _uniquetrt;
    call symput(compress("_labtrt"||put(_trtcd,best.)),strip(decode_1));
run;

data &output_ds..&rename_output(drop=_dummy_row);
  set _final(keep = col1 cpct: order _bodysmq _aeterm aegrade_c lnbreak _dummy_row);
  label %do _ii=1 %to &notrt.;
            cpct&_ii.="CountPct &&_labtrt&_ii.."

          %end;
        ;
    if _dummy_row='Y' then delete;
run;

proc print data=&output_ds..&rename_output label;
run;
%end;

%*----------------------------------------------------------------------------------*;
%*- Step 12: Create supporting listing file;
%*----------------------------------------------------------------------------------*;
%if %length(&support_listing_lib.)>0 %then %do;
proc sql noprint;
  create table _support0listing as 
  select distinct 
    ord, _col, studyid, sitenum, usubjid, decode_1, coded_1, _bodysmq, _aeterm, aegrade_c
  from support
  order by ord, _col, studyid, sitenum, usubjid, decode_1, coded_1;
quit;

%let excelpath=&support_listing_lib.; %** Get the path of output excel file **;

/*proc sql noprint;*/
/*    select distinct  tranwrd(tranwrd(rtf_out,".rtf",""),"-","_") into: rtf_output*/
/*    from metadata.tracker*/
/*    where compress(tranwrd(base_output_name,".rtf",""))=compress(tranwrd("&rename_output.",".rtf",""))*/
/*    ;*/
/*quit;*/
proc export data=_support0listing outfile="&excelpath./%sysfunc(compress(&rename_output.-suplist.csv))" dbms=csv replace;
run;
%end;

%* Label to use if there is no data to report *;
%no_data_to_report:


%if %qupcase(&_data_to_report)=%quote(N) %then %do;
data _final;
  length col1 $100;

  lnbreak=1;
  order=1;
  col1="";
  output;
  order=2;
  col1="No Events Reported";
  output;
  order=3;
  col1="";
  output;
run;
data &output_ds..&rename_output;
  set _final(keep=col1);
run;
%end;


%*---------------------------------------------------------------------------------*;
%*- Step 14: Set up macro variables for columns and headers
             Create rtf tables using output dataset created in analysis macro 
%*---------------------------------------------------------------------------------*;

%if %qupcase(&_data_to_report)=%quote(Y) %then %do;
%*** Build report column attributes based on treatment code and description;
%*** put column attributes in macro variables ;


%if %length(&rel_col_widths)>0 %then
    %do;
        %if %eval(&_col_width_count)<&notrt %then
            %do;
                %do _jj=&_col_width_count+1 %to &notrt.;
                    %let _col_widths&_jj=&&_col_widths&_col_width_count..;
                %end;

                %let _col_width_count=&notrt;
            %end;
    %end;
%else
    %do;
        %let _col_width_count=&notrt;
        %let _col_widths0=2.0;

        %do _jj=1 %to &_col_width_count;
            %let _col_widths&_jj.=0.8;
        %end;
    %end;

proc sql noprint;
    create table _uniquetrt_denom0
    as select l.*, r.denom
    from _uniquetrt as l left join _n01_denomds0 as r
    on l.coded_1=r.coded_1
    order by _trtcd;
run;


data _uniquetrt_denom1;
  length hd1 hd2 $200.;
  set _uniquetrt_denom0;
  if index(decode_1,'^') then do;
	        hd1=strip(scan(decode_1,1,"^"));
      hd2=strip(scan(decode_1,2,"^"))||"#(N="||strip(put(denom,best.))||")#n (%)";
  end;
  else do;
      hd1="";
      hd2=strip(decode_1)||"#(N="||strip(put(denom,best.))||")#n (%)";    
  end;

  %do _jj=1 %to &notrt.;
      if _trtcd=&_jj then _uline=round(&&_col_widths&_jj..*13,1);
  %end;
run;


proc sql noprint;
    create table _uniquetrt_denom
    as select *, sum(_uline) as _num_uline
    from _uniquetrt_denom1
    group by hd1
    order by _trtcd;
quit;

*Display the columns in 2 or more pages based on the therapy_per_page;
proc sql noprint;
    select distinct count(distinct hd1), 
                    count(distinct strip(scan(decode_1,2,"^"))),
                    count(distinct hd1)*count(distinct strip(scan(decode_1,2,"^"))) 
    into :_num_c1, :_num_c2, :_num_ca
    from _uniquetrt_denom;
quit;

%put macro message: column numbers &_num_ca.;

data _null_;
  set _uniquetrt_denom end=eof;
  by hd1 hd2 notsorted;
  length varlst $2000. page $5.;
  retain varlst '' _numtrt 0;    
  if index(upcase("&rename_output."),'P1')>0 then do;	
  	 if _trtcd in (4) then hd2="&tlr. "||strip(hd2);
	 if _trtcd in (5) then hd2="&tll. "||strip(hd2);	 
  end; 
  call symput(compress("_hd_"||put(_trtcd,best.)), hd2);

  if first.hd1 then do;
      if index(upcase("&rename_output."),'P1')>0 then do;
		  if _n_^=1 then hd1="&ull. "||strip(hd1);
		  else hd1="&ul. "||strip(hd1);;
	  end;
	   hd1="&ul. "||strip(hd1);
      if hd1^="" then 
        varlst=trim(varlst)||' ("'||strip(hd1)/*||'#%sysfunc(repeat(%str(_),'||compress(put(_num_uline,best.))||
               '))"'*/||'" cpct'||compress(put(_trtcd,8.));
    else varlst=trim(varlst)||' ("'||strip(hd1)||'" cpct'||compress(put(_trtcd,8.));
    _numtrt=_numtrt+1;
  end;
  else do;
    varlst=trim(varlst)||' cpct'||compress(put(_trtcd,8.));
  end;
  if last.hd1 then varlst=trim(varlst)||')';
  if eof then call symput("_varlst_", trim(varlst));

  page=""; 
  %if &_num_c1.>&therapy_per_page %then %do;
     if mod(_numtrt+1,&therapy_per_page)=0 and first.hd1 and _n_^=1 then page="page";
     else page="";
  %end;
  call symput(compress("_page_"||put(_trtcd,best.)), page);
run;


    
**Generate the header for col1;
%local _hd1_col1 _hd2_col1;

%if %qupcase(&display_term) eq Y and %qupcase(&display_soc_grpval) eq Y %then %do;
    %let _hd1_col1=%nrbquote(&grp_term_label.);
    %let _hd2_col1=%nrbquote(^{style[just=left]^{nbspace 2}}&ae_term_label.);
    %let _hd3_col1=%nrbquote(^{style[just=left]^{nbspace 4}}&ae_grade_label.);
%end;
%else %if %qupcase(&display_term) eq Y %then %do;
    %let _hd1_col1=%nrbquote();
    %let _hd2_col1=%nrbquote(&ae_term_label.);
    %let _hd3_col1=%nrbquote(^{style[just=left]^{nbspace 2}}&ae_grade_label.);
%end;
%else %if %qupcase(&display_soc_grpval) eq Y %then %do;
    %let _hd1_col1=%nrbquote();
    %let _hd2_col1=%nrbquote(&grp_term_label.);
    %let _hd3_col1=%nrbquote(^{style[just=left]^{nbspace 2}}&ae_grade_label.);
%end;


%m_tflprep ( outname = &rename_output, orient=&_page_orientation, fnt=&font_size) ;

proc report
    data = _final
    headline headskip missing center split = "#" nowd spanrows style ( report ) = [ frame = hsides] ;
    column pagebreak /*lnbreak*/ order col1 &_varlst_.;
    define pagebreak / order noprint ;
/*    define lnbreak / order noprint ;*/
    define order    / order noprint ;
    define col1  / id display "&_hd1_col1.#&_hd2_col1.#&_hd3_col1."            
                                             style ( column ) = [ /*asis = on*/ cellwidth = &_col_widths0.in just = left ]
                                             style ( header ) = [               cellwidth = &_col_widths0.in just = left ] ;
    %do _ii=1 %to &notrt.;
    define cpct&_ii.  / &&_page_&_ii.. display "&&_hd_&_ii.."
                                             style ( column ) = [ /*asis = on*/ cellwidth = &&_col_widths&_ii..in just = center ]
                                             style ( header ) = [           cellwidth = &&_col_widths&_ii..in just = center ] ;
    %end;

    break after pagebreak/ page;
/*    compute after lnbreak ;*/
/*      line " " ;*/
/*    endcomp ;*/
run ;

ods _all_ close;
ods listing;

/********************************/
/** Add Bookmark to PDF Output **/
/********************************/
%m_postp_rtf(inrtf=&rtf_fil);
%m_bkmrk_pdf(inpdf=&pdf_out, bkmrk=%QUOTE(&pdf_bkmrk));


%end; %*** END %if %qupcase(&_data_to_report)=%quote(Y);
%else %do;

%m_tflprep ( outname = &rename_output, orient=&_page_orientation, fnt=&font_size ) ;

proc report
    data = _final
    noheader missing center split = "#" nowd spanrows style ( report ) = [ frame = hsides ] ;
    column lnbreak order col1;
    define lnbreak / order noprint ;
    define order    / order noprint ;
    define col1  / display " "               style ( column ) = [ asis = on cellwidth = 4.0in just = left ]
                                             style ( header ) = [           cellwidth = 4.0in just = left ] ;    

run ;

ods _all_ close;
ods listing;

/********************************/
/** Add Bookmark to PDF Output **/
/********************************/
%m_bkmrk_pdf(inpdf=&pdf_out, bkmrk=%QUOTE(&pdf_bkmrk));
%m_postp_rtf(inrtf=&rtf_fil);

%end; %*** END %else %do;

%*----------------------------------------------------------------------------------*;
%*- Step 16: clean up;
%*----------------------------------------------------------------------------------*;


%if %qupcase(&debug) = %quote(N) or %qupcase(&debug)=%quote(ANALYSIS) %then %do;
proc datasets library=work memtype=data nolist ;                                                                                                                                                  
  delete 
%if %qupcase(&_data_to_report)=%quote(Y) %then  
         _data_for_counting: _observation_extract:                                                                                                                                            
         _population_extract:                                                                                                                                       
         _frameds 
         _n01: _n02: _totaeds:        
         _final 
        _pop_obs_extract:
        _uni: 
   ;;
quit ;

%end;
*/

title;
footnote;

%*** exit ***;
%exit:
  
 
 
%put;
%put ---End of %upcase(&sysmacroname) macro;
%put;


%mend m_t_ae_maxgrd;

