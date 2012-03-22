val _ = map load ["rich_listTheory","compilerTheory"]

(* TODO: move to rich_list  (or somewhere) *)
val REPLACE_ELEMENT_compute =
  CONV_RULE numLib.SUC_TO_NUMERAL_DEFN_CONV rich_listTheory.REPLACE_ELEMENT_DEF

val _ = computeLib.add_thms
[ listTheory.SUM (* TODO: put in list_rws? similarly the other one *)
, REPLACE_ELEMENT_compute
] computeLib.the_compset

val d = !Globals.emitMLDir
val _ = map (fn s => (use (d^s^"ML.sig"); use (d^s^"ML.sml")))
["combin","pair","num","option","list","set",
 "fmap","sum","fcp","string","bit","words","int",
 "rich_list","bytecode"]

open bytecodeML

val s = ``<| env := []; next_label := 0; sz := 0; inst_length := λi. 0 |>``
fun term_to_num x = (numML.fromString (Parse.term_to_string x))
fun term_to_int x = (intML.fromString ((Parse.term_to_string x)^"i"))

fun term_to_stack_op tm = let
  val (f,x) = dest_comb tm
in(case fst (dest_const f) of
    "PushInt" => PushInt (term_to_int x)
  | "Load" => Load (term_to_num x)
  | "Store" => Store (term_to_num x)
  | "Pops" => Pops (term_to_num x)
  | "El" => El (term_to_num x)
  | s => raise Fail s
  )
handle HOL_ERR _ => let
  val (f,w) = dest_comb f
in case fst (dest_const f) of
    "Cons" => Cons (term_to_num w,term_to_num x)
  | s => raise Fail s
end end handle HOL_ERR _ =>
  case fst (dest_const tm) of
    "Equal" => Equal
  | "Pop" => Pop
  | "Add" => Add
  | "Sub" => Sub
  | "Less" => Less
  | s => raise Fail s
fun term_to_bc tm = let
  val (f,x) = dest_comb tm
in case fst (dest_const f) of
    "Jump" => Jump (term_to_num x)
  | "JumpNil" => JumpNil (term_to_num x)
  | "Stack" => Stack (term_to_stack_op x)
  | "Call" => Call (term_to_num x)
  | s => raise Fail s
end handle HOL_ERR _ =>
  case fst (dest_const tm) of
    "Return" => Return
  | "CallPtr" => CallPtr
  | s => raise Fail s
val term_to_bc_list = (map term_to_bc) o fst o listSyntax.dest_list
fun f1 e = EVAL ``FST (compile (remove_Gt_Geq ^e,^s))``
fun f2 e = rhs (concl (f1 e))
fun f e = term_to_bc_list (f2 e)
fun g1 c = bc_eval (init_state c)
fun g c = bc_state_stack (g1 c)

val e1 = ``Val (Lit (IntLit 42))``
val c1 = f e1
val [Number i] = g c1
val SOME 42 = intML.toInt i;
val e2 = ``If (Val (Lit (Bool T))) (Val (Lit (IntLit 1))) (Val (Lit (IntLit 2)))``
val c2 = f e2
val [Number i] = g c2
val SOME 1 = intML.toInt i;
val e3 = ``If (Val (Lit (Bool F))) (Val (Lit (IntLit 1))) (Val (Lit (IntLit 2)))``
val c3 = f e3
val [Number i] = g c3
val SOME 2 = intML.toInt i;
val e4 = ``App Equality (Val (Lit (IntLit 1))) (Val (Lit (IntLit 2)))``
val c4 = f e4
val [Number i] = g c4
val SOME 0 = intML.toInt i;
val e5 = ``Fun "x" (Var "x")``
val c5 = f e5
val st = g c5
val e6 = ``Let "x" (Val (Lit (IntLit 1))) (App (Opn Plus) (Var "x") (Var "x"))``
val c6 = f e6
val [Number i] = g c6
val SOME 2 = intML.toInt i;
val e7 = ``Let "x" (Val (Lit (IntLit 1)))
             (Let "y" (Val (Lit (IntLit 2)))
                (Let "x" (Val (Lit (IntLit 3)))
                   (App (Opn Plus) (Var "x") (Var "y"))))``
val c7 = f e7
val [Number i] = g c7
val SOME 5 = intML.toInt i;
val e8 = ``
Let "0?" (Fun "x" (App Equality (Var "x") (Val (Lit (IntLit 0)))))
  (Let "x" (Val (Lit (IntLit 1)))
    (Let "x" (App (Opn Minus) (Var "x") (Var "x"))
      (App Opapp (Var "0?") (Var "x"))))``
val c8 = f e8
val [Number i] = g c8
val SOME 1 = intML.toInt i;
val e9 = ``
Let "1?" (Fun "x" (App Equality (Var "x") (Val (Lit (IntLit 1)))))
  (Let "x" (Val (Lit (IntLit 1)))
    (Let "x" (App (Opn Minus) (Var "x") (Var "x"))
      (App Opapp (Var "1?") (Var "x"))))``
val c9 = f e9
val [Number i] = g c9
val SOME 0 = intML.toInt i;
val e10 = ``
Let "x" (Val (Lit (IntLit 3)))
(If (App (Opb Gt) (Var "x") (App (Opn Plus) (Var "x") (Var "x")))
  (Var "x") (Val (Lit (IntLit 4))))``
val c10 = f e10
val [Number i] = g c10
val SOME 4 = intML.toInt i;
val e11 = ``
Let "x" (Val (Lit (IntLit 3)))
(If (App (Opb Geq) (Var "x") (Var "x"))
  (Var "x") (Val (Lit (IntLit 4))))``
val c11 = f e11
val [Number i] = g c11
val SOME 3 = intML.toInt i;
val e12 = ``
Let "lt2" (Fun "x" (App (Opb Lt) (Var "x") (Val (Lit (IntLit 2)))))
  (App Opapp (Var "lt2") (Val (Lit (IntLit 3))))``
val c12 = f e12
val [Number i] = g c12
val SOME 0 = intML.toInt i;
val e13 = ``
Let "lq2" (Fun "x" (App (Opb Leq) (Var "x") (Val (Lit (IntLit 2)))))
  (App Opapp (Var "lq2") (Val (Lit (IntLit 0))))``
val c13 = f e13
val [Number i] = g c13
val SOME 1 = intML.toInt i;
val e14 = ``
Let "x" (Val (Lit (IntLit 0)))
  (Let "y" (App (Opn Plus) (Var "x") (Val (Lit (IntLit 2))))
    (If (App (Opb Geq) (Var "y") (Var "x"))
      (Var "x") (Val (Lit (IntLit 4)))))``
val c14 = f e14
val [Number i] = g c14
val SOME 0 = intML.toInt i