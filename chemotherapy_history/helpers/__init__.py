
from .. import config
from ..models import *
from dateutil import parser

def debug(*args):
	if len(args) == 1 or len(args) > 3:
		return print("[DEBUG:] ", *args)
	if len(args) == 2:
		return print(f"[DEBUG:] {args[1]} is {args[0]}")
	if len(args) == 3:
		return print(f"[DEBUG:] In {args[2]}, {args[1]} is {args[0]}")
	else:
		return print("")

def getPatient(patient_num):
	return Patient.objects.filter(id=int(patient_num))[0]



def dtFromElm(dtString):
	def cleanDate():
		if len(dtString) > 0:
			if dtString[0] == '"':
				print(dtString[1:-1])
				return dtString[1:-1]
			return dtString
	return parser.parse(cleanDate())


