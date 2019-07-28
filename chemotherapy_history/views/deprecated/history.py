
### PATIENT HISTORY VIEWS
### DECORATORS

def patientHistoryDecorator(query_title): 
	""" A decorator that looks up all the context. Decorated functions only need to add stuff to the state element"""
# This holds the argument
	def decorator(func_to_decorate): 
	# This holds the actual function
		def new_func(request, patient_num, **original_kwargs): 
		# This is the new function that has access to the old function's namespace.
			state = {
			'translation' : getPatient(patient_num).translation,
			'query_title': query_title}
			return func_to_decorate(request,patient_num, state=state)
		return new_func
	return decorator

def patientHistoryTable(func_to_decorate): 
    def new_func(request, patient_num): 
        state=func_to_decorate(request, patient_num)
        state['table'] = makeTable(   state['query']
                                    , translation=state['translation']
                                    , tableMenu=[ { 'txt': "恢复到以前的值", 'href':"rollback"}
                                                , {'txt': "以csv下载", 'href':"csv"} 
                                                , {'txt': "回到患者资料", 'href':".."} 
                                                ]
                                    )
        return render(request, 'patient_history.html', state)
    return new_func

def tableToCSV(filename): 
    def decorator(func_to_decorate): 
        def new_func(request, patient_num): 
            state=func_to_decorate(request, patient_num)

            response = HttpResponse(content_type='text/csv')
            response['Content-Disposition'] = f'attachment; filename={filename}.csv'

            writer = csv.writer(response)
            def translate(val):
                if "translation" in state:
                    if val in state["translation"]:
                        return state["translation"][val]
                return val
            writer.writerow([translate(val) for val in state['query'].values()[0].keys()])

            for row in state['query'].values():
                writer.writerow([val for val in row.values()])

            return response
        return new_func
    return decorator


def rollbackDeprecated(model, order_by, patient_update):
    def decorator(func_to_decorate):
        def new_func(request, patient_num, **kwargs):

            def query():
                return model.objects.filter(patient_id=getPatient(patient_num)).order_by(order_by)

            def latestValue():
                return query()[0]

            if len(query())>=2:
                latestValue().delete()
                patient = Patient.objects.filter(id=patient_num)[0]
                patient_update(patient,latestValue())
                patient.save()
            return func_to_decorate(request, patient_num, **kwargs)
        return new_func
    return decorator


## View functions

@patientHistoryDecorator(u"查看基本信息历史")
@sameHospital
@isUserAuth
def personalHistoryQuery(request, patient_num, state={}):
	state['query'] = PatientInfo.objects.filter(patient_id=getPatient(patient_num)).values('id',
								'patient_name', 
								'patient_age', 
								'patient_card', 
								'patient_therapy',
								'patient_frequency',
								'patient_info_dt_update',
								).order_by('-patient_info_dt_update') or []
	return state

@patientHistoryTable
def personalHistory(request, patient_num):
    return personalHistoryQuery(request, patient_num, state={})



@patientHistoryTable
@rollbackDeprecated(PatientInfo, '-patient_info_dt_update', (lambda patient, info: patient.fromPersonalInfo(info)))
def personalHistoryRollback(r, pid, state={}):
    return personalHistoryQuery(r, pid, state={})

@tableToCSV("personalHistory")
def personalHistoryCSV(r, pid, state={}):
    return personalHistoryQuery(r, pid, state={})

@patientHistoryDecorator(u"查看用药信息")
@sameHospital
@isUserAuth
def doseHistoryQuery(request, patient_num, state={}):
	state['query'] = DoseReport.objects.filter(patient_id=getPatient(patient_num)).values(
								'dose_dt',
								'dose_amount',
								'dose_remaining_dose',
								'dose_dt_opened',
								'dose_weight',
								'dose_remarks',
								'dose_dt_created',).order_by('-dose_dt_created') or []
	return state

@patientHistoryTable
def doseHistory(request, patient_num):
    return doseHistoryQuery(request, patient_num, state={})

@patientHistoryTable
@rollbackDeprecated(DoseReport, '-dose_dt_created', (lambda patient, dose: patient.fromDoseReport(dose)))
def doseHistoryRollback(r, pid, state={}):
    return doseHistoryQuery(r, pid, state={})

@tableToCSV("doseHistory")
def doseHistoryCSV(r, pid, state={}):
    return doseHistoryQuery(r, pid, state={})

@patientHistoryDecorator(u"查看使用前检查历史")
@sameHospital
@isUserAuth
def heartHistoryQuery(request, patient_num, state={}):
	state['query'] = HeartReport.objects.filter(patient_id=getPatient(patient_num)).values('heart_text', 
								'heart_percentage', 
								'heart_dt', 
								'heart_remarks', 
								'heart_created_date', ) or []
	return state

@patientHistoryTable
def heartHistory(request, patient_num):
    return heartHistoryQuery(request, patient_num, state={})

@patientHistoryTable
@rollbackDeprecated(HeartReport, '-heart_dt', (lambda patient, heart: patient.fromHeartReport(heart)))
def heartHistoryRollback(r, pid, state={}):
    return heartHistoryQuery(r, pid, state={})

@tableToCSV("heartHistory")
def heartHistoryCSV(r, pid, state={}):
    return heartHistoryQuery(r, pid, state={})


