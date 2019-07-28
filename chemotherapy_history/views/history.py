from django.http import HttpResponseRedirect
from django.core.files.storage import FileSystemStorage
from django.shortcuts import render, redirect
from django.forms.models import model_to_dict
from django.http import JsonResponse, HttpResponse

from datetime import datetime, timedelta, date
from dateutil import parser
from toolz import curry, pipe 
from toolz.curried import map
import csv

from ..models import *
from ..helpers import *
from ..helpers.smart_form import makeTable

from .permissions import *


"""
Data structure: history params
A tuple holding:
      entity
    , values
    , order_by
    , lambda to update patient info from a new report
"""


personalHistoryParams =(
      PatientInfo
    , ('id','patient_name', 'patient_age', 'patient_card', 'patient_therapy','patient_frequency','patient_info_dt_update')
    , '-patient_info_dt_update'
    , (lambda patient, info: patient.fromPersonalInfo(info))
    )


doseHistoryParams = (
      DoseReport
    , ('dose_dt', 'dose_amount', 'dose_remaining_dose', 'dose_dt_opened', 'dose_weight', 'dose_remarks', 'dose_dt_created', 'dose_next_appointment_dt', 'dose_number', 'dose_number_cycle')
    , '-dose_dt_created'
    , (lambda patient, dose: patient.fromDoseReport(dose))
    )


heartHistoryParams = (
    HeartReport
    , ('heart_text', 'heart_percentage', 'heart_dt', 'heart_remarks', 'heart_created_date' )
    , '-heart_dt'
    , (lambda patient, heart: patient.fromHeartReport(heart))
    )


""" 
Functions
(Designed to be composed)
""" 

@curry
def historyTable(params, rpid):
    """ First function, looks up the data on the database"""
    debug("params in historyTable is: ", params)
    debug("rpid in historyTable is: ", rpid)

    entity, values, order_by, patient_update = params
    r, pid = rpid 

    print("historyTable")
    state = {
      'translation' : getPatient(pid).translation
    , 'query' : entity.objects.filter(patient_id=getPatient(pid)).values(*values).order_by(order_by) or []
    }
    print(type(state['query']))
    print(state['query'][0])
    return state, r, pid


@curry
def rollback(params, args):
    """ Optional function to be used after historyTable, 
    rolls back latest record and updates main patient object."""

    entity, values, order_by, patient_update = params
    state, r, pid = args
    
    def query():
        return entity.objects.filter(patient_id=getPatient(pid)).order_by(order_by)

    def latestValue():
        return query()[0]

    if len(query())>=2:
        latestValue().delete()
        patient = Patient.objects.filter(id=pid)[0]
        patient_update(patient,latestValue())
        patient.save()

    return historyTable(params, (r,pid))


@curry
def tableToHTML(args): 
    """ Renders as a table view """

    state, r, pid = args
    state['table'] = makeTable(   state['query']
                                , translation=state['translation']
                                , tableMenu=[ { 'txt': "恢复到以前的值", 'href':"rollback"}
                                            , {'txt': "以csv下载", 'href':"csv"} 
                                            , {'txt': "回到患者资料", 'href':".."} 
                                            ]
                                )
    return render(r, 'patient_history.html', state)


@curry
def toCSV(filename, args): 
    """ Renders as a CSV"""

    state, r, pid = args

    response = HttpResponse(content_type='text/csv')
    response['Content-Disposition'] = f'attachment; filename={filename}.csv'

    writer = csv.writer(response)

    def translate(val):
        if "translation" in state:
            if val in state["translation"]:
                return state["translation"][val]
        return val

    # First row with the keys
    pipe(state['query'].values()[0].keys()
            , map(translate)
            , writer.writerow
        )
    # Remaining rows with the values
    pipe(state['query'].values()
            , map((lambda row:row.values()))
            , map(writer.writerow)
            , list # List is needed to force evaluation since map is lazy
        )
    return response

# @curry
# def toJSON(params,rpid): 
#     entity, values, order_by, patient_update = params
#     r, pid = rpid 

#     query = \
#         entity.objects.filter(patient_id=getPatient(pid))

#     # response = list(map(model_to_dict, query))

#     return JsonResponse(query, safe=False)

@curry
def toJSON(max_,args):
    max_ = int(max_)
    state, r, pid = args
    query = list(state['query'])
    if len(query) > max_:
        query = query[0:max_]
    return JsonResponse(query, safe=False)

