""" The Patient model has all the latest information in one table that gets updated. 
The other models are there for logging purposes (for example, to see all the doses
a patient has taken throughout the therapy."""

from django.db import models
from django.utils import timezone
from datetime import datetime, timedelta, date
from . import config

from django.contrib.auth.models import AbstractUser


class Hospital(models.Model):
	name = models.CharField(max_length=50)
	dt_created = models.DateTimeField(blank=True, null=True,default=timezone.now())
	email = models.CharField(max_length=150) 
	contact = models.TextField()
	remarks = models.TextField(blank=True, null=True,)
	url = models.CharField(max_length=50)
	allowsOpenRegistration = models.BooleanField(default=False)

	def publish(self):
		self.dt_created = timezone.now()
		self.save()

	def __str__(self):
		return (self.name)


class User(AbstractUser):
	hospital = models.ForeignKey(Hospital,blank=True, null=True,on_delete=models.CASCADE)
	isHospitalAdmin = models.BooleanField(default=False)
	isActive = models.BooleanField(default=False)
	isNew = models.BooleanField(default=True)

	translation = 	{ 'first_name': 		u'姓名'
					, 'hospital': 			u'医院'
					, 'username': 			u'用户名'
					, 'email': 				u'电子邮件'
					, 'last_login': 		u"上次登录"
					, 'date_joined': 		u"登记日期"
					, 'isHospitalAdmin': 	u"管理员权限"
					, 'isActive': 			u"活性"
					, 'isNew': 				u"新的用户"
					}
	pass

	def toggleActive(self):
		self.isActive = not self.isActive

	def toggleAdmin(self):
		self.isHospitalAdmin = not self.isHospitalAdmin


class Patient(models.Model):
	""" This is a model with all the latest information about a patient's therapy, dose, heart report...
	Each patient should only have one which keeps getting updated. 
	It's main purpose is to prevent too many join table calls. """

	patient_name = models.CharField(max_length=100)
	patient_age = models.CharField(max_length=10, default=0)
	patient_card = models.CharField(max_length=20)
	patient_therapy = models.CharField(max_length=100)
	patient_frequency= models.CharField(max_length=50)
	patient_nacl_amount= models.CharField(max_length=10, default=config.nacl_amounts[0])

	patient_initial_dose = models.CharField(max_length=10)
	patient_initial_dose_dt = models.DateTimeField(blank=True, null=True,default=timezone.now())
	patient_maintenance_dose = models.CharField(max_length=10)

	patient_active = models.BooleanField(default=True)
	patient_stop_drug_reason = models.CharField(blank=True, null=True,max_length=100)
	patient_stop_drug_temporary_reason = models.CharField(blank=True, null=True,max_length=100)

	heart_text = models.TextField()
	heart_remarks = models.TextField(blank=True, null=True,)
	heart_percentage = models.CharField(max_length=10)
	heart_dt = models.DateTimeField(blank=True, null=True,default=timezone.now())
	
	dose_weight = models.CharField(max_length=10)
	dose_amount = models.CharField(max_length=10)
	dose_dt_opened = models.DateTimeField(blank=True, null=True,default=timezone.now()) # Used to calculate the expiry date. Show it if red with a warning if expired. Can modify only if new bottle.
	dose_remaining_dose = models.CharField(max_length=10) # Should not be negative
	dose_dt = models.DateTimeField(blank=True, null=True,default=timezone.now()) # 首次用药时间 Can modify only if new bottle.
	dose_remarks = models.TextField(blank=True, null=True)
	dose_next_appointment_dt = models.DateTimeField()
	dose_number_cycle = models.CharField(blank=True, null=True,default=0, max_length=1) # Used only for 3 weeks on, 1 week off dose frquency
	dose_number = models.CharField(blank=True, null=True,default=0, max_length=1) # Used only for 3 weeks on, 1 week off dose frquency

	therapy_status = models.CharField(max_length=10)
	therapy_dt = models.DateTimeField(blank=True, null=True,default=timezone.now())
	therapy_reason = models.CharField(max_length=10, blank=True, null=True,default="")
	therapy_remarks = models.CharField(max_length=100, blank=True, null=True,default="")


	patient_update_dt = models.DateTimeField(blank=True, null=True,default=timezone.now()) # DT of last update.
	
	hospital = models.ForeignKey(Hospital, on_delete=models.CASCADE,blank=True, null=True)
	user = models.ForeignKey(User, on_delete=models.CASCADE,blank=True, null=True)

	dose = models.ForeignKey("DoseReport", on_delete=models.SET_NULL,blank=True, null=True)

	translation = {
					'patient_name': u"姓名",
					'patient_age': u"年龄",
					'patient_card': u"磁卡号",
					'patient_therapy': u"化疗方案",
					'patient_frequency': u"剂量频率",
					'heart_text': u"心超报告",
					'heart_remarks': u"备注",
					'heart_percentage': u"左心射血分数",
					'heart_dt': u"心超日期",
					'dose_amount': u"剂量",
					'dose_weight': u"体重",
					'dose_open_new': u'是否开封新药',
					'dose_dt_opened': u'开封新药日期',
					'dose_initial_dose': u'首次用药时间',
					'patient_maintenance_dose': u"维持使用",
					'dose_remaining_dose': u"剩余剂量",
					'dose_dt_created': u'记录日期',
					'heart_created_date': u'记录日期',
					'dose_dt': u'用药日期',
					'dose_remarks': u'备注',
					'dose_remarks': u"备注",
					'dose_useby_date': u"使用日期",
					'patient_update_dt': u"最后更新",
					'patient_info_dt_update': u'最后更新',
					'patient_initial_dose': u'首次使用剂量',
					'patient_maintenance_dose': u'维持剂量',
					'patient_dt_initial_dose': u'首次使用时间',	
					'drug_stop_reasons': u'停药原因：',
					'drug_stop_reasons_temp': u'暂停原因：',
	}

	chemotherapy_protocols = config.chemotherapy_protocols
	echocardiography_reports = config.echocardiography_reports
	drug_stop_reasons_temp = config.drug_stop_reasons_temp
	drug_stop_reasons = config.drug_stop_reasons

	def setHospitalFromID(self, hospital_id):
		# I've had issues setting the hospital other ways, so this is a bit of a roundabout way of doing it.
		self.hospital = Hospital.objects.filter(id=int(hospital_id))[0]
		self.save()

	def getDoseAmountMg(self):
		return str(round(21.0/440*float(self.dose_amount), 1))

	def dose_dt_expiration(self):
		return self.dose_dt_opened + timedelta(days=config.drug_shelf_life)  # 开封药品过期时间

	def publish(self):
		""" Whenever we create a new patient we also create records in the other tables. """

		self.patient_update_dt = timezone.now()
		self.save()

	def fromPersonalInfo(self, personalInfo):
		self.patient_name = personalInfo.patient_name
		self.patient_age = personalInfo.patient_age
		self.patient_card = personalInfo.patient_card
		self.patient_therapy = personalInfo.patient_therapy
		self.patient_frequency= personalInfo.patient_frequency
		self.patient_initial_dose = personalInfo.patient_initial_dose
		self.patient_initial_dose_dt = personalInfo.patient_initial_dose_dt
		self.patient_maintenance_dose = personalInfo.patient_maintenance_dose
		self.patient_nacl_amount = personalInfo.patient_nacl_amount
		self.publish()

	def fromDoseReport(self, dose):
		self.dose_weight = dose.dose_weight
		self.dose_dt_opened = dose.dose_dt_opened
		self.dose_remaining_dose = dose.dose_remaining_dose
		self.dose_remarks = dose.dose_remarks
		self.dose_dt = dose.dose_dt
		self.dose_amount = dose.dose_amount
		self.dose_next_appointment_dt = dose.dose_next_appointment_dt
		self.dose_number_cycle = dose.dose_number_cycle
		self.dose_number = dose.dose_number
		self.dose = dose
		self.publish()

	def fromHeartReport(self, heart):
		self.heart_text = heart.heart_text
		self.heart_percentage = heart.heart_percentage
		self.heart_dt = heart.heart_dt
		self.heart_remarks = heart.heart_remarks
		self.publish()

	def fromTherapyStatus(self, therapy):
		self.therapy_status = therapy.therapy_status
		self.therapy_dt = therapy.therapy_dt
		self.therapy_reason = therapy.therapy_reason
		self.therapy_remarks = therapy.therapy_remarks
		self.publish()
		print(self.therapy_status, self.therapy_reason, self.id)

	def __str__(self):
		return self.patient_name

class PatientInfo(models.Model):
	""" The next three ORMs serve logging / history purposes. 
	This one logs changes in personal info (if any)."""
	patient_id = models.ForeignKey(Patient, on_delete=models.CASCADE)
	patient_name = models.CharField(max_length=100)
	patient_age = models.CharField(max_length=10)
	patient_card = models.CharField(max_length=20)
	patient_therapy = models.CharField(max_length=100)
	patient_initial_dose = models.CharField(max_length=10)
	patient_initial_dose_dt = models.DateTimeField(blank=True, null=True,default=timezone.now())
	patient_maintenance_dose = models.CharField(max_length=10)
	patient_nacl_amount = models.CharField(max_length=10,default=config.nacl_amounts[0])

	patient_info_dt_update = models.DateTimeField(blank=True, null=True,default=timezone.now())	
	patient_frequency= models.CharField(max_length=50)

	def publish(self):
		self.patient_info_dt_update = timezone.now()
		self.save()

	def fromPatient(self, patient):
		print(patient)
		self.patient_id = patient
		self.patient_name = patient.patient_name
		self.patient_age = patient.patient_age
		self.patient_card = patient.patient_card
		self.patient_therapy = patient.patient_therapy
		self.patient_frequency= patient.patient_therapy
		self.patient_initial_dose = patient.patient_initial_dose
		self.patient_initial_dose_dt = patient.patient_initial_dose_dt
		self.patient_maintenance_dose = patient.patient_maintenance_dose
		self.patient_nacl_amount = patient.patient_nacl_amount
		self.publish()


	def __str__(self):
		return self.patient_name or ""



class HeartReport(models.Model):
	""" Used to have a history of all heart reports. """
	patient_id = models.ForeignKey(Patient, on_delete=models.CASCADE)
	heart_text = models.TextField()
	heart_percentage = models.CharField(max_length=10)
	heart_dt = models.DateTimeField()
	heart_remarks = models.TextField(blank=True, null=True,)
	heart_created_date = models.DateTimeField(blank=True, null=True,default=timezone.now())

	def publish(self):
		self.heart_created_date = timezone.now()
		self.save()

	def fromPatient(self, patient):
		self.patient_id = patient
		self.heart_text = patient.heart_text
		self.heart_remarks = patient.heart_remarks
		self.heart_percentage = patient.heart_percentage
		self.heart_dt = patient.heart_dt
		self.publish()

	def __str__(self):
		return self.patient_id or ""


class DoseReport(models.Model):
	""" History of all bottles opened and doses dispensed. """
	patient_id = models.ForeignKey(Patient, on_delete=models.CASCADE)
	dose_weight = models.CharField(max_length=10)
	dose_amount = models.CharField(max_length=10)
	dose_dt_opened = models.DateTimeField(blank=True, null=True, default=timezone.now()) # Used to calculate the expiry date. Show it if red with a warning if expired. Can modify only if new bottle.
	dose_remaining_dose = models.CharField(max_length=10) # Should not be negative
	dose_remarks = models.TextField(blank=True, null=True)
	dose_dt = models.DateTimeField(blank=True, null=True,default=timezone.now())
	dose_dt_created = models.DateTimeField(blank=True, null=True,default=timezone.now())
	dose_next_appointment_dt = models.DateTimeField(blank=True, null=True,default=timezone.now())
	dose_number_cycle = models.CharField(blank=True, null=True,default=0, max_length=1) # Used only for 3 weeks on, 1 week off dose frquency
	dose_number = models.CharField(blank=True, null=True,default=0, max_length=1) # Used only for 3 weeks on, 1 week off dose frquency

	def publish(self):
		self.dose_dt_created = timezone.now()
		self.save()

	def fromPatient(self, patient):
		self.patient_id = patient
		self.dose_weight = patient.dose_weight
		self.dose_amount = patient.dose_amount
		self.dose_dt_opened = patient.dose_dt_opened
		self.dose_remaining_dose = patient.dose_remaining_dose
		self.dose_remarks = patient.dose_remarks
		self.dose_dt = patient.dose_dt
		self.dose_next_appointment_dt = patient.dose_next_appointment_dt
		self.dose_number_cycle = patient.dose_number_cycle
		self.publish()

	def __str__(self):
		return (self.patient_id + " " + self.dose_dt) or ""

class TherapyStatus(models.Model):
	patient_id = models.ForeignKey(Patient, on_delete=models.CASCADE)
	therapy_status = models.CharField(max_length=10)
	# status can be Active | TemporaryHalt | Halt | Finished
	therapy_dt = models.DateTimeField(blank=True, null=True,default=timezone.now())
	therapy_dt_created = models.DateTimeField(blank=True, null=True,default=timezone.now())
	therapy_reason = models.CharField(max_length=10, blank=True, null=True,default="")
	therapy_remarks = models.CharField(max_length=100, blank=True, null=True,default="")

	translation = config.drug_stop_states

	def fromPatient(self, patient):
		self.therapy_status = patient.therapy_status
		self.therapy_dt = patient.therapy_dt
		self.therapy_reason = patient.therapy_reason
		self.therapy_remarks = patient.therapy_remarks
		self.publish()

	def publish(self):
		self.therapy_dt_created = timezone.now()
		self.save()

class Bottle(models.Model):
	dose = models.ForeignKey(DoseReport, on_delete=models.CASCADE)
	amount = models.CharField(max_length=10)
	remaining = models.CharField(max_length=10)
	dt = models.DateTimeField(blank=True, null=True,default=timezone.now())
	opened = models.DateTimeField(blank=True, null=True,default=timezone.now())
	expiry = models.DateTimeField(blank=True, null=True,default=timezone.now())
	number = models.CharField(max_length=10)
	def getDoseAmountMl(self):
		return str(round(21.0/440*float(self.amount), 1))