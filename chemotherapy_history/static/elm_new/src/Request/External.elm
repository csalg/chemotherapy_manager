module Request.External exposing (..)

print pid = "/patient/"++(toString pid)++"/printall/"
personalHistory pid = "/patient/"++(toString pid)++"/personalHistory/"
doseHistory pid = "/patient/"++(toString pid)++"/doseHistory/"
heartHistory pid = "/patient/"++(toString pid)++"/heartHistory/"
newPatient = "/patient/"
