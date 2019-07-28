# -*- coding: utf-8 -*-
#
version = 0.2
#
main_window_title = u"靶向药物用药跟踪 | 瑞金医院乳腺中心"
#
db_name = "drug_tracking"
#
debug = True

#
default_export_path = u"D:\\赫赛汀用药记录系统\\导出\\"
default_export_filename = u"导出.xls"
default_export_passwd = "123456"

single_bottle_dosage = 440 # mg

#
# 化疗方案种类
chemotherapy_protocols = ['EC-T(H)','T(H)','TCb(H)','EC-Wp(H)','P(H)','PCb(H)','EC-wPCb(H)','TC(H)','N(H)','X(H)',
                                       'FEC - T(H)','ddAC - Wp(H)','ddAC - ddP(H)']

dose_frequency = ['一周一次', '三周一次']

chemotherapy_dose_table = [	('EC-T(H)',		0.9),
							('T(H)',		1.2),
							('TCb(H)',		1.4),
							('EC-Wp(H)',	0.4),
							('P(H)',		1.8),
							('PCb(H)',		2),
							('EC-wPCb(H)',	2.3),
							('TC(H)',		1.1),
							('N(H)',		1.3),
							('X(H)',		1.5),
							('FEC - T(H)',	1.7),
							('ddAC - Wp(H)',0.6),
							('ddAC - ddP(H)',0.2),
                                       ]

# 心超检查结果种类
echocardiography_reports = [u'遵医嘱',u'二尖瓣狭窄',u'三尖瓣狭窄',u'二尖瓣关闭不全',u'三尖瓣关闭不全',
                                                  u'主动脉关闭不全',u'二尖瓣反流',u'三尖瓣反流',u'室间隔缺损',u'肺动脉高压',
                                                  u'主动脉内径增宽',u'右室增大与肥厚',u'左心房增大',u'无明显异常']

# 停药原因种类
drug_stop_reasons_temp = [u'经济原因',u'患者不愿继续完成',u'家属原因',u'医生建议',u'心超结果',u'药物过敏',
                                      u'其他药物副反应',u'药物过期',u'药物结冰',u'其他药物原因',u'其他原因']

drug_stop_reasons = [u'经济原因',u'患者不愿继续完成',u'其他原因']

drug_stop_states = \
	{ "Active":"治疗中"
	, "TemporaryHalt":"暂停治疗"
	, "Halt":"终止"
	, "Finished":"完成所有治疗"
	}

#
age_min = 0
age_max = 120

#
lvef_max = 100
lvef_min = 0

#
using_dosage_min = 0
using_dosage_max = 10*single_bottle_dosage

#
expected_check_cycle = 90
drug_shelf_life = 28
