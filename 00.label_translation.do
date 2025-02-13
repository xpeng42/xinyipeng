clear all

use "$rawdata\anagr", clear
/* Anagr */
label var cod_pgr "WORKER_ID: COD. PROGR. LAVORATORE"
label var sesso "GENDER: SESSO"
label var data_n "WORKER_DOB (DDMMYY): DATA DI NASCITA (GGMMAA)"
label var com_n "WORKER_CITY OB: COMUNE DI NASCITA"
label var prov_n "WORKER_PROVINCEOB: PROV. DI NASCITA (SIGLA)"
label var naz "WORKER_NATIONALITY: NAZIONALITA’ (SIGLA)"
label var com_r "WORKER_CITY_RESIDENCE: COMUNE DI RESIDENZA"
label var prov_r "WORKER_PROVINCE_RESIDENCE: PROV.DI RESIDENZA (SIGLA)"
label var anno_n "WORKER_YEAROB: ANNO DI NASCITA"
save anagr, replace

use azien, clear
/* Azien */
label var matr_az "FIRM_ID: MATRICOLA AZIENDALE"
label var rag_soc "FIRM_NAME: RAGIONE SOCIALE"
label var att_econ "FIRM_SECTOR(description of economic activity): DESCRIZ. ATTIVITA’ ECONOMICA"
label var indirizzo "FIRM_ADDRESS: INDIRIZZO (VIA/PIAZZA N° CIVICO)"
label var cap "FIRM_ZIP_CODE: CAP"
label var comune "FIRM_MUNICIPALITY: COMUNE"
label var prov "FIRM_PROVINCE: PROVINCIA (SIGLA)"
label var csc "FIRM_STATISTICAL_CONTRIBUTION_CODE: COD.STATISTICO CONTRIBUTIVO"
label var data_cost "DATE_FOUNDATION (YYYYMMDD): DATA DI COSTIT. (AAAAMMGG)"
label var data_sosp "DATE_SUSPENSION (YYYYMMDD): DATA DI SOSPENS. (AAAAMMGG)"
label var data_cess "DATE_FORECLOSURE (YYYYMMDD): DATA DI CESSAZIONE (AAAAMMGG)"
label var cod_fis "FIRM_FISCAL_CODE: CODICE FISCALE"
label var part_iva "FIRM_PROFESSIONAL_FISCAL_CODE: PARTITA IVA"
label var cod_com "FIRM_CITY_CODE: CODICE COMUNE DI APPARTENENZA"
label var ateco81 "FIRM ATECO81 (CIC): ATECO81_SECTOR_CODE"
label var ateco91 "ATECO91 (NB NOT TO BE USED!!): ATECO91_SECTOR_CODE"
label var artig "CRAFT (or ARTISAN) (1=YES): ARTIGIANA (1=Sì)"
label var data_in "DATE_BEGINNING_ACTIVITY(YYMM): DATA INIZIO ATTIVITA’(AAMM)"
label var data_out "DATE_END_ACTIVITY (YYMM): DATA CESSAZ. ATT.(AAMM)"
label var dip_in "NUMBER_EMPLOYED_AT_BEG: NUMERO DIP. ALL’INIZIO ATT."
label var dip_out "NUMBER_EMPLOYED_AT_END: N° DIP. ALLA CESSAZ. ATT."
label var mes_sosp "N_MONTHS_SUSPENDED_ACTIVITY: N° DI MESI DI ATT. SOSPESA"
label var num_sosp "N_ACTIVITY_SUSPENSION NUMERO DI SOSPENSIONI"
label var matr_azl "FIRM_ID_CONNECTED (USED FOR MERGER OR SPLIT)"
save azien, replace

use contr, clear
/* Contr */
label var cod_pgr "WORKER_ID: CODICE PROGRES. LAVOR."
label var anno "YEAR_of_TAXATION: ANNO DI CONTRIBUZ. (AA)"
label var matr_az "FIRM_ID: MATRICOLA AZIENDALE"
label var mesi_r "MONTHS_SALARY_PAID: MESI RETRIBUITI"
label var sett_r "WEEKS_SALARY_PAID: SETTIMANE RETRIBUITE"
label var gior_r "DAYS_SALARY_PAID: GIORNATE RETRIBUITE"
label var retrib03 "EARNING(2003)*1000: RETRIBUZ.2003 (*1000)"
label var contrat "COLLECTIVE CONTRACT_TYPE: TIPO CONTRATTO"
label var livello "CONTRACT_CLASSIFICATION: LIVELLO INQUADRAMENTO"
label var qualif "QUALIFICATION: QUALIFICA"
label var tipo_rap "TYPE_RELATIONSHIP: TIPO RAPPORTO"
label var d_cess " DATE_END_RELATIONSHIP(DDMM): DATA CESS. RAPP.(GGMM)"
label var sett_u "WORKING_WEEKS: SETTIMANE UTILI"
label var prov_l "PROVINCE_OF_WORK: PROVINCIA DI LAVORO"
label var uff_zon "ZONE_OFFICE: UFFICIO ZONALE"
label var inter "INTERNAL_FIRM (1=YES): AZIENDA INTERNA (1=Sì)"
save contr, replace
