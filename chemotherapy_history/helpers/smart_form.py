from abc import ABC, abstractmethod
from django.utils.safestring import mark_safe
from ..models import *

## interfaces
class Renderable(object):
	def __init__(self):
		pass

	def render(self):
		return ""
		pass


class Translatable(object):
	def __init__(self):
		self.translation_dict = dict()

	def appendTranslation(self, new_translation):
		# print(new_translation)
		self.translation_dict.update(new_translation)
		pass
	

## helper classes

class Header(object):
	def __init__(self,title):
		self.title: str = title

	def render(self):
		return self.title

class FormHeader(Header):
		def __init__(self,title,post_address, id=""):
			super().__init__(title)
			self.post_address = post_address
			self.id = id
			
		def render(self):
			return f"""
			{super().render()}
			<form id="{self.id}" action='/{self.post_address}' method='post'>"""

class Button(object):
	def __init__(self, text,onclick=None,buttonType=None, fa=""):
		self.type: str = buttonType if buttonType else 'button'
		self.classes: List[str] = ['btn', 'btn-default']
		self.text: str = text
		self.onclick: str = f"location.href='{onclick}';" if onclick else ""
		self.disabled: str = ""
		self.fa = fa

	def addClasses(self, *args):
		for i in args:
			self.classes.append(i)

	def render(self):
		return f"""
			<button type="{self.type}" class="{' '.join(self.classes)}" onclick="{self.onclick}" {self.disabled}>
				<i class="{self.fa}"></i> {self.text}
			</button>
			"""

class FormButton(Button):
	def __init__(self, text, onclick=None):
		super().__init__(text, onclick=onclick)
		self.onclick: str = onclick
		self.classes.append("btn-inline")



class Input(Translatable):
	def __init__(self,width,name,value=None,disabled=False,type=False, translation={}, validation_text=""):
	# (input-width,name,**value="",**disabled=bool,**hidden=bool)
		super().__init__()
		self.width: str = width
		self.name: str = name
		self.value: str = str(value)
		self.disabled: str = 'disabled' if disabled else ""
		self.type: str = type if type else "Text"
		self.classes: List(str) = ['form-control']
		self.translation: str = name
		self.validation_text = validation_text

	def appendTranslation(self, new_translation):
		super().appendTranslation(new_translation)
		# print('input:', self.translation_dict)
		# print(self.name)

		if self.name in self.translation_dict:
			self.translation = self.translation_dict[self.name]

	def render(self):

		self.validation_icon = f"""<i class="{'fas fa-circle inactive-grey' if not self.disabled == 'disabled'  else ''}"></i>"""
		# print(self.disabled)

		return f"""
							<div class="col-sm-{self.width}">
							<div>
								<input display: inline;' type="{self.type}" name="{self.name}" class="{' '.join(self.classes)}" placeholder="{self.translation}" value="{self.value}" {self.disabled}>
							</div>
							<div>
								{f"<p class='validation-text'>{self.validation_text}</p>" if not self.disabled else ''}
							</div>
							</div>
				"""

	def enable(self):
		self.disabled = ""
		# print('ENABLING: self.disabled is: ', self.disabled)

	def disable(self):
		self.disabled = "disabled"

	def hide(self):
		self.type="Hidden"


class Label(Translatable):
	def __init__(self, width, name, fa=""):
		super().__init__()
		self.width = width
		self.name = name
		self.translation = name
		self.classes = ['control-label', 'form_label']
		self.fa = fa

	def appendTranslation(self, new_translation):
		super().appendTranslation(new_translation)
		# print('label:', self.translation_dict)
		# print(self.name)

		if self.name in self.translation_dict.keys():
			self.translation = self.translation_dict[self.name]
		# print('success')

	def render(self):
		return f'<label class="col-sm-{self.width} {" ".join(self.classes)}" for="{self.name}"><i class="{self.fa}"></i> {self.translation}</label>'


class RuijinForm(Translatable):
	def __init__(self):
		super().__init__()
		self.id=""
		self.title = ""
		self.hasErrors = False
		self.canCommit = False

		self.contentRows = []
		self.footerButtons = []
		self.footer: List[Button] = []
		pass

	def parseFormDisabledValue(self):
		# Returns form with all values disabled, overrides optional setting
		pass


class UserForm(RuijinForm):
	def __init__(self, user):
		self.user = user
		super().__init__()
		self.appendTranslation(user.translation)
		pass

class CommonUserForm(UserForm):
	def __init__(self,user):
		super().__init__(user)
		print(self.user)
		self.id='CommonUserForm'

		self.contentRows.append([
			Label(2,'username', fa='fas fa-user-tie'), Input(3,'username', disabled=True, value=user.username,),
			Label(2,'email', fa='far fa-envelope'), Input(5,'email', disabled=True, value=user.email, type='email', validation_text='按照下列格式: xx@xx.xx')
			])
		self.contentRows.append([
			Label(2,'first_name', fa='far fa-id-card'), Input(3,'first_name', disabled=True, value=user.first_name, validation_text='请输入至少两字符'),
			Label(2,'hospital', fa='far fa-hospital'), Input(5,'hospital', disabled=True, value=user.hospital,)
			])

		for row in self.contentRows:
			for elem in row:
				elem.appendTranslation(self.translation_dict)

		self.footer = [
			Button(u'回到主页',onclick='/index', fa='fas fa-home'),
			Button(u'编辑个人资料',onclick='/user/edit', fa='far fa-edit')
		]

		self.header = Header('<i class="fas fa-user"></i> 个人资料')

		if user.isHospitalAdmin or user.is_superuser:
			self.footer.append(Button(u'查看用户单',onclick='/user/viewUsers', fa='fas fa-users'))
			self.footer.append(Button(u'新建用户',onclick='/admin/signup', fa='fas fa-user-plus'))

	def makeEditable(self):
		for row in self.contentRows:
			for elem in row:
				if isinstance(elem,Input):
					print('input found!:', elem)
					if elem.name is not 'hospital'and elem.name is not 'username':
						elem.enable()

		self.footer = [
			Button(u'回到个人资料',onclick='/user', fa='far fa-address-card'),
			Button(u'提交',buttonType='submit', fa='fas fa-check')
		]

		self.header = FormHeader('<i class="fas fa-user"></i> 个人资料', 'user/edit', id='CommonUserForm')



class FormGroup(Translatable):
	""" This is just the stuff inside the panel-body, 
	not the header, footer or form wrapper. """

	def __init__(self,name, labelText, width=4, inputType="text", placeholder="", helpText="", value="", options=[], disabled=False, allowOverride=False):
		self.width = width
		self.name = name
		self.labelText = labelText
		self.inputType = inputType
		self.placeholder = placeholder
		self.helpText = helpText
		self.options=options
		self.value = value
		self.disabled = disabled
		self.allowOverride = allowOverride
		print(self.options)

	def render(self, disabled=False):

		overrideHTML = """<div>
		<input type="checkbox">
		<span>直接输入</span>
		</div>"""

		input_ = f"""<input type="{self.inputType}" value="{self.value}" name="{self.name}" class="form-control" placeholder="{self.placeholder}" {'disabled=""' if (self.disabled or disabled) else ""} ></input>"""
		inputOptions = ' '.join([f"""<option value="{option}">{option}</option>""" for option in self.options])
		inputSelect = f"""<select name="{self.name}" class="form-control">
		{inputOptions}
		</select>"""

			
		return mark_safe(f"""<div id={self.name} class="form-group col-sm-{self.width}">
	    <label class="control-label" for="{self.name}">{self.labelText}</label>

	    {inputSelect if (self.inputType == "options" and not (self.disabled or disabled)) else input_}
	    {overrideHTML if self.allowOverride else ""}
	    <span class="help-block">{self.helpText}</span>
	    
	    </div>""")

	def renderDisabled(self):
		return self.render(disabled=True)




def makeTable(query, translation=[], menu=[], tableMenu=[]):
	""" Enforces table data is properly passed to the template.
	Use with components/table.html like this:
	{% with table as table %}
	{% include "components/table.html" %}
	{% endwith %}
	Menu a list like this: { 'txt': "暂停帐户" 'href':"activate"}

	Translation usually a static field from the model called translation,
	like User.translation, it's a dictionary english : chinese.
	"""

	return  { 'query' : query
			, 'translation' : translation
			, 'rowMenu' : menu
			, 'tableMenu' : tableMenu
			}

def checkNewUsers(user):
	if user.is_superuser:
		return bool(User.objects.all()
				.filter(isNew=True, hospital=user.hospital))
	elif user.isHospitalAdmin:
		return bool(User.objects.all()
				.filter(isNew=True, hospital=user.hospital))
	else:
		return False