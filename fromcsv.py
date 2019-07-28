import csv
import os
from datetime import timedelta

from dateutil import parser
from chemotherapy_history import models

os.environ["PYTHONIOENCODING"] = "UTF-8"

# print(models.Hospital.objects.all())

# assert(False)
def getFieldnames(filename):
  print(f"\nFieldnames for {filename}\n")
  with open(filename, newline='\n') as csvfile:
      spamreader = csv.reader(csvfile, delimiter=',', quotechar='|')
      first_line = spamreader.__next__()
      counter = 0
      for val in first_line:
          print(counter, ":", val)
          counter += 1

# getFieldnames('Patient.csv')
# getFieldnames('Heart.csv')
# getFieldnames('Dose.csv')
# assert(False)


patient_dict = \
    { 0 : "patient_name"
    , 1 : "patient_card"
    , 2 : "patient_age"
    , 4 : "patient_therapy"
    , 5 : "patient_initial_dose_dt"
    , 6 : "patient_initial_dose"
    , 8 : "days"
    # , 11 : "therapy_reason"
    }

heart_dict = \
    { 0 : "patient_name"
    , 1 : "patient_card"
    , 2 : "heart_dt"
    , 3 : "heart_text"
    , 4 : "heart_percentage"
    , 5 : "heart_dt"
    , 6 : "heart_remarks"
    }

dose_dict = \
    { 0 : "patient_name"
    , 1 : "patient_card"
    , 2 : "dose_number"
    , 3 : "dose_dt"
    , 4 : "dose_amount"
    , 5 : "patient_maintenance_dose"
    , 6 : "dose_weight"
    , 9 : "dose_remaining_dose"
    , 10 : "dose_expiry"
    , 11 : "dose_remarks"
    }

patientsFile = "/Users/vivian/Desktop/Patient.csv"
doseFile = "/Users/vivian/Desktop/Dose.csv"
heartFile = "/Users/vivian/Desktop/Heart.csv"

patients = {}
personalInfo = {}
dose = {}
heart = {}

personal_info_not_found = []
heart_not_found = []

hospital = models.Hospital.objects.all()[0]
# user = models.User.objects.all()[1]
# user.hospital = hospital
# user.save()
models.Patient.objects.all().delete()
def make_patients():
    for patient_card, personal_info in personalInfo.items():
        print(patient_card, personal_info)

        patient = models.Patient()
        print(dose[patient_card])

        def addDays(prev,days):
            return parser.parse(prev) + timedelta(days=days)

        def getFrequency(days):
            if days == 7:
                return u"一周一次"
            if days == 21:
                return u"三周一次"
            else:
                return u"请手工输入剂量频率"


        if patient_card in dose:
            print(personalInfo[patient_card]["days"])
            setattr(patient
                ,"dose_next_appointment_dt"
                , addDays(dose[patient_card]["dose_dt"], int(personalInfo[patient_card]["days"]))
                )
            setattr(patient
                ,"dose_dt_opened"
                , addDays(dose[patient_card]["dose_expiry"], -28))

            setattr(patient
                ,"patient_frequency"
                , getFrequency(int(personalInfo[patient_card]["days"])))

            setattr(patient
                ,"patient_maintenance_dose"
                , int(dose[patient_card]["patient_maintenance_dose"]))

            print(f'set {dose[patient_card]["patient_maintenance_dose"]} for {patient_card}')
            print(patient.patient_maintenance_dose)
            for key,val in dose[patient_card].items():
                if not (key == "dose_expiry"):
                    setattr(patient, key, val)

        if patient_card in personalInfo:
            for key,val in personalInfo[patient_card].items():
                setattr(patient, key, val)
        else:
            personal_info_not_found.append(patient_card)


        if patient_card in heart:
            for key,val in heart[patient_card].items():
                setattr(patient, key, val)
        else:
            print("\n\n\nNOT FOUND\n\n\n")
            heart_not_found.append(str(patient_card))
            print(heart_not_found)

        patient.hospital = hospital
        # patient.save()
        # patient_info = PatientInfo()
        # patient_info.fromPatient(patient)
        # heart_report = HeartReport()
        # heart_report.fromPatient(patient)
        # dose_report = DoseReport()
        # dose_report.fromPatient(patient)
        # patient.dose=dose_report
        patient.save()
        patient_info = models.PatientInfo()
        patient_info.fromPatient(patient)
        heart_report = models.HeartReport()
        heart_report.fromPatient(patient)
        dose_report = models.DoseReport()
        dose_report.fromPatient(patient)
        patient.dose=dose_report
        patient.save()
        # assert(False)
        # print(heart[patient_card])

        #     setattr(patient, val, dose[val])
        # for key,val in heart_dict.items():

def populateFrom(filename, dict_, outputDict):
    with open(filename, newline='\n') as csvfile:
            spamreader = csv.reader(csvfile, delimiter=',', quotechar='|')
            spamreader.__next__()
            for row in spamreader:
                # print(row)
                outputDict[row[1]] = {}
                for key,val in dict_.items():
                    # print(key, val)
                    outputDict[row[1]][val] = row[key]

# patients_init()

populateFrom(patientsFile, patient_dict, personalInfo)
populateFrom(heartFile, heart_dict, heart)
populateFrom(doseFile, dose_dict, dose)
make_patients()
print("这些患者没有找到基本信息，无法加到数据库：\n", [print(i) for i in personal_info_not_found])

# 这些患者没有找到基本信息，无法加到数据库：

# H01201166
# K00596110
# 132002102723285
# E18813618
# 000000
# L00137500

# ['H01201166', 'K00596110', '132002102723285', 'E18813618', '000000', 'L00137500']

print("这些患者没有找到心超信息，请直接输入：\n", [print(i) for i in heart_not_found])
# print(personalInfo)

assert(False)
# print(patients.kets)


# 姓名 0
# 磁卡号 1
# 年龄 2
# 初始体重(kg) 3
# 化疗方案 4
# 首次使用时间 5
# 首次使用剂量(mg) 6
# 首次心超时间 7
# 注射间隔（天） 8
# 维持使用 9
# 注射次数 10
# 停药原因 11
# 备注 12

    # for row in spamreader:
    #     print(', '.join(row))
