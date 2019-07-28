from chemotherapy_history import models

hospital = models.Hospital.objects.all()[0]
user = models.User.objects.all()[0]
user.hospital= hospital
user.isActive=True
dir(user)
user.isHospitalAdmin = True
user.save()
exit()
