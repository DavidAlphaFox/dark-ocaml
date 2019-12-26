type t = Types.fluidExpr

(** Generate a new EBlank *)
val newB : unit -> t

(** to convert between NExprs and `t`, this
 * file need to know all the functions. This
 * is nasty to pass around as state so we use
 * global state. *)
val functions : Types.function_ list ref

(** [toNExpr e] recursively converts [e] to the corresponding [nExpr blankOr] *)
val toNExpr : t -> Types.expr

(** [fromNExpr e] recursively converts a corresponding [nExpr blankOr] to [e] *)
val fromNExpr : Types.expr -> t

(** [id e] returns the id of [e] *)
val id : t -> Types.id

(** [show e] returns a string representation of [e]. *)
val show : t -> string

(** [walk f ast] is a helper for recursively walking an expression tree. It
    returns a new ast with every subexpression e replaced by [f e]. To use
    effectively, [f] must call [walk]. *)
val walk : f:(t -> t) -> t -> t

(** [find target ast] recursively finds the expression having an id of [target]
   and returns it if found. *)
val find : Types.id -> t -> t option

(** [findParent target ast] recursively finds the expression having an id of
    [target] and then returns the parent of that expression. *)
val findParent : Types.id -> t -> t option

(** [isEmpty e] returns true if e is an EBlank or a collection (ERecord or
    EList) with only EBlanks inside. *)
val isEmpty : t -> bool

(** [hasEmptyWithId target ast] recursively finds the expression having an id
    of [target] and returns true if that expression exists and [isEmpty]. *)
val hasEmptyWithId : Types.id -> t -> bool

(** [isBlank e] returns true iff [e] is an EBlank. *)
val isBlank : t -> bool

(** [update f target ast] recursively searches [ast] for an expression e
    having an id of [target].

    If found, replaces the expression with the result of [f e] and returns the new ast.
    If not found, will assertT before returning the unmodified [ast]. *)
val update : ?failIfMissing:bool -> f:(t -> t) -> Types.id -> t -> t

(** [replace replacement target ast] finds the expression with id of [target] in the [ast] and replaces it with [replacement]. *)
val replace : replacement:t -> Types.id -> t -> t

val removeVariableUse : string -> t -> t

val renameVariableUses : oldName:string -> newName:string -> t -> t

val updateVariableUses : string -> f:(t -> t) -> t -> t

val clone : t -> t
