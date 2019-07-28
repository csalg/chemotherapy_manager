from bs4 import BeautifulSoup
import requests
from chemotherapy_history.models import *
from random import randrange, randint
import datetime
import re

def getIds():
	url  = "http://id.8684.cn/ajax.php?act=getCardList&type=2&flag=&code="
	r    = requests.get(url)

	data = r.text
	soup = BeautifulSoup(data, "lxml")

	return([name.get_text() for name in soup.find_all("span", class_='table-td1')])


# regex = r"/d"

# for iter in range(1,1000):
#     with open("sample.txt", mode="a", encoding="utf8") as f:
#         for s in getIds():
#             s = s[0:4]
#             if re.match(regex,(s[-1])):
#                 s=s[0:3]
#             print(s)
#             print(s, file=f)

# assert(False)

def randomDate(y=2018,m=6):
	return datetime.datetime(randrange(y,2019),randrange(m,7),randrange(1,27))

def randomDateBeforeToday(days=1):
	date = datetime.datetime.today()
	return (date - timedelta(days=randrange(0,days), hours=randrange(0,23), minutes=randrange(0,60), seconds=randrange(0,60)))


def randomElement(lst):
	return lst[randrange(0,len(lst))]

hospital = Hospital.objects.filter(name__contains="瑞金")[0]
hospital_id = hospital.id
print(hospital)
dose_frequency = ['一周一次', "一周一次 (三周用药，一周停药)", '三周一次']

Patient.objects.all().delete()
PatientInfo.objects.all().delete()
HeartReport.objects.all().delete()
DoseReport.objects.all().delete()
TherapyStatus.objects.all().delete()
# assert(False)

def repeat(fun, *args, times=1):
    for i in range(0,times):
        fun(*args)

def addRandomDose(patient):
    print("adding random dose")
    dose = DoseReport()
    dose.patient_id = patient
    dose.dose_weight = randrange(20,101)
    dose.dose_amount = randrange(20,501)
    dose.dose_dt_opened = randomDateBeforeToday(28)
    dose.dose_remaining_dose = randrange(20,441)
    dose.dose_dt = randomDateBeforeToday(10)
    dose.save()

with open('scripts/sample.txt', 'r') as f:

    users = User.objects.all().filter(hospital=hospital_id)

    counter=0

    for line in f:
        patient = Patient()
        patient.hospital = hospital
        patient.user = users[randint(0, len(users)-1)]

        patient.patient_name = f.readline(randrange(1,7000))
        patient.patient_age = randrange(20,101)
        patient.patient_card = randrange(1000000,10000000)
        patient.patient_therapy = randomElement(patient.chemotherapy_protocols)
        patient.patient_frequency = randomElement(dose_frequency)
        patient.patient_initial_dose = randrange(300,501)
        patient.patient_initial_dose_dt = randomDateBeforeToday(280)
        patient.patient_maintenance_dose = str(int(int(patient.patient_initial_dose)*0.8))

        patient.dose_weight = randrange(20,101)
        patient.dose_amount = randrange(250,501)
        patient.dose_dt_opened = randomDateBeforeToday(28)
        patient.dose_remaining_dose = randrange(20,441)
        patient.dose_dt = randomDateBeforeToday(10)
        patient.dose_next_appointment_dt = patient.dose_dt + timedelta(days=randrange(7,28))

        patient.heart_text = randomElement(patient.echocardiography_reports)
        patient.heart_percentage = randrange(20,131)
        patient.heart_dt = randomDateBeforeToday(90)

        patient.patient_update_dt = randomDate()

        patient.setHospitalFromID(hospital_id)
        patient.save()
        patient_info = PatientInfo()
        patient_info.fromPatient(patient)
        heart_report = HeartReport()
        heart_report.fromPatient(patient)
        dose_report = DoseReport()
        dose_report.fromPatient(patient)
        repeat(addRandomDose, patient, times=10)
        counter +=1
        if counter>300:
            break

print(Patient.objects.all())
print(Hospital.objects.all())
print(hospital_id)
print(hospital_id)

assert(False)