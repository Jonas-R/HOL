open HolKernel Parse boolLib bossLib boolSimps pred_setTheory pairTheory categoryTheory functorTheory nat_transTheory lcsymtacs SatisfySimps;

val _ = new_theory "ens_cat";

val HasFunType_def = Define`
  HasFunType f X Y = extensional f X ∧ ∀x. x ∈ X ⇒ f x ∈ Y`;

val IsTypedFun_def = Define`
  IsTypedFun f = HasFunType f.map f.dom f.cod`;

val TypedGraphFun_def = Define`
  TypedGraphFun (X,Y) f = <|
    dom := X; cod := Y; map := restrict f X |>`;

val TypedGraphFun_components = Q.store_thm(
"TypedGraphFun_components",
`∀X Y f. ((TypedGraphFun (X,Y) f).dom = X) ∧
         ((TypedGraphFun (X,Y) f).cod = Y) ∧
         ((TypedGraphFun (X,Y) f).map = restrict f X)`,
srw_tac [][TypedGraphFun_def]);
val _ = export_rewrites["TypedGraphFun_components"];

val IsTypedFunTypedGraphFun = Q.store_thm(
"IsTypedFunTypedGraphFun",
`∀f X Y. IsTypedFun (TypedGraphFun (X,Y) f) = ∀x. x ∈ X ⇒ f x ∈ Y`,
srw_tac [][EQ_IMP_THM,IsTypedFun_def,TypedGraphFun_def,HasFunType_def,restrict_def,extensional_def]);
val _ = export_rewrites["IsTypedFunTypedGraphFun"];

val TypedGraphFun_Ext = Q.store_thm(
"TypedGraphFun_Ext",
`∀X Y f X' Y' f'. (TypedGraphFun (X,Y) f = TypedGraphFun (X',Y') f') ⇔ ((X = X') ∧ (Y = Y') ∧ ∀x. x ∈ X ⇒ (f x = f' x))`,
srw_tac [][TypedGraphFun_def,restrict_def,EQ_IMP_THM] >> metis_tac []);

val ComposeFun_def = Define`
  ComposeFun (X,Y) g f = restrict ((restrict g Y) o f) X`;

val ComposeTypedFun_def = Define`
  ComposeTypedFun = compose (λf g. ComposeFun (f.dom,g.dom) g.map f.map)`;

val _ = overload_on("o",``λg f. ComposeTypedFun f g``);
val _ = overload_on("o",``λg f. (combin$o) g f``);

val ComposeTypedFun_components = Q.store_thm(
"ComposeTypedFun_components",
`∀f g. (f ≈> g) ⇒
((g o f).dom = f.dom) ∧
((g o f).cod = g.cod) ∧
((g o f).map = ComposeFun(f.dom,g.dom) g.map f.map)`,
srw_tac [][ComposeTypedFun_def]);
val _ = export_rewrites["ComposeTypedFun_components"];

val IdFun_def = Define`
  IdFun s = restrict I s`;

val IdFunAp = Q.store_thm(
"IdFunAp",
`∀x s. x ∈ s ⇒ (IdFun s x = x)`,
srw_tac [][IdFun_def,restrict_def]);
val _ = export_rewrites["IdFunAp"];

val IdFunType = Q.store_thm(
"IdFunType",
`∀s. HasFunType (IdFun s) s s`,
srw_tac [][HasFunType_def,IdFun_def]);
val _ = export_rewrites["IdFunType"];

val ComposeFunId = Q.store_thm(
"ComposeFunId",
`∀X Y f. HasFunType f X Y ⇒
(ComposeFun (X,X) f (IdFun X) = f) ∧
(ComposeFun (X,Y) (IdFun Y) f = f)`,
srw_tac [][ComposeFun_def,IdFun_def,FUN_EQ_THM,HasFunType_def] >>
fsrw_tac [][restrict_def,extensional_def] >>
metis_tac []);
val _ = export_rewrites["ComposeFunId"];

val ComposeFunAssoc = Q.store_thm(
"ComposeFunAssoc",
`∀a f b g c h ab bc ac.
  HasFunType f a b ∧ HasFunType g b c ∧
  (ab = (a,b)) ∧ (bc = (b,c)) ∧ (ac = (a,c)) ⇒
  (ComposeFun ac h (ComposeFun ab g f) = ComposeFun ab (ComposeFun bc h g) f)`,
srw_tac [][ComposeFun_def,FUN_EQ_THM] >>
fsrw_tac [][HasFunType_def,extensional_def,restrict_def]);
val _ = export_rewrites["ComposeFunAssoc"];

val ComposeFunType = Q.store_thm(
"ComposeFunType",
`∀X f Y g XY Z. HasFunType f X Y ∧ HasFunType g Y Z ∧ (XY = (X,Y)) ⇒ HasFunType (ComposeFun XY g f) X Z`,
srw_tac [][HasFunType_def,ComposeFun_def] >>
fsrw_tac [][extensional_def,restrict_def]);
val _ = export_rewrites["ComposeFunType"];

val _ = overload_on("IsTypedFunIn",``λU f. f.dom ∈ U ∧ f.cod ∈ U ∧ IsTypedFun f``);

val ens_cat_def = Define`
  ens_cat U = mk_cat <|
    obj := U ;
    mor := {f | IsTypedFunIn U f} ;
    id_map := IdFun ;
    comp := λf g. (g o f).map |>`;

val is_category_ens_cat = Q.store_thm(
"is_category_ens_cat",
`∀U. is_category (ens_cat U)`,
srw_tac [][ens_cat_def] >>
srw_tac [][category_axioms_def] >- (
  srw_tac [][maps_to_in_def,id_in_def,IsTypedFun_def,restrict_def] )
>- (
  srw_tac [][id_in_def,restrict_def] >>
  srw_tac [][compose_in_def,restrict_def] >>
  fsrw_tac [SATISFY_ss][IsTypedFun_def,morphism_component_equality] >>
  fsrw_tac [][composable_in_def] >> fsrw_tac [][])
>- (
  srw_tac [][id_in_def,restrict_def] >>
  srw_tac [][compose_in_def,restrict_def] >>
  fsrw_tac [SATISFY_ss][IsTypedFun_def,morphism_component_equality] >>
  fsrw_tac [][composable_in_def] >> fsrw_tac [][])
>- (
  fsrw_tac [][compose_in_def,restrict_def] >>
  fsrw_tac [][composable_in_def] >>
  fsrw_tac [][compose_def,restrict_def] >>
  fsrw_tac [][IsTypedFun_def]) >>
fsrw_tac [][maps_to_in_def] >>
fsrw_tac [][compose_in_def,restrict_def,composable_in_def] >>
fsrw_tac [][IsTypedFun_def]);
val _ = export_rewrites["is_category_ens_cat"];

val ens_cat_obj = Q.store_thm(
"ens_cat_obj",
`∀U. (ens_cat U).obj = U`,
srw_tac [][ens_cat_def]);

val ens_cat_mor = Q.store_thm(
"ens_cat_mor",
`∀U f. f ∈ (ens_cat U).mor ⇔ IsTypedFunIn U f`,
srw_tac [][ens_cat_def]);

val ens_cat_id = Q.store_thm(
"ens_cat_id",
`∀U x. x ∈ U ⇒ ((id x -:(ens_cat U)) = TypedGraphFun (x,x) (IdFun x))`,
srw_tac [][id_in_def,ens_cat_def,mk_cat_def,restrict_def,TypedGraphFun_def,IdFun_def]);

val ens_cat_composable_in = Q.store_thm(
"ens_cat_composable_in",
`∀U f g. f ≈> g -:(ens_cat U) ⇔ IsTypedFunIn U f ∧ IsTypedFunIn U g ∧ f ≈> g`,
srw_tac [][composable_in_def,ens_cat_mor]);

val ens_cat_comp = Q.store_thm(
"ens_cat_comp",
`∀U f g. f ≈> g -:(ens_cat U) ⇒ ((ens_cat U).comp f g = ComposeFun(f.dom,g.dom) g.map f.map)`,
srw_tac [][ens_cat_def,mk_cat_def,restrict_def,composable_in_def]);

val ens_cat_compose_in = Q.store_thm(
"ens_cat_compose_in",
`∀U f g. f ≈> g -:(ens_cat U) ⇒ (g o f -:(ens_cat U) = g o f)`,
srw_tac [][compose_in_def,morphism_component_equality,ens_cat_comp,ens_cat_composable_in,restrict_def]>>
metis_tac []);

val ens_cat_maps_to_in = Q.store_thm(
"ens_cat_maps_to_in",
`∀U f x y. f :- x → y -:(ens_cat U) ⇔ IsTypedFunIn U f ∧ f :- x → y`,
srw_tac [][maps_to_in_def,EQ_IMP_THM,ens_cat_mor]);

val _ = export_rewrites[
"ens_cat_obj","ens_cat_mor","ens_cat_id",
"ens_cat_composable_in","ens_cat_comp",
"ens_cat_compose_in","ens_cat_maps_to_in"];

val pre_hom_functor_def = Define`
  (pre_hom_functor c x : ('a,'b,('a,'b) mor set, ('a,'b) mor -> ('a,'b) mor) functor) = <|
    dom := c ; cod := ens_cat UNIV;
    map := λf. TypedGraphFun ((c|x→f.dom|),(c|x→f.cod|)) (λg. f o g -:c)
  |>`;

val pre_hom_functor_dom = Q.store_thm(
"pre_hom_functor_dom",
`∀c x. (pre_hom_functor c x).dom = c`,
srw_tac [][pre_hom_functor_def]);

val pre_hom_functor_cod = Q.store_thm(
"pre_hom_functor_cod",
`∀c x. (pre_hom_functor c x).cod = ens_cat UNIV`,
srw_tac [][pre_hom_functor_def]);

val _ = export_rewrites["pre_hom_functor_cod","pre_hom_functor_dom"];

val pre_hom_functor_morf_dom_cod = Q.store_thm(
"pre_hom_functor_morf_dom_cod",
`∀c x f. (((pre_hom_functor c x)##f).dom = c|x→f.dom|) ∧
         (((pre_hom_functor c x)##f).cod = c|x→f.cod|)`,
srw_tac [][pre_hom_functor_def,morf_def,TypedGraphFun_def]);
val _ = export_rewrites ["pre_hom_functor_morf_dom_cod"];

val pre_hom_functor_morf = Q.store_thm(
"pre_hom_functor_morf",
`∀c x f. (pre_hom_functor c x)##f =
  TypedGraphFun ((c|x→f.dom|), c|x→f.cod|) (λg. f o g -:c)`,
srw_tac [][pre_hom_functor_def,morf_def]);
val _ = export_rewrites["pre_hom_functor_morf"];

val pre_hom_functor_objf = Q.store_thm(
"pre_hom_functor_objf",
`∀c x y. is_category c ∧ x ∈ c.obj ∧ y ∈ c.obj
  ⇒ ((pre_hom_functor c x)@@y = c|x→y|)`,
srw_tac [][objf_def,pre_hom_functor_def] >>
imp_res_tac id_dom_cod >>
SELECT_ELIM_TAC >>
srw_tac [][] >- (
  qexists_tac `c|x→y|` >>
  srw_tac [][morphism_component_equality,TypedGraphFun_def] >>
  srw_tac [][restrict_def,FUN_EQ_THM] >> srw_tac [][] >>
  fsrw_tac [][hom_def,maps_to_in_def] ) >>
fsrw_tac [][TypedGraphFun_def,ens_cat_def]);
val _ = export_rewrites ["pre_hom_functor_objf"];

val _ = add_rule{
  term_name = "hom_functor",
  fixity=Suffix 620,
  pp_elements=[TOK"|",TM,TOK"\226\134\146_|"],
  paren_style=OnlyIfNecessary,
  block_style=(AroundEachPhrase,(PP.INCONSISTENT,0))};

val hom_functor_def = Define`
  c|x→_| = mk_functor (pre_hom_functor c x)`;

val hom_functor_objf = Q.store_thm(
"hom_functor_objf",
`∀c x y. is_category c ∧ x ∈ c.obj ∧ y ∈ c.obj
  ⇒ (objf (hom_functor c x) y = c|x→y|)`,
srw_tac [][hom_functor_def]);

val hom_functor_morf = Q.store_thm(
"hom_functor_morf",
`∀c x f. f ∈ c.mor ⇒
((c|x→_|)##f =
  TypedGraphFun ((c|x→f.dom|), c|x→f.cod|) (λg. f o g -:c))`,
srw_tac [][hom_functor_def,pre_hom_functor_def,mk_functor_def,restrict_def,morf_def]);

val _ = export_rewrites["hom_functor_objf","hom_functor_morf"];

val is_functor_hom_functor = Q.store_thm(
"is_functor_hom_functor",
`∀c x. is_category c ∧ x ∈ c.obj ⇒ is_functor (c|x→_|)`,
srw_tac [][hom_functor_def] >>
srw_tac [][functor_axioms_def]
>- (
  srw_tac [][hom_def] >>
  match_mp_tac maps_to_comp >>
  qexists_tac `f.dom` >>
  fsrw_tac [][hom_def,maps_to_in_def] )
>- (
  imp_res_tac maps_to_obj >>
  fsrw_tac [][maps_to_in_def] )
>- (
  imp_res_tac maps_to_obj >>
  fsrw_tac [][maps_to_in_def] )
>- (
  srw_tac [][TypedGraphFun_def] >>
  srw_tac [][FUN_EQ_THM,restrict_def] >>
  srw_tac [][] >>
  fsrw_tac [][hom_def,maps_to_in_def] ) >>
qmatch_abbrev_tac `hh = gg o ff -:(ens_cat U)` >>
`ff ≈> gg -:(ens_cat U)` by (
  srw_tac [][Abbr`ff`,Abbr`gg`,Abbr`U`,TypedGraphFun_def] >>
  imp_res_tac composable_in_def >> fsrw_tac [][] >>
  fsrw_tac [][hom_def] >>
  metis_tac [maps_to_comp,maps_to_in_dom_cod] ) >>
srw_tac [][] >>
`(ff ≈> gg) ∧ f ≈> g` by (
  imp_res_tac composable_in_def >>
  srw_tac [][] ) >>
srw_tac [][Abbr`ff`,Abbr`gg`,Abbr`hh`] >>
srw_tac [][morphism_component_equality] >>
TRY ( srw_tac [][hom_def,compose_in_def,restrict_def] >> NO_TAC) >>
srw_tac [][ComposeFun_def] >>
srw_tac [][restrict_def,FUN_EQ_THM] >>
srw_tac [][] >- (
  match_mp_tac comp_assoc >>
  fsrw_tac [][hom_def,composable_in_def,maps_to_in_def] ) >>
qsuff_tac `F` >- srw_tac [][] >>
qpat_assum `X ∉ Y` mp_tac >> srw_tac [][] >>
fsrw_tac [][hom_def,comp_mor_dom_cod] >>
pop_assum mp_tac >> srw_tac [][comp_mor_dom_cod]);
val _ = export_rewrites["is_functor_hom_functor"];

val hom_functor_dom = Q.store_thm(
"hom_functor_dom",
`∀c x. (hom_functor c x).dom = c`,
srw_tac [][hom_functor_def]);

val hom_functor_cod = Q.store_thm(
"hom_functor_cod",
`∀c x. (hom_functor c x).cod = (ens_cat UNIV)`,
srw_tac [][hom_functor_def]);

val _ = export_rewrites["hom_functor_cod","hom_functor_dom"];

val hom_op_cat = Q.store_thm(
"hom_op_cat",
`∀c x y. (c° |x→y|) = IMAGE op_mor (c|y→x|)`,
srw_tac [][hom_def,EXTENSION] >>
metis_tac [op_cat_maps_to_in,op_mor_map,op_mor_idem]);
val _ = export_rewrites["hom_op_cat"];

(*
val contra_functor_def = Define`
  contra_functor G = <| dom := G.dom°; cod := G.cod; map := G.map o op_mor |>`;

val contra_functor_components = Q.store_thm(
"contra_functor_components",
`∀G. ((contra_functor G).dom = G.dom°) ∧
     ((contra_functor G).cod = G.cod) ∧
     ((contra_functor G).map = G.map o op_mor)`,
srw_tac [][contra_functor_def]);
val _ = export_rewrites["contra_functor_components"];

val contra_functor_morf = Q.store_thm(
"contra_functor_morf",
`∀G f. (contra_functor G)##f = G##(f°)`,
srw_tac [][contra_functor_def,morf_def]);

val contra_functor_objf = Q.store_thm(
"contra_functor_objf",
`∀G x. is_category G.dom ∧ x ∈ G.dom.obj ⇒ ((contra_functor G)@@x = G@@x)`,
srw_tac [][objf_def,contra_functor_def]);

val _ = export_rewrites["contra_functor_morf","contra_functor_objf"];

val extensional_functor_contra_functor = Q.store_thm(
"extensional_functor_contra_functor",
`∀G. extensional_functor (contra_functor G) ⇔ extensional_functor G`,
srw_tac [DNF_ss][extensional_functor_def,extensional_def,EQ_IMP_THM] >- (
  first_x_assum (qspec_then `e°` mp_tac) >>
  srw_tac [][] ) >>
first_x_assum match_mp_tac >>
first_x_assum (qspec_then `e°` mp_tac) >>
srw_tac [][] );

val functor_axioms_contra_functor = Q.store_thm(
"functor_axioms_contra_functor",
`∀G. functor_axioms (contra_functor G) ⇔ functor_axioms G`,
srw_tac [][functor_axioms_def] >> EQ_TAC >> strip_tac >> fsrw_tac [][] >- (
  conj_tac >- (
    srw_tac [][] >>
    first_x_assum (qspecl_then [`f°`,`x`,`y`] mp_tac) >>
    imp_res_tac maps_to_obj >>
    srw_tac [][]

val is_functor_contra_functor = Q.store_thm(
"is_functor_contra_functor",
`∀G. is_functor (contra_functor G) ⇔ is_functor G`,
srw_tac [][is_functor_def,extensional_functor_contra_functor,functor_axioms_contra_functor]);
val _ = export_rewrites["is_functor_contra_functor"];
*)

val pre_op_mor_functor_def = Define`
  pre_op_mor_functor U = <| dom := ens_cat U; cod := ens_cat U;
    map := λf. TypedGraphFun
                (IMAGE op_mor f.dom, IMAGE op_mor f.cod)
                (op_mor o f.map o op_mor) |>`;

val pre_op_mor_functor_components = Q.store_thm(
"pre_op_mor_functor_components",
`∀U. ((pre_op_mor_functor U).dom = ens_cat U) ∧
     ((pre_op_mor_functor U).cod = ens_cat U) ∧
     ((pre_op_mor_functor U).map = λf. TypedGraphFun
                (IMAGE op_mor f.dom, IMAGE op_mor f.cod)
                (op_mor o f.map o op_mor))`,
srw_tac [][pre_op_mor_functor_def]);
val _ = export_rewrites["pre_op_mor_functor_components"];

val pre_op_mor_functor_morf = Q.store_thm(
"pre_op_mor_functor_morf",
`∀U f. (pre_op_mor_functor U)##f =
  TypedGraphFun (IMAGE op_mor f.dom, IMAGE op_mor f.cod) (op_mor o f.map o op_mor)`,
srw_tac [][morf_def]);
val _ = export_rewrites["pre_op_mor_functor_morf"];

val pre_op_mor_functor_objf = Q.store_thm(
"pre_op_mor_functor_objf",
`∀U x. x ∈ U ∧ IMAGE op_mor x ∈ U ⇒ ((pre_op_mor_functor U)@@x = IMAGE op_mor x)`,
srw_tac [][objf_def] >>
SELECT_ELIM_TAC >>
conj_tac >- (
  qexists_tac `IMAGE op_mor x` >>
  srw_tac [][] >>
  srw_tac [][morphism_component_equality] >>
  srw_tac [][restrict_def,FUN_EQ_THM] >>
  srw_tac [][] >> fsrw_tac [][] ) >>
srw_tac [][] >>
fsrw_tac [][morphism_component_equality]);
val _ = export_rewrites["pre_op_mor_functor_objf"];

val op_mor_functor_def = Define`
  op_mor_functor U = mk_functor (pre_op_mor_functor U)`;

val is_functor_op_mor_functor = Q.store_thm(
"is_functor_op_mor_functor",
`∀U. (∀x. x ∈ U ⇒ IMAGE op_mor x ∈ U) ⇒ is_functor (op_mor_functor U)`,
srw_tac [][op_mor_functor_def] >>
srw_tac [][functor_axioms_def] >>
srw_tac [][] >- fsrw_tac [][IsTypedFun_def,HasFunType_def]
>- (
  qexists_tac `IMAGE op_mor x` >>
  srw_tac [][morphism_component_equality] >>
  srw_tac [][restrict_def,FUN_EQ_THM] >>
  srw_tac [][] >> fsrw_tac [][] ) >>
qmatch_abbrev_tac `hh = gg o ff -: ens_cat U` >>
`ff ≈> gg -:ens_cat U` by (
  srw_tac [][Abbr`ff`,Abbr`gg`] >>
  fsrw_tac [][IsTypedFun_def,HasFunType_def] ) >>
srw_tac [][] >>
srw_tac [][Abbr`gg`,Abbr`ff`,Abbr`hh`,morphism_component_equality] >>
srw_tac [][ComposeFun_def] >>
srw_tac [][restrict_def,FUN_EQ_THM] >>
srw_tac [][] >>
fsrw_tac [][IsTypedFun_def,HasFunType_def] >>
metis_tac []);
val _ = export_rewrites["is_functor_op_mor_functor"];

val op_mor_functor_dom_cod = Q.store_thm(
"op_mor_functor_dom_cod",
`∀U. ((op_mor_functor U).dom = ens_cat U) ∧
     ((op_mor_functor U).cod = ens_cat U)`,
srw_tac [][op_mor_functor_def]);
val _ = export_rewrites["op_mor_functor_dom_cod"];

val op_mor_functor_morf = Q.store_thm(
"op_mor_functor_morf",
`∀U f. IsTypedFunIn U f ⇒ ((op_mor_functor U)##f =
  TypedGraphFun (IMAGE op_mor f.dom, IMAGE op_mor f.cod) (op_mor o f.map o op_mor))`,
srw_tac [][op_mor_functor_def,mk_functor_def,morphism_component_equality,morf_def,
           restrict_def]);
val _ = export_rewrites["op_mor_functor_morf"];

val op_mor_functor_objf = Q.store_thm(
"op_mor_functor_objf",
`∀U x. x ∈ U ∧ IMAGE op_mor x ∈ U ⇒ ((op_mor_functor U)@@x = IMAGE op_mor x)`,
srw_tac [][op_mor_functor_def]);
val _ = export_rewrites["op_mor_functor_objf"];

val _ = add_rule{
  term_name = "contra_hom_functor",
  fixity=Suffix 620,
  pp_elements=[TOK"|_\226\134\146",TM,TOK"|"],
  paren_style=OnlyIfNecessary,
  block_style=(AroundEachPhrase,(PP.INCONSISTENT,0))};

val _ = overload_on("contra_hom_functor",``λc x.  (op_mor_functor UNIV) ◎ (hom_functor c° x)``);

val contra_hom_functor_objf = Q.store_thm(
"contra_hom_functor_objf",
`∀c x y. is_category c ∧ x ∈ c.obj ∧ y ∈ c.obj ⇒ ((c|_→y|)@@x = (c|x→y|))`,
srw_tac [][] >> srw_tac [DNF_ss][EXTENSION]);

val contra_hom_functor_morf = Q.store_thm(
"contra_hom_functor_morf",
`∀c x f. is_category c ∧ f° ∈ c.mor ∧ x ∈ c.obj ⇒
  ((c|_→x|)##f = TypedGraphFun ((c|f.dom→x|), (c|f.cod→x|)) (λg. g o f° -:c))`,
srw_tac [][] >>
qabbrev_tac `ff = f° °` >>
`f = ff` by srw_tac [][Abbr`ff`] >>
`ff ∈ c°.mor` by (
  srw_tac [][Abbr`ff`] >>
  qexists_tac `f°` >> srw_tac [][] ) >>
fsrw_tac [][] >> srw_tac [][] >>
qmatch_abbrev_tac `(op_mor_functor UNIV)##f = g` >>
`IsTypedFun f` by (
  srw_tac [][Abbr`f`,Abbr`g`] >>
  qmatch_assum_rename_tac `f ∈ (c|g.cod→x|)` [] >>
  qexists_tac `f° ° o g° ° -:c` >>
  `g° ° ≈> f° ° -:c` by (
    match_mp_tac maps_to_composable >>
    srw_tac [][] >> fsrw_tac [][hom_def,maps_to_in_def] ) >>
  conj_tac >- (
    match_mp_tac op_cat_compose_in >>
    srw_tac [][] ) >>
  imp_res_tac composable_maps_to >>
  fsrw_tac [][hom_def] >>
  fsrw_tac [][maps_to_in_def] ) >>
srw_tac [][Abbr`g`,Abbr`f`,morphism_component_equality] >>
TRY (srw_tac [DNF_ss][EXTENSION] >> NO_TAC) >>
srw_tac [][restrict_def,FUN_EQ_THM] >>
srw_tac [][] >> fsrw_tac [DNF_ss][] >- (
  qmatch_rename_tac `(g° o f° -:c°)° = f o g -:c` [] >>
  qspecl_then [`f`,`g`,`c°`] mp_tac op_cat_compose_in >>
  srw_tac [][] >> pop_assum (match_mp_tac o GSYM) >>
  match_mp_tac maps_to_composable >>
  fsrw_tac [][hom_def,maps_to_in_def] ) >>
metis_tac [op_mor_idem]);
val _ = export_rewrites["contra_hom_functor_objf","contra_hom_functor_morf"];

val YfunctorNT_def = Define`
  YfunctorNT c f = mk_nt <|
    dom := c|_→f.dom|; cod := c|_→f.cod|;
    map := λx. (c|x→_|##f) |>`

val YfunctorNT_dom_cod = Q.store_thm(
"YfunctorNT_dom_cod",
`∀c f. ((YfunctorNT c f).dom = c|_→f.dom|) ∧
       ((YfunctorNT c f).cod = c|_→f.cod|)`,
srw_tac [][YfunctorNT_def]);
val _ = export_rewrites["YfunctorNT_dom_cod"];

val ntdom_YfunctorNT = Q.store_thm(
"ntdom_YfunctorNT",
`∀c f. ntdom (YfunctorNT c f) = c°`,
srw_tac [][YfunctorNT_def,mk_nt_def]);

val ntcod_YfunctorNT = Q.store_thm(
"ntcod_YfunctorNT",
`∀c f. ntcod (YfunctorNT c f) = (ens_cat UNIV)`,
srw_tac [][YfunctorNT_def,mk_nt_def]);

val YfunctorNT_at = Q.store_thm(
"YfunctorNT_at",
`∀c f x. x ∈ c.obj ⇒
  ((YfunctorNT c f)@+x = (c|x→_|##f))`,
srw_tac [][YfunctorNT_def,mk_nt_def,restrict_def]);

val _ = export_rewrites ["ntdom_YfunctorNT","ntcod_YfunctorNT","YfunctorNT_at"];

(*
val HasFunType_postcomp = Q.store_thm(
"HasFunType_postcomp",
`∀c f w x y z. is_category c ∧ f :- x → y -:c ∧ (w = z)
  ⇒ HasFunType (λg. g o f -:c) (c|y→z|) (c|x→w|)`,

Problem: (λg. g o f -:c) has a dependent type.
The type is ∀z. c|y→z| c|x→z|
It is extensional on the union over all z of c|y→z|
but depending on which element of the union you came from, the result type can be constrained
*)

val is_nat_trans_YfunctorNT = Q.store_thm(
"is_nat_trans_YfunctorNT",
`∀c f. is_category c ∧ f ∈ c.mor ⇒ is_nat_trans (YfunctorNT c f)`,
srw_tac [][YfunctorNT_def] >>
srw_tac [][nat_trans_axioms_def] >- (
  imp_res_tac mor_obj >>
  fsrw_tac [][hom_def] >>
  match_mp_tac maps_to_comp >>
  metis_tac [maps_to_in_def,maps_to_def] ) >>
qmatch_assum_rename_tac `g° :- y → x -:c` [] >>
imp_res_tac maps_to_in_def >>
fsrw_tac [][] >> srw_tac [][] >>
imp_res_tac mor_obj >> srw_tac [][] >>
qmatch_abbrev_tac
  `(TypedGraphFun (t2,t3) f2) o (TypedGraphFun (t1,t2) f1) -:ens_cat U =
   (TypedGraphFun (t4,t3) f1) o (TypedGraphFun (t1,t4) f2) -:ens_cat U` >>
`(∀x. x ∈ t1 ⇒ f1 x ∈ t2) ∧
 (∀x. x ∈ t4 ⇒ f1 x ∈ t3) ∧
 (∀x. x ∈ t2 ⇒ f2 x ∈ t3) ∧
 (∀x. x ∈ t1 ⇒ f2 x ∈ t4)` by (
  unabbrev_all_tac >>
  fsrw_tac [][hom_def] >>
  srw_tac [][] >>
  match_mp_tac maps_to_comp >>
  metis_tac []) >>
qmatch_abbrev_tac `x o w -:ens_cat U = v o u -:ens_cat U` >>
`IsTypedFun u ∧ IsTypedFun v ∧ IsTypedFun w ∧ IsTypedFun x` by
  metis_tac [IsTypedFunTypedGraphFun] >>
`u ∈ (ens_cat U).mor ∧ v ∈ (ens_cat U).mor ∧ w ∈ (ens_cat U).mor ∧ x ∈ (ens_cat U).mor` by
  metis_tac [ens_cat_mor,IN_UNIV] >>
`u ≈> v -:(ens_cat U)` by (
  srw_tac [][composable_def,Abbr`v`,Abbr`u`,Abbr`U`]) >>
`w ≈> x -:ens_cat U` by (
  srw_tac [][composable_def,Abbr`x`,Abbr`w`,Abbr`U`]) >>
srw_tac [][] >>
map_every qunabbrev_tac [`u`,`v`,`w`,`x`] >>
srw_tac [][ComposeTypedFun_def,TypedGraphFun_def] >>
srw_tac [][ComposeFun_def] >>
srw_tac [][restrict_def] >>
srw_tac [][FUN_EQ_THM] >>
srw_tac [][Abbr`f1`,Abbr`f2`] >>
match_mp_tac (GSYM comp_assoc) >>
qunabbrev_tac `t1` >>
fsrw_tac [][hom_def] >>
imp_res_tac maps_to_composable >>
srw_tac [][]);
val _ = export_rewrites["is_nat_trans_YfunctorNT"];

val YfunctorNT_maps_to = Q.store_thm(
"YfunctorNT_maps_to",
`∀c f. is_category c ∧ f ∈ c.mor ⇒
    (YfunctorNT c f) :- (c|_→f.dom|) → (c|_→f.cod|) -:[(c°)→ens_cat UNIV]`,
srw_tac [][maps_to_in_def]);
val _ = export_rewrites["YfunctorNT_maps_to"];

val YfunctorNT_composable = Q.store_thm(
"YfunctorNT_composable",
`∀c f g. is_category c ∧ f ≈> g -:c ⇒
  (YfunctorNT c f) ≈> (YfunctorNT c g) -:[(c°)→ens_cat UNIV]`,
srw_tac [][composable_nts_def] >> fsrw_tac [][composable_in_def]);
val _ = export_rewrites["YfunctorNT_composable"];

val YfunctorNT_id = Q.store_thm(
"YfunctorNT_id",
`∀c x. is_category c ∧ x ∈ c.obj ⇒ (YfunctorNT c (id x -:c) = id_nt (c|_→x|))`,
srw_tac [][] >> match_mp_tac nt_eq_thm >>
srw_tac [][id_mor] >>
srw_tac [][TypedGraphFun_def,restrict_def] >>
srw_tac [][FUN_EQ_THM] >> srw_tac [][] >>
fsrw_tac [][hom_def,maps_to_in_def]);
val _ = export_rewrites["YfunctorNT_id"];

val is_category_presheaf_cat = Q.store_thm(
"is_category_presheaf_cat",
`∀c. is_category c ⇒ is_category [(c°)→ens_cat UNIV]`,
metis_tac [is_category_functor_cat,is_category_ens_cat,is_category_op_cat])
val _ = export_rewrites["is_category_presheaf_cat"];

val pre_Yfunctor_def = Define`
  pre_Yfunctor c = <|
    dom := c; cod := [(c°)→ens_cat UNIV];
    map := λf. YfunctorNT c f |>`;

val pre_Yfunctor_components = Q.store_thm(
"pre_Yfunctor_components",
`∀c. ((pre_Yfunctor c).dom = c) ∧
     ((pre_Yfunctor c).cod = [(c°)→ens_cat UNIV]) ∧
     ((pre_Yfunctor c).map = λf. YfunctorNT c f) ∧
     (∀f. (pre_Yfunctor c)##f = YfunctorNT c f)`,
srw_tac [][pre_Yfunctor_def,morf_def]);
val _ = export_rewrites["pre_Yfunctor_components"];

val pre_Yfunctor_objf = Q.store_thm(
"pre_Yfunctor_objf",
`∀c x. is_category c ∧ x ∈ c.obj
  ⇒ ((pre_Yfunctor c)@@x = c|_→x|)`,
srw_tac [][objf_def] >>
SELECT_ELIM_TAC >> srw_tac [][] >- (
  qexists_tac `c|_→x|` >> srw_tac [][] ) >>
pop_assum mp_tac >>
srw_tac [][id_in_def] >>
Q.ISPEC_THEN `[(c°)→ens_cat UNIV]` match_mp_tac id_inj >>
srw_tac [][]);
val _ = export_rewrites["pre_Yfunctor_objf"];

val Yfunctor_def = Define`
  Yfunctor c = mk_functor (pre_Yfunctor c)`;

val is_functor_Yfunctor = Q.store_thm(
"is_functor_Yfunctor",
`∀c. is_category c ⇒ is_functor (Yfunctor c)`,
srw_tac [][Yfunctor_def] >>
srw_tac [][functor_axioms_def,morf_def]
>- (imp_res_tac maps_to_obj >> fsrw_tac [][morf_def,maps_to_in_def])
>- (imp_res_tac maps_to_obj >> fsrw_tac [][morf_def,maps_to_in_def])
>- fsrw_tac [][maps_to_in_def]
>- (qexists_tac `c|_→x|` >> srw_tac [][]) >>
qspecl_then [`c`,`f`,`g`,`f.dom`,`g.cod`] mp_tac composable_maps_to >>
srw_tac [][] >>
imp_res_tac maps_to_in_def >>
imp_res_tac YfunctorNT_composable >>
match_mp_tac nt_eq_thm >> fsrw_tac [][] >>
conj_tac >- ( fsrw_tac [][nt_comp_def,compose_def,mk_nt_def,restrict_def,YfunctorNT_def,composable_in_def]) >>
conj_tac >- ( fsrw_tac [][nt_comp_def,compose_def,mk_nt_def,restrict_def,YfunctorNT_def,composable_in_def]) >>
`f ∈ c.mor ∧ g ∈ c.mor` by (
  imp_res_tac composable_in_def >> srw_tac [][]) >>
srw_tac [][] >>
qmatch_abbrev_tac
  `h = TypedGraphFun (i,j) k o TypedGraphFun (l,m) n -:ens_cat UNIV` >>
`(∀x. x ∈ i ⇒  k x ∈ j) ∧ (∀x. x ∈ l ⇒ n x ∈ m)` by (
  unabbrev_all_tac >>
  srw_tac [][hom_def] >>
  match_mp_tac maps_to_comp >>
  metis_tac [maps_to_in_def,maps_to_def] ) >>
imp_res_tac IsTypedFunTypedGraphFun >>
imp_res_tac ens_cat_mor >>
ntac 2 (pop_assum (qspec_then `UNIV` mp_tac)) >>
`m = i` by (
  fsrw_tac [][composable_in_def,Abbr`m`,Abbr`i`] ) >>
`(TypedGraphFun (l,m) n) ≈> (TypedGraphFun (i,j) k) -:ens_cat UNIV` by (
  srw_tac [][]) >>
srw_tac [][Abbr`h`] >>
srw_tac [][TypedGraphFun_def,ComposeTypedFun_def] >>
srw_tac [][ComposeFun_def] >>
srw_tac [][restrict_def] >>
srw_tac [][FUN_EQ_THM] >>
unabbrev_all_tac >>
srw_tac [][] >>
`g.dom = f.cod` by (
  fsrw_tac [][composable_in_def] ) >>
match_mp_tac comp_assoc >>
fsrw_tac [][hom_def] >>
match_mp_tac maps_to_composable >>
map_every qexists_tac [`x`,`f.dom`,`f.cod`] >>
srw_tac [][]);

val Yfunctor_dom = Q.store_thm(
"Yfunctor_dom",
`∀c. (Yfunctor c).dom = c`,
srw_tac [][Yfunctor_def]);

val Yfunctor_cod = Q.store_thm(
"Yfunctor_cod",
`∀c. (Yfunctor c).cod = [(c°)→ens_cat UNIV]`,
srw_tac [][Yfunctor_def]);

val Yfunctor_objf = Q.store_thm(
"Yfunctor_objf",
`∀c x. is_category c ∧ x ∈ c.obj ⇒
 ((Yfunctor c)@@x = c|_→x|)`,
srw_tac [][Yfunctor_def,mk_functor_objf]);

val Yfunctor_morf = Q.store_thm(
"Yfunctor_morf",
`∀c f. is_category c ∧ f ∈ c.mor ⇒
  ((Yfunctor c)##f = YfunctorNT c f)`,
srw_tac [][Yfunctor_def,morf_def]);

val _ = export_rewrites["Yfunctor_dom","Yfunctor_cod","Yfunctor_objf","Yfunctor_morf"];

val YMap_def = Define`
  YMap c x n = (n@+x).map (id x-:c)`;

val YMapImage = Q.store_thm(
"YMapImage",
`∀c x n f. is_category c ∧ is_functor f ∧ is_nat_trans n ∧
           (f :- c° → ens_cat UNIV) ∧ x ∈ c.obj ∧
           (n :- ((Yfunctor c)@@x) → f) ⇒
             (YMap c x n) ∈ (f@@x)`,
srw_tac [][YMap_def] >>
`(n @+ x) :- (n.dom @@ x) → (n.cod @@ x) -: n.dom.cod` by (
  fsrw_tac [][is_nat_trans_def,nat_trans_axioms_def] ) >>
pop_assum mp_tac >> srw_tac [][] >>
ntac 4 (pop_assum mp_tac) >> srw_tac [][] >>
fsrw_tac [][IsTypedFun_def] >>
fsrw_tac [][HasFunType_def] >>
first_x_assum match_mp_tac >>
srw_tac [][hom_def,id_maps_to]);

val YMapInv_def = Define`
  YMapInv c x f y = mk_nt <|
    dom := (Yfunctor c)@@x;
    cod := f;
    map := λz. TypedGraphFun ((c|z→x|), f@@z)
               (λg. (f##(g°)).map y) |>`;

val YMapInv_at = Q.store_thm(
"YMapInv_at",
`∀c x f y z. is_category c ∧ x ∈ c.obj ∧ z ∈ c.obj ⇒
    ((YMapInv c x f y) @+ z =
     TypedGraphFun ((c|z→x|), f@@z)
       (λg. (f##g°).map y))`,
srw_tac [][YMapInv_def,mk_nt_def,restrict_def]);
val _ = export_rewrites["YMapInv_at"];

val is_nat_trans_YMapInv = Q.store_thm(
"is_nat_trans_YMapInv",
`∀c x f y. is_category c ∧ is_functor f ∧ (f :- c° → ens_cat UNIV) ∧
           x ∈ c.obj ∧ y ∈ (f@@x)
 ⇒ is_nat_trans (YMapInv c x f y)`,
srw_tac [][YMapInv_def] >>
srw_tac [][nat_trans_axioms_def]
>- (
  qmatch_assum_rename_tac `g ∈ c|u→x|` [] >>
  `g° :- x → u -:(c°)` by fsrw_tac [][hom_def] >>
  `f##g° :- (f@@x) → (f@@u) -:ens_cat UNIV` by (
    match_mp_tac morf_maps_to >>
    map_every qexists_tac [`f.dom`,`x`,`u`] >>
    srw_tac [][] ) >>
  fsrw_tac [][IsTypedFun_def,HasFunType_def] >>
  fsrw_tac [][]) >>
qmatch_assum_rename_tac `g° :- u → v -:c` [] >>
imp_res_tac maps_to_in_def >>
fsrw_tac [][] >>
qmatch_abbrev_tac
`(TypedGraphFun (i,j) k) o (TypedGraphFun (l,i) n) -:ens_cat UNIV =
 q o (TypedGraphFun (l,s) h) -:ens_cat UNIV` >>
`(∀x. x ∈ i ⇒  k x ∈ j) ∧ (∀x. x ∈ l ⇒ h x ∈ s)` by (
 unabbrev_all_tac >> srw_tac [][] >>
 qmatch_assum_abbrev_tac `z ∈ (c|q→x|)` >>
 `f##(z)° :- f@@x → f@@q -:ens_cat UNIV` by (
   match_mp_tac morf_maps_to >>
   fsrw_tac [][hom_def] ) >>
 fsrw_tac [][maps_to_in_def,IsTypedFun_def,HasFunType_def] >>
 fsrw_tac [][]) >>
`∀x. x ∈ l ⇒ n x ∈ i` by (
  srw_tac [][Abbr`n`,Abbr`i`,Abbr`l`,hom_def] >>
  match_mp_tac maps_to_comp >>
  qexists_tac `g.dom` >>
  srw_tac [SATISFY_ss][]) >>
`q :- s → j -:ens_cat UNIV` by (
  map_every qunabbrev_tac [`q`,`s`,`j`] >>
  match_mp_tac morf_maps_to >>
  map_every qexists_tac [`f.dom`,`g.dom`,`g.cod`] >>
  srw_tac [][] ) >>
`IsTypedFun q` by fsrw_tac [][maps_to_in_def] >>
imp_res_tac maps_to_in_def >>
srw_tac [][Abbr`k`] >>
imp_res_tac IsTypedFunTypedGraphFun >>
`TypedGraphFun (l,s) h ≈> q -: ens_cat UNIV` by (
  fsrw_tac [][Abbr`q`,Abbr`s`,maps_to_in_def] ) >>
srw_tac [][] >>
unabbrev_all_tac >>
fsrw_tac [][ComposeTypedFun_def,compose_def,restrict_def] >>
srw_tac [][ComposeFun_def] >>
srw_tac [][restrict_def] >>
srw_tac [][FUN_EQ_THM] >>
srw_tac [][hom_def] >>
Q.ISPECL_THEN [`f`,`f.dom`,`f.cod`,`e°`,`g`] mp_tac morf_comp >>
`e° ≈> g -:c°` by (
  srw_tac [][composable_in_def] >>
  fsrw_tac [][maps_to_in_def] ) >>
fsrw_tac [][op_cat_compose_in] >>
Q.ISPECL_THEN [`f`,`f.dom`,`f.cod`,`e°`,`g`] mp_tac morf_composable >>
srw_tac [][ComposeFun_def,restrict_def] >- (
  fsrw_tac [][hom_def] >> metis_tac [] ) >>
Q.ISPECL_THEN [`f`,`f.dom`,`f.cod`,`e°`,`e.cod`,`e.dom`] mp_tac morf_maps_to >>
fsrw_tac [][maps_to_in_def] >> srw_tac [][] >>
fsrw_tac [][]);
val _ = export_rewrites["is_nat_trans_YMapInv"];

val YMapInvImage = Q.store_thm(
"YMapInvImage",
`∀c x f y. is_category c ∧ is_functor f ∧ (f :- c° → ens_cat UNIV) ∧
           x ∈ c.obj ∧ y ∈ (f@@x) ⇒
           is_nat_trans (YMapInv c x f y) ∧
           ((YMapInv c x f y) :- (Yfunctor c)@@x → f)`,
srw_tac [][YMapInv_def]);

val YMap1 = Q.store_thm(
"YMap1",
`∀c f x n. is_category c ∧ is_functor f ∧ (f :- c° → ens_cat UNIV) ∧
           x ∈ c.obj ∧ is_nat_trans n ∧ (n :- ((Yfunctor c)@@x) → f) ⇒
             (YMapInv c x f (YMap c x n) = n)`,
rpt strip_tac >>
match_mp_tac nt_eq_thm >>
imp_res_tac YMapImage >>
imp_res_tac is_nat_trans_YMapInv >>
srw_tac [][]
>- fsrw_tac [][YMapInv_def]
>- fsrw_tac [][YMapInv_def] >>
qmatch_rename_tac `X = n @+ z` ["X"] >>
`z ∈ c.obj` by (
  pop_assum mp_tac >> srw_tac [][YMapInv_def] ) >>
srw_tac [][] >>
fsrw_tac [][] >>
qpat_assum `X = (Yfunctor c)@@x` mp_tac >> srw_tac [][] >>
`∀z. z ∈ c.obj ⇒ n @+ z :- c|z→x| → (n.cod@@z) -:n.cod.cod` by (
  fsrw_tac [][is_nat_trans_def,nat_trans_axioms_def] >>
  metis_tac [contra_hom_functor_objf] ) >>
first_assum (qspec_then `z` mp_tac) >>
first_x_assum (qspec_then `x` mp_tac) >>
srw_tac [][] >>
srw_tac [][TypedGraphFun_def,morphism_component_equality] >>
srw_tac [][restrict_def] >>
srw_tac [][FUN_EQ_THM] >>
fsrw_tac [][IsTypedFun_def,HasFunType_def,extensional_def] >>
srw_tac [][YMap_def] >>
qmatch_assum_rename_tac `f ∈ c|z→x|` [] >>
Q.ISPECL_THEN [`n`,`c|_→x|`,`n.cod` ,`n.cod.cod` ,`f°`,`x`,`z`]
  mp_tac naturality >>
fsrw_tac [][hom_def] >>
qmatch_abbrev_tac `(f1 o f2 -:ens_cat UNIV = f3 o f4 -:ens_cat UNIV) ⇒ X` >>
`IsTypedFun f2` by (
  srw_tac [][Abbr`f2`] >>
  imp_res_tac maps_to_in_def >>
  srw_tac [][hom_def] >>
  match_mp_tac maps_to_comp >>
  qexists_tac `x` >>
  fsrw_tac [][maps_to_in_def]) >>
`f1 :- f1.dom → f1.cod -:ens_cat UNIV` by (
  qunabbrev_tac `f1` >>
  match_mp_tac nt_at_maps_to >>
  srw_tac [][hom_def] ) >>
`f4 :- f4.dom → f4.cod -:ens_cat UNIV` by (
  qunabbrev_tac `f4` >>
  match_mp_tac nt_at_maps_to >>
  srw_tac [][hom_def] ) >>
`(n.cod##f°) :- n.cod@@x → n.cod@@z -:n.cod.cod` by (
  match_mp_tac morf_maps_to >>
  fsrw_tac [][] >>
  map_every qexists_tac [`x`,`z`] >>
  srw_tac [][] ) >>
`f3 :- f3.dom → f3.cod -:ens_cat UNIV` by (
  qunabbrev_tac `f3` >>
  match_mp_tac morf_maps_to >>
  srw_tac [][] >>
  map_every qexists_tac [`x`,`z`] >>
  srw_tac [][] >>
  fsrw_tac [][maps_to_in_def] ) >>
imp_res_tac maps_to_in_def >>
`f2 ≈> f1 -:ens_cat UNIV` by (
  fsrw_tac [][Abbr`f2`,hom_def] >>
  srw_tac [][] >>
  match_mp_tac maps_to_comp >>
  srw_tac [SATISFY_ss][] ) >>
`f4 ≈> f3 -:ens_cat UNIV` by (
  fsrw_tac [][Abbr`f3`] ) >>
`n.cod@@z = f3.cod` by (
  fsrw_tac [][maps_to_in_def,Abbr`f3`] ) >>
`f2.dom = f4.dom` by (
  fsrw_tac [][Abbr`f4`,Abbr`f2`,hom_def] ) >>
`f2.map (id f.cod -:c) = f` by (
  srw_tac [][Abbr`f2`] >>
  srw_tac [][restrict_def,hom_def] >>
  fsrw_tac [][] >> srw_tac [][] >>
  pop_assum mp_tac >> srw_tac [][id_maps_to] ) >>
fsrw_tac [][ComposeTypedFun_def,compose_def,restrict_def,ComposeFun_def] >>
srw_tac [][FUN_EQ_THM] >>
pop_assum (qspec_then `id f.cod -:c` mp_tac) >>
fsrw_tac [][id_maps_to]);

val YMap2 = Q.store_thm(
"YMap2",
`∀c x f y. is_category c ∧ is_functor f ∧ (f :- c° → ens_cat UNIV) ∧
           x ∈ c.obj ∧ y ∈ (f@@x) ⇒
             (YMap c x (YMapInv c x f y) = y)`,
srw_tac [][YMap_def] >>
srw_tac [][restrict_def,hom_def] >>
pop_assum mp_tac >> srw_tac [][id_maps_to] >>
`f##(id x -:(c°)) = id (f@@x) -: ens_cat UNIV` by srw_tac [][morf_id] >>
fsrw_tac [][] >>
srw_tac [][restrict_def]);

val YfunctorNT_YMapInv = Q.store_thm(
"YfunctorNT_YMapInv",
`∀c f x y. is_category c ∧ f :- x → y -:c ⇒
    (YfunctorNT c f = YMapInv c x (c|_→y|) f)`,
srw_tac [][] >>
match_mp_tac nt_eq_thm >>
imp_res_tac maps_to_in_def >>
imp_res_tac maps_to_obj >>
fsrw_tac [][] >>
conj_tac >- (
  match_mp_tac is_nat_trans_YMapInv >>
  srw_tac [][hom_def] ) >>
conj_tac >- srw_tac [][YfunctorNT_def,YMapInv_def] >>
conj_tac >- srw_tac [][YfunctorNT_def,YMapInv_def] >>
srw_tac [][TypedGraphFun_def] >>
srw_tac [][restrict_def] >>
srw_tac [][FUN_EQ_THM] >>
srw_tac [][hom_def] >>
imp_res_tac maps_to_in_def >>
srw_tac [][restrict_def] >>
fsrw_tac [][hom_def,maps_to_in_def] >>
fsrw_tac [][]);

val YMapYoneda = Q.store_thm(
"YMapYoneda",
`∀c f x y. is_category c ∧ f :- x → y -:c ⇒
  ((Yfunctor c)##f = YMapInv c x ((Yfunctor c)@@y) f)`,
srw_tac [][] >>
imp_res_tac maps_to_in_def >>
imp_res_tac maps_to_obj >>
srw_tac [][YfunctorNT_YMapInv]);

val YonedaFull = Q.store_thm(
"YonedaFull",
`∀c. is_category c ⇒ full (Yfunctor c)`,
srw_tac [][full_def] >>
qexists_tac `YMap c a h` >>
`YMap c a h ∈ (c|_→b|)@@a` by (
  match_mp_tac YMapImage >>
  imp_res_tac Yfunctor_objf >>
  fsrw_tac [][] ) >>
pop_assum mp_tac >> srw_tac [][contra_hom_functor_objf,hom_def] >>
match_mp_tac EQ_TRANS >>
qexists_tac `YMapInv c a (Yfunctor c@@b) (YMap c a h)` >>
conj_tac >- srw_tac [][YMapYoneda] >>
match_mp_tac YMap1 >>
fsrw_tac [][]);

val YonedaFaithful = Q.store_thm(
"YonedaFaithful",
`∀c. is_category c ⇒ faithful (Yfunctor c)`,
srw_tac [][faithful_def] >>
`YMap c a (YMapInv c a (c|_→b|) g) =
 YMap c a (YMapInv c a (c|_→b|) h)`
 by metis_tac [maps_to_in_def,Yfunctor_morf,YfunctorNT_YMapInv] >>
match_mp_tac EQ_TRANS >>
qexists_tac `YMap c a (YMapInv c a (c|_→b|) g)` >>
conj_tac >- (
  match_mp_tac EQ_SYM >>
  match_mp_tac YMap2 >>
  imp_res_tac maps_to_obj >>
  fsrw_tac [][hom_def] ) >>
srw_tac [][] >>
match_mp_tac YMap2 >>
imp_res_tac maps_to_obj >>
fsrw_tac [][hom_def]);

val YonedaEmbedding = Q.store_thm(
"YonedaEmbedding",
`∀c. is_category c ⇒ embedding (Yfunctor c)`,
srw_tac [][embedding_def,YonedaFaithful,YonedaFull]);

val YonedaInjObj = Q.store_thm(
"YonedaInjObj",
`∀c. is_category c ⇒ inj_obj (Yfunctor c)`,
srw_tac [][inj_obj_def] >>
srw_tac [][] >> pop_assum mp_tac >> srw_tac [][] >>
`(c|_→a|)@@a = (c|_→b|)@@a` by asm_simp_tac std_ss [] >>
pop_assum mp_tac >>
pop_assum (K ALL_TAC) >>
srw_tac [][EXTENSION] >>
pop_assum (qspec_then `id a -:c` mp_tac) >>
srw_tac [][hom_def,id_maps_to] >>
fsrw_tac [][maps_to_in_def] >>
imp_res_tac id_maps_to >>
fsrw_tac [][maps_to_in_def]);

val _ = export_theory ();
