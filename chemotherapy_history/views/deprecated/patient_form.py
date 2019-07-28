
### FORMS

# @isUserAuth
# def newPatientForm(request):
# 	# this little idiom will populate the form with data received or create a new form if GET req.
# 	form = NewPatientForm(request.POST or None)
# 	state=dict(form=form)

# 	state['personalFormGroups'] = [ FormGroup('patient_name', '姓名：'), FormGroup('age', '年龄：', inputType="number"), FormGroup('patient_card', '磁卡号：', inputType="number"), FormGroup('patient_therapy', "化疗方案：", width=6, inputType="options", options=config.chemotherapy_protocols, value="some val"), FormGroup('patient_frequency', "剂量频率：", width=6, inputType="options", options=config.dose_frequency),  ]		

# 	state['doseFormGroups'] = [ FormGroup('dose_dt', '最新用药日期：', inputType="date", width=12), FormGroup('dose_opened', '本药开封日期：', inputType="date", width=6), FormGroup('dose_opened_expiry', '本药过期日期：', inputType="date", width=6, disabled=True), FormGroup('dose_weight', '体重(kg)：', inputType="number"), FormGroup('dose_amount', '剂量(mg)：', inputType="number", disabled=True, allowOverride=True), FormGroup('dose_remaining_dose', '使用后剩余剂量(mg)：', inputType="number")]				
# 	state['heartFormGroups'] = [ FormGroup('heart_text', '心超报告：', width=12), FormGroup('heart_dt', '心超日期：', inputType="date", width=6), FormGroup('heart_percentage', '左心射血分数(%)：', inputType="number", width=6), FormGroup('heart_remarks', '备注:', width=12)]


# 	# this bit will create a new patient if validation succeeds


# 	if request.method == 'POST':
# 		if form.is_valid():
# 			print("New patient post form is valid")
# 			patient = form.save(commit=False)
# 			patient.hospital = request.user.hospital
# 			patient.publish()
# 			patient_id_str = '{0:0{width}}'.format(patient.id, width=6)
# 			print(f"Patient id is {patient_id_str}")
# 			print("New patient successfully created")
# 			patient_info = PatientInfo()
# 			patient_info.fromPatient(patient)
# 			heart_report = HeartReport()
# 			heart_report.fromPatient(patient)
# 			dose_report = DoseReport()
# 			dose_report.fromPatient(patient)
# 			print("New patient history records successfully added")
# 			return HttpResponseRedirect(f'/patient/{patient_id_str}')
# 		else:
# 			return render(request, 'patient_new_errors.html', state)

# 		return patientElm(request)
