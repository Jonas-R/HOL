signature tttSynt =
sig

  include Abbrev
  
  datatype pattern =
    Pconst of int
  | Pcomb  of pattern * pattern
  | Plamb  of pattern * pattern
  
  (* globals *)
  val concept_threshold : int ref
  val concept_flag : bool ref
  val tycheck_flag : bool ref

  (* debugging *)
  val ttt_synt_dir  : string ref
  val log_synt      : string -> unit 
  val log_synt_file : string -> string -> unit
  val msg_synt      : 'a list -> string -> unit
  val time_synt     : string -> ('a -> 'b) -> 'a -> 'b
  val writel_synt   : string -> string list -> unit
  
  (* conjecturing *)
  val conjecture : int -> term list -> term list
 
end
