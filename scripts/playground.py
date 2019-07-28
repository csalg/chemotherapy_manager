def someDecorator(fun):
	person = "Martin"
	def someFn(arg1):
		foo = arg1 + " likes bananas"
		print(foo)
		return fun(arg1)
	return someFn


@someDecorator
def myFn(arg1):
	nonlocal person
	print(person, " likes them too")
	pass

myFn('Lucas')