from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import *

admin.site.register(Patient)
admin.site.register(PatientInfo)
admin.site.register(HeartReport)
admin.site.register(DoseReport)
admin.site.register(User, UserAdmin)
admin.site.register(Hospital)
