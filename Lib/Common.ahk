; "Function Binding" methods for changing the context / scope of a call to a class method
bind(fn, args*) {  ; bind v1.1
	try bound := fn.bind(args*)  ; Func.Bind() not yet implemented.
	return bound ? bound : new BoundFunc(fn, args*)
}

class BoundFunc {
	__New(fn, args*) {
		this.fn := IsObject(fn) ? fn : Func(fn)
		this.args := args
	}
	__Call(callee) {
		if (callee = "" || callee = "call" || IsObject(callee)) {  ; IsObject allows use as a method.
			fn := this.fn
			return %fn%(this.args*)
		}
	}
}

/*
Bind(fn, args*) {
	return new this.BoundFunc(fn, args*)
}

class BoundFunc {
	__New(fn, args*) {
		this.fn := IsObject(fn) ? fn : Func(fn)
		this.args := args
	}
	__Call(callee) {
		if (callee = "") {
			fn := this.fn
			return %fn%(this.args*)
		}
	}
}
*/
