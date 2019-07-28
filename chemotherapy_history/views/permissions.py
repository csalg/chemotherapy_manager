from django.shortcuts import render, redirect
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

from typing import List, Tuple,Dict
from datetime import datetime, timedelta, date
from dateutil import parser
from toolz import curry, pipe 
from toolz.curried import map
import qrcode
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

ALLOW_ALL = False

""" All permission decorators in one place. """

def isUser(fun, check):
	""" check is (Request -> Bool)
	Allows fun to run only if check returns true, else redirects to login page"""
	def new_fun(*args,**kwargs):
		if ALLOW_ALL:
			return fun(*args,**kwargs)
		request=args[0]
		if type(args[0]) == tuple:
			# This is necessary for functional composition where the request 
			# and other data is passed around packed as a tuple 
			# (as opposed to unpacked in args.
			request=args[0][0]

		if (check(request) and request.user.isActive) or request.user.is_superuser:
			return fun(*args,**kwargs)
		else:
			return redirect('logout')
	return new_fun


def isUserAuth(fun):
	""" Enforces user is logged in. """
	return isUser(fun, check=(lambda request : request.user.is_authenticated))


def isUserAdmin(fun):
	""" Enforces user is admin. """
	return isUser(fun, check=(lambda request : request.user.is_superuser or request.user.isHospitalAdmin))


def sameHospital(fun):
	""" Prevents users froma accessing resources from other hospitals. """
	def new_fun(request,patient_id,*args,**kwargs):
		if ALLOW_ALL:
			return fun(request,patient_id,*args,**kwargs)

		user = User.objects.filter(id=int(request.user.id))[0]
		patient = Patient.objects.filter(id=int(patient_id))
		if not patient:
			return redirect('home')
		else: 
			patient = patient[0]
		print(user.hospital, patient.hospital)
		if user.hospital.id == patient.hospital.id:
			return fun(request,patient_id,*args,**kwargs)
		else:
			return redirect('home')
	return new_fun

@isUserAuth
def userAuthIdentity(a):
	"""
	For use in cases where the tuple 
	containing the request is going to be piped as the last argument.
	"""
	return a


def insecureAllowOrigin(fun):
	def new_fun(*args,**kwargs):
		response = fun(*args,**kwargs)
		response["Access-Control-Allow-Origin"] = "*" # Only for development
		response["Access-Control-Allow-Methods"] = "GET, OPTIONS"
		response["Access-Control-Max-Age"] = "1000"
		response["Access-Control-Allow-Headers"] = "X-Requested-With, Content-Type"
		return response
	return new_fun

