********************************************************************************
* MASTER DO-FILE — Analyse représentativité élus municipaux
* Auteur : Louis Briaux
* Date   : Juillet 2026
********************************************************************************

********************************************************************************
* 0. PARAMÈTRES GLOBAUX
********************************************************************************
clear all
set more off
set max_memory 8g

global rne    "/Users/loulou/Documents/Pro/Stage éco politique/RNE"
global rne26  "/Users/loulou/Documents/Pro/Stage éco politique/RNE/RNE 2026"
global rna    "/Users/loulou/Documents/Pro/Stage éco politique/rna_import_20260601"
global data   "/Users/loulou/Documents/Pro/Stage éco politique"

********************************************************************************
* 1. CONSTRUCTION DE LA BASE RNE PRINCIPALE
*    Input  : rne_all_dep_u2020.dta + rne_2020.dta
*    Output : $rne26/rne_cat_actualise.dta
********************************************************************************
use "$rne/New RNE/data_rne_all_copie.dta", clear

* --- Genre ---
gen femme = (codesexe == "F")

* --- Population actualisée ---
gen annee = mandat
merge m:1 code_insee annee using "$rne/pop_par_annee.dta"
replace populationdelacommune = populationdelacommune_new if populationdelacommune_new != .
drop populationdelacommune_new annee _merge

* Correction Paris
replace populationdelacommune = 2249975 if code_insee == "75056" & mandat == 2020

* Suppression des observations sans code INSEE
drop if code_insee == ""
drop if mandat == .

* Suppression des DOM-TOM non métropolitains
foreach dep in "975" "976" "986" "987" "988" {
    drop if substr(code_insee, 1, 3) == "`dep'"
}

* --- Revenu médian (Filosofi) ---
merge m:1 code_insee using "$rne/revenu-des-francais-a-la-commune-1765372688826", ///
    keepusing(DISP_med)
drop if _merge == 2
drop _merge

* --- Tranches de population ---
gen tranche_pop = .
replace tranche_pop = 1 if populationdelacommune < 500
replace tranche_pop = 2 if populationdelacommune >= 500   & populationdelacommune < 1000
replace tranche_pop = 3 if populationdelacommune >= 1000  & populationdelacommune < 2000
replace tranche_pop = 4 if populationdelacommune >= 2000  & populationdelacommune < 3500
replace tranche_pop = 5 if populationdelacommune >= 3500  & populationdelacommune < 5000
replace tranche_pop = 6 if populationdelacommune >= 5000  & populationdelacommune < 10000
replace tranche_pop = 7 if populationdelacommune >= 10000 & populationdelacommune < 30000
replace tranche_pop = 8 if populationdelacommune >= 30000 & populationdelacommune != .

label define tranche_pop_lbl 1 "< 500" 2 "500-1000" 3 "1000-2000" 4 "2000-3500" ///
    5 "3500-5000" 6 "5000-10000" 7 "10000-30000" 8 ">30000"
label values tranche_pop tranche_pop_lbl

* --- Tranches de revenu (déciles) ---
gen tranche_revenu = .
replace tranche_revenu = 1 if DISP_med < 19951
replace tranche_revenu = 2 if DISP_med >= 19951 & DISP_med < 21291
replace tranche_revenu = 3 if DISP_med >= 21291 & DISP_med < 22881
replace tranche_revenu = 4 if DISP_med >= 22881 & DISP_med < 24871
replace tranche_revenu = 5 if DISP_med >= 24871 & DISP_med < 27161
replace tranche_revenu = 6 if DISP_med >= 27161 & DISP_med != .

label define tranche_rev_lbl 1 "< 10%" 2 "10-25%" 3 "25-50%" 4 "50-75%" 5 "75-90%" 6 ">90%"
label values tranche_revenu tranche_rev_lbl

* --- Log population et revenu ---
gen log_pop     = log(populationdelacommune)
gen log_DISP_med = log(DISP_med)

* --- Statut social (classification high/middle/low) ---
gen social_status = .
replace social_status = 1 if low_social_status == 1
replace social_status = 2 if middle_social_status == 1
replace social_status = 3 if high_social_status == 1
replace social_status = 4 if unknown_social_status == 1

label define status_lbl 1 "Bas" 2 "Intermédiaire" 3 "Élevé" 4 "Inconnu"
label values social_status status_lbl

* --- PCS comparables INSEE ---

* 1 - Agriculteurs
gen pcs_agriculteurs = 0
foreach prof in "Agriculteur propriétaire exploit." "Agriculteur sur grande exploitation" ///
"Agriculteur sur moyenne exploitation" "Agriculteur sur petite exploitation" ///
"Agriculteurs propriétaires exploit." "Ancien agriculteur exploitant" ///
"Retraités agricoles" "Retraité agricole" {
    replace pcs_agriculteurs = 1 if strpos(libellédelaprofession, "`prof'") > 0
}

* 2 - Artisans, commerçants, chefs d'entreprise
gen pcs_artisans = 0
foreach prof in "Artisan" "Artisans" "Commercant" "Commercants" "Commerçant et assimilé" ///
"Entrepreneur en batiments" "Entrepreneurs en batiments" ///
"Industriel-Chef entreprise" "Industriels-Chefs entreprise" ///
"Chef d'entreprise de 10 salariés ou p" ///
"Administrateur de sociétés" "Administrateurs de sociétés" ///
"Marin (patron)" "Marins (patrons)" ///
"Ancien artisan, commerçant, chef d'en" "Ancien artisan, commerçant, chef d'en.." ///
"Retr.artis.commerc.chefs d'entrep." "Retr.artis.commerc.chef d'entrep." {
    replace pcs_artisans = 1 if strpos(libellédelaprofession, "`prof'") > 0
}

* 3 - Cadres et professions intellectuelles supérieures
gen pcs_cadres = 0
foreach prof in "Cadre administratif et commercial d'e" "Cadre de la fonction publique" ///
"Cadre sup. (entreprises publiques)" "Cadre supérieur (secteur privé)" ///
"Cadres (entreprises publiques)" "Cadres sup. (entreprises publiques)" ///
"Cadres supérieurs (secteur privé)" "Ancien cadre" ///
"Autres cadres (secteur privé)" "Autres cadres (secteur prive)" ///
"Autre cadre (secteur privé) (obsolète)" ///
"Ingénieur" "Ingénieurs" "Ingénieur conseil" "Ingénieurs conseils" ///
"Ingénieur et cadre technique d'entrep" ///
"Médecin" "Médecins" "Chirurgien" "Chirurgiens" "Dentiste" "Dentistes" ///
"Pharmacien" "Pharmaciens" "Vétérinaire" "Vétérinaires" ///
"Avocat" "Avocats" "Notaires" "Huissiers" "Magistrats" ///
"Expert comptable" "Experts comptables" ///
"Architecte" "Architectes" ///
"Professeur de faculté" "Professeurs de faculté" ///
"Professeur, profession scientifique" ///
"Grands corps de l'état" ///
"Fonctionnaire de catégorie A" "Fonctionnaires de catégorie A" ///
"Journaliste et autre média" "Journalistes et autres médias" ///
"Profession libérale" "Autres professions libérales" ///
"Autre profession libérale (obsolète)" ///
"Homme de lettres et Artiste" "Hommes de lettres et Artistes" ///
"Profession de l'information, des arts" ///
"Permanent politique (obsolète)" "Permanents politiques" ///
"Retraités des professions libérales" "Retraité des professions libérales" {
    replace pcs_cadres = 1 if strpos(libellédelaprofession, "`prof'") > 0
}
* Correction : "Autres professions libérales" ne doit pas être dans intermédiaires
replace pcs_cadres = 1 if strpos(libellédelaprofession, "Autres professions libérales") > 0

* 4 - Professions intermédiaires
gen pcs_interm = 0
foreach prof in "Agent technique et technicien" "Agents technique et techniciens" ///
"Profession intermédiaire administra" "Profession intermédiaire administrati" ///
"Profession intermédiaire de la santé" ///
"Fonctionnaire de catégorie B" "Fonctionnaires de catégorie B" ///
"Enseignant 1er deg.-directeur école" "Enseignants 1er deg.-directeurs école" ///
"Professeur des écoles, instituteur" ///
"Professeur du secondaire et techn." "Professeurs du secondaire et techn" ///
"Profession rattachée à enseignt" "Professions rattachées à enseignt" ///
"Assistante sociale" "Assistantes sociales" ///
"Salarié du secteur médical" "Salariés du secteur médical" ///
"Représentant de commerce" "Représentants de commerce" ///
"Agent d'assurances" "Agents d'assurances" ///
"Agent général d'assurances" "Agents généraux d'assurances" ///
"Agent immobilier" "Agents immobiliers" ///
"Conseiller juridique" "Conseillers juridiques" ///
"Contremaitre" "Contremaitres" "Contremaître, agent de maîtrise" ///
"Technicien" "Personnel des services directs aux pa" ///
"Ancienne profession intermédiaire" ///
"Autres professions" "Autre profession (obsolète)" ///
"Policier et militaire" "Agents d'affaires" ///
"Propriétaires" "Propriétaire (obsolète)" ///
"Retraités fonct.publique (sf enseig." ///
"Retraités des entreprises publiques" "Retraité des entreprises publiques" ///
"Retraités de l'enseignement" "Retraité de l'enseignement" {
    replace pcs_interm = 1 if strpos(libellédelaprofession, "`prof'") > 0
}
* Correction chevauchement
replace pcs_interm = 0 if strpos(libellédelaprofession, "Autres professions libérales") > 0

* 5 - Employés
gen pcs_employes = 0
foreach prof in "Employé (autres entrep. publiques)" "Employé (secteur privé)" ///
"Employé administratif d'entreprise" "Employé civil et agent de service de" ///
"Employé de commerce" "Employés (autres entrep. publiques)" ///
"Employés (secteur privé)" "Fonctionnaire de catégorie C" ///
"Fonctionnaires de catégorie C" "Agents subalternes (entr.publiques)" ///
"Ancien employé" ///
"Retraités salariés privés" "Retraité salarié privé" ///
"Autres retraités" "Autre retraité" {
    replace pcs_employes = 1 if strpos(libellédelaprofession, "`prof'") > 0
}

* 6 - Ouvriers
gen pcs_ouvriers = 0
foreach prof in "Ouvrier agricole" "Ouvrier non qualifié de type artisanal" ///
"Ouvrier non qualifié de type industriel" "Ouvrier qualifié de la manutention" ///
"Ouvrier qualifié de type artisanal" "Ouvrier qualifié de type industriel" ///
"Ouvriers (secteur privé)" "Ouvrier (secteur privé) (obsolète)" ///
"Salarié agricole" "Salariés agricoles" ///
"Marin (salarié)" "Marins (salariés)" "Chauffeur" "Ancien ouvrier" {
    replace pcs_ouvriers = 1 if strpos(libellédelaprofession, "`prof'") > 0
}

* 7 - Inconnu
gen pcs_inconnu = 0
foreach prof in "Sans profession déclarée" "Sans profession déclarée (obsolète)" ///
"Elève, étudiant" "Etudiants" "Militaire du contingent" ///
"Personne diverse sans activité" "Chômeur n'ayant jamais travaillé" ///
"Non Connu" "Ministres du culte" "Clergé, religieux" {
    replace pcs_inconnu = 1 if strpos(libellédelaprofession, "`prof'") > 0
}
replace pcs_inconnu = 1 if libellédelaprofession == ""

* Vérification
gen pcs_total = pcs_agriculteurs + pcs_artisans + pcs_cadres + ///
                pcs_interm + pcs_employes + pcs_ouvriers + pcs_inconnu
tab pcs_total
drop pcs_total

* Variable PCS unique
gen pcs_groupe = ""
replace pcs_groupe = "Agriculteurs"         if pcs_agriculteurs == 1
replace pcs_groupe = "Artisans/Commerçants" if pcs_artisans == 1
replace pcs_groupe = "Cadres"               if pcs_cadres == 1
replace pcs_groupe = "Prof. intermédiaires" if pcs_interm == 1
replace pcs_groupe = "Employés"             if pcs_employes == 1
replace pcs_groupe = "Ouvriers"             if pcs_ouvriers == 1
replace pcs_groupe = "Inconnu"              if pcs_inconnu == 1

* --- Normalisation nom de commune pour merge RNA ---
gen libcom_clean = lower(libellédelacommune)
foreach car in "-" "'" "_" "." {
    replace libcom_clean = subinstr(libcom_clean, "`car'", " ", .)
}
replace libcom_clean = subinstr(libcom_clean, "  ", " ", .)
replace libcom_clean = strtrim(libcom_clean)
gen dep = substr(code_insee, 1, 2)

save "$rne26/rne_cat_actualise.dta", replace

********************************************************************************
* 2. IMPUTATION PCS 2020 → 2008/2014
*    Input  : rne_cat_actualise.dta
*    Output : rne_cat_actualise.dta (mis à jour)
* NOTE : permet de comparer les PCS entre mandats malgré le changement
*        de nomenclature en 2020
********************************************************************************
use "$rne26/rne_cat_actualise.dta", clear

keep if mandat == 2020 & libellédelaprofession != ""
keep nomdelélu prénomdelélu codesexe code_insee libellédelaprofession codeprofession
duplicates drop nomdelélu prénomdelélu codesexe code_insee, force
rename libellédelaprofession libellédelaprofession_2020
rename codeprofession        codeprofession_2020
save "$rne26/pcs_reference_2020.dta", replace

use "$rne26/rne_cat_actualise.dta", clear

merge m:1 nomdelélu prénomdelélu codesexe code_insee ///
    using "$rne26/pcs_reference_2020.dta"

drop if _merge == 2

replace libellédelaprofession = libellédelaprofession_2020 if mandat != 2020 & _merge == 3
replace codeprofession        = codeprofession_2020        if mandat != 2020 & _merge == 3

drop libellédelaprofession_2020 codeprofession_2020 _merge
save "$rne26/rne_cat_actualise.dta", replace

********************************************************************************
* 3. FICHIER PCS POPULATION (DS_RP_EMPLOI)
*    Input  : DS_RP_EMPLOI_LR_COMP_data.csv
*    Output : pop_pcs_communes.dta
********************************************************************************
import delimited using "$data/wetransfer_rna-2024_2026-06-15_0624/DS_RP_EMPLOI_LR_COMP_data.csv", ///
    delim(";") varnames(1) encoding("utf-8") clear

keep if geo_object == "COM"
keep if empsta_enq == "1"
keep if time_period == 2021
keep if pcs != "_T"

rename geo      code_insee
rename pcs      pcs_code
rename obs_value pop_pcs
keep code_insee pcs_code pop_pcs

reshape wide pop_pcs, i(code_insee) j(pcs_code) string

rename pop_pcs1 pop_agriculteurs
rename pop_pcs2 pop_artisans
rename pop_pcs3 pop_cadres
rename pop_pcs4 pop_interm
rename pop_pcs5 pop_employes
rename pop_pcs6 pop_ouvriers

egen pop_total = rowtotal(pop_agriculteurs pop_artisans pop_cadres ///
                          pop_interm pop_employes pop_ouvriers)

gen share_cadres_pop        = pop_cadres        / pop_total
gen share_ouvriers_pop      = pop_ouvriers      / pop_total
gen share_employes_pop      = pop_employes      / pop_total
gen share_agriculteurs_pop  = pop_agriculteurs  / pop_total
gen share_artisans_pop      = pop_artisans      / pop_total
gen share_interm_pop        = pop_interm        / pop_total

save "$rne/pop_pcs_communes.dta", replace

********************************************************************************
* 4. FICHIER GAPS PAR COMMUNE (élus vs population)
*    Input  : rne_cat_actualise.dta + pop_pcs_communes.dta
*    Output : rne_proportion_pop_elus_v2.dta
********************************************************************************
use "$rne26/rne_cat_actualise.dta", clear

gen one   = 1

collapse ///
    (sum)  n_elus          = one ///
    (sum)  n_agriculteurs  = pcs_agriculteurs ///
    (sum)  n_artisans      = pcs_artisans ///
    (sum)  n_cadres        = pcs_cadres ///
    (sum)  n_interm        = pcs_interm ///
    (sum)  n_employes      = pcs_employes ///
    (sum)  n_ouvriers      = pcs_ouvriers ///
    (sum)  n_inconnu       = pcs_inconnu ///
    (sum)  n_femmes        = femme ///
    (mean) age_moy         = age_2020 ///
    , by(code_insee mandat)

gen n_known = n_agriculteurs + n_artisans + n_cadres + ///
              n_interm + n_employes + n_ouvriers

gen share_agriculteurs_elus = n_agriculteurs / n_known
gen share_artisans_elus     = n_artisans     / n_known
gen share_cadres_elus       = n_cadres       / n_known
gen share_interm_elus       = n_interm       / n_known
gen share_employes_elus     = n_employes     / n_known
gen share_ouvriers_elus     = n_ouvriers     / n_known
gen share_femmes_elus       = n_femmes       / n_elus

keep if mandat == 2020

merge m:1 code_insee using "$rne/pop_pcs_communes.dta", ///
    keepusing(pop_agriculteurs pop_artisans pop_cadres pop_interm pop_employes pop_ouvriers ///
              share_cadres_pop share_ouvriers_pop share_employes_pop ///
              share_agriculteurs_pop share_artisans_pop share_interm_pop)
drop if _merge == 2
drop _merge

* Gaps (positif = surreprésenté parmi les élus)
gen gap_agriculteurs = share_agriculteurs_elus - share_agriculteurs_pop
gen gap_artisans     = share_artisans_elus     - share_artisans_pop
gen gap_cadres       = share_cadres_elus       - share_cadres_pop
gen gap_interm       = share_interm_elus       - share_interm_pop
gen gap_employes     = share_employes_elus     - share_employes_pop
gen gap_ouvriers     = share_ouvriers_elus     - share_ouvriers_pop

* Valeurs absolues
foreach gap in gap_cadres gap_ouvriers gap_employes gap_agriculteurs gap_artisans gap_interm {
    gen abs_`gap' = abs(`gap')
}

save "$rne26/rne_proportion_pop_elus_v2.dta", replace

********************************************************************************
* 5. FICHIER RNA AGRÉGÉ PAR COMMUNE
*    Input  : rna_import_20260601_dpt_XX.csv
*    Output : rna_collapsed_commune.dta
********************************************************************************
cd "$rna"
clear
local first = 1

foreach n of numlist 1/98 {
    local dpt : display %02.0f `n'
    capture confirm file "rna_import_20260601_dpt_`dpt'.csv"
    if _rc == 0 {

        import delimited using "rna_import_20260601_dpt_`dpt'.csv", ///
            delim(";") varnames(1) encoding("utf-8") clear stringcols(_all)

        gen one = 1

        gen cat_politique = 0
        replace cat_politique = 1 if substr(objet_social1, 1, 3) == "001"

        gen cat_politique_indirecte = 0
        foreach code in "003" "002" "023" "005" "022" {
            replace cat_politique_indirecte = 1 if substr(objet_social1, 1, 3) == "`code'"
        }
        replace cat_politique_indirecte = 0 if cat_politique == 1

        gen libcom_clean = lower(libcom)
        foreach car in "-" "'" "_" "." {
            replace libcom_clean = subinstr(libcom_clean, "`car'", " ", .)
        }
        replace libcom_clean = subinstr(libcom_clean, "  ", " ", .)
        replace libcom_clean = strtrim(libcom_clean)

        collapse ///
            (sum)    total_asso     = one ///
            (sum)    n_asso_pol     = cat_politique ///
            (sum)    n_asso_pol_ind = cat_politique_indirecte ///
            (firstnm) libcom ///
            , by(adrs_codepostal libcom_clean)

        if `first' == 1 {
            save "rna_collapsed_all.dta", replace
            local first = 0
        }
        else {
            append using "rna_collapsed_all.dta"
            save "rna_collapsed_all.dta", replace
        }
    }
}

* Corse
foreach dpt in "2A" "2B" {
    capture confirm file "rna_import_20260601_dpt_`dpt'.csv"
    if _rc == 0 {
        import delimited using "rna_import_20260601_dpt_`dpt'.csv", ///
            delim(";") varnames(1) encoding("utf-8") clear stringcols(_all)

        gen one = 1
        gen cat_politique = 0
        replace cat_politique = 1 if substr(objet_social1, 1, 3) == "001"
        gen cat_politique_indirecte = 0
        foreach code in "003" "002" "023" "005" "022" {
            replace cat_politique_indirecte = 1 if substr(objet_social1, 1, 3) == "`code'"
        }
        replace cat_politique_indirecte = 0 if cat_politique == 1

        gen libcom_clean = lower(libcom)
        foreach car in "-" "'" "_" "." {
            replace libcom_clean = subinstr(libcom_clean, "`car'", " ", .)
        }
        replace libcom_clean = subinstr(libcom_clean, "  ", " ", .)
        replace libcom_clean = strtrim(libcom_clean)

        collapse ///
            (sum)    total_asso     = one ///
            (sum)    n_asso_pol     = cat_politique ///
            (sum)    n_asso_pol_ind = cat_politique_indirecte ///
            (firstnm) libcom ///
            , by(adrs_codepostal libcom_clean)

        append using "rna_collapsed_all.dta"
        save "rna_collapsed_all.dta", replace
    }
}

* Nettoyage et consolidation
use "rna_collapsed_all.dta", clear

gen dep = substr(adrs_codepostal, 1, 2)
replace libcom_clean = subinstr(libcom_clean, "  ", " ", .)
replace libcom_clean = strtrim(libcom_clean)

drop if libcom_clean == "" | libcom_clean == " "
drop if regexm(libcom_clean, "^[0-9]") | strpos(libcom_clean, "+") > 0

collapse ///
    (sum)     total_asso n_asso_pol n_asso_pol_ind ///
    (firstnm) adrs_codepostal libcom ///
    , by(libcom_clean dep)

gen share_asso_pol     = n_asso_pol     / total_asso
gen share_asso_pol_ind = n_asso_pol_ind / total_asso

save "rna_collapsed_commune.dta", replace

********************************************************************************
* 6. FICHIER COMMUNES_REF
*    Input  : rne_cat_actualise.dta
*    Output : communes_ref.dta
********************************************************************************
use "$rne26/rne_cat_actualise.dta", clear
keep code_insee populationdelacommune tranche_pop DISP_med tranche_revenu libcom_clean dep
duplicates drop code_insee, force
save "$rne26/communes_ref.dta", replace

********************************************************************************
* 7. FICHIER FINAL COMMUNE (merge RNE + RNA + communes_ref)
*    Input  : rne_proportion_pop_elus_v2.dta + communes_ref.dta + rna_collapsed_commune.dta
*    Output : fichier_final_commune.dta
********************************************************************************
use "$rne26/rne_proportion_pop_elus_v2.dta", clear

merge m:1 code_insee using "$rne26/communes_ref.dta", ///
    keepusing(tranche_pop populationdelacommune DISP_med tranche_revenu libcom_clean dep)
drop if _merge == 2
drop _merge

merge m:1 libcom_clean dep using "$rna/rna_collapsed_commune.dta", ///
    keepusing(total_asso n_asso_pol n_asso_pol_ind share_asso_pol share_asso_pol_ind)
drop if _merge == 2
drop _merge

* Imputer 0 pour les communes sans association matchée
foreach var in total_asso n_asso_pol n_asso_pol_ind {
    replace `var' = 0 if `var' == .
}

gen log_total_asso   = log(total_asso + 1)
gen log_asso_pol     = log(n_asso_pol + 1)
gen log_asso_pol_ind = log(n_asso_pol_ind + 1)
gen log_pop          = log(populationdelacommune)
gen log_DISP_med     = log(DISP_med)

save "$data/fichier_final_commune.dta", replace

********************************************************************************
* 8. RÉGRESSIONS
*    Input  : fichier_final_commune.dta
********************************************************************************
use "$data/fichier_final_commune.dta", clear


replace dep = "201" if dep == "2A"
replace dep = "202" if dep == "2B"

destring dep, replace
* Variables standardisées
foreach var in n_asso_pol n_asso_pol_ind total_asso log_DISP_med {
    egen z_`var' = std(`var')
}

* Régressions par gap avec variables standardisées
foreach gap in gap_cadres gap_ouvriers gap_employes gap_agriculteurs gap_artisans gap_interm {
    di "========================================"
    di "Régression pour `gap'"
    di "========================================"
    areg `gap' z_n_asso_pol z_n_asso_pol_ind z_total_asso z_log_DISP_med  i.tranche_pop, absorb(dep) robust
}

* Coefficient plot synthétique
foreach gap in cadres ouvriers employes agriculteurs artisans interm {
    local outcome = cond("`gap'" == "cadres",       "gap_cadres", ///
                    cond("`gap'" == "ouvriers",     "gap_ouvriers", ///
                    cond("`gap'" == "employes",     "gap_employes", ///
                    cond("`gap'" == "agriculteurs", "gap_agriculteurs", ///
                    cond("`gap'" == "artisans",     "gap_artisans", "gap_interm")))))
    reg `outcome' z_n_asso_pol z_n_asso_pol_ind z_total_asso z_log_DISP_med, robust
    estimates store `gap'
}

coefplot cadres ouvriers employes agriculteurs artisans interm, ///
    drop(_cons) xline(0) ///
    title("Effet des associations sur les gaps de représentation") ///
    xtitle("Effet d'une hausse d'1 écart-type") ///
    coeflabels(z_n_asso_pol     = "Asso. politiques" ///
               z_n_asso_pol_ind = "Asso. pol. indirectes" ///
               z_total_asso     = "Total associations" ///
               z_log_DISP_med   = "Revenu médian", wrap(20)) ///
    legend(order(2 "Cadres" 4 "Ouvriers" 6 "Employés" ///
                 8 "Agriculteurs" 10 "Artisans" 12 "Intermédiaires")) ///
    plotregion(margin(medlarge)) ///
    graphregion(fcolor(white))

graph export "$data/coefplot_gaps.png", replace width(2500)

********************************************************************************
* 9. MATCHINGS (PSM)
*    Input  : fichier_final_commune.dta
********************************************************************************
use "$data/fichier_final_commune.dta", clear

* Traitements
gen traitement1  = (n_asso_pol     > 0)   // asso politiques
gen traitement2 = (n_asso_pol_ind > 0)   // asso pol. indirectes
summarize total_asso, detail
gen traitement3 = (total_asso > r(p50))  // densité associative globale

local covariates "log_DISP_med share_cadres_pop share_ouvriers_pop share_agriculteurs_pop share_artisans_pop share_interm_pop i.tranche_pop"

foreach t in 1 2 3 {
    foreach outcome in gap_cadres gap_ouvriers gap_employes ///
                       gap_agriculteurs gap_artisans gap_interm share_femmes_elus {
        di "========================================"
        di "Traitement `t' — Outcome : `outcome'"
        di "========================================"
        psmatch2 traitement`t' `covariates', ///
            outcome(`outcome') logit caliper(0.01)
    }
}


********************************************************************************
* STATISTIQUES DESCRIPTIVES
********************************************************************************
use "$rne26/rne_cat_actualise.dta", clear

* --- Genre ---
tab codesexe if mandat_2008 == 1
tab codesexe if mandat_2014 == 1
tab codesexe if mandat_2020 == 1

tab codesexe if maire_juin_2008 == 1
tab codesexe if maire_juin_2014 == 1
tab codesexe if maire_mars_2025 == 1

tab codesexe if (maire_juin_2008 == 1 | adjoint_juin_2008 == 1)
tab codesexe if (maire_juin_2014 == 1 | adjoint_juin_2014 == 1)
tab codesexe if (maire_mars_2025 == 1 | adjoint_mars_2025 == 1)

* Genre × taille de commune
tab codesexe tranche_pop if maire_mars_2025 == 1, col nofreq

* --- Âge ---
sum age_2014 if maire_juin_2008 == 1, detail
sum age_2020 if maire_juin_2014 == 1, detail
sum age_2026 if maire_mars_2025 == 1, detail

tabstat age_2026 if maire_mars_2025 == 1, by(tranche_pop) stat(mean median sd)

* --- Statut social ---
tabstat low_social_status middle_social_status high_social_status unknown_social_status ///
    if maire_juin_2008 == 1, stat(sum)
tabstat low_social_status middle_social_status high_social_status unknown_social_status ///
    if maire_juin_2014 == 1, stat(sum)
tabstat low_social_status middle_social_status high_social_status unknown_social_status ///
    if maire_mars_2025 == 1, stat(sum)

tab social_status tranche_pop if maire_mars_2025 == 1, col nofreq
tab social_status codesexe    if maire_mars_2025 == 1, row nofreq

* --- PCS ---
tab pcs_groupe if maire_mars_2025 == 1

* --- Revenu médian ---
sum DISP_med, detail
tab tranche_revenu if maire_mars_2025 == 1
tabstat DISP_med if maire_mars_2025 == 1, by(tranche_pop) stat(mean median sd)
tab codesexe tranche_revenu if maire_mars_2025 == 1, col nofreq
tab social_status tranche_revenu if maire_mars_2025 == 1, col nofreq

* --- Secteur public ---
tab secteur_public if maire_mars_2025 == 1

* --- Graphiques descriptifs ---

* Genre par mandat
foreach annee in 2008 2014 {
    local var = cond(`annee' == 2008, "maire_juin_2008", "maire_juin_2014")
    graph pie if `var' == 1, over(codesexe) ///
        plabel(_all percent, color(navy) size(small) gap(22)) ///
        title("Répartition des genres chez les maires en `annee'", ///
              color(navy) margin(medsmall)) ///
        graphregion(fcolor(white))
    graph export "RepartitionMaires_HF_`annee'.png", replace
}
graph pie if maire_mars_2025 == 1, over(codesexe) ///
    plabel(_all percent, color(navy) size(small) gap(22)) ///
    title("Répartition des genres chez les maires en 2020", ///
          color(navy) margin(medsmall)) ///
    graphregion(fcolor(white))
graph export "RepartitionMaires_HF_2020.png", replace

* Statut social par mandat
graph pie if maire_juin_2008 == 1, over(social_status) ///
    plabel(_all percent, format(%4.1f)) ///
    title("Statut social des maires en 2008") ///
    graphregion(fcolor(white))
graph export "StatutSocial_Maires_2008.png", replace

graph pie if maire_juin_2014 == 1, over(social_status) ///
    plabel(_all percent, format(%4.1f)) ///
    title("Statut social des maires en 2014") ///
    graphregion(fcolor(white))
graph export "StatutSocial_Maires_2014.png", replace

graph pie if maire_mars_2025 == 1, over(social_status) ///
    plabel(_all percent, format(%4.1f)) ///
    title("Statut social des maires en 2020") ///
    graphregion(fcolor(white))
graph export "StatutSocial_Maires_2020.png", replace

* PCS par taille de commune et par mandat
foreach mandat_var in "maire_juin_2008" "maire_juin_2014" "maire_mars_2025" {
    local annee = cond("`mandat_var'" == "maire_juin_2008", "2008", ///
                  cond("`mandat_var'" == "maire_juin_2014", "2014", "2020"))
    preserve
    keep if `mandat_var' == 1 & pcs_inconnu == 0

    * PCS détaillées
    collapse (mean) pcs_agriculteurs pcs_artisans pcs_cadres ///
                    pcs_interm pcs_employes pcs_ouvriers, by(tranche_pop)
    foreach var in pcs_agriculteurs pcs_artisans pcs_cadres pcs_interm pcs_employes pcs_ouvriers {
        replace `var' = `var' * 100
    }
    graph bar pcs_agriculteurs pcs_artisans pcs_cadres pcs_interm pcs_employes pcs_ouvriers, ///
        over(tranche_pop, label(angle(45))) stack ///
        title("Répartition des PCS des maires en `annee' par taille de commune") ///
        ytitle("Part (%)") ///
        legend(order(1 "Agriculteurs" 2 "Artisans/Commerçants" 3 "Cadres" ///
                     4 "Prof. intermédiaires" 5 "Employés" 6 "Ouvriers") rows(2)) ///
        graphregion(fcolor(white))
    graph export "PCS_Maires_`annee'.png", replace
    restore
}

* PCS agrégées (3 classes) par taille de commune
preserve
keep if maire_mars_2025 == 1
gen pcs_classes_pop  = pcs_employes + pcs_ouvriers
gen pcs_classes_moy  = pcs_agriculteurs + pcs_artisans + pcs_interm
gen pcs_classes_sup  = pcs_cadres
gen pcs_classes_inco = pcs_inconnu

collapse (mean) pcs_classes_pop pcs_classes_moy pcs_classes_sup pcs_classes_inco, by(tranche_pop)
foreach var in pcs_classes_pop pcs_classes_moy pcs_classes_sup pcs_classes_inco {
    replace `var' = `var' * 100
}
graph bar pcs_classes_pop pcs_classes_moy pcs_classes_sup pcs_classes_inco, ///
    over(tranche_pop, label(angle(45))) stack ///
    title("Répartition des classes sociales des maires en 2020") ///
    ytitle("Part (%)") ///
    legend(order(1 "Classes populaires" 2 "Classes moyennes" ///
                 3 "Classes supérieures" 4 "Inconnu") rows(2)) ///
    graphregion(fcolor(white))
graph export "Classes_Maires_2020.png", replace
restore

* Âge par taille de commune
graph bar (mean) age_2026 if maire_mars_2025 == 1, over(tranche_pop) ///
    title("Âge moyen des maires par taille de commune (2020)") ///
    ytitle("Âge moyen") graphregion(fcolor(white))
graph export "Age_Maires_2020.png", replace

* lpoly statut social et revenu selon population
lpoly high_social_status log_pop if maire_mars_2025 == 1, ///
    title("Part des maires de classe supérieure selon la taille de commune") ///
    ytitle("Part de classe supérieure") xtitle("Log(population)") ///
    graphregion(fcolor(white))
graph export "lpoly_classe_sup.png", replace

lpoly DISP_med log_pop if maire_mars_2025 == 1, ///
    title("Revenu médian communal selon la taille de commune") ///
    ytitle("Revenu médian (€)") xtitle("Log(population)") ///
    graphregion(fcolor(white))
graph export "lpoly_revenu.png", replace
