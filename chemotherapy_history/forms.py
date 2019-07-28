from django import forms
from .models import *
from django.contrib.auth import get_user_model
from django.contrib.auth.forms import UserCreationForm
from .helpers.smart_form import *
from django.shortcuts import render, redirect
from django.http import HttpResponseRedirect


class NewPatientForm(forms.ModelForm):
	class Meta:
		model = Patient
		fields = \
			( "patient_name"
			, "patient_age"
			, "patient_card"
			, "patient_therapy"
			, "patient_frequency"
			, "patient_initial_dose"
			, "patient_initial_dose_dt"
			, "patient_maintenance_dose"
			, "patient_nacl_amount"
			, "dose_dt"
			, "dose_dt_opened"
			, "dose_weight"
			, "dose_amount"
			, "dose_remaining_dose"
			, "dose_next_appointment_dt"
			, "dose_number"
			, "dose_number_cycle"
			, "heart_text"
			, "heart_dt"
			, "heart_percentage"
			, "therapy_status"
			, "therapy_dt"
			, "therapy_reason"
			, "dose_remarks"
			, 'heart_remarks'
			)

		DTArgs = {}
		# DTArgs = {"input_formats":['%Y-%m-%d %H:%M:%S']}
		# patient_initial_dose_dt = forms.DateTimeField(**DTArgs)
		# dose_dt = forms.DateTimeField(**DTArgs)
		# dose_dt_opened = forms.DateTimeField(**DTArgs)
		# dose_next_appointment_dt = forms.DateTimeField(**DTArgs)
		# heart_dt = forms.DateTimeField(**DTArgs)
		# therapy_dt = forms.DateTimeField(**DTArgs)
		# dose_remarks = forms.CharField(required=False)
		# heart_remarks = forms.CharField(required=False)

class UpdatePatientInfo(forms.ModelForm):
	class Meta:
		model = PatientInfo
		fields = ('patient_name'
				, 'patient_age'
				, 'patient_card'
				, 'patient_therapy'
				, 'patient_frequency'
				, 'patient_initial_dose'
				, 'patient_initial_dose_dt'
				, 'patient_maintenance_dose'
				)


class UpdateHeartReport(forms.ModelForm):
	class Meta:
		model = HeartReport
		fields = ('heart_text', 'heart_percentage', 'heart_remarks')
		heart_dt = forms.DateTimeField(input_formats=['%Y-%m-%dT%H:%M'])

class UpdateDoseReport(forms.ModelForm):
	class Meta:
		model = DoseReport
		fields = (
			'dose_weight', 
			'dose_amount',
			'dose_number',
			'dose_number_cycle',
			"dose_next_appointment_dt",
			"dose_remarks",
			"dose_dt",
			"dose_dt_opened",
			)
		# dose_dt = forms.DateTimeField(input_formats=['%Y-%m-%dT%H:%M'])
		# dose_dt_opened = forms.DateTimeField(input_formats=["""\\" %Y-%m-%dT%H:%M "\\"""])

class UpdateTherapyStatus(forms.ModelForm):
	class Meta:
		model = TherapyStatus
		fields = \
			( 'therapy_status'
			, 'therapy_dt'
			, 'therapy_reason'
			, 'therapy_remarks'
			)
		therapy_remarks = forms.CharField(required=False)
		therapy_reason = forms.CharField(required=False)
		therapy_dt = forms.DateTimeField(input_formats=['%Y-%m-%dT%H:%M'])

class UserSignup(UserCreationForm):
	class Meta:
		model = User
		fields = ('username', 'first_name' , 'hospital' )
		last_name = forms.CharField(required=False)


class UserPlaygroundForm(forms.ModelForm, CommonUserForm):
	class Meta:
		model = User
		fields = ('first_name' , 'email' )
		last_name = forms.CharField(required=False)

	def __init__(self, request, user):
		CommonUserForm.__init__(self,user)
		forms.ModelForm.__init__(self, request.POST or None)
		self.request, self.user = request, user
		self.title = self.user.first_name + u' | 用户区'
		self.newUsers = False

		if checkNewUsers(user):
			self.newUsers = makeTable(
				User.objects.filter(isNew=True).values(
					  "id"
					, "first_name"
					, 'username'
					, 'email'
					, 'last_login'
					, 'date_joined'
					, 'id'),
				translation=User.translation,
				menu= [ { 'txt': u"暂停帐户", 'href':"suspend"}
					  , { 'txt': u"激活帐户", 'href':"activate"}
				  ])

		if request.method == 'POST':
			# print('request is post', self.is_valid())
			if self.is_valid():
				self.canCommit = True

			else:
				# print('has errors')
				# print(self.errors)
				self.hasErrors=True

	def render(self):
		user = User.objects.filter(id=self.request.user.id)[0]
		if self.canCommit == True:
			self.user.email = self.request.POST['email']
			self.user.first_name = self.request.POST['first_name']
			self.user.save()
			return redirect('user')

		return render(self.request, 'user.html', { 'form':self
												 , 'newUsers': self.newUsers})




