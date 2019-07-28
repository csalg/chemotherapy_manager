# def pass_thru(func_to_decorate):
#     def new_func(*original_args, **original_kwargs):
#         print("Function has been decorated.  Congratulations.")
#         # Do whatever else you want here
#         print(original_args)
#         return func_to_decorate(*original_args, **original_kwargs)
#     new_func.attr = 'some attr'
#     return new_func

# # @pass_thru
# # def bar(hey):
# # 	print('bar')
# # 	print(bar.attr)

# # bar("hey")

# class someClass(object):
# 	def __init__(self,*args):
# 		counter = 0
# 		for arg in args:
# 			print(arg)
# 			counter += 1
# 			setattr(self, "attr" + str(counter), arg)


# # setattr(self, name, None)

# someClass("a", "b")

# print(someClass.attr0)

def formMaker(input_width,value,disabled=False,hidden=False):
	return(disabled)

# def formDecorator(row, translationDict=None):
# 	label, input = row
# 	""" 
# 	[(label), (input)] -> [{label}{input}] 
# 	Translates shorthand in the form of two tuples to a list of dictionaries that's easy to work with in the template.
# 	The label tuple is in the form:
# 	(<label-width> <**translation>)
# 	If a translation dictionary is provided to the fn then the translation arg will be ignored.
# 	(input-width,name,**value="",**disabled=bool,**hidden=bool)
# 	"""
# 	# Process label

# 	def processLabel(width,translation=None):
# 		if not translation and translationDict:
# 			translation = translationDict
# 		return {'width': width}

# 	return "done"


# def formDecorator(row, translationDict=None):
# 	(label_args, label_kwargs), (input_args, input_kwargs) = row
# 	""" 
# 	[(label), (input)] -> [{label}{input}] 
# 	Translates shorthand in the form of two tuples to a list of dictionaries that's easy to work with in the template.
# 	The label tuple is in the form:
# 	(<label-width> <**translation>)
# 	If a translation dictionary is provided to the fn then the translation arg will be ignored.
# 	(input-width,name,**value="",**disabled=bool,**hidden=bool)
# 	"""
# 	# Process label

# 	def processLabel(width,translation=None):
# 		if not translation:
# 			translation

# 		return {'width': width}

# 	return processLabel(*label_args, **label_kwargs)

# print(formDecorator((((1,""),{}),(3,{'disabled':True}))))

# class form(object):
# 	def __init__():
# 		self.rows = []
# 		self.translation_dictionary = {}
# 		pass

# 	def appendTranslation(self, new_translation):
# 		self.translation_dictionary.update(new_translation)
# 		pass

# 	def appendRow(self,):
# 		pass

d = {'a': 2}

if 'a' in d:
	print(d['a'])
