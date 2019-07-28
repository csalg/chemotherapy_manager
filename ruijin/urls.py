"""ruijin URL Configuration

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/1.11/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  url(r'^$', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  url(r'^$', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.conf.urls import url, include
    2. Add a URL to urlpatterns:  url(r'^blog/', include('blog.urls'))
"""
from django.conf.urls import url
from django.contrib import admin
from django.contrib.auth import views as auth_views

from chemotherapy_history.views.main import *
from chemotherapy_history.views.history import *
from chemotherapy_history.views.permissions import *
from chemotherapy_history.views.user_management import *

urlpatterns = [
    url(r'^django_admin/', admin.site.urls),
    url(r'^$', patients),
    url(r'^index', patients, name="home"),
    url(r'^search', search),
    url(r'^user/edit', userEdit),
    url(r'^user/viewUsers/toggleActive', userToggleActive),
    url(r'^user/viewUsers/toggleAdmin', userToggleAdmin),
    url(r'^user/viewUsers/new', usersNew, name='users_new'),
    url(r'^user/viewUsers', usersView, name='users_view'),
    url(r'^user/', userMain, name='user'),
    url(r'^patient/([\w]+)/updatePersonalInfo/$', updatePersonalInfo),
    url(r'^patient/([\w]+)/updateDoseReport/$', updateDoseReport),
    url(r'^patient/([\w]+)/updateBottle/$', updateBottle),
    url(r'^patient/([\w]+)/updateStop/$', updateStop),
    url(r'^patient/([\w]+)/updateHeart/$', updateHeart),
    url(r'^patient/$', patientElm, name="new_patient"),
    url(r'^patient/([\w]+)/$', patientElm),
    url(r'^patient/([\w]+)/printPersonal/$', printPersonal),
    url(r'^patient/([\w]+)/printDose/$', printDose),
    url(r'^patient/([\w]+)/printall/$', printAll),
    url(r'^patient/([\w]+)/qr/$', getQR),
    url(r'^patients/json/$', patientListJson),
    url(r'^patients/$', patients, name="patients"),
    url(r'^patientprofile/$', patientProfilePlayground),



# History Views

    url(r'^patient/([\w]+)/personalHistory/$', 
        (lambda r,pid : pipe( (r, pid), userAuthIdentity, historyTable(personalHistoryParams), tableToHTML))),

    url(r'^patient/([\w]+)/personalHistory/csv$', 
        (lambda r,pid : pipe( (r, pid), userAuthIdentity, historyTable(personalHistoryParams), toCSV("personalHistory")))),

    url(r'^patient/([\w]+)/personalHistory/rollback$', 
        (lambda r,pid : pipe( (r, pid), userAuthIdentity, historyTable(personalHistoryParams), rollback, tableToHTML))),

    url(r'^patient/([\w]+)/doseHistory/$', 
        (lambda r,pid : pipe( (r, pid), userAuthIdentity, historyTable(doseHistoryParams), tableToHTML))),

    url(r'^patient/([\w]+)/doseHistory/csv$', 
        (lambda r,pid : pipe( (r, pid), userAuthIdentity, historyTable(doseHistoryParams), toCSV("doseHistory")))),

    url(r'^patient/([\w]+)/doseHistory/rollback$', 
        (lambda r,pid : pipe( (r, pid), userAuthIdentity, historyTable(doseHistoryParams),rollback(doseHistoryParams), tableToHTML))),

    url(r'^patient/([\w]+)/heartHistory/$', 
        (lambda r,pid : pipe( (r, pid), userAuthIdentity, historyTable(heartHistoryParams), tableToHTML))),

    url(r'^patient/([\w]+)/heartHistory/csv$', 
        (lambda r,pid : pipe( (r, pid), userAuthIdentity, historyTable(heartHistoryParams), toCSV("heartHistory")))),

    url(r'^patient/([\w]+)/heartHistory/rollback$',
        (lambda r,pid : pipe( (r, pid), userAuthIdentity, historyTable(heartHistoryParams), rollback(heartHistoryParams)))),

    url(r'^patient/([\w]+)/json/$', patientJSON),

# User views

    url(r'^signup/$', signup, name='signup'),
    url(r'^login/$', auth_views.login, name='login'),
    url(r'^afterLogin/$', afterLogin, name='afterLogin'),
    url(r'^logout/$', auth_views.logout, {'next_page': 'login'}, name='logout'),

# Hospital admin views
    url(r'^admin/settings$', adminSettings, name='adminSettings'),
    url(r'^admin/signup$', adminSignup, name='adminSettings'),
    # adminMain

# Json API
    url(r'^api/patient/([\w]+)/$', patientJSON),
    url(r'^api/newpatient/$', newPatient),
    url(r'^api/patients/$', patientListJson),
    url(r'^api/updatePersonalInfo/([\w]+)/$', updatePersonalInfo),
    url(r'^api/updateDoseReport/([\w]+)/$', updateDoseReport),
    url(r'^api/updateHeartReport/([\w]+)/$', updateHeart),
    url(r'^api/updateTherapyStatus/([\w]+)/$', updateTherapyStatus),

    url(r'^api/patient/([\w]+)/doseHistory/([\w]+)$', 
        (lambda r,pid,max_ : pipe( (r, pid), userAuthIdentity, historyTable(doseHistoryParams), toJSON(max_)))),

]

