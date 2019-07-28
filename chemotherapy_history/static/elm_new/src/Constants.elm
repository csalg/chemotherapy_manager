module Constants exposing (..)

constants= 
        { chemotherapy_protocols= ["EC-T(H)","T(H)","TCb(H)","EC-Wp(H)","P(H)","PCb(H)","EC-wPCb(H)","TC(H)","N(H)","X(H)",
                                       "FEC - T(H)","ddAC - Wp(H)","ddAC - ddP(H)"]
        , injection_frequency =
                [ "一周一次"
                , "三周一次"
                , "一周一次 (三周用药，一周停药)"
                , "12周三周一次， 后来一周一次" 
                , "8周两周一次， 后来一周一次" 
                ]
        , echocardiography_reports = ["遵医嘱","二尖瓣狭窄","三尖瓣狭窄","二尖瓣关闭不全","三尖瓣关闭不全", "主动脉关闭不全","二尖瓣反流","三尖瓣反流","室间隔缺损","肺动脉高压",
                                                        "主动脉内径增宽","右室增大与肥厚","左心房增大","无明显异常"]
        , links = 
                { namePDF           = "printPersonal"
                , dosePDF           = "printDose"
                , doseHistory       = "doseHistory"
                , heartHistory      = "heartHistory"
                , personalHistory   = "personalHistory"
                , therapyHistory    = "therapyHistory"
            }
        , postTo = 
            { updatePersonal    = "updatePersonalInfo/"
            , updateDose        = "updateDoseReport/"
            , updateStop        = "updateStop/"
            , updateHeart       = "updateHeart/"
            , newPatient        = "/patient/"
    }
        --, drug_stop_reasons = ["暂停靶向治疗", "完成所有治疗"]
        , drug_stop_reasons = ["经济原因","患者不愿继续完成","家属原因","医生建议","心超结果","药物过敏",
                                      "其他药物副反应","药物过期","药物结冰","其他药物原因","其他原因"]
        , therapy_states = 
            [ "治疗中"
            , "暂停治疗"
            , "终止"
            , "完成所有治疗"
            ]

        , multiplier = { initial= 
                                { weekly=6
                                , triweekly=8
                                }
                        , maintenance=
                                { weekly=4
                                , triweekly=6
                                }
                        }
        , single_bottle_dosage = 440
        , drug_shelf_life = 28*24*60*60*1000
        , drug_shelf_life_days = 28
        , heart_report_frequency = 90*24*60*60*1000
        , heart_report_frequency_days = 90
        , heart_report_range = (25,0) -- start notifying, require to fill form, frequency
        , take_dose_buffer= 3
        , debug_mode = False
        , nacl_amounts = ["250", "100"]
        }

--rsync patients.js cit@jdlab:/opt/www/static/elm_new -v
