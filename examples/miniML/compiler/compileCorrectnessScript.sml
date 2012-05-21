open HolKernel bossLib boolLib listTheory pred_setTheory finite_mapTheory alistTheory lcsymtacs
open SatisfySimps boolSimps compileTerminationTheory intLangTheory

val _ = new_theory "compileCorrectness"

(* Invariants *)

val good_cm_cw_def = Define`
  good_cm_cw cm cw =
  (FDOM cw = FRANGE cm) ∧
  (FRANGE cw = FDOM cm) ∧
  (∀x. x ∈ FDOM cm ⇒ (cw ' (cm ' x) = x)) ∧
  (∀y. y ∈ FDOM cw ⇒ (cm ' (cw ' y) = y))`

val good_cmaps_def = Define`
good_cmaps cenv cm cw =
  (∀cn n. do_con_check cenv cn n ⇒ cn IN FDOM cm) ∧
  good_cm_cw cm cw`

(*
val observable_v_def = tDefine "observable_v"`
  (observable_v (Lit l) = T) ∧
  (observable_v (Conv cn vs) = EVERY observable_v vs) ∧
  (observable_v _ = F)`(
WF_REL_TAC `measure v_size` >>
rw[MiniMLTerminationTheory.exp9_size_thm] >>
Q.ISPEC_THEN `v_size` imp_res_tac SUM_MAP_MEM_bound >>
srw_tac[ARITH_ss][])
val _ = export_rewrites["observable_v_def"]

val observable_Cv_def = tDefine "observable_Cv"`
  (observable_Cv (CLit l) = T) ∧
  (observable_Cv (CConv cn vs) = EVERY observable_Cv vs) ∧
  (observable_Cv _ = F)`(
WF_REL_TAC `measure Cv_size` >>
rw[Cexp8_size_thm] >>
Q.ISPEC_THEN `Cv_size` imp_res_tac SUM_MAP_MEM_bound >>
srw_tac[ARITH_ss][])
val _ = export_rewrites["observable_Cv_def"]
*)

val good_G_def = Define`
  good_G G =
    (∀cm v Cv. v_Cv G cm v Cv ⇒ G cm v Cv) ∧
    (∀cm v Cv cw.
      good_cm_cw cm cw ∧
      G cm v Cv ⇒ ((v_to_ov v) = (Cv_to_ov cw) Cv))`

val a_good_G_exists = store_thm(
"a_good_G_exists",
``∃G. good_G G``,
qexists_tac `v_Cv (K (K (K F)))` >>
rw[good_G_def] >- (
  qsuff_tac `∀G cm v Cv. v_Cv G cm v Cv ⇒ (G = v_Cv (K(K(K F)))) ⇒ v_Cv (K(K(K F))) cm v Cv` >- rw[] >>
  ho_match_mp_tac v_Cv_ind >>
  rw[] >>
  rw[v_Cv_cases] >>
  fsrw_tac[boolSimps.ETA_ss][] ) >>
qsuff_tac `∀G cm v Cv. v_Cv G cm v Cv ⇒ (G = K(K(K F))) ∧ good_cm_cw cm cw ⇒ (v_to_ov v = Cv_to_ov cw Cv)` >- (rw[] >> PROVE_TAC[]) >>
ho_match_mp_tac v_Cv_ind >>
rw[] >- fs[good_cm_cw_def] >>
pop_assum mp_tac >>
srw_tac[boolSimps.ETA_ss][] >>
rw[MAP_EQ_EVERY2] >>
PROVE_TAC[EVERY2_LENGTH])

val good_envs_def = Define`
  good_envs env s s' Cenv = s.cmap SUBMAP s'.cmap`

val good_cmap_def = Define`
good_cmap cenv cm =
  (∀cn n. do_con_check cenv cn n ⇒ cn IN FDOM cm)`

val good_repl_state_def = Define`
  good_repl_state s =
    INJ (FAPPLY s.vmap) (FDOM s.vmap) UNIV ∧
    (∀n. n ∈ FRANGE s.vmap ⇒ n < s.nv)`

val good_env_state_def = Define`
  good_env_state env s =
  good_repl_state s ∧
  IMAGE FST (set env) ∪
  BIGUNION (IMAGE (clV_v o SND) (set env))
  ⊆ FDOM s.vmap`

(* Soundness(?) of exp_Cexp *)

(*
val exp_Cexp_thm = store_thm(
"exp_Cexp_thm",``
∀G cm env Cenv exp Cexp. exp_Cexp G cm env Cenv exp Cexp ⇒
  good_G G ⇒
  ∀cenv res.
    evaluate cenv env exp res ⇒
    ∀cw. good_cmaps cenv cm cw ⇒
      ∃Cres.
        Cevaluate Cenv Cexp Cres ∧
        (map_result (Cv_to_ov cw) Cres =
         map_result v_to_ov res)``,
ho_match_mp_tac exp_Cexp_ind >>
rw[] >- (
  fs[good_G_def,good_cmaps_def] >>
  PROVE_TAC[] )
>- (
  fs[EVERY2_EVERY,EVERY_MEM] >>
  qpat_assum `LENGTH es = LENGTH ces` assume_tac >>
  fsrw_tac[boolSimps.DNF_ss][MEM_ZIP] >>
  first_x_assum (assume_tac o (CONV_RULE (RESORT_FORALL_CONV (fn [n,cenv,res,cw] => [cenv,cw,n,res] | _ => raise mk_HOL_ERR"""""")))) >>
  pop_assum (qspecl_then [`cenv`,`cw`] mp_tac) >> rw[] >>
  fs[GSYM RIGHT_EXISTS_IMP_THM,SKOLEM_THM] >>
  fs[evaluate_con,Cevaluate_con] >>
  Cases_on `do_con_check cenv cn (LENGTH Ces)` >> fs[] >> rw[] >- (
    fs[evaluate_list_with_evaluate,evaluate_list_with_error,Cevaluate_list_with_Cevaluate,Cevaluate_list_with_error] >>
    qexists_tac `f n (Rerr err)` >> rw[] >>
    first_assum (qspecl_then [`n`,`Rerr err`] mp_tac) >>
    Cases_on `f n (Rerr err)` >> rw[Cevaluate_list_with_error] >>
    qexists_tac `n` >> rw[] >>
    res_tac >>
    first_x_assum (qspecl_then [`m`,`Rval v`] mp_tac) >>
    `m < LENGTH Ces` by srw_tac[ARITH_ss][] >>
    rw[] >>
    Cases_on `f m (Rval v)` >> fs[] >>
    metis_tac[] )
  >- (
    fs[evaluate_list_with_evaluate,Cevaluate_list_with_Cevaluate] >>
    fs[evaluate_list_with_value,Cevaluate_list_with_value] >>
    qexists_tac `Rval (CConv (cm ' cn) (GENLIST (λn. @v. (f n (Rval (EL n vs))) = Rval v) (LENGTH vs)))` >>
    rw[] >- (
      first_x_assum (qspec_then `n` mp_tac) >>
      first_x_assum (qspec_then `n` mp_tac) >>
      rw[] >>
      first_x_assum (qspec_then `Rval (EL n vs)` mp_tac) >>
      Cases_on `f n (Rval (EL n vs))` >> rw[] )
    >- (
      fs[good_cmaps_def,good_cm_cw_def] ) >>
    rw[MAP_EQ_EVERY2,EVERY2_EVERY,EVERY_MEM,MEM_ZIP,pairTheory.FORALL_PROD] >>
    rw[EL_GENLIST] >>
    first_x_assum (qspec_then `n` mp_tac) >>
    first_x_assum (qspec_then `n` mp_tac) >>
    rw[] >>
    first_x_assum (qspec_then `Rval (EL n vs)` mp_tac) >>
    Cases_on `f n (Rval (EL n vs))` >> rw[] ) >>
  qexists_tac `Rerr Rtype_error` >> rw[] >>
  need Cevaluate to do a con check?
  ) >>
fs[evaluate_var] >> fs[] >> rw[] >>
fs[good_G_def,good_cmaps_def] >>
first_x_assum (match_mp_tac o GSYM) >>
metis_tac[])
*)

val FOLDR_CONS_triple = store_thm(
"FOLDR_CONS_triple",
``!f ls a. FOLDR (\(x,y,z) w. f x y z :: w) a ls = (MAP (\(x,y,z). f x y z) ls)++a``,
GEN_TAC THEN
Induct THEN1 SRW_TAC[][] THEN
Q.X_GEN_TAC `p` THEN
PairCases_on `p` THEN
SRW_TAC[][])

val extend_good_repl_state = store_thm(
"extend_good_repl_state",
``∀s vn s' n. good_repl_state s ∧ (extend s vn = (s',n)) ⇒ good_repl_state s'``,
rw[extend_def] >>
fs[good_repl_state_def,FRANGE_DEF,INJ_DEF] >>
fs[FAPPLY_FUPDATE_THM,FRANGE_DEF,DOMSUB_FAPPLY_THM] >>
fsrw_tac[boolSimps.DNF_ss][] >>
reverse conj_tac >- (
  rw[] >> res_tac >> DECIDE_TAC ) >>
conj_asm1_tac >- (
  rw[] >>
  spose_not_then strip_assume_tac >>
  res_tac >> DECIDE_TAC ) >>
fs[] >> rw[])

val extend_FDOM_SUBSET = store_thm(
"extend_FDOM_SUBSET",
``∀s vn s' n. (extend s vn = (s',n)) ⇒ FDOM s.vmap ⊆ FDOM s'.vmap``,
rw[extend_def,SUBSET_DEF] >> rw[])

val extend_IN_FDOM = store_thm(
"extend_IN_FDOM",
``∀s vn s' n. (extend s vn = (s',n)) ⇒ vn ∈ FDOM s'.vmap``,
rw[extend_def] >> rw[])

val extend_preserve = store_thm(
"extend_preserve",
``∀s vn s' n. (extend s vn = (s',n)) ⇒ ∀v. v ∈ FDOM s.vmap ⇒ (s'.vmap ' v = s.vmap ' v)``,
rw[extend_def] >> rw[FAPPLY_FUPDATE_THM] >> fs[])

val pat_to_Cpat_invariants = store_thm(
"pat_to_Cpat_invariants",
``(∀p s pvs s' pvs' Cp. (pat_to_Cpat s pvs p = (s',pvs',Cp)) ⇒
   (good_repl_state s ⇒ good_repl_state s') ∧
   (FDOM s.vmap ⊆ FDOM s'.vmap) ∧
   (pat_vars p ⊆ FDOM s'.vmap) ∧
   (∀v. v ∈ FDOM s.vmap ⇒ (s'.vmap ' v = s.vmap ' v))) ∧
  (∀ps s pvs s' pvs' Cps. (pats_to_Cpats s pvs ps = (s',pvs',Cps)) ⇒
   (good_repl_state s ⇒ good_repl_state s') ∧
   (FDOM s.vmap ⊆ FDOM s'.vmap) ∧
   (BIGUNION (IMAGE pat_vars (set ps)) ⊆ FDOM s'.vmap) ∧
   (∀v. v ∈ FDOM s.vmap ⇒ (s'.vmap ' v = s.vmap ' v)) ∧
   (LENGTH ps = LENGTH Cps))``,
ho_match_mp_tac (TypeBase.induction_of ``:pat``) >>
fs[pat_to_Cpat_def,LET_THM] >>
conj_tac >- (
  qx_gen_tac `vn` >> qx_gen_tac `s` >>
  Cases_on `extend s vn` >> fs[] >> rw[] >>
  fsrw_tac[SATISFY_ss][extend_good_repl_state,extend_FDOM_SUBSET,extend_IN_FDOM,extend_preserve] ) >>
conj_tac >- (
  Induct >- rw[pat_to_Cpat_def] >>
  simp_tac (srw_ss()) [pat_to_Cpat_def,LET_THM] >>
  qx_gen_tac `p` >>
  strip_tac >>
  qx_gen_tac `cn` >>
  qx_gen_tac `s` >>
  qx_gen_tac `pvs` >>
  qabbrev_tac `r = pats_to_Cpats s pvs ps` >>
  pop_assum (assume_tac o SYM o REWRITE_RULE [markerTheory.Abbrev_def]) >>
  PairCases_on `r` >>
  simp_tac(srw_ss())[] >>
  qabbrev_tac `r = pat_to_Cpat r0 r1 p` >>
  pop_assum (assume_tac o SYM o REWRITE_RULE [markerTheory.Abbrev_def]) >>
  PairCases_on `r` >>
  simp_tac(srw_ss())[] >>
  first_x_assum (qspecl_then [`s`,`pvs`] mp_tac) >>
  ntac 2 (pop_assum mp_tac) >>
  simp_tac(srw_ss()++ETA_ss)[] ) >>
rw[] >>
qabbrev_tac `r = pats_to_Cpats s pvs ps` >>
pop_assum (assume_tac o SYM o REWRITE_RULE [markerTheory.Abbrev_def]) >>
PairCases_on `r` >>
fs[] >>
qabbrev_tac `r = pat_to_Cpat r0 r1 p` >>
pop_assum (assume_tac o SYM o REWRITE_RULE [markerTheory.Abbrev_def]) >>
PairCases_on `r` >>
fs[] >> rw[] >>
PROVE_TAC[SUBSET_TRANS,SUBSET_DEF])

(* TODO: move? *)
val FOLDR_invariant = store_thm(
"FOLDR_invariant",
``∀P ls f a. P a ∧ (∀x a. MEM x ls ∧ P a ⇒ P (f x a)) ⇒ P (FOLDR f a ls)``,
GEN_TAC THEN Induct THEN SRW_TAC[][])

val exp_to_Cexp_nice_ind = save_thm(
"exp_to_Cexp_nice_ind",
exp_to_Cexp_ind
|> Q.SPECL [`P`
   ,`λs defs. EVERY (λ(d,vn,e). P (FST (extend s vn)) e) defs`
   ,`λs pes. EVERY (λ(p,e). P (FST (pat_to_Cpat s [] p)) e) pes`
   ,`λs. EVERY (P s)`
   ,`Pv`
   ,`λs. EVERY (Pv s)`
   ,`λs. EVERY (Pv s o SND)`]
|> SIMP_RULE (srw_ss()) []
|> UNDISCH_ALL
|> CONJUNCTS
|> (fn ls => CONJ (List.nth(ls,0)) (List.nth(ls,4)))
|> DISCH_ALL
|> Q.GEN `Pv` |> Q.GEN `P`
|> SIMP_RULE (srw_ss()) [])

val exps_to_Cexps_MAP = store_thm(
"exps_to_Cexps_MAP",
``∀s es. exps_to_Cexps s es = MAP (exp_to_Cexp s) es``,
gen_tac >> Induct >> rw[exp_to_Cexp_def])

val pes_to_Cpes_MAP = store_thm(
"pes_to_Cpes_MAP",
``∀s pes. pes_to_Cpes s pes = (s, MAP (λ(p,e). let (s,pvs,Cp) = pat_to_Cpat s [] p in (Cp, exp_to_Cexp s e)) pes)``,
gen_tac >> Induct >- rw[exp_to_Cexp_def] >>
Cases >> rw[exp_to_Cexp_def])

val defs_to_Cdefs_MAP = store_thm(
"defs_to_Cdefs_MAP",
``∀s defs. defs_to_Cdefs s defs = MAP (λ(d,vn,e). let (s',n) = extend s vn in ([n],exp_to_Cexp s' e)) defs``,
gen_tac >> Induct >- rw[exp_to_Cexp_def] >>
qx_gen_tac `d` >> PairCases_on `d` >> rw[exp_to_Cexp_def])

val vs_to_Cvs_MAP = store_thm(
"vs_to_Cvs_MAP",
``∀s vs. vs_to_Cvs s vs = MAP (v_to_Cv s) vs``,
gen_tac >> Induct >> rw[exp_to_Cexp_def])

val env_to_Cenv_MAP = store_thm(
"env_to_Cenv_MAP",
``∀s env. env_to_Cenv s env = MAP (λ(x,v). (s.vmap ' x, v_to_Cv s v)) env``,
gen_tac >> Induct >- rw[exp_to_Cexp_def] >>
Cases >> rw[exp_to_Cexp_def])

val extend_defs_invariants = store_thm(
"extend_defs_invariants",
``∀defs s s' fns. (extend_defs s defs = (s',fns)) ⇒
  (good_repl_state s ⇒ good_repl_state s') ∧
  FDOM s.vmap ⊆ FDOM s'.vmap ∧
  IMAGE FST (set defs) ⊆ FDOM s'.vmap ∧
  (∀v. v ∈ FDOM s.vmap ⇒ (s'.vmap ' v = s.vmap ' v)) ∧
  (set fns = IMAGE (FAPPLY s'.vmap o FST) (set defs))``,
Induct >> fs[extend_defs_def] >>
qx_gen_tac `d` >> PairCases_on `d` >>
fs[extend_defs_def,LET_THM] >>
qx_gen_tac `s` >>
qabbrev_tac `p = extend s d0` >>
PairCases_on `p` >> fs[] >>
qabbrev_tac `q = extend_defs p0 defs` >>
PairCases_on `q` >> fs[] >>
fs[SUBSET_DEF,pairTheory.EXISTS_PROD] >>
conj_asm1_tac >- PROVE_TAC[extend_good_repl_state] >>
conj_asm1_tac >- PROVE_TAC[extend_FDOM_SUBSET,SUBSET_DEF] >>
conj_asm1_tac >- PROVE_TAC[extend_IN_FDOM] >>
conj_asm1_tac >- PROVE_TAC[extend_preserve,extend_FDOM_SUBSET,SUBSET_DEF] >>
qpat_assum `Abbrev (X = extend s d0)` mp_tac >>
rw[markerTheory.Abbrev_def,extend_def] >- PROVE_TAC[] >>
fs[markerTheory.Abbrev_def] >>
qmatch_assum_abbrev_tac `(q0,q1) = extend_defs ss defs` >>
first_x_assum (qspecl_then [`ss`,`q0`,`q1`] mp_tac) >>
rw[] >> AP_THM_TAC >> AP_TERM_TAC >>
qunabbrev_tac `ss` >> fs[])

val tac =
  rw[force_dom_DRESTRICT_FUNION,FUNION_DEF,DRESTRICT_DEF,MEM_MAP,pairTheory.EXISTS_PROD,FUN_FMAP_DEF,MAP_MAP_o] >>
  qmatch_abbrev_tac `canonical_env_Cv ((alist_to_fmap (MAP f env)) ' k)` >>
  `∃f1 f2. f = (λ(n,v). (f1 n, f2 v))` by (
    rw[FUN_EQ_THM,pairTheory.UNCURRY,Abbr`f`,pairTheory.FORALL_PROD] >>
    rw[GSYM SKOLEM_THM,Once SWAP_EXISTS_THM] >>
    rw[FORALL_AND_THM] >>
    rw[GSYM SKOLEM_THM] ) >>
  `INJ f1 (set (MAP FST env)) UNIV` by (
    unabbrev_all_tac >>
    fs[good_repl_state_def] >>
    fs[INJ_DEF] >>
    fs[FUN_EQ_THM,pairTheory.FORALL_PROD,FORALL_AND_THM] >>
    rpt strip_tac >> fs[] >>
    first_x_assum (match_mp_tac o MP_CANON) >> fs[] >>
    fs[SUBSET_DEF,pairTheory.EXISTS_PROD,MEM_MAP] >>
    metis_tac[] ) >>
  fs[] >>
  rw[alist_to_fmap_MAP] >>
  qmatch_abbrev_tac `canonical_env_Cv (MAP_KEYS f1 fm ' k)` >>
  `∃a. (a ∈ FDOM fm) ∧ (k = f1 a)` by (
    fs[FUN_EQ_THM,markerTheory.Abbrev_def,pairTheory.FORALL_PROD,MEM_MAP,pairTheory.EXISTS_PROD] >>
    metis_tac[] ) >>
  rw[] >>
  `INJ f1 (FDOM fm) UNIV` by (
    fs[FUN_EQ_THM,markerTheory.Abbrev_def,pairTheory.FORALL_PROD] ) >>
  rw[MAP_KEYS_def,Abbr`fm`] >>
  fs[o_f_DEF,markerTheory.Abbrev_def,FUN_EQ_THM,pairTheory.FORALL_PROD]

val exp_to_Cexp_canonical = store_thm(
"exp_to_Cexp_canonical",``
(∀s e.
  good_repl_state s ∧
  clV_exp e ⊆ FDOM s.vmap
  ⇒ canonical_env_Cexp (exp_to_Cexp s e)) ∧
(∀s v.
  good_repl_state s ∧
  (clV_v v ⊆ FDOM s.vmap)
  ⇒ canonical_env_Cv (v_to_Cv s v))``,
ho_match_mp_tac exp_to_Cexp_nice_ind >>
rw[exp_to_Cexp_def,exps_to_Cexps_MAP,pes_to_Cpes_MAP,defs_to_Cdefs_MAP,vs_to_Cvs_MAP,env_to_Cenv_MAP] >>
fsrw_tac[boolSimps.DNF_ss][BIGUNION_SUBSET,exp_to_Cexp_def,EVERY_MEM,MEM_MAP,pairTheory.FORALL_PROD,AND_IMP_INTRO] >>
fsrw_tac[SATISFY_ss][] >>
TRY (
  first_x_assum match_mp_tac >>
  conj_asm1_tac >- (
    fsrw_tac[SATISFY_ss][extend_good_repl_state] ) >>
  imp_res_tac extend_FDOM_SUBSET >>
  fsrw_tac[SATISFY_ss][SUBSET_DEF] >>
  NO_TAC)
>- (
  BasicProvers.EVERY_CASE_TAC >>
  fs[LET_THM] >> rw[] >>
  fs[EVERY_MEM] )
>- (
  Cases_on `dest_var e` >> fs[EVERY_MEM,MEM_MAP,pairTheory.EXISTS_PROD,LET_THM,pairTheory.UNCURRY] >>
  srw_tac[DNF_ss][] >>
  first_x_assum (match_mp_tac o MP_CANON) >> fs[] >>
  qmatch_rename_tac `good_repl_state (FST (pat_to_Cpat s0 [] p0)) ∧ X`["X"] >>
  qabbrev_tac `q = pat_to_Cpat s0 [] p0` >> PairCases_on `q` >> fs[] >>
  PROVE_TAC[pat_to_Cpat_invariants,SUBSET_TRANS] )
>- (
  unabbrev_all_tac >> rw[MEM_MAP,pairTheory.EXISTS_PROD,LET_THM,pairTheory.UNCURRY] >>
  first_x_assum (match_mp_tac o MP_CANON) >>
  TRY (
    qmatch_assum_rename_tac `MEM (p0,p1,p2) defs`[] >>
    qexists_tac `p0` >>
    qabbrev_tac `q = extend s' p1` >>
    PairCases_on `q` >> fs[] ) >>
  PROVE_TAC[extend_good_repl_state,extend_FDOM_SUBSET,SUBSET_TRANS,extend_defs_invariants] )
>- ( Cases_on `extend s vn` >> fs[] )
>- ( Cases_on `extend s vn` >> fs[] )
>- ( qabbrev_tac `q = pat_to_Cpat s [] p` >> PairCases_on `q` >> fs[] )
>- ( qabbrev_tac `q = pat_to_Cpat s [] p` >> PairCases_on `q` >> fs[] )
>- (
  unabbrev_all_tac >>
  rw[mk_env_def,FLOOKUP_DEF] >>
  tac )
>- (
 Cases_on `find_index n fns 0` >> fs[] >>
 fs[LET_THM] >>
 imp_res_tac find_index_LESS_LENGTH >>
 Cases_on `LENGTH fns = LENGTH Cdefs` >> fs[] >>
 TRY (rw[pairTheory.UNCURRY] >> NO_TAC) >>
 fs[MEM_MAP,EVERY_MAP,EL_MAP,DIFF_UNION,DIFF_COMM] >>
 fs[FOLDR_CONS_triple,LET_THM,pairTheory.UNCURRY,MAP_MAP_o] >>
 qunabbrev_tac `Cdefs` >> fs[EVERY_MAP,pairTheory.UNCURRY,EL_MAP] >>
 rw[EVERY_MEM,pairTheory.FORALL_PROD,FLOOKUP_DEF,mk_env_def,DIFF_UNION,DIFF_COMM] >>
 unabbrev_all_tac >>
 tac))

val force_dom_FUNION_id = store_thm(
"force_dom_FUNION_id",
``∀fm s d. FINITE s ⇒ ((force_dom fm s d ⊌ fm = fm) = (s ⊆ FDOM fm))``,
rw[force_dom_DRESTRICT_FUNION,GSYM SUBMAP_FUNION_ABSORPTION] >>
rw[SUBMAP_DEF,DRESTRICT_DEF,FUN_FMAP_DEF,EQ_IMP_THM,SUBSET_DEF,FUNION_DEF] >>
fs[])

val Cevaluate_FUPDATE = store_thm(
"Cevaluate_FUPDATE",
``∀env exp res k v. Cevaluate env exp res ∧
 (free_vars exp ⊆ FDOM env) ∧
 k ∉ free_vars exp
 ⇒ Cevaluate (env |+ (k,v)) exp res``,
rw[] >>
qsuff_tac `env |+ (k,v) = (force_dom env (free_vars exp) (CLit (Bool F))) ⊌ (env |+ (k,v))` >- metis_tac[Cevaluate_any_env] >>
rw[GSYM SUBMAP_FUNION_ABSORPTION] >>
rw[force_dom_DRESTRICT_FUNION,SUBMAP_DEF,FUNION_DEF,FUN_FMAP_DEF,DRESTRICT_DEF,FAPPLY_FUPDATE_THM] >>
fs[SUBSET_DEF] >> rw[] >> fs[])

val force_dom_idempot = store_thm(
"force_dom_idempot",
``FINITE s ==> (force_dom (force_dom fm s d) s d = force_dom fm s d)``,
rw[force_dom_id])
val _ = export_rewrites["force_dom_idempot"]

val Cevaluate_super_env = store_thm(
"Cevaluate_super_env",
``∀s env exp res. FINITE s ∧ Cevaluate (force_dom env (free_vars exp) (CLit (Bool F))) exp res ∧ free_vars exp ⊆ s ⇒ Cevaluate (force_dom env s (CLit (Bool F))) exp res``,
rw[] >>
imp_res_tac Cevaluate_any_env >>
qpat_assum `FINITE s` assume_tac >>
fs[] >>
qmatch_abbrev_tac `Cevaluate env1 exp res` >>
qmatch_assum_abbrev_tac `∀env'. Cevaluate (env0 ⊌ env') exp res` >>
qsuff_tac `env1 = env0 ⊌ env1` >- metis_tac[] >>
rw[GSYM SUBMAP_FUNION_ABSORPTION] >>
fsrw_tac[][Abbr`env0`,Abbr`env1`,SUBMAP_DEF,SUBSET_DEF,force_dom_DRESTRICT_FUNION] >> rw[] >>
srw_tac[][FUN_FMAP_DEF,DRESTRICT_DEF,FUNION_DEF])

(* Prove compiler phases preserve semantics *)

(* TODO: move? *)
val ALOOKUP_NONE = store_thm(
"ALOOKUP_NONE",
``!l x. (ALOOKUP l x = NONE) = ~MEM x (MAP FST l)``,
SRW_TAC[][ALOOKUP_FAILS,MEM_MAP,pairTheory.FORALL_PROD])

val force_dom_FUPDATE = store_thm(
"force_dom_FUPDATE",
``∀fm s d k v. FINITE s ⇒ ((force_dom fm s d) |+ (k,v) = force_dom (fm |+ (k,v)) (k INSERT s) d)``,
rw[force_dom_DRESTRICT_FUNION,GSYM fmap_EQ_THM,DRESTRICT_DEF,FUNION_DEF,FUN_FMAP_DEF,FAPPLY_FUPDATE_THM] >>
rw[FUN_FMAP_DEF] >> fs[])

val force_dom_of_FUPDATE = store_thm(
"force_dom_of_FUPDATE",
``∀fm s d k v. FINITE s ∧ k ∉ s ⇒ (force_dom (fm |+ (k,v)) s d = force_dom fm s d)``,
rw[force_dom_DRESTRICT_FUNION])

(*
val exp_to_Cexp_nontp_same_next = store_thm(
"exp_to_Cexp_nontp_same_next",
``∀tp cm Ps Pexp s exp s' Cexp. ((Ps,Pexp) = (s,exp)) ∧
(exp_to_Cexp tp cm (s,exp) = (s',Cexp))
∧ (tp = F) ⇒ (s'.n = s.n)``,
ho_match_mp_tac exp_to_Cexp_ind >>
rw[] >>
fs[exp_to_Cexp_def,LET_THM,pairTheory.UNCURRY] >>

val exp_to_Cexp_vars_below_next = store_thm(
"exp_to_Cexp_vars_below_next",
``∀tp cm Ps Pexp s exp s' Cexp. ((Ps,Pexp) = (s,exp)) ∧
  (exp_to_Cexp tp cm (s,exp) = (s',Cexp))
⇒ ∀v. v ∈ free_vars Cexp ⇒ v < s'.n
exp_to_Cexp_ind
*)

val exp_to_Cexp_App_case = store_thm(
"exp_to_Cexp_App_case",
``(exp_to_Cexp s (App op e1 e2) = x) ⇒
  ((∃Ce Ces. (x = CCall Ce Ces) ∧ (op = Opapp)) ∨
   (∃ns es b. (x = CLet ns es b) ∧ ((op = Opb Gt) ∨ (op = Opb Geq))) ∨
   (∃Cop2 Ce1 Ce2. x = CPrim2 Cop2 Ce1 Ce2) ∨
   (∃Ce1 Ce2. x = CLprim CLeq [Ce1; Ce2]))``,
Cases_on `op` >> rw[exp_to_Cexp_def,LET_THM] >>
BasicProvers.EVERY_CASE_TAC >> rw[])

val dest_var_def = save_thm("dest_var_def",CompileTheory.dest_var_def)
val _ = export_rewrites["dest_var_def"]

val dest_var_case = store_thm(
"dest_var_case",
``(dest_var e = SOME x) ⇒ (∃v. e = Var v)``,
Cases_on `e` >> rw[dest_var_def])

val exp_to_Cexp_cases = store_thm(
"exp_to_Cexp_cases",``
(¬(exp_to_Cexp s e = CDecl xs)) ∧
((exp_to_Cexp s e = CRaise err) = (e = Raise err)) ∧
((exp_to_Cexp s e = CVar n) = (∃x. (e = Var x) ∧ (n = s.vmap ' x))) ∧
((exp_to_Cexp s e = CVal Cv) = (∃v. (e = Val v) ∧ (Cv = v_to_Cv s v))) ∧
((exp_to_Cexp s e = CCon cn Ces) ⇒ (∃n es. (e = Con n es))) ∧
(¬(exp_to_Cexp s e = CTagEq Ce n)) ∧
(¬(exp_to_Cexp s e = CProj Ce n)) ∧
((exp_to_Cexp s e = CMat n Cpes) ⇒ (∃v pes. e = Mat (Var v) pes)) ∧
(¬(exp_to_Cexp s e = CLetfun F fns Cdefs Cb)) ∧
((exp_to_Cexp s e = CLet xs es Ce) ⇒ ((∃e1 pes. (e = Mat e1 pes) ∧ (dest_var e = NONE)) ∨ (∃opb e1 e2. (e = App (Opb opb) e1 e2) ∧ ((opb = Gt) ∨ (opb = Geq))) ∨ (∃x r b. e = Let x r b))) ∧
((exp_to_Cexp s e = CFun xs Ce) ⇒ (∃x b. e = Fun x b)) ∧
((exp_to_Cexp s e = CCall Ce es) ⇒ (∃e1 e2. e = App Opapp e1 e2)) ∧
((exp_to_Cexp s e = CLetfun T fns Cdefs Cb) ⇒ (∃defs b. e = Letrec defs b))``,
Cases_on `e` >> rw[exp_to_Cexp_def] >>
BasicProvers.EVERY_CASE_TAC >> rw[EQ_IMP_THM] >>
imp_res_tac dest_var_case >> fs[] >>
spose_not_then strip_assume_tac >>
imp_res_tac exp_to_Cexp_App_case >>
fs[LET_THM,pairTheory.UNCURRY] >> rw[])

(* TODO: move? *)
val DIFF_SAME_UNION = store_thm(
"DIFF_SAME_UNION",
``!x y. ((x UNION y) DIFF x = y DIFF x) /\ ((x UNION y) DIFF y = x DIFF y)``,
SRW_TAC[][EXTENSION,EQ_IMP_THM])

val FOLDR_transitive_property = store_thm(
"FOLDR_transitive_property",
``!P ls f a. P [] a /\ (!n a. n < LENGTH ls /\ P (DROP (SUC n) ls) a ==> P (DROP n ls) (f (EL n ls) a)) ==> P ls (FOLDR f a ls)``,
GEN_TAC THEN Induct THEN SRW_TAC[][] THEN
`P ls (FOLDR f a ls)` by (
  FIRST_X_ASSUM MATCH_MP_TAC THEN
  SRW_TAC[][] THEN
  Q.MATCH_ASSUM_RENAME_TAC `P (DROP (SUC n) ls) b` [] THEN
  FIRST_X_ASSUM (Q.SPECL_THEN [`SUC n`,`b`] MP_TAC) THEN
  SRW_TAC[][] ) THEN
FIRST_X_ASSUM (Q.SPEC_THEN `0` MP_TAC) THEN
SRW_TAC[][])

val MEM_DROP = store_thm(
"MEM_DROP",
``!x ls n. MEM x (DROP n ls) = (n < LENGTH ls /\ (x = (EL n ls))) \/ MEM x (DROP (SUC n) ls)``,
GEN_TAC THEN
Induct THEN1 SRW_TAC[][] THEN
NTAC 2 GEN_TAC THEN
SIMP_TAC (srw_ss()) [] THEN
Cases_on `n` THEN SIMP_TAC (srw_ss()) [] THEN
PROVE_TAC[])

val Cpat_vars_pat_to_Cpat = store_thm(
"Cpat_vars_pat_to_Cpat",
``(∀p s pvs s' pvs' Cp. (pat_to_Cpat s pvs p = (s',pvs',Cp))
  ⇒ (Cpat_vars Cp = IMAGE (FAPPLY s'.vmap) (pat_vars p))) ∧
  (∀ps s pvs s' pvs' Cps. (pats_to_Cpats s pvs ps = (s',pvs',Cps))
  ⇒ (MAP Cpat_vars Cps = MAP (IMAGE (FAPPLY s'.vmap) o pat_vars) ps))``,
ho_match_mp_tac (TypeBase.induction_of ``:pat``) >>
rw[pat_to_Cpat_def,LET_THM,pairTheory.UNCURRY] >>
rw[FOLDL_UNION_BIGUNION,IMAGE_BIGUNION] >- (
  rw[extend_def] )
>- (
  qabbrev_tac `q = pats_to_Cpats s' pvs ps` >>
  PairCases_on `q` >>
  fsrw_tac[ETA_ss][MAP_EQ_EVERY2,EVERY2_EVERY,EVERY_MEM,pairTheory.FORALL_PROD] >>
  AP_TERM_TAC >>
  first_x_assum (qspecl_then [`s'`,`pvs`] mp_tac) >>
  rw[] >>
  pop_assum mp_tac >>
  rw[MEM_ZIP] >>
  rw[Once EXTENSION,MEM_EL] >>
  PROVE_TAC[] )
>- (
  qabbrev_tac `q = pats_to_Cpats s pvs ps` >>
  PairCases_on `q` >>
  qabbrev_tac `r = pat_to_Cpat q0 q1 p` >>
  PairCases_on `r` >>
  fs[] >>
  PROVE_TAC[] )
>- (
  qabbrev_tac `q = pats_to_Cpats s pvs ps` >>
  PairCases_on `q` >>
  qabbrev_tac `r = pat_to_Cpat q0 q1 p` >>
  PairCases_on `r` >>
  fs[] >>
  fs[LIST_EQ_REWRITE] >>
  conj_asm1_tac >- PROVE_TAC[pat_to_Cpat_invariants] >>
  first_x_assum (qspecl_then [`s`,`pvs`,`q0`,`q1`,`q2`] mp_tac) >>
  rw[EL_MAP] >>
  rw[Once EXTENSION] >>
  qsuff_tac `pat_vars (EL x ps) ⊆ FDOM q0.vmap`
    >- PROVE_TAC [pat_to_Cpat_invariants,SUBSET_DEF] >>
  `BIGUNION (IMAGE pat_vars (set ps)) ⊆ FDOM q0.vmap`
    by PROVE_TAC [pat_to_Cpat_invariants] >>
  fs[SUBSET_DEF,MEM_EL] >>
  PROVE_TAC[]))

val free_vars_exp_to_Cexp = store_thm(
"free_vars_exp_to_Cexp",
``
(∀s e. good_repl_state s ∧ (FV e ⊆ FDOM s.vmap) ⇒
  (free_vars (exp_to_Cexp s e) = IMAGE (FAPPLY s.vmap) (FV e))) ∧
(∀(s:repl_state) (v:v). T)``,
ho_match_mp_tac exp_to_Cexp_nice_ind >>
srw_tac[ETA_ss,DNF_ss][exp_to_Cexp_def,exps_to_Cexps_MAP,pes_to_Cpes_MAP,defs_to_Cdefs_MAP,
FOLDL_UNION_BIGUNION,IMAGE_BIGUNION,BIGUNION_SUBSET,LET_THM,EVERY_MEM] >>
rw[] >- (
  AP_TERM_TAC >>
  rw[Once EXTENSION] >>
  fsrw_tac[DNF_ss][MEM_MAP,EVERY_MEM] >>
  PROVE_TAC[] )
>- (
  qabbrev_tac `p = extend s vn` >>
  PairCases_on `p` >> rw[] >>
  rw[Once EXTENSION] >>
  `good_repl_state p0` by metis_tac[extend_good_repl_state] >>
  `FV e ⊆ FDOM p0.vmap` by (
    fs[SUBSET_DEF] >>
    PROVE_TAC[SUBSET_DEF,extend_FDOM_SUBSET,extend_IN_FDOM] ) >>
  fs[extend_def] >>
  Cases_on `vn ∈ FDOM s.vmap` >>
  fs[markerTheory.Abbrev_def,FAPPLY_FUPDATE_THM] >- (
    fs[good_repl_state_def,INJ_DEF,SUBSET_DEF] >>
    rw[EQ_IMP_THM] >>
    PROVE_TAC[] ) >>
  rw[] >>
  rw[EQ_IMP_THM] >> rw[] >>
  fs[good_repl_state_def,FRANGE_DEF,FAPPLY_FUPDATE_THM,SUBSET_DEF] >>
  PROVE_TAC[prim_recTheory.LESS_REFL] )
>- (
  fs[] >>
  BasicProvers.EVERY_CASE_TAC >> rw[] >>
  srw_tac[DNF_ss][Once EXTENSION] >>
  PROVE_TAC[] )
>- (
  srw_tac[DNF_ss][Once EXTENSION] >>
  PROVE_TAC[] )
>- (
  fs[EVERY_MEM,pairTheory.FORALL_PROD] >>
  Cases_on `dest_var e` >> fs[] >>
  rw[FOLDL_UNION_BIGUNION_paired,DIFF_SAME_UNION,UNION_COMM] >>
  imp_res_tac dest_var_case >> rw[] >> fs[] >> rw[] >>
  AP_TERM_TAC >>
  rw[Once EXTENSION,MEM_MAP,pairTheory.EXISTS_PROD] >>
  srw_tac[DNF_ss][] >>
  fs[SUBSET_DEF,pairTheory.UNCURRY] >>
  srw_tac[DNF_ss][CONJ_ASSOC, Once CONJ_COMM] >>
  ((qho_match_abbrev_tac `
      (∃p1 p2. A p1 p2 ∧ MEM (p1,p2) pes) =
      (∃p1 p2 x. B p1 p2 x ∧ MEM (p1,p2) pes)`)
   ORELSE
   (rw[Once(GSYM CONJ_ASSOC),SimpLHS] >>
    qho_match_abbrev_tac `
      (∃p1 p2. MEM (p1,p2) pes ∧ A p1 p2) =
      (∃p1 p2 x. B p1 p2 x ∧ MEM (p1,p2) pes)`)) >>
  (qsuff_tac `∀p1 p2. MEM (p1,p2) pes ⇒ (A p1 p2 = ∃x. B p1 p2 x)` >- PROVE_TAC[]) >>
  srw_tac[DNF_ss][Abbr`A`,Abbr`B`] >>
  rpt (first_x_assum (qspecl_then [`p1`,`p2`] mp_tac)) >>
  qabbrev_tac `q = pat_to_Cpat s [] p1` >>
  PairCases_on `q` >> fs[] >>
  `good_repl_state q0` by PROVE_TAC[pat_to_Cpat_invariants] >>
  rw[] >>
  `pat_vars p1 ⊆ FDOM q0.vmap` by PROVE_TAC[pat_to_Cpat_invariants] >>
  `FV p2 ⊆ FDOM q0.vmap` by (
    PROVE_TAC[pat_to_Cpat_invariants,SUBSET_DEF] ) >>
  fs[SUBSET_DEF] >>
  fs[markerTheory.Abbrev_def] >>
  qpat_assum`X = pat_to_Cpat s [] p1` (assume_tac o SYM) >>
  imp_res_tac Cpat_vars_pat_to_Cpat >>
  EQ_TAC >> strip_tac >- (
    qpat_assum `Cpat_vars q2 = X` assume_tac >>
    fs[] >> PROVE_TAC[pat_to_Cpat_invariants] ) >>
  fs[Once EXTENSION] >>
  rw[] >- (
    res_tac >>
    fs[good_repl_state_def,FRANGE_DEF] >>
    PROVE_TAC[prim_recTheory.LESS_REFL,pat_to_Cpat_invariants] ) >>
  TRY (
    qmatch_rename_tac `s.vmap ' x1 ≠ q0.vmap ' x2 ∨ x2 ∉ pat_vars p1`[] >>
    spose_not_then strip_assume_tac >>
    `q0.vmap ' x1 = q0.vmap ' x2` by PROVE_TAC[pat_to_Cpat_invariants] >>
    fs[good_repl_state_def,INJ_DEF] >>
    PROVE_TAC[] ) >>
  PROVE_TAC[pat_to_Cpat_invariants] )
>- (
  fs[] >>
  qabbrev_tac `p = extend s vn` >>
  PairCases_on `p` >> rw[] >>
  qpat_assum `Abbrev x` (assume_tac o SYM o REWRITE_RULE[markerTheory.Abbrev_def]) >> fs[] >>
  qmatch_assum_rename_tac `FV e2 DIFF {vn} ⊆ FDOM s.vmap` [] >>
  `FV e2 ⊆ FDOM p0.vmap` by (
    imp_res_tac extend_FDOM_SUBSET >>
    fs[SUBSET_DEF] >>
    metis_tac[extend_IN_FDOM] ) >>
  imp_res_tac extend_good_repl_state >>
  fs[] >>
  rw[UNION_COMM] >>
  AP_TERM_TAC >>
  rw[Once EXTENSION] >>
  qpat_assum `extend s vn = X` mp_tac >>
  rw[extend_def] >> rw[FAPPLY_FUPDATE_THM] >- (
    fs[good_repl_state_def,INJ_DEF] >>
    metis_tac[SUBSET_DEF] ) >>
  fs[] >>
  rw[EQ_IMP_THM] >> rw[]
    >- metis_tac[] >- metis_tac[] >>
  fs[good_repl_state_def,FRANGE_DEF] >>
  metis_tac[prim_recTheory.LESS_REFL,SUBSET_DEF,IN_INSERT] )
>- (
  qabbrev_tac `p = extend_defs s defs` >>
  PairCases_on `p` >>
  fs[FOLDL_UNION_BIGUNION_paired] >>
  `good_repl_state p0 ∧ FV e ⊆ FDOM p0.vmap` by (
    fs[SUBSET_DEF] >>
    PROVE_TAC[SIMP_RULE(srw_ss())[SUBSET_DEF]extend_defs_invariants] ) >>
  fs[] >>
  qmatch_abbrev_tac `X ∪ Y = Z ∪ A` >>
  `X = A` by (
    fs[markerTheory.Abbrev_def] >>
    rw[EXTENSION,pairTheory.FORALL_PROD] >>
    fs[SUBSET_DEF,pairTheory.FORALL_PROD] >>
    rw[EQ_IMP_THM]
      >- PROVE_TAC[SIMP_RULE(srw_ss())[EXTENSION,pairTheory.EXISTS_PROD]extend_defs_invariants]
      >- PROVE_TAC[SIMP_RULE(srw_ss())[EXTENSION,pairTheory.EXISTS_PROD]extend_defs_invariants] >>
    qmatch_rename_tac `¬MEM (s.vmap ' xz) p1`[] >>
    qsuff_tac `∀xx p1 p2. MEM (xx,p1,p2) defs ⇒ (s.vmap ' xz ≠ p0.vmap ' xx)`
      >- PROVE_TAC[SIMP_RULE(srw_ss())[EXTENSION,pairTheory.EXISTS_PROD]extend_defs_invariants] >>
    `xz ∈ FDOM s.vmap` by PROVE_TAC[] >>
    `s.vmap ' xz = p0.vmap ' xz` by PROVE_TAC[extend_defs_invariants] >>
    rw[] >>
    spose_not_then strip_assume_tac >>
    qsuff_tac `xx = xz` >- PROVE_TAC[] >>
    fs[good_repl_state_def,INJ_DEF] >>
    qsuff_tac `xx ∈ FDOM p0.vmap` >- PROVE_TAC[] >>
    `IMAGE FST (set defs) ⊆ FDOM p0.vmap` by PROVE_TAC[extend_defs_invariants] >>
    fs[SUBSET_DEF,pairTheory.EXISTS_PROD] >> PROVE_TAC[] ) >>
  rw[UNION_COMM] >>
  qpat_assum `Abbrev (pp = extend_defs s defs)` (assume_tac o SYM o SIMP_RULE(srw_ss())[markerTheory.Abbrev_def]) >>
  unabbrev_all_tac >>
  ntac 2 AP_TERM_TAC >>
  rw[Once EXTENSION,pairTheory.EXISTS_PROD] >>
  srw_tac[DNF_ss][MEM_MAP,pairTheory.EXISTS_PROD,pairTheory.UNCURRY] >>
  qho_match_abbrev_tac `(∃q1 q2 q3. A q2 q3 ∧ MEM (q1,q2,q3) defs) = (∃q1 q2 q3. B q2 q3 ∧ MEM (q1,q2,q3) defs)` >>
  qsuff_tac `∀q0 q1 q2. MEM (q0,q1,q2) defs ⇒ (A q1 q2 = B q1 q2)` >- PROVE_TAC[] >>
  rw[Abbr`A`,Abbr`B`] >>
  qmatch_abbrev_tac `(x = A) = (x = B)` >>
  qsuff_tac `A = B` >- PROVE_TAC[] >>
  rw[Abbr`A`,Abbr`B`] >>
  qabbrev_tac `r = extend p0 q1` >>
  PairCases_on `r` >> fs[] >>
  fs[pairTheory.FORALL_PROD] >>
  rpt (first_x_assum (qspecl_then [`q0`,`q1`,`q2`] mp_tac)) >>
  `good_repl_state r0` by metis_tac [extend_good_repl_state] >>
  fs[] >> rw[] >>
  imp_res_tac extend_defs_invariants >>
  fs[SUBSET_DEF,pairTheory.FORALL_PROD,pairTheory.EXISTS_PROD] >>
  `FV q2 ⊆ FDOM r0.vmap` by (
    rw[SUBSET_DEF] >>
    metis_tac[extend_IN_FDOM,extend_FDOM_SUBSET,SUBSET_DEF] ) >>
  fs[SUBSET_DEF] >>
  rw[DIFF_UNION,IMAGE_COMPOSE] >>
  rw[DIFF_COMM,DIFF_DIFF] >>
  srw_tac[DNF_ss][Once EXTENSION,pairTheory.FORALL_PROD,GSYM CONJ_ASSOC] >>
  qho_match_abbrev_tac `(∃z. (x = r0.vmap ' z) ∧ (z ∈ FV p2) ∧ A x) = (∃z. (x = s.vmap ' z) ∧ (z ∈ FV p2) ∧ B z)` >>
  qsuff_tac `∀z. z ∈ FV p2 ⇒ (B z ⇒ (r0.vmap ' z = s.vmap ' z)) ∧ (A (r0.vmap ' z) = B z)` >- metis_tac[] >>
  qx_gen_tac `z` >> strip_tac >>
  fs[Abbr`A`,Abbr`B`] >>
  conj_asm1_tac >- (
    rw[] >> PROVE_TAC[extend_preserve,extend_defs_invariants] ) >>
  `∀z. z ∈ FDOM r0.vmap ⇒ ((r0.vmap ' z = r1) = (z = q1))` by (
    qpat_assum `Abbrev (X = extend p0 q1)` mp_tac >>
    rw[extend_def,markerTheory.Abbrev_def] >>
    fs[FAPPLY_FUPDATE_THM] >> rw[] >> fs[] >- (
      fs[good_repl_state_def,INJ_DEF] >>
      metis_tac[] ) >>
    fs[good_repl_state_def] >>
    fs[FRANGE_DEF] >>
    metis_tac[prim_recTheory.LESS_REFL] ) >>
  `q1 ∈ FDOM r0.vmap` by PROVE_TAC[extend_IN_FDOM] >>
  Cases_on `z=q1` >> fs[] >>
  `z ∈ FDOM r0.vmap` by fs[SUBSET_DEF] >>
  Cases_on `r0.vmap ' z = r1` >> fs[] >- PROVE_TAC[] >>
  `r0.vmap ' z = p0.vmap ' z` by (
    qpat_assum `Abbrev (X = extend p0 q1)` mp_tac >>
    rw[extend_def,markerTheory.Abbrev_def] >>
    fs[FAPPLY_FUPDATE_THM] >> rw[] >> fs[] ) >>
  rw[EQ_IMP_THM] >- PROVE_TAC[] >>
  spose_not_then strip_assume_tac >>
  qmatch_assum_rename_tac `MEM (x1,x2,x3) defs` [] >>
  `x1 ∈ FDOM p0.vmap` by (
    fs[SUBSET_DEF,pairTheory.EXISTS_PROD] >> PROVE_TAC[] ) >>
  `z ∈ FDOM p0.vmap` by (
    qpat_assum `Abbrev (X = extend p0 q1)` mp_tac >>
    rw[extend_def,markerTheory.Abbrev_def] >>
    fs[FAPPLY_FUPDATE_THM] >> rw[] >> fs[] ) >>
  fs[good_repl_state_def,INJ_DEF] >>
  metis_tac[])
>- (
  qabbrev_tac `p = extend s vn` >>
  PairCases_on `p` >> fs[] )
>- (
  qmatch_assum_rename_tac `MEM d defs`[] >>
  PairCases_on `d` >> fs[] >>
  qabbrev_tac `p = extend s d1` >>
  PairCases_on `p` >> fs[] >>
  qabbrev_tac `q = extend s vn` >>
  PairCases_on `q` >> fs[pairTheory.FORALL_PROD] >>
  first_x_assum (qspecl_then [`d0`,`d1`,`d2`] mp_tac) >>
  rw[] )
>- (
  qabbrev_tac `q = pat_to_Cpat s [] p` >>
  PairCases_on`q`>>fs[] )
>- (
  qmatch_assum_rename_tac `MEM d defs`[] >>
  PairCases_on `d` >> fs[] >>
  qabbrev_tac `q = pat_to_Cpat s [] d0` >>
  PairCases_on `q` >> fs[] >>
  qabbrev_tac `r = pat_to_Cpat s [] p` >>
  PairCases_on `r` >> fs[pairTheory.FORALL_PROD] >>
  first_x_assum (qspecl_then [`d0`,`d1`] mp_tac) >>
  rw[] ))

val tac1 =
   match_mp_tac Cevaluate_super_env >>
   fsrw_tac[boolSimps.DNF_ss][] >>
   (reverse conj_tac >- (
      match_mp_tac SUBSET_BIGUNION_I >>
      srw_tac[boolSimps.DNF_ss][MEM_MAP,MEM_EL] >>
      metis_tac[] )) >>
   qmatch_abbrev_tac `Cevaluate env0 (exp_to_Cexp s0 (EL kk es)) res0` >>
   first_x_assum (qspecl_then [`kk`,`s0`] mp_tac) >> rw[] >>
   pop_assum (match_mp_tac o MP_CANON) >>
   fsrw_tac[DNF_ss,SATISFY_ss][BIGUNION_SUBSET,MEM_EL]

(*
val v_to_Cv_inj_rwt = store_thm(
"v_to_Cv_inj_rwt",
``∀s v1 v2. (v_to_Cv s v1 = v_to_Cv s v2) = (v1 = v2)``,
probably not true until equality is corrected in the source language *)

fun sorry g = ([],K(mk_thm g))

val MAP_values_fmap_to_alist = store_thm(
"MAP_values_fmap_to_alist",
``∀f fm. MAP (λ(k,v). (k, f v)) (fmap_to_alist fm) = fmap_to_alist (f o_f fm)``,
rw[fmap_to_alist_def,MAP_MAP_o,MAP_EQ_f])

val alist_to_fmap_MAP_values = store_thm(
"alist_to_fmap_MAP_values",
``∀f al. alist_to_fmap (MAP (λ(k,v). (k, f v)) al) = f o_f (alist_to_fmap al)``,
rw[] >>
Q.ISPECL_THEN [`I:γ->γ`,`f`,`al`] match_mp_tac alist_to_fmap_MAP_matchable >>
rw[INJ_I])

val o_f_force_dom = store_thm(
"o_f_force_dom",
``∀f fm s d. FINITE s ⇒ (f o_f force_dom fm s d = force_dom (f o_f fm) s (f d))``,
rw[force_dom_DRESTRICT_FUNION,GSYM fmap_EQ_THM,FUNION_DEF,DRESTRICT_DEF,FUN_FMAP_DEF] >>
rw[])

(*
val exp_to_Cexp_thm1 = store_thm(
"exp_to_Cexp_thm1",
``(∀s exp cenv env res.
  evaluate cenv env exp res ∧
  (res ≠ Rerr Rtype_error) ∧
  clV_exp exp ⊆ FDOM s.vmap ∧
  FV exp ⊆ FDOM s.vmap ∧
  good_env_state env s ⇒
  ∀Cexp. (Cexp = exp_to_Cexp s exp) ⇒
    Cevaluate
     (force_dom (alist_to_fmap (MAP (λ(x,v). (s.vmap ' x, v_to_Cv s v)) env)) (free_vars Cexp) (CLit (Bool F)))
     Cexp
     (map_result (v_to_Cv s) res))
∧ (∀(s:repl_state) (v:v). T)``,
ho_match_mp_tac exp_to_Cexp_nice_ind >>
strip_tac >- rw[exp_to_Cexp_def] >>
strip_tac >- (
  rw[exp_to_Cexp_def] >>
  match_mp_tac EQ_SYM >>
  match_mp_tac (CONJUNCT2 ce_Cexp_canonical_id) >>
  match_mp_tac (CONJUNCT2 exp_to_Cexp_canonical) >>
  fs[good_env_state_def] ) >>
strip_tac >- (
  srw_tac[DNF_ss,ETA_ss][exp_to_Cexp_def,exps_to_Cexps_MAP,vs_to_Cvs_MAP,FOLDL_UNION_BIGUNION] >>
  fsrw_tac[DNF_ss][EVERY_MEM,MEM_EL,SUBSET_DEF] >>
  fsrw_tac[]
    [evaluate_con,Cevaluate_con,
     evaluate_list_with_evaluate,Cevaluate_list_with_Cevaluate,
     evaluate_list_with_value,evaluate_list_with_error,
     Cevaluate_list_with_value,Cevaluate_list_with_error]
  >- (
    qexists_tac `n` >>
    `err ≠ Rtype_error` by (spose_not_then strip_assume_tac >> fs[]) >>
    fsrw_tac[SATISFY_ss][EL_MAP] >>
    conj_tac >- (
      first_x_assum (qspecl_then [`cenv`,`env`,`Rerr err`,`n`] mp_tac) >>
      fsrw_tac[DNF_ss,SATISFY_ss][SUBSET_DEF,MEM_MAP,MEM_EL,Cevaluate_super_env] ) >>
    qx_gen_tac `m` >> strip_tac >>
    first_x_assum (qspec_then `m` mp_tac) >> rw[] >>
    qexists_tac `v_to_Cv s v` >>
    first_x_assum (qspecl_then [`cenv`,`env`,`Rval v`,`m`] mp_tac) >>
    `m < LENGTH es` by srw_tac[ARITH_ss][] >>
    fsrw_tac[DNF_ss,SATISFY_ss][EL_MAP,SUBSET_DEF,MEM_MAP,MEM_EL,Cevaluate_super_env] )
  >- (
    fs[exp_to_Cexp_def,vs_to_Cvs_MAP,EL_MAP] >>
    qx_gen_tac `n` >> strip_tac >>
    first_x_assum (qspec_then `n` mp_tac) >> rw[] >>
    first_x_assum (qspecl_then [`cenv`,`env`,`Rval (EL n vs)`,`n`] mp_tac) >>
    fsrw_tac[DNF_ss,SATISFY_ss][EL_MAP,SUBSET_DEF,MEM_MAP,MEM_EL,Cevaluate_super_env] )) >>
strip_tac >- (
  rw[exp_to_Cexp_def,evaluate_var] >> rw[] >>
  qmatch_abbrev_tac `v_to_Cv s v = ce_Cv (force_dom (alist_to_fmap mal) u d ' x)` >>
  `INJ (FAPPLY s.vmap) (set (MAP FST env)) UNIV` by (
    fs[good_env_state_def,good_repl_state_def,LIST_TO_SET_MAP] >>
    PROVE_TAC[INJ_SUBSET,SUBSET_REFL] ) >>
  `alist_to_fmap mal = MAP_KEYS (FAPPLY s.vmap) ((v_to_Cv s) o_f alist_to_fmap env)` by (
    Q.ISPECL_THEN [`FAPPLY s.vmap`,`v_to_Cv s`,`env`] match_mp_tac alist_to_fmap_MAP_matchable >>
    rw[Abbr`mal`] ) >>
  unabbrev_all_tac >>
  imp_res_tac ALOOKUP_MEM >>
  reverse (rw[force_dom_DRESTRICT_FUNION,FUNION_DEF,DRESTRICT_DEF,MAP_KEYS_def,MEM_MAP,pairTheory.EXISTS_PROD,o_f_DEF]) >-
    PROVE_TAC[] >>
  qmatch_abbrev_tac `v_to_Cv s v = ce_Cv (MAP_KEYS f fm ' (f y))` >>
  `y ∈ FDOM fm` by (
    unabbrev_all_tac >>
    rw[MEM_MAP,pairTheory.EXISTS_PROD] >>
    PROVE_TAC[] ) >>
  rw[MAP_KEYS_def,Abbr`fm`] >>
  rw[o_f_DEF] >>
  imp_res_tac ALOOKUP_SOME_FAPPLY_alist_to_fmap >>
  fs[] >>
  match_mp_tac EQ_SYM >>
  match_mp_tac (CONJUNCT2 ce_Cexp_canonical_id) >>
  match_mp_tac (CONJUNCT2 exp_to_Cexp_canonical) >>
  fsrw_tac[DNF_ss][good_env_state_def,SUBSET_DEF,pairTheory.FORALL_PROD] >>
  PROVE_TAC[] ) >>
strip_tac >- (
  rw[exp_to_Cexp_def,env_to_Cenv_MAP] >>
  rw[Cevaluate_fun] >>
  rw[mk_env_def] >>
  unabbrev_all_tac >>
  rw[MAP_values_fmap_to_alist,o_f_force_dom,alist_to_fmap_MAP_values] ) >>
strip_tac >- (
  rw[exp_to_Cexp_def,evaluate_app]
  >- (
    rw[Once Cevaluate_cases] >>
    disj1_tac >>
    rw[Cevaluate_list_with_Cevaluate,Cevaluate_list_with_EVERY] >>
    qexists_tac `v_to_Cv s v1` >>
    qexists_tac `v_to_Cv s v2` >>
    first_x_assum (qspecl_then [`cenv`,`env`,`Rval v1`] mp_tac) >>
    first_x_assum (qspecl_then [`cenv`,`env`,`Rval v2`] mp_tac) >>
    fs[Cevaluate_super_env] >> ntac 2 strip_tac >>
    qmatch_assum_rename_tac `do_app env (Opn opn) v1 v2 = SOME (env',exp'')` [] >>
    Cases_on `opn` >>
    Cases_on `v1` >> Cases_on `l` >> fs[MiniMLTheory.do_app_def] >>
    Cases_on `v2` >> Cases_on `l` >> fs[] >> rw[] >>
    fs[CevalPrim2_def,doPrim2_def,exp_to_Cexp_def,MiniMLTheory.opn_lookup_def,i0_def] >>
    rw[] >> fs[] >> rw[] >> fs[] >>
    rw[exp_to_Cexp_def] )
  >- (
    rw[Once Cevaluate_cases] >>
    disj2_tac >>
    rw[Cevaluate_list_with_Cevaluate,Cevaluate_list_with_error] >>
    qexists_tac `1` >>
    first_x_assum (qspecl_then [`cenv`,`env`,`Rval v1`] mp_tac) >>
    first_x_assum (qspecl_then [`cenv`,`env`,`Rerr err`] mp_tac) >>
    fs[Cevaluate_super_env] >> ntac 2 strip_tac >>
    Cases >> srw_tac[ARITH_ss][] >>
    qexists_tac `v_to_Cv s v1` >>
    fs[Cevaluate_super_env] )
  >- (
    rw[Once Cevaluate_cases] >>
    disj2_tac >>
    rw[Cevaluate_list_with_Cevaluate,Cevaluate_list_with_error] >>
    qexists_tac `0` >>
    first_x_assum (qspecl_then [`cenv`,`env`,`Rerr err`] mp_tac) >>
    fs[Cevaluate_super_env] )) >>
strip_tac >- (
  rw[exp_to_Cexp_def,evaluate_app]
  >- (
    first_x_assum (qspecl_then [`cenv`,`env`,`Rval v1`] mp_tac) >>
    first_x_assum (qspecl_then [`cenv`,`env`,`Rval v2`] mp_tac) >>
    fs[] >> ntac 2 strip_tac >>
    Cases_on `(opb = Lt) ∨ (opb = Leq)` >- (
      fs[] >>
      rw[Once Cevaluate_cases] >>
      disj1_tac >>
      rw[Cevaluate_list_with_Cevaluate,Cevaluate_list_with_EVERY] >>
      qexists_tac `v_to_Cv s v1` >>
      qexists_tac `v_to_Cv s v2` >>
      fs[Cevaluate_super_env] >>
      Cases_on `v1` >> Cases_on `l` >> fs[MiniMLTheory.do_app_def] >>
      Cases_on `v2` >> Cases_on `l` >> fs[] >> rw[] >>
      fs[CevalPrim2_def,doPrim2_def,exp_to_Cexp_def,MiniMLTheory.opb_lookup_def,i0_def] )
    >- (
      Cases_on `opb` >> fs[] >>
      rw[Once Cevaluate_cases] >>
      disj1_tac >>
      qexists_tac `v_to_Cv s v1` >>
      fsrw_tac[SATISFY_ss][GSYM INSERT_SING_UNION,Cevaluate_super_env] >>
      rw[Once Cevaluate_cases] >>
      disj1_tac >>
      qexists_tac `v_to_Cv s v2` >> (
      conj_tac >- (
        match_mp_tac Cevaluate_FUPDATE >>
        fs[good_env_state_def] >>
        fs[free_vars_exp_to_Cexp,Abbr`Ce1`,Abbr`Ce2`] >>
        reverse conj_tac >- (
          fs[good_repl_state_def,FRANGE_DEF,SUBSET_DEF] >>
          metis_tac[prim_recTheory.LESS_REFL] ) >>
        fsrw_tac[SATISFY_ss][Cevaluate_super_env,free_vars_exp_to_Cexp] )) >>
      rw[Once Cevaluate_cases] >>
      disj1_tac >>
      rw[Cevaluate_list_with_Cevaluate] >>
      rw[Cevaluate_list_with_cons] >>
      srw_tac[ARITH_ss][FAPPLY_FUPDATE_THM] >>
      Cases_on `v1` >> Cases_on `l` >> fs[MiniMLTheory.do_app_def] >>
      Cases_on `v2` >> Cases_on `l` >> fs[] >> rw[] >>
      fs[doPrim2_def,exp_to_Cexp_def,MiniMLTheory.opb_lookup_def] >>
      rw[integerTheory.int_gt,integerTheory.int_ge] ))
  >- (
    Cases_on `(opb = Lt) ∨ (opb = Leq)` >- (
      fs[] >>
      rw[Once Cevaluate_cases] >>
      disj2_tac >>
      rw[Cevaluate_list_with_Cevaluate,Cevaluate_list_with_cons] >>
      disj1_tac >>
      qexists_tac `v_to_Cv s v1` >>
      first_x_assum (qspecl_then [`cenv`,`env`,`Rval v1`] mp_tac) >>
      first_x_assum (qspecl_then [`cenv`,`env`,`Rerr err`] mp_tac) >>
      fs[Cevaluate_super_env] )
    >- (
      Cases_on `opb` >> fs[] >>
      rw[Once Cevaluate_cases] >>
      disj1_tac >>
      qexists_tac `v_to_Cv s v1` >>
      first_x_assum (qspecl_then [`cenv`,`env`,`Rval v1`] mp_tac) >>
      fsrw_tac[SATISFY_ss][GSYM INSERT_SING_UNION,Cevaluate_super_env] >>
      strip_tac >>
      rw[Once Cevaluate_cases] >>
      disj2_tac >>
      match_mp_tac Cevaluate_FUPDATE >>
      first_x_assum (qspecl_then [`cenv`,`env`,`Rerr err`] mp_tac) >>
      fs[good_env_state_def] >>
      fs[free_vars_exp_to_Cexp,Abbr`Ce1`,Abbr`Ce2`] >>
      strip_tac >> (
      reverse conj_tac >- (
        fs[good_repl_state_def,FRANGE_DEF,SUBSET_DEF] >>
        metis_tac[prim_recTheory.LESS_REFL] )) >>
      fsrw_tac[SATISFY_ss][Cevaluate_super_env,free_vars_exp_to_Cexp] ))
  >- (
    Cases_on `(opb = Lt) ∨ (opb = Leq)` >- (
      fs[] >>
      rw[Once Cevaluate_cases] >>
      disj2_tac >>
      rw[Cevaluate_list_with_Cevaluate,Cevaluate_list_with_cons] >>
      disj2_tac >>
      first_x_assum (qspecl_then [`cenv`,`env`,`Rerr err`] mp_tac) >>
      fs[Cevaluate_super_env] )
    >- (
      Cases_on `opb` >> fs[] >>
      rw[Once Cevaluate_cases] >>
      disj2_tac >>
      first_x_assum (qspecl_then [`cenv`,`env`,`Rerr err`] mp_tac) >>
      fsrw_tac[SATISFY_ss][GSYM INSERT_SING_UNION,Cevaluate_super_env]  ))) >>
strip_tac >- (
  rw[exp_to_Cexp_def,evaluate_app]
  >- (
    rw[Once Cevaluate_cases] >>
    disj1_tac >>
    rw[Cevaluate_list_with_Cevaluate,Cevaluate_list_with_EVERY] >>
    qexists_tac `v_to_Cv s v1` >>
    qexists_tac `v_to_Cv s v2` >>
    first_x_assum (qspecl_then [`cenv`,`env`,`Rval v1`] mp_tac) >>
    first_x_assum (qspecl_then [`cenv`,`env`,`Rval v2`] mp_tac) >>
    fs[Cevaluate_super_env] >> ntac 2 strip_tac >>
    fs[MiniMLTheory.do_app_def] >> rw[] >>
    fs[evaluate_val] >> rw[exp_to_Cexp_def] >>
    sorry )
  >- (
    rw[Once Cevaluate_cases] >>
    rw[Cevaluate_list_with_Cevaluate,Cevaluate_list_with_error] >>
    qexists_tac `1` >>
    first_x_assum (qspecl_then [`cenv`,`env`,`Rval v1`] mp_tac) >>
    first_x_assum (qspecl_then [`cenv`,`env`,`Rerr err`] mp_tac) >>
    fs[Cevaluate_super_env] >> ntac 2 strip_tac >>
    Cases >> srw_tac[ARITH_ss][] >>
    qexists_tac `v_to_Cv s v1` >>
    fs[Cevaluate_super_env] )
  >- (
    rw[Once Cevaluate_cases] >>
    rw[Cevaluate_list_with_Cevaluate,Cevaluate_list_with_error] >>
    qexists_tac `0` >>
    first_x_assum (qspecl_then [`cenv`,`env`,`Rerr err`] mp_tac) >>
    fs[Cevaluate_super_env] )) >>
strip_tac >- (
  rw[exp_to_Cexp_def,evaluate_app]
  >- (
    fs[MiniMLTheory.do_app_def] >>
    Cases_on `v1` >> fs[] >> rw[]
    >- (
      rw[Once Cevaluate_cases] >>
      disj1_tac >>
      qmatch_assum_rename_tac `evaluate cenv env exp (Rval (Closure env' v b))`[] >>
      first_x_assum (qspecl_then [`cenv`,`env`,`Rval (Closure env' v b)`] mp_tac) >>
      fs[exp_to_Cexp_def,LET_THM] >>
      qabbrev_tac`p = extend s v` >>
      PairCases_on`p` >> fs[] >>
      fs[exp_to_Cexp_def] >> rw[] >>
      qmatch_assum_abbrev_tac `Cevaluate Cenv Ce1 (Rval (CClosure Cenv' ns Cb))` >>
      map_every qexists_tac [`Cenv'`,`ns`,`Cb`] >>
      fs[Cevaluate_super_env,Abbr`Cenv`] >>
      srw_tac[DNF_ss][Cevaluate_list_with_Cevaluate,Cevaluate_list_with_cons,Abbr`ns`] >>
      qexists_tac `v_to_Cv s v2` >>
      first_x_assum (qspecl_then [`cenv`,`env`,`Rval v2`] mp_tac) >>
      fs[Cevaluate_super_env] >> strip_tac >>

*)

val tacLt =
  rw[Once Cevaluate_cases] >>
  disj1_tac >>
  rw[Cevaluate_list_with_Cevaluate] >>
  rw[Cevaluate_list_with_cons] >>
  qexists_tac `v_to_Cv s v1` >>
  qexists_tac `v_to_Cv s v2` >>
  rw[] >>
  Cases_on `v1` >> Cases_on `l` >> fs[MiniMLTheory.do_app_def] >>
  Cases_on `v2` >> Cases_on `l` >> fs[] >> rw[] >>
  fs[CevalPrim2_def,doPrim2_def,exp_to_Cexp_def,MiniMLTheory.opb_lookup_def] >>
  fsrw_tac[SATISFY_ss][Cevaluate_super_env]

val tacGt =
  rw[Once Cevaluate_cases] >>
  disj1_tac >>
  qexists_tac `v_to_Cv s v1` >>
  fsrw_tac[SATISFY_ss][GSYM INSERT_SING_UNION,Cevaluate_super_env] >>
  rw[Once Cevaluate_cases] >>
  disj1_tac >>
  qexists_tac `v_to_Cv s v2` >>
  conj_tac >- (
    match_mp_tac Cevaluate_FUPDATE >>
    fs[good_env_state_def] >>
    fs[free_vars_exp_to_Cexp] >>
    reverse conj_tac >- (
      fs[good_repl_state_def,FRANGE_DEF,SUBSET_DEF] >>
      metis_tac[prim_recTheory.LESS_REFL] ) >>
    fsrw_tac[SATISFY_ss][Cevaluate_super_env,free_vars_exp_to_Cexp] ) >>
  rw[Once Cevaluate_cases] >>
  disj1_tac >>
  rw[Cevaluate_list_with_Cevaluate] >>
  rw[Cevaluate_list_with_cons] >>
  srw_tac[ARITH_ss][FAPPLY_FUPDATE_THM] >>
  Cases_on `v1` >> Cases_on `l` >> fs[MiniMLTheory.do_app_def] >>
  Cases_on `v2` >> Cases_on `l` >> fs[] >> rw[] >>
  fs[doPrim2_def,exp_to_Cexp_def,MiniMLTheory.opb_lookup_def] >>
  rw[integerTheory.int_gt,integerTheory.int_ge]

(*
val exp_to_Cexp_thm1 = store_thm(
"exp_to_Cexp_thm1",
``∀cenv env exp res. evaluate cenv env exp res ⇒
  ∀s Cexp. (res ≠ Rerr Rtype_error) ∧
    (Cexp = exp_to_Cexp s exp) ∧
    (clV_exp exp ⊆ FDOM s.vmap) ∧
    (FV exp ⊆ FDOM s.vmap) ∧
    good_env_state env s ⇒
 Cevaluate
   (force_dom (alist_to_fmap (MAP (λ(x,v). (s.vmap ' x, v_to_Cv s v)) env)) (free_vars Cexp) (CLit (Bool F)))
   Cexp
   (map_result (v_to_Cv s) res)``,
ho_match_mp_tac evaluate_nice_strongind >>
strip_tac >- rw[exp_to_Cexp_def] >>
strip_tac >- (
  rw[exp_to_Cexp_def] >>
  match_mp_tac EQ_SYM >>
  match_mp_tac (CONJUNCT2 ce_Cexp_canonical_id) >>
  match_mp_tac (CONJUNCT2 exp_to_Cexp_canonical) >>
  fs[good_env_state_def] ) >>
strip_tac >- (
  rw[exp_to_Cexp_def,exps_to_Cexps_MAP,vs_to_Cvs_MAP,evaluate_list_with_value,Cevaluate_con,Cevaluate_list_with_Cevaluate,Cevaluate_list_with_value,EL_MAP,FOLDL_UNION_BIGUNION] >>
  tac1 ) >>
strip_tac >- rw[] >>
strip_tac >- (
  rw[exp_to_Cexp_def,exps_to_Cexps_MAP,evaluate_list_with_error,Cevaluate_con,Cevaluate_list_with_Cevaluate,Cevaluate_list_with_error] >>
  first_x_assum (qspec_then `s` assume_tac) >>
  qmatch_assum_rename_tac `P ⇒ Cevaluate A (exp_to_Cexp s (EL nn es)) B` ["P","A","B"] >>
  qexists_tac `nn` >>
  fs[EL_MAP,FOLDL_UNION_BIGUNION] >>
  conj_tac >- (
    match_mp_tac Cevaluate_super_env >>
    fsrw_tac[boolSimps.DNF_ss,SATISFY_ss][BIGUNION_SUBSET,MEM_EL] >>
    match_mp_tac SUBSET_BIGUNION_I >>
    fsrw_tac[boolSimps.DNF_ss][MEM_MAP,MEM_EL] >>
    PROVE_TAC[] ) >>
  fsrw_tac[boolSimps.DNF_ss,SATISFY_ss][BIGUNION_SUBSET,MEM_EL] >>
  rw[] >>
  qpat_assum `∀m. m < nn ⇒ P` (qspec_then `m` mp_tac) >>
  srw_tac[ARITH_ss][EL_MAP] >>
  pop_assum (qspec_then `s` mp_tac) >>
  `m < LENGTH es` by srw_tac[ARITH_ss][] >>
  fsrw_tac[ARITH_ss,SATISFY_ss][] >>
  rw[] >>
  qexists_tac `v_to_Cv s v` >>
  match_mp_tac Cevaluate_super_env >>
  fsrw_tac[boolSimps.DNF_ss][] >>
  match_mp_tac SUBSET_BIGUNION_I >>
  fsrw_tac[boolSimps.DNF_ss][MEM_MAP,MEM_EL] >>
  qexists_tac `m` >> srw_tac[ARITH_ss][] ) >>
strip_tac >- (
  rw[exp_to_Cexp_def,force_dom_DRESTRICT_FUNION,FUNION_DEF,DRESTRICT_DEF,FUN_FMAP_DEF,MEM_MAP,pairTheory.EXISTS_PROD] >>
  reverse (rw[]) >- (
    imp_res_tac ALOOKUP_MEM >>
    fs[] >> metis_tac[] ) >>
  qho_match_abbrev_tac `x = ce_Cv (alist_to_fmap (MAP (λ(x,y). (f1 x, f2 y)) al) ' z)` >>
  `f1 = FAPPLY s.vmap` by rw[Abbr`f1`,FUN_EQ_THM] >>
  `INJ f1 (set (MAP FST al)) UNIV` by (
    fs[good_env_state_def,good_repl_state_def] >>
    metis_tac[INJ_SUBSET,SUBSET_UNIV,LIST_TO_SET_MAP] ) >>
  rw[alistTheory.alist_to_fmap_MAP] >>
  `n IN FDOM (f2 o_f alist_to_fmap al)` by (
    rw[MEM_MAP] >>
    qexists_tac `(n,v)` >> rw[ALOOKUP_MEM] ) >>
  unabbrev_all_tac >> simp_tac(srw_ss())[] >>
  rw[finite_mapTheory.MAP_KEYS_def] >>
  rw[finite_mapTheory.o_f_DEF] >>
  imp_res_tac alistTheory.ALOOKUP_SOME_FAPPLY_alist_to_fmap >>
  rw[] >>
  match_mp_tac EQ_SYM >>
  match_mp_tac (CONJUNCT2 ce_Cexp_canonical_id) >>
  match_mp_tac (CONJUNCT2 exp_to_Cexp_canonical) >>
  fsrw_tac[boolSimps.DNF_ss][good_env_state_def,BIGUNION_SUBSET,pairTheory.EXISTS_PROD,MEM_MAP] >>
  imp_res_tac ALOOKUP_MEM >>
  metis_tac[]) >>
strip_tac >- rw[] >>
strip_tac >- (
  rw[exp_to_Cexp_def,env_to_Cenv_MAP] >> rw[] >>
  rw[mk_env_canon,Abbr`env'`,Abbr`env''`,ALOOKUP_APPEND,ALOOKUP_MAP,FLOOKUP_DEF] >>
  unabbrev_all_tac >> fs[] >>
  rw[force_dom_DRESTRICT_FUNION,FUNION_DEF,DRESTRICT_DEF,FUN_FMAP_DEF] >>
  fs[GSYM ALOOKUP_NONE] >>
  BasicProvers.EVERY_CASE_TAC >> fs[ALOOKUP_NONE] >>
  imp_res_tac ALOOKUP_SOME_FAPPLY_alist_to_fmap >>
  rw[]) >>
strip_tac >- (
  ntac 2 gen_tac >>
  Cases >> fs[exp_to_Cexp_def] >>
  qx_gen_tac `e1` >>
  qx_gen_tac `e2` >>
  rw[] >- (
    rw[Once Cevaluate_cases] >>
    disj1_tac >>
    rw[Cevaluate_list_with_Cevaluate] >>
    rw[Cevaluate_list_with_cons] >>
    qexists_tac `v_to_Cv s v1` >>
    qexists_tac `v_to_Cv s v2` >>
    fsrw_tac[][Cevaluate_super_env,Abbr`Ce1`,Abbr`Ce2`] >>
    qmatch_assum_rename_tac `do_app env (Opn opn) v1 v2 = SOME (env',exp'')` [] >>
    Cases_on `opn` >>
    Cases_on `v1` >> Cases_on `l` >> fs[MiniMLTheory.do_app_def] >>
    Cases_on `v2` >> Cases_on `l` >> fs[] >> rw[] >>
    fs[CevalPrim2_def,doPrim2_def,exp_to_Cexp_def,MiniMLTheory.opn_lookup_def,i0_def] >>
    rw[] >> fs[] >> rw[] >> fs[] >>
    qpat_assum `∀s. good_env_state env s ⇒ P` (qspec_then `s` mp_tac) >>
    rw[Once MiniMLTheory.evaluate_cases,exp_to_Cexp_def] )
  >- (
    qmatch_assum_rename_tac `do_app env (Opb opb) v1 v2 = SOME (env',exp'')` [] >>
    Cases_on `opb` >> fs[Abbr`Ce1`,Abbr`Ce2`]
    >- tacLt >- tacGt >- tacLt >- tacGt )
  >- (
    rw[Once Cevaluate_cases] >>
    disj1_tac >>
    rw[Cevaluate_list_with_Cevaluate] >>
    rw[Cevaluate_list_with_cons] >>
    qexists_tac `v_to_Cv s v1` >>
    qexists_tac `v_to_Cv s v2` >>
    fsrw_tac[][Cevaluate_super_env,Abbr`Ce1`,Abbr`Ce2`] >>
    fs[MiniMLTheory.do_app_def] >> rw[] >> fs[exp_to_Cexp_def] >>
    sorry )
  >- (
    fs[MiniMLTheory.do_app_def] >>
    Cases_on `v1` >> fs[] >- (
      rw[Once Cevaluate_cases] >>
      disj1_tac >>
      srw_tac[DNF_ss][Cevaluate_list_with_Cevaluate,Cevaluate_list_with_cons] >>
      qmatch_assum_rename_tac `evaluate cenv env e1 (Rval (Closure env' v b))`[] >>
      qpat_assum `∀s''. P ⇒ Cevaluate A B (Rval (v_to_Cv s'' (Closure env' v b)))` (qspec_then `s` mp_tac) >>
      fs[exp_to_Cexp_def,LET_THM] >>
      qabbrev_tac `p = extend s v` >>
      PairCases_on`p` >> fs[] >>
      qmatch_abbrev_tac `Cevaluate Cenv Ce1 (Rval (CClosure Cenv' ns Cb)) ⇒ X` >>
      strip_tac >> qunabbrev_tac `X` >>
      map_every qexists_tac [`Cenv'`,`ns`,`Cb`] >>
      fs[Cevaluate_super_env,Abbr`ns`] >>
      qexists_tac `v_to_Cv s v2` >>
      qpat_assum `∀s. P ⇒ Cevaluate A B (Rval (v_to_Cv s v2))` (qspec_then `s` mp_tac) >>
      fs[Cevaluate_super_env] >>
      fs[MiniMLTheory.bind_def,env_to_Cenv_MAP] >>
      strip_tac >>

      qsuff_tac `clV_exp b ⊆ FDOM p0.vmap ∧ FV b ⊆ FDOM p0.vmap` >- (
        strip_tac >>
        first_x_assum (qspec_then `p0` mp_tac) >>
        `good_env_state ((v,v2)::env') p0` by (
          fs[good_env_state_def]

          evaluate cenv env exp (Rval (Closure env' v b)) ==> either the closure came from the environment, or its environment is an extension of the input envirnoment. and in either case the body's free variables are contained in the closure's environment + argument.

      first_x_assum (qspec_then `p0` mp_tac) >>
      `FDOM FDOM p0.vmap 

      exp_to_Cexp_canonical
      ce_Cexp_canonical_id
      map_every qunabbrev_tac [`P`,`A`,`B`,`X`] >> strip_tac >>
      qpat_assum `∀s'. P ⇒ Cevaluate A B (map_result f res)` (qspec_then `s` mp_tac) >>
      qmatch_abbrev_tac `(P ⇒ Cevaluate Cenv Cb Cres) ⇒ X` >>
      map_every qunabbrev_tac [`X`,`P`] >> strip_tac >>
      map_every qexists_tac [`fmap_to_alist Cenv`,`[s.nv]`,`Cb`] >>
      first_x_assum (qspec_then `s` mp_tac) >> fs[] >>
      fs[exp_to_Cexp_def,LET_THM]

*)

(*
let rec
v_to_ov cenv (Lit l) = OLit l
and
v_to_ov cenv (Conv cn vs) = OConv cn (List.map (v_to_ov cenv) vs)
and
v_to_ov cenv (Closure env vn e) = OFn
  (fun ov -> map_option (o (v_to_ov cenv) snd)
    (some (fun (a,r) -> v_to_ov cenv a = ov
           && evaluate cenv (bind vn a env) e (Rval r))))
and
v_to_ov cenv (Recclosure env defs n) = OFn
  (fun ov -> option_bind (optopt (find_recfun n defs))
    (fun (vn,e) -> map_option (o (v_to_ov cenv) snd)
      (some (fun (a,r) -> v_to_ov cenv a = ov
             && evaluate cenv (bind vn a (build_rec_env defs env)) e (Rval r)))))

let rec
Cv_to_ov m (CLit l) = OLit l
and
Cv_to_ov m (CConv cn vs) = OConv (Pmap.find cn m) (List.map (Cv_to_ov m) vs)
and
Cv_to_ov m (CClosure env ns e) = OFn
  (fun ov -> some
and
Cv_to_ov m (CRecClos env ns fns n) = OFn
*)


val _ = export_theory ()