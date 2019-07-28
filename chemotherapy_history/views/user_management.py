from ..models import *
from ..forms import *
from ..helpers.smart_form import *
from ..helpers import *
from .permissions import *

### USER MANAGEMENT STUFF

 
def signup(request, fromAdmin=False):
    print(request.user.is_authenticated)
    print(dir(request.user))
    form = UserSignup(request.POST or None)
    
    if fromAdmin:
        hospitals = list(Hospital.objects.all().filter(user=request.user).values("name", "id"))
    else:
        hospitals = list(Hospital.objects.all().filter(allowsOpenRegistration=True).values("name", "id"))
    
    if request.method == 'POST':
        if hospitals or request.user.isHospitalAdmin:
            print(request.POST)
            print(form.errors)
            if form.is_valid():
                user = form.save()
                if request.user.isHospitalAdmin:
                    user.isNew = False
                    user.isActive = True
                    user.save()
                # print(hospital)
                # username = form.cleaned_data.get('username')
                # raw_password = form.cleaned_data.get('password1')
                # user = authenticate(username=username, password=raw_password)
                # login(request, user)
        return redirect('home')

    if hospitals:
        return render(request
            # , 'signup.html'
            , 'registration/register.html'
            , {'form': form
            , "hospitals": hospitals
              }
        	)
    else:
        return redirect('logout')

@isUserAuth
def userEdit(request):
	user = User.objects.filter(id=request.user.id)[0]
	form = UserPlaygroundForm(request, user)
	form.makeEditable()
	# form.tryCommit()

	return form.render()

@isUserAuth
def userMain(request):
	user = User.objects.filter(id=request.user.id)[0]
	form = UserPlaygroundForm(request, user)

	return form.render()


@isUserAdmin
@isUserAuth
def usersV(
				request, 
				fields= ( 'id'
						, 'first_name'
						, 'username'
						, 'email'
						, 'last_login'
						, 'date_joined'
						, 'isHospitalAdmin'
						, 'isActive'
						, "isNew"
						, "isHospitalAdmin"
						),
				filterVals={'isNew': False}):
	state = {}
	state['table'] =    makeTable ( User.objects.all()
								.values(*fields)
								.filter(**filterVals)
								.order_by('-last_login') or [],
						translation = User.translation,
						menu= 	[ { 'txt': u"切换帐户激活", 'href':"/user/viewUsers/toggleActive"}
								, { 'txt': u"切换管理员权限", 'href':"/user/viewUsers/toggleAdmin"}
								])
	return render(request, 'generic_table.html', state)

@isUserAdmin
@isUserAuth
def usersView(req):
	if req.user.is_superuser:
		return usersV(req)
	else:
		return usersV(req, filterVals = { 'isNew': False
									, 'hospital': req.user.hospital
						})

@isUserAdmin
@isUserAuth
def usersNew(req):
	if req.user.is_superuser:
		return usersV(req, filterVals={'isNew': True})
	else:
		return usersV(req, filterVals= 	{'isNew': True
										, 'hospital': req.user.hospital
			})

@isUserAdmin
@isUserAuth
def userDo(request, actOnUser):
	# print(request)
	if request.POST:
		print(request.POST)
		id = request.POST['RowID']
		user = User.objects.filter(id=id)[0]
		actOnUser(user)
		user.isNew = False
		user.save()
	return redirect('users_view')


@isUserAdmin
@isUserAuth
def userToggleActive(request):	
	return userDo(request, (lambda user : user.toggleActive()))

@isUserAdmin
@isUserAuth
def userToggleAdmin(request):	
	return userDo(request, (lambda user : user.toggleAdmin()))

@isUserAuth
def afterLogin(req):
	if req.user.isHospitalAdmin or req.user.is_superuser:
		if checkNewUsers:
			return redirect('user')
	else:
		return redirect('home')

@isUserAdmin
@isUserAuth
def adminSettings(r):
	return render(r, 'hospital_admin/settings.html', {})

@isUserAdmin
@isUserAuth
def adminSignup(r):
	return signup(r,fromAdmin=True)

# def adminSignup(r):
	