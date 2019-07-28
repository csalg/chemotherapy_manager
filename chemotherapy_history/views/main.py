from django.http import HttpResponseRedirect
from django.core.paginator import EmptyPage, PageNotAnInteger, Paginator
from django.core.files.storage import FileSystemStorage
from django.template.loader import render_to_string
from django.utils import timezone
from django.db.models import Q
from django.contrib.auth import login, authenticate
from django.shortcuts import render, redirect
from django.forms.models import model_to_dict
from django.http import JsonResponse, HttpResponse
from django.core import serializers
from django.views.decorators.csrf import csrf_exempt

import os
from typing import List, Tuple,Dict
from datetime import datetime, timedelta, date
from dateutil import parser
from toolz import curry, pipe 
from toolz.curried import map
import qrcode
import json
# import csv

# Note: requires setting environment var:
# export LC_ALL=en_US.UTF-8
from weasyprint import HTML

from ..forms import *
from ..models import *
from ..conf import config
from ..helpers.smart_form import *
from ..helpers import *

from .permissions import *

os.environ["LC_ALL"] = "en_US.UTF-8" # Required for weasyprint to work

### PAGES

@curry
def saveBottle(doseReport,bottle):
	bottle_ = Bottle()
	bottle_.dose = doseReport
	bottle_.amount = bottle['amount']
	bottle_.remaining = bottle['remaining']
	bottle_.dt = bottle['dt']
	bottle_.opened = bottle['opened']
	bottle_.expiry = bottle['expiry']
	bottle_.number = bottle['number']
	bottle_.save()




@isUserAuth
def index(req, search_term=""):
	""" Deprecated"""
	debug(f"Index view accessed by: {req.user}")
	""" This is the main database page which can be searched """

	patient_active = not ('search_archive' in req.GET)

	def deleteTrailingSpaces(text):
		if len(text) > 1:
			if text[-1] == ' ':
				return deleteTrailingSpaces(text[0:-2])
		return text

	search_term = deleteTrailingSpaces(search_term)

	debug('Search term is: ',search_term) if search_term else ""

	patient_list = Patient.objects.values( 
		'id',
		'patient_name', 
		'patient_age', 
		'patient_card', 
		'patient_therapy', 
		'dose_weight',  
		'dose_dt_opened', 
		'dose_remaining_dose', 
		'patient_update_dt'
			).order_by('-patient_update_dt').filter(
			Q(patient_card__icontains=search_term) | 
			Q(patient_name__contains=search_term)| 
			Q(id__contains=search_term)
			).filter(
			Q(hospital=req.user.hospital)
			).filter(
			Q(patient_active=patient_active)
			)

	paginator = Paginator(patient_list, 100) # Show 100 patients per page

	page = req.GET.get('page') or 1
	patients = paginator.get_page(page)

	template = 'index.html' if search_term=="" else 'search.html'

	return render(req, template, {
									'translation': Patient.translation,
									'patients': patients
									})

@isUserAuth
def search(req):
	""" Deprecated"""
	""" This function just has a snippet of code to check whether the search_term is from a QR code, if so redirects to page. Else passes args to index() function """
	search_term = req.GET['search_term']
	if len(search_term) > 1:
		if search_term[0] == '!' or search_term[0] == '！':
			if search_term[-1] == '!' or search_term[-1] == '！':
				search_term = search_term[:len(search_term)-1]
			return HttpResponseRedirect(f'/patient/{search_term[1:len(search_term)]}')
	return index(req, search_term=search_term)


@insecureAllowOrigin
@isUserAuth
def patientListJson(req):
	# data = serializers.serialize("json", Patient.objects.all())
	def assignUser(p): user = str(p.user); return p,user;
	def asDict(pu): 
		p,user = pu
		mod = model_to_dict(p)
		mod['user'] = user
		return mod
	data = pipe(Patient.objects.all().values('id'
					, 'patient_name'
					, 'patient_age'
					, 'patient_card'
					, 'dose_dt'
					, 'dose_dt_opened'
					, 'heart_dt'
					, 'therapy_status').filter(
			Q(hospital=req.user.hospital))
				# , list
				# , map(assignUser)
				# , map(asDict)
				, list)
	return JsonResponse(data, safe=False)

@csrf_exempt
@isUserAuth
def patientElm(request, pid=-1):
	form = NewPatientForm(request.POST or None)

	if request.method == 'POST':
		print(request.POST)
		if form.is_valid():
			print("New patient post form is valid")
			# patient_initial_dose_dt
			patient = form.save(commit=False)

			patient.patient_initial_dose_dt = dtFromElm(request.POST['patient_initial_dose_dt'])
			patient.dose_dt = dtFromElm(request.POST['dose_dt'])
			patient.dose_dt_opened = dtFromElm(request.POST['dose_dt_opened'])
			patient.heart_dt = dtFromElm(request.POST['heart_dt'])
			
			patient.hospital = request.user.hospital
			patient.user = request.user
			patient.publish()
			patient_id_str = '{0:0{width}}'.format(patient.id, width=6)
			print(f"Patient id is {patient_id_str}")
			print("New patient successfully created")
			patient_info = PatientInfo()
			patient_info.fromPatient(patient)
			heart_report = HeartReport()
			heart_report.fromPatient(patient)
			dose_report = DoseReport()
			dose_report.fromPatient(patient)
			print("New patient history records successfully added")
			return redirect('home')
		else:
			print(form.errors)

	return render(request, "patient_elm.html", {'pid':pid} )

### PATIENT FORMS
""" The factory class does most of the work, the view functions only handle the specifics of commiting the data """

class patientUpdateFactory():
	# @insecureAllowOrigin
	def __init__(self,request, patient_id, template, formClass=None, newBottle=False):
		self.request = request
		self.template = template
		self.patient = Patient.objects.filter(id=int(patient_id))[0]
		self.commit = False
		self.form = None
		self.errors = False

		self.suggested = {
						'dose_dt': timezone.now(),
						# 'dose_amount': dose_amount,
						'dose_weight' : self.patient.dose_weight,
						'bottle_expiry': timezone.now() + timedelta(days=config.drug_shelf_life),
						# 'dose_dt_opened_timestamp': self.patient.dose_dt_opened,
						# 'previous_dose': self.patient.dose_remaining_dose,
						# 'dose_remaining_dose': remaining_dose
		}
		if "application/json" in request.content_type:
			self.post_data = json.loads(request.body)
		else:
			print(f"request.content_type: '{request.content_type}' ")
			self.post_data=request.POST

		if formClass:
			print(self.post_data)
			self.form = formClass(self.post_data or request.POST or None)
			print(self.form)
			if request.method == 'POST':
				# print(self.form.render_as_p())
				# print(self.render())
				if self.form.is_valid():
					print('Valid form')
					self.commit = True
				else:
					print("Form not valid")
					self.errors = True
					print(self.form.errors)
					print(self.form.non_field_errors)

	def canCommit(self):
		return self.commit

	def render(self):
		return render(self.request, self.template, 
					{
					'patient': self.patient,
					'expiration_date': self.patient.dose_dt_expiration(),
					'form': self.form,
					'errors': self.errors,
					'suggested': self.suggested
					})
	def profileMainRedirect(self):
		return HttpResponseRedirect(f'/patient/{self.patient.id}')

	def jsonResponseSuccess(self):
		return JsonResponse(
			{ 'status': "success"
			, 'message': "信息已成功更新"
			})

	def jsonResponseFailure(self):
		return JsonResponse(
			{ 'status': "error"
			, 'message': f"Server reported errors. Field errors:{self.form.errors.as_data()}. Non-field errors: {self.form.non_field_errors()}"
			})



def DjangoMsg(message, isSuccess=True):
	status = "success" if isSuccess else "error"
	msg = { 'status': status, 'message': message}
	print(msg)
	return JsonResponse( msg )

# def DjangoMsgErrorForm(form):
# 	return JsonResponse(
# 			{ 'status': "error"
# 			, 'message': f"Server reported errors. Field errors:{form.errors.as_data()}. Non-field errors: {form.non_field_errors()}"
# 			})

def DjangoMsgErrorBadContentType(format):
	return DjangoMsg(f"Server doesn't recognise content type headers: {format}"
					, False
					)

def DjangoMsgErrorForm(form):
	return DjangoMsg(f"表格有问题. Field errors:{form.errors.as_data()}. Non-field errors: {form.non_field_errors()}"
					, False
					)


def DjangoMsgSuccess():
	return DjangoMsg("信息已成功更新")


# -------

@insecureAllowOrigin
@sameHospital
@isUserAuth
def patientJSON(r,pid):
	patient = Patient.objects.filter(id=int(pid))[0]
	expiry_days = (patient.dose_dt_opened + timedelta(days=config.drug_shelf_life) ) - timezone.now()
	dose_ago = timezone.now() - patient.dose_dt
	heart_ago = timezone.now() - patient.heart_dt
	response = model_to_dict(patient)
	response["expiry_ago"] = expiry_days.days
	response["dose_ago"] = dose_ago.days
	response["heart_ago"] = heart_ago.days
	response["user"] = str(patient.user)
	response["dt_now"] = timezone.now()
	return JsonResponse(response)



@csrf_exempt
@insecureAllowOrigin
@sameHospital
@isUserAuth
def updatePersonalInfo(r,pid):
	print(r.body, r.method, r.content_type)

	pu = patientUpdateFactory(r,pid, 'patient_update_personal.html', formClass=UpdatePatientInfo)
	if r.method=="POST":
		print("POST")
		if pu.canCommit():
			print("New personal info is valid")
			personalInfo = pu.form.save(commit=False)
			personalInfo.patient_id = pu.patient
			personalInfo.publish()
			pu.patient.fromPersonalInfo(personalInfo)
			print(pu.form)
			return pu.jsonResponseSuccess()
		else:
			return pu.jsonResponseFailure()

	return pu.render()

@csrf_exempt
@insecureAllowOrigin
@sameHospital
@isUserAuth
def updateDoseReport(r,pid,template='patient_update_dose.html',newBottle=False):
	print(r.body, r.method, r.content_type)
	
	def cleanDate(dt):
		if dt[0] == '"':
			print(dt[1:-1])
			return dt[1:-1]
		return dt
	pu = patientUpdateFactory(r,pid, template, formClass=UpdateDoseReport, newBottle=newBottle)
	
	if r.method=="POST":

		if pu.canCommit():
			print("New dose report is valid")
			doseReport = pu.form.save(commit=False)
			doseReport.patient_id = pu.patient
			doseReport.dose_remarks = pu.post_data['dose_remarks']
			doseReport.dose_number = pu.post_data['dose_number']
			doseReport.dose_dt = dtFromElm(pu.post_data['dose_dt'])
			doseReport.dose_dt_opened = dtFromElm(pu.post_data['dose_dt_opened'])
			doseReport.dose_remaining_dose= pu.post_data['dose_remaining_dose']
			doseReport.publish()

			pu.patient.fromDoseReport(doseReport)

			def saveBottle(bottle):
				bottle_ = Bottle()
				bottle_.dose = doseReport
				bottle_.amount = bottle['amount']
				bottle_.remaining = bottle['remaining']
				bottle_.dt = bottle['dt']
				bottle_.opened = bottle['opened']
				bottle_.expiry = bottle['expiry']
				bottle_.number = bottle['number']
				bottle_.save()

			print("post_data is", pu.post_data)
			list(map(saveBottle,pu.post_data['bottles']))


			return pu.jsonResponseSuccess()
		else:
			return pu.jsonResponseFailure()

	return pu.render()

@sameHospital
@isUserAuth
def updateBottle(r,pid):
	return updateDoseReport(r,pid,'patient_update_bottle.html', True)

@sameHospital
@isUserAuth
def updateStop(request,patient_id):
	print(request.POST)

	pu = patientUpdateFactory(request,patient_id,'patient_update_stop.html')

	if pu.request.method == 'POST':
		pu.patient.patient_stop_drug_reason = request.POST['patient_stop_drug_reason']
		pu.patient.patient_stop_drug_temporary_reason = request.POST['patient_stop_drug_temporary_reason']
		pu.patient.patient_active = False
		pu.patient.publish()
		return pu.profileMainRedirect()
	return pu.render()

@csrf_exempt
@insecureAllowOrigin
@sameHospital
@isUserAuth
def updateHeart(request,patient_id):
	pu = patientUpdateFactory(request,patient_id,'patient_update_heart.html', formClass=UpdateHeartReport)

	if pu.request.method == 'POST':
		print(request.POST)
		if pu.canCommit():
			heartReport = pu.form.save(commit=False)
			heartReport.heart_dt = parser.parse(pu.post_data['heart_dt'])
			heartReport.patient_id = pu.patient
			heartReport.heart_remarks = pu.post_data['heart_remarks']
			heartReport.publish()
			pu.patient.fromHeartReport(heartReport)
			return pu.jsonResponseSuccess()
		else:
			return pu.jsonResponseFailure()

	return pu.render()

@csrf_exempt
@insecureAllowOrigin
@sameHospital
@isUserAuth
def updateTherapyStatus(request,patient_id):
	pu = patientUpdateFactory(request,patient_id,'patient_update_heart.html', formClass=UpdateTherapyStatus)

	if pu.request.method == 'POST':
		if pu.canCommit():
			therapy_status = pu.form.save(commit=False)
			print(pu.patient)
			therapy_status.patient_id = pu.patient
			therapy_status.publish()
			print(therapy_status.therapy_status)
			pu.patient.fromTherapyStatus(therapy_status)
			print(pu.patient.therapy_status)

			return pu.jsonResponseSuccess()
		else:
			print('Cannot commit.')
			return pu.jsonResponseFailure()

	return pu.render()



def PDFDocumentFactory(request,patient_id,template_file):
	patient = Patient.objects.filter(id=int(patient_id))[0]
	expiration_date = patient.dose_dt_opened + timedelta(days=config.drug_shelf_life)  # 开封药品过期时间
	dose_dt, dose_dt_opened, expiration_date = patient.dose_dt.strftime("%Y-%m-%d %H:%M"), patient.dose_dt_opened.strftime("%Y-%m-%d %H:%M:%S"), expiration_date.strftime("%Y-%m-%d %H:%M:%S")
	bottles = Bottle.objects.all().filter(dose=patient.dose)
	print(bottles)
	html_string = render_to_string(template_file, {
					  'patient': patient
					, 'expiration_date': expiration_date
					, 'dose_dt': dose_dt
					, 'dose_dt_opened': dose_dt_opened
					, 'expiration_date': expiration_date
					, 'bottles' : bottles
					, 'bottle_count' : bottles.count()
					})
	# return render(request, template_file, {
	# 				'patient': patient,
	# 				'expiration_date': expiration_date
	# 				})
	print(html_string)
	html = HTML(string=html_string)
	html.write_pdf(target='/tmp/doc.pdf');

	fs = FileSystemStorage('/tmp')
	with fs.open('doc.pdf') as pdf:
		response = HttpResponse(pdf, content_type='application/pdf')
		return response

	return response



@sameHospital
@isUserAuth
def printPersonal(request,patient_id):
	return PDFDocumentFactory(request,patient_id,'patient_print_personal.html')

def printAll(request,patient_id):
	return PDFDocumentFactory(request,patient_id,'print/printall.html')

@sameHospital
@isUserAuth
def printDose(request,patient_id):
	return PDFDocumentFactory(request,patient_id,'patient_print_dose.html')


def getQR(request,patient_id):
	patient_id_str = '{0:0{data}}'.format(int(patient_id), data=6)

	qr = qrcode.QRCode(
	    version = 1,
	    error_correction = qrcode.constants.ERROR_CORRECT_H,
	    box_size = 10,
	    border = 2,
	)

	data = "!" + patient_id_str + "!"

	# Add data
	qr.add_data(data)
	qr.make(fit=True)

	# Create an image from the QR Code instance
	img = qr.make_image()
	print(img)

	fs = FileSystemStorage('/tmp')
	img.save("/tmp/myqr.png")	

	with fs.open('myqr.png') as png:
		response = HttpResponse(png, content_type='image/png')
		return response

@isUserAuth
def patients(r):
	return render(r, 'patients.html', {})

# @curry
# def historyTable(entity, values, order_by, rpid):
#     r, pid = rpid 
#     print("historyTable")
#     state = {
#       'translation' : getPatient(pid).translation
#     , 'query' : entity.objects.filter(patient_id=getPatient(pid)).values(*values).order_by(order_by) or []
#     }
#     return state, r, pid


@csrf_exempt
@isUserAuth
def newPatient(request, pid=-1):
	if request.method == 'POST':
		if ("application/json" in request.content_type):
			post_data = json.loads(request.body)
			print(post_data)
			form = NewPatientForm(post_data or None)
			if form.is_valid():
				print("New patient post form is valid")
				# patient_initial_dose_dt
				patient = form.save(commit=False)

				# patient.patient_initial_dose_dt = dtFromElm(post_data['patient_initial_dose_dt'])
				# patient.dose_dt = dtFromElm(post_data['dose_dt'])
				# patient.dose_dt_opened = dtFromElm(post_data['dose_dt_opened'])
				# patient.dose_next_appointment_dt = dtFromElm(post_data['dose_next_appointment_dt'])
				# patient.heart_dt = dtFromElm(post_data['heart_dt'])
				# patient.therapy_dt = dtFromElm(post_data['therapy_dt'])
				
				patient.hospital = request.user.hospital
				patient.user = request.user
				patient.publish()
				patient_id_str = '{0:0{width}}'.format(patient.id, width=6)
				print(f"Patient id is {patient_id_str}")
				print("New patient successfully created")
				patient_info = PatientInfo()
				patient_info.fromPatient(patient)
				heart_report = HeartReport()
				heart_report.fromPatient(patient)
				dose_report = DoseReport()
				dose_report.fromPatient(patient)
				patient.dose=dose_report
				patient.save()
				list(map(saveBottle(dose_report),post_data['bottles']))
				print("New patient history records successfully added")

				# return DjangoMsgErrorForm(form)
				return DjangoMsgSuccess()
			else:
				return DjangoMsgErrorForm(form)
		else:
			return DjangoMsgErrorBadFormat(request.content_type)

	return redirect('home')


def patientProfilePlayground(r):
	return render(r,'patient_profile_playground.html', {})