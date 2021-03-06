open Ast

type sexpr = typ * sx
and sx = 
    SBinop of sexpr * bop * sexpr
  | SBLit of bool
  | SILit of int
  | SFLit of float
  | SStrLit of string 
  | SArrayLit of sexpr list 
  (* list of vals, must all have the same type one of (Int, Bool, Float) *)
  | SAsn of string * sexpr (* must be Void reported by semant.ml *)
  | SCustDecl of string * string (* (id, custom_type) *)
  | SVar of string
  | SSwap of sexpr * sexpr (* arr[x], arr[y] *)
  | SCall of string * sexpr list 
  | SCustVar of string * string  (* id, var, e.g. myCustTypeVar.myIntVar *)
  | SCustAsn of string * string * sexpr  (* id, var, expr *)
  | SArrayAccess of string * sexpr (* name, loc should be int *)
  | SArrayMemberAsn of string * sexpr * sexpr (* name, loc, val *)
  | SArrayDecl of string * int * typ * sexpr list (* name, size, arr_type, values *)
  | SArrLength of string (* arr to get length of *)

type sstmt =
    SBlock of sstmt list 
  | SExpr of sexpr 
  | SIf of sexpr * sstmt * sstmt  
  | SWhile of sexpr * sstmt
  | SFor of string * sexpr * sexpr * sstmt
  | SFordown of string * sexpr * sexpr * sstmt
  | SReturn of sexpr

type sfunc_def = { 
    srtyp : typ;
    sfname : string; 
    sargs : param_type list;
    sbody : sstmt list;
}

type scustom_type_def = {
  sname: string; 
  svars: param_type list;
}

type sprog_part = SFuncDef of sfunc_def | SCustomTypeDef of scustom_type_def

type sprogram = sprog_part list

(* Pretty-printing functions *)
let rec string_of_sexpr (t, e) =
  "(" ^ string_of_typ t ^ " : " ^ (
    match e with
      SBinop(e1, b, e2) -> string_of_sexpr e1 ^ " " ^ string_of_bop b ^ " " ^
                            string_of_sexpr e2
    | SBLit(true) -> "TRUE"
    | SBLit(false) -> "FALSE"
    | SILit(l) -> string_of_int l
    | SFLit(l) -> string_of_float l
    | SArrayLit(sexprs) -> "[" ^ (String.concat ", " (List.map string_of_sexpr sexprs)) ^ "]"
    | SAsn(id, e) -> "Assignment # " ^ id ^ " := " ^ string_of_sexpr e
    | SCustDecl(id, cust) -> "CustomAssignment # " ^ id ^ " := " ^ cust
    | SVar(id) -> id
    | SSwap(e1, e2) -> "swap(" ^ (string_of_sexpr e1) ^ ", " ^
        (string_of_sexpr e2) ^ ")"
    | SCall(func, args) -> "Call # " ^ func ^ "(" ^ String.concat ", " (List.map string_of_sexpr args) ^ ")"
    | SCustVar(id, var) -> id ^ "." ^ var
    | SCustAsn(id, var, e) -> "Assignment # " ^ id ^ "." ^ var ^ " := " ^ (string_of_sexpr e)
    | SArrayDecl(id, size, t, values) -> "Array: " ^ id ^ " of type " ^ (string_of_typ t) ^ " with size " ^ (string_of_int size) ^ " and values " ^ "[" ^ (String.concat ", " (List.map string_of_sexpr values)) ^ "]"
    | SArrayAccess (id, loc) -> id ^ "[" ^ (string_of_sexpr loc) ^ "]"
    | SArrayMemberAsn (id, loc, v) -> id ^ "[" ^ (string_of_sexpr loc) ^ "]" ^ " = " ^ (string_of_sexpr v)
    | SStrLit(str) -> enclose str "\""
    | SArrLength(id) -> id ^ ".length"
  ) ^ ")"

let rec string_of_sstmt = function
  | SExpr(e) -> string_of_sexpr e ^ "[;]\n"
  | SBlock(sstmts) -> "{\n" ^ String.concat "" (List.map string_of_sstmt sstmts) ^ "}\n"
  | SIf(cond, sstmt1, sstmt2) ->
      "if " ^ string_of_sexpr cond ^ "\n" ^ string_of_sstmt sstmt1 ^ "else\n" ^
      string_of_sstmt sstmt2
  | SWhile(cond, sstmt) -> "while " ^ string_of_sexpr cond ^ "\n" ^ string_of_sstmt sstmt
  | SFor(id, lo, hi, sstmt) ->
      "for " ^ id ^ " = " ^ (string_of_sexpr lo) ^ " to "
      ^ (string_of_sexpr hi) ^ (string_of_sstmt sstmt)
  | SFordown (id, hi, lo, sstmt) ->
      "for " ^ id ^ " = " ^ (string_of_sexpr hi) ^ " downto "
      ^ (string_of_sexpr lo) ^ (string_of_sstmt sstmt)
  | SReturn(e) -> "return " ^ string_of_sexpr e ^ "[;]\n"

let string_of_sfdecl sfdecl =
  string_of_typ sfdecl.srtyp ^ " function:\n" ^
  sfdecl.sfname ^ "(" ^ (String.concat ", " (List.map string_of_param_type sfdecl.sargs)) ^ ")\n{\n" ^
  String.concat "" (List.map string_of_sstmt sfdecl.sbody) ^
  "}\n"


let string_of_scust_type_def c = 
  c.sname ^ " {" ^ (String.concat ", " (List.map string_of_param_type c.svars)) ^ "}"
 
 let string_of_prog_part = function 
   | SFuncDef(sfunc_def) -> string_of_sfdecl sfunc_def
   | SCustomTypeDef(scust_type_def) -> string_of_scust_type_def scust_type_def
 

let string_of_sprogram prog =
  "\n\nSementically checked program: \n\n" ^
  String.concat "\n" (List.map string_of_prog_part prog)
