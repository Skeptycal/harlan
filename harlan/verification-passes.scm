(library
  (harlan verification-passes)
  (export
    verify-harlan
    verify-nest-lets
    verify-parse-harlan
    verify-flatten-lets
    verify-returnify
    verify-lift-complex
    verify-typecheck
    verify-lower-vectors
    verify-returnify-kernels
    verify-remove-nested-kernels
    verify-uglify-vectors
    verify-annotate-free-vars
    verify-hoist-kernels
    verify-move-gpu-data
    verify-generate-kernel-calls
    verify-compile-module
    verify-convert-types
    verify-compile-kernels)
  (import
    (rnrs)
    (elegant-weapons helpers)
    (util verify-grammar))

  (grammar-transforms

    (%static
      (Ret-Stmt (return Expr))
      (Type
        scalar-type
        (vector Type Integer)
        (ptr Type)
        ((Type *) -> Type))
      (Var ident)
      (Integer integer)
      (Reduceop reduceop)
      (Binop binop)
      (Relop relop)
      (Float float)
      (String string)
      (Number number))
    
    (harlan
      (Start Module)
      (Module (module Decl +))
      (Decl
        (extern Var (Type *) -> Type)
        (fn Var (Var *) Expr +))
      (Expr
        integer
        float
        string
        ident
        (let Var Expr)
        (let ((Var Expr) *) Expr +)
        (begin Expr * Expr)
        (print Expr)
        (assert Expr)
        (set! Expr Expr)
        (vector-set! Expr Expr Expr)
        (for (Var Expr Expr) Expr +)
        (while Expr Expr +)
        (if Expr Expr)
        (if Expr Expr Expr)
        (return Expr)
        (var Var)
        (vector Expr +)
        (vector-ref Expr Expr)
        (kernel ((Var Expr) +) Expr * Expr)
        (reduce Reduceop Expr)
        (iota Integer)
        (length Expr)
        (make-vector Integer)
        (Binop Expr Expr)
        (Relop Expr Expr)
        (Var Expr *)))

    (nest-lets (%inherits Module Decl)
      (Start Module)
      (Expr
        integer
        float
        string
        ident
        (let ((Var Expr) *) Expr +)
        (begin Expr * Expr)
        (print Expr)
        (assert Expr)
        (set! Expr Expr)
        (vector-set! Expr Expr Expr)
        (for (Var Expr Expr) Expr +)
        (while Expr Expr +)
        (if Expr Expr)
        (if Expr Expr Expr)
        (return Expr)
        (var Var)
        (vector Expr +)
        (vector-ref Expr Expr)
        (kernel ((Var Expr) +) Expr +)
        (reduce Reduceop Expr)
        (iota Integer)
        (length Expr)
        (make-vector Integer)
        (Binop Expr Expr)
        (Relop Expr Expr)
        (Var Expr *)))

    (parse-harlan (%inherits Module)
      (Start Module)
      (Decl
        (extern Var (Type *) -> Type)
        (fn Var (Var *) Stmt))
      (Stmt
        (let ((Var Expr) *) Stmt)
        (if Expr Stmt)
        (if Expr Stmt Stmt)
        (begin Stmt * Stmt)
        (print Expr)
        (assert Expr)
        (set! Expr Expr)
        (vector-set! Expr Expr Expr)
        (do Expr)
        (for (Var Expr Expr) Stmt)
        (while Expr Stmt)
        (return Expr))
      (Expr
        (num Integer)
        (float Float)
        (str String)
        (var Var)
        (vector Expr +)
        (begin Stmt * Expr)
        (if Expr Expr Expr)
        (vector-ref Expr Expr)
        (let ((Var Expr) *) Expr)
        (kernel ((Var Expr) +) Expr)
        (reduce Reduceop Expr)
        (iota (num Integer))
        (length Expr)
        (int->float Expr)
        (make-vector (num Integer))
        (Binop Expr Expr)
        (Relop Expr Expr)
        (call Var Expr *)))

    (typecheck (%inherits Module)
      (Start Module)
      (Decl
        (extern Var (Type *) -> Type)
        (fn Var (Var *) Type Stmt))
      (Stmt
        (let ((Var Expr) *) Stmt)
        (if Expr Stmt)
        (begin Stmt * Stmt)
        (if Expr Stmt Stmt)
        (print Expr)
        (assert Expr)
        (set! Expr Expr)
        (vector-set! Type Expr Expr Expr)
        (do Expr)
        (for (Var Expr Expr) Stmt)
        (while Expr Stmt)
        (return Expr))
      (Expr
        (int Integer)
        (u64 Number)
        (float Float)
        (str String)
        (var Type Var)
        (if Expr Expr Expr)
        (let ((Var Expr) *) Expr)
        (begin Stmt * Expr)
        (vector Type Expr +)
        (vector-ref Type Expr Expr)
        (kernel Type (((Var Type) (Expr Type)) +) Expr)
        (reduce Type Reduceop Expr)
        (iota (int Integer))
        (length Expr)
        (int->float Expr)
        (make-vector Type (int Integer))
        (Binop Expr Expr)
        (Relop Expr Expr)
        (call Type Var Expr *)))

    (returnify (%inherits Module Expr)
      (Start Module)
      (Decl
        (fn Var (Var *) Type Body)
        (extern Var (Type *) -> Type))
      (Body
        (begin Stmt * Body)
        (let ((Var Expr) *) Body)
        (if Expr Body)
        (if Expr Body Body)
        Ret-Stmt)
      (Stmt
        (let ((Var Expr) *) Stmt)
        (if Expr Stmt)
        (if Expr Stmt Stmt)
        (begin Stmt * Stmt)
        (print Expr)
        (assert Expr)
        (set! Expr Expr)
        (vector-set! Type Expr Expr Expr)
        (do Expr)
        (for (Var Expr Expr) Stmt)
        (while Expr Stmt)
        Ret-Stmt))

    (lift-complex (%inherits Module Decl)
      (Start Module)
      (Body
        (begin Stmt * Body)
        (let ((Var Let-Expr) *) Body)
        (if Expr Body)
        (if Expr Body Body)
        Ret-Stmt)      
      (Stmt
        (let ((Var Let-Expr) *) Stmt)
        (if Expr Stmt)
        (if Expr Stmt Stmt)
        (begin Stmt * Stmt)
        (print Expr)
        (assert Expr)
        (set! Expr Expr)
        (vector-set! Type Expr Expr Expr)
        (do Expr +)
        (for (Var Expr Expr) Stmt)
        (while Expr Stmt)
        Ret-Stmt)
      (Let-Expr
        (begin Stmt * Let-Expr)
        (let ((Var Let-Expr) *) Let-Expr)
        (kernel Type (((Var Type) (Let-Expr Type)) +) Let-Expr)
        (vector Type Let-Expr +)
        (reduce Type Reduceop Let-Expr)
        (make-vector Type (int Integer))
        (iota (int Integer))
        Expr)
      (Expr
        (int Integer)
        (u64 Number)
        (float Float)
        (str String)
        (var Type Var)
        (int->float Expr)
        (length Expr)
        (if Expr Expr Expr)
        (let ((Var Let-Expr) *) Expr)
        (call Type Var Expr *)
        (vector-ref Type Expr Expr)
        (Binop Expr Expr)
        (Relop Expr Expr)))

    (remove-nested-kernels
      (%inherits Module Decl Expr Stmt Body Let-Expr)
      (Start Module))

    (returnify-kernels (%inherits Module Decl Expr Body)
      (Start Module)
      (Stmt 
        (print Expr)
        (assert Expr)
        (set! (var Type Var) Expr)
        (vector-set! Type Expr Expr Expr)
        (kernel Type (((Var Type) (Expr Type)) +) Stmt)
        (let ((Var Let-Expr) *) Stmt)
        (if Expr Stmt)
        (if Expr Stmt Stmt)
        (for (Var Expr Expr) Stmt)
        (while Expr Stmt)
        (do Expr +)
        (begin Stmt * Stmt)
        Ret-Stmt)
      (Let-Expr
        (let ((Var Let-Expr) *) Let-Expr)
        (vector Type Let-Expr +)
        (reduce Type Reduceop Let-Expr)
        (make-vector Type (int Integer))
        (iota (int Integer))
        Expr))

    (lower-vectors (%inherits Module Decl Body)
      (Start Module)
      (Stmt 
        (print Expr)
        (assert Expr)
        (set! Expr Expr)
        (vector-set! Type Expr Expr Expr)
        (kernel Type (((Var Type) (Expr Type)) +) Stmt)
        (let ((Var Let-Expr) *) Stmt)
        (begin Stmt * Stmt)
        (if Expr Stmt)
        (if Expr Stmt Stmt)
        (for (Var Expr Expr) Stmt)
        (while Expr Stmt)
        (do Expr +)
        Ret-Stmt)
      (Let-Expr
        (let ((Var Let-Expr) *) Let-Expr)
        (make-vector Type (int Integer))
        Expr)
      (Expr
        (int Integer)
        (u64 Number)
        (float Float)
        (int->float Expr)
        (str String)
        (var Type Var)
        (let ((Var Let-Expr) *) Expr)
        (if Expr Expr Expr)
        (call Type Var Expr *)
        (vector-ref Type Expr Expr)
        (length Expr)
        (Relop Expr Expr)
        (Binop Expr Expr)))

    (uglify-vectors (%inherits Module Decl)
      (Start Module)
      (Body
        (begin Stmt * Body)
        (let ((Var Expr) *) Body)
        (if Expr Body)
        (if Expr Body Body)
        Ret-Stmt)
      (Stmt
        (print Expr)
        (assert Expr)
        (set! Expr Expr)
        (kernel (((Var Type) (Expr Type)) +) Stmt)
        (let ((Var Expr) *) Stmt)
        (if Expr Stmt)
        (if Expr Stmt Stmt)
        (for (Var Expr Expr) Stmt)
        (while Expr Stmt)
        (do Expr +)
        (begin Stmt +)
        Ret-Stmt)
      (Expr 
        (int Integer)
        (u64 Number)
        (str String)
        (float Float)
        (var Type Var)
        (let ((Var Expr) *) Expr)
        (if Expr Expr Expr)
        (call Type Var Expr *)
        (cast Type Expr)
        (sizeof Type)
        (addressof Expr)
        (vector-ref Type Expr Expr)
        (length Expr)
        (Relop Expr Expr)
        (Binop Expr Expr)))

    (annotate-free-vars
      (%inherits Module Decl Expr Body)
      (Start Module)
      (Stmt 
        (print Expr)
        (assert Expr)
        (set! Expr Expr)
        (kernel (((Var Type) (Expr Type)) +)
          (free-vars Var *) Stmt)
        (let ((Var Expr) *) Stmt)
        (begin Stmt * Stmt)
        (if Expr Stmt)
        (if Expr Stmt Stmt)
        (for (Var Expr Expr) Stmt)
        (while Expr Stmt)
        (do Expr +)
        Ret-Stmt))

    (flatten-lets (%inherits Module Decl)
      (Start Module)
      (Body
        (begin Stmt * Body)
        (if Expr Body)
        (if Expr Body Body)
        Ret-Stmt)
      (Stmt
        (print Expr)
        (assert Expr)
        (set! Expr Expr)
        (kernel (((Var Type) (Expr Type)) +)
          (free-vars (Var Type) *) Stmt)
        (let Var Type Expr)
        (if Expr Stmt)
        (if Expr Stmt Stmt)
        (for (Var Expr Expr) Stmt)
        (while Expr Stmt)
        (do Expr +)
        (begin Stmt +)
        Ret-Stmt)
      (Expr 
        (int Integer)
        (u64 Number)
        (str String)
        (float Float)
        (var Type Var)
        (if Expr Expr Expr)
        (call Type Var Expr *)
        (cast Type Expr)
        (sizeof Type)
        (addressof Expr)
        (vector-ref Type Expr Expr)
        (length Expr)
        (Relop Expr Expr)
        (Binop Expr Expr)))

    (hoist-kernels (%inherits Module Body)
      (Start Module)
      (Decl
        (gpu-module Kernel *)
        (fn Var (Var *) ((Type *) -> Type) Body)
        (extern Var (Type *) -> Type))
      (Kernel
        (kernel Var ((Var Type) +) Stmt))
      (Stmt 
        (print Expr)
        (assert Expr)
        (set! Expr Expr)
        (apply-kernel Var (var Type Var) +)
        (let Var Type Expr)
        (begin Stmt * Stmt)
        (if Expr Stmt)
        (if Expr Stmt Stmt)
        (for (Var Expr Expr) Stmt)
        (while Expr Stmt)
        (do Expr +)
        Ret-Stmt)
      (Expr 
        (int Integer)
        (u64 Number)
        (str String)
        (float Float)
        (var Type Var)
        (if Expr Expr Expr)
        (deref (var Type Var))
        (call Type Var Expr *)
        (call Type Field Expr *)
        (cast Type Expr)
        (sizeof Type)
        (addressof Expr)
        (vector-ref Type Expr Expr)
        (Relop Expr Expr)
        (Binop Expr Expr))
      (Field
        (field (var cl::program g_prog) build)))

    (move-gpu-data
      (%inherits Module Kernel Decl Expr Field Body)
      (Start Module)
      (Stmt 
        (print Expr)
        (assert Expr)
        (set! Expr Expr)
        (apply-kernel Var (var Type Var) +)
        (let-gpu Var Type)
        (map-gpu ((Var Expr)) Stmt)
        (let Var Type Expr)
        (begin Stmt * Stmt)
        (if Expr Stmt)
        (if Expr Stmt Stmt)
        (for (Var Expr Expr) Stmt)
        (while Expr Stmt)
        (do Expr +)
        Ret-Stmt))

    (generate-kernel-calls
      (%inherits Module Kernel Decl Expr Body)
      (Start Module)
      (Stmt
        (print Expr)
        (assert Expr)
        (set! Expr Expr)
        (let-gpu Var Type)
        (map-gpu ((Var Expr)) Stmt)
        (let Var Type Expr)
        (begin Stmt * Stmt)
        (if Expr Stmt)
        (if Expr Stmt Stmt)
        (for (Var Expr Expr) Stmt)
        (while Expr Stmt)
        (do Expr +)
        Ret-Stmt)
      (Field
        (field (var Type Var) Var)))

    (compile-module
      (%inherits Kernel Body)
      (Start Module)
      (Module (Decl *))
      (Decl
        (gpu-module Kernel *)
        (func Type Var (Type *) Body)
        (extern Type Var (Type *)))
      (Stmt
        (print Expr)
        (set! Expr Expr)
        (map-gpu ((Var Expr)) Stmt)
        (if Expr Stmt)
        (if Expr Stmt Stmt)
        (let Var Let-Type Expr)
        (begin Stmt * Stmt)
        (for (Var Expr Expr) Stmt)
        (while Expr Stmt)
        (do Expr +)
        Ret-Stmt)
      (Expr 
        integer
        number
        string
        float
        Var
        (deref Var)
        (Var Expr *)
        (Field Expr *)
        (assert Expr)
        (cast Type Expr)
        (if Expr Expr Expr)
        (memcpy Expr Expr Expr)
        (sizeof Type)
        (addressof Expr)
        (vector-ref Expr Expr)
        (Relop Expr Expr)
        (Binop Expr Expr))
      (Field
        (field Var +)
        (field Var + Type))
      (Let-Type
        (cl::buffer Type)
        (cl::buffer_map Type)
        Type))

    (convert-types (%inherits Module Stmt Body)
      (Start Module)
      (Decl
        (gpu-module Kernel *)
        (func C-Type Var (C-Type *) Body)
        (extern C-Type Var (C-Type *))) 
      (Kernel
        (kernel Var ((Var C-Type) +) Stmt))
      (Expr 
        integer
        number
        string
        float
        Var
        (deref Var)
        (Var Expr *)
        (Field Expr *)
        (assert Expr)
        (if Expr Expr Expr)
        (cast C-Type Expr)
        (memcpy Expr Expr Expr)
        (sizeof C-Type)
        (addressof Expr)
        (vector-ref Expr Expr)
        (Relop Expr Expr)
        (Binop Expr Expr))
      (Field
        (field Var +)
        (field Var + C-Type))
      (Let-Type
        (cl::buffer C-Type)
        (cl::buffer_map C-Type)
        C-Type)
      (C-Type
        (const-ptr C-Type)
        (ptr C-Type)
        c-type))

    (compile-kernels
      (%inherits Module Stmt Expr Field Let-Type C-Type Body)
      (Start Module)
      (Decl
        (global cl::program g_prog
          ((field g_ctx createProgramFromSource) String))
        (func C-Type Var (C-Type *) Stmt)
        (extern C-Type Var (C-Type *)))))

)