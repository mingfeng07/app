/*********************************************************************    
***  Study Name: BGB3111_1002                                                        
***  Program: t_ae.sas                                             
***  Programmer: tingting.zeng
***  Date: 24NOV2017                                                    
***                                                                  
***  Description: Call macro %m_t_ae and create below tables 
        - TEAE by System Organ Class and Preferred Term
        - Grade 3 or Higher TEAE by System Organ Class and Preferred Term
        - Serious TEAE by System Organ Class and Preferred Term
        - TEAE Leading to Death by System Organ Class and Preferred Term
        - TEAE Leading to Treatment Discontinuation by System Organ Class and Preferred Term
        - TEAE Leading to Dose Interruption by System Organ Class and Preferred Term
        - Treatment-Related TEAE by System Organ Class and Preferred Term
        - Treatment-Related Grade 3 or Higher TEAE by System Organ Class and Preferred Term
        - Treatment-Related Serious TEAE by System Organ Class and Preferred Term

        - TEAE by Preferred Term
        - Grade 3 or Higher TEAE by Preferred Term
        - Treatment-Related TEAE by Preferred Term 
***                                                                  
*********************************************************************
***  MODIFICATIONS:                                                  
***  Programmer: Tingting Zeng                                                       
***  Date: 25Jul2018                                                               
***  Reason: Use 4:1 mapping for AE relationship: consider UNLIKELY RELATED as related AE as well                                                        
***       

*********************************************************************
***  MODIFICATIONS:                                                  
***  Programmer: Pengfei Cheng                                                       
***  Date: 19Nov2018                                                               
***  Reason: Use 3:2 mapping for AE relationship: consider UNLIKELY RELATED as unrelated AE as well ADAE.RELGR1;  
***          update the treatment group based on the ARM update on SDTM, update m_t_ae macro accordingly;                                                      
***  
*********************************************************************
***  MODIFICATIONS:                                                  
***  Programmer: Weibin Cai                                                      
***  Date: 1APR2019                                                               
***  Reason: update program for 213 
***                                                               
***                                                                   
*********************************************************************/  


%include "/usrfiles/bgcrh/support/utilities/init/init_global.sas";

%m_tlfhead(inds=adam.adsl);

%m_tlfhead(inds=adam.adae);

options mprint nomlogic nosymbolgen;

** Call macro %m_t_ae to generate table: Serious TEAE by Preferred Term;            
proc datasets lib=work memtype=data nolist nowarn; save adsl adae; run;            
%m_t_ae(            
     population_from    =    adsl
    ,population_where    =    %str(SAFFL='Y' )
    ,observation_from    =    adae
    ,observation_where    =    %str(TRTEMFL="Y" and aeser='Y')
    ,therapy_des_var    =    trt01a
    ,therapy_cd_var    =    
    ,aetrt_des_var    =    trt01a
    ,aetrt_cd_var    =    
    ,subgroup_des_var    =    _CANTYP
    ,subgroup_cd_var    =    
    ,ae_term_selection    =    AEDECOD
    ,grp_term_selection    =    AEBODSYS
    ,display_soc_grpval    =    N
    ,display_term    =    Y
    ,sort_order    =    COUNTDES
	    /* ,sort_column    =    %str(BGB-3111 320 mg QD^Total|BGB-3111 160 mg BID^Total) */
    ,sort_column    =    %str(Zanubrutinib + Rituximab^Total)
    ,display_totals    =    N
    ,display_totals_select_grps    =    
    ,display_totals_subgroup    =    Y
    ,display_with_rows    =    Y
    ,with_withno_row_label    =    %nrbquote(Patients with at Least 1 TEAE)
    ,reduction_method_2    =    percent
    ,percent_incidence    =    0
    ,subject_ct_min_value    =    
    ,control_group_cd    =    
    ,ib_rsi_min_ratio    =    1
    ,create_output_dataset    =    Y
    ,rel_col_widths    =    %str(28 9 9 9 9 )
    ,page_orientation    =    P
    ,therapy_per_page    =    
    ,output_lib    =    &tables
    ,support_listing_lib    =    
    ,rename_output    =    t-teae-pt-ser
    ,decimal_places_percent    =    1
    ,font_size    =    regular
    ,trackerid       = &titlesid.
    ,debug    =    Y
); 