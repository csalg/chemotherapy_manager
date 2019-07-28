
displayOnly: FormControl Types.Msg -> FormControl Types.Msg
displayOnly fc =
 {fc | disabled = True, validationState=Empty, displayOnly=True }


--View renderers
viewView: Dict.Dict String (FormControl Types.Msg) -> Patient -> Html Types.Msg
viewView formControls patient = 
 div
                    [ class "panel-body" ]

                    [ div
                        [ class "row" ]
                        (formControls
                         |> Dict.values
                         |> List.sortBy .order
                         |> List.map (populateValues patient)
                         |> List.map displayOnly 
                         |> List.map render
                         )
                        ]


viewEdit formControls = 
 div
  [ class "panel-body" ]

  [ div
      [ class "row" ]
      (formControls
       |> Dict.values
       |> List.sortBy .order
       |> List.map render
       )

  ]







--FormControl renderer
render: FormControl Types.Msg -> Html Types.Msg
render fc =
    let 
-------------------------------
      wrapper inpt=
        let
          extraDivArgs = (if fc.hidden then [style [("display", "none")]] else  [])
          hasWhat = case fc.validationState of
            Empty -> ""
            Invalid -> " has-error"
            Valid -> " has-success"
        in
          div
              [ id fc.fieldName, class ("form-group col-sm-" ++ (toString(fc.width)) ++ hasWhat) ]
              [  ifNotHidden (label
                  [ class "control-label", for fc.fieldName ]
                  [ text fc.labelText])
              , inpt
              , ifNotHidden (span [class hasWhat] [(text fc.helpText)])
              , ifNotHidden actions]
-------------------------------
      labl = label
                  [ class "control-label", for fc.fieldName ]
                  [ text fc.labelText]
-------------------------------
      --actions= 
      --  let
      --    overrideHTML =  
      --      if fc.allowOverride
      --      then
      --        if fc.fieldName == "dose_amount" then doseAmountExtraOptions
      --        else 
      --          [div []
      --            [ div [] 
      --                [ input [ type_ "checkbox", onCheck (\val -> (FormControlMsg (AccordingToDose (not val)))) ] []
      --                , span [] [text "直接输入"]
      --                ]
      --            ]
      --          ]
      --      else []
      --  in
      --  div []
      --    ([span
      --      [ ]
      --      [ text fc.helpText ]
      --    ]++overrideHTML)

      actions = div [] (List.map viewAction fc.actions)
        --[ ("doseAmountExtraOptions", "radio", "使用维持剂量", (\val -> (FormControlMsg (AccordingToMaintenance val))))
        --, ("doseAmountExtraOptions", "radio", "按照体重算剂量", (\val -> (FormControlMsg (AccordingToWeight val))))
        ----, ("doseAmountExtraOptions", "radio", "使用剩余剂量填写", (\val -> (FormControlMsg (UseRemainingDose val))))
        --, ("doseAmountExtraOptions", "radio", "直接输入", (\val -> (FormControlMsg (AllowDoseManualInput val))))
        ----, ("", "checkbox", "减去上次剂量填写", (\val -> (FormControlMsg (SubtractPreviousDose val))))
        --])



-------------------------------
      ifNotHidden what = if fc.hidden then text "" else what
      inpt extra = 
        let
          attrs = 
            if fc.hidden 
            then [type_ "hidden"]
            else 
              if fc.displayOnly 
              then [type_ "text", value fc.value] 
              else extra
        in
          div[]
          [input
            (attrs++[ name fc.fieldName
              , class (if fc.inputType == NewBottle then "" else "form-control")
              , disabled (fc.disabled || fc.displayOnly)
              , required fc.required
              ])
            []
            , hiddenVal
            ]

--      inputText = inpt [(type_ "text")]

--      inputNumber = inpt [(type_ "number")]
----
      --inputWeight = inpt [(type_ "number"), (onInput (\val-> FormControlMsg (WeightChange val)))]
--

--
      --inputNewBottle = inpt [(onCheck (\val -> (FormControlMsg (OpenBottle val)))), type_  "checkbox" ]
      
      viewOption optionValue = option
                            [ Html.Attributes.value optionValue ]
                            [ text optionValue]
      inputSelect = 
        if fc.displayOnly then inpt [] else
          select
            [ name fc.fieldName, required fc.required, class "form-control", onInput (\val-> (FormControlMsg (FormControlValidationCheck fc.fieldName val))) ]
            (List.map viewOption fc.options) 

-------------------------------
      hiddenVal = 
        if fc.displayOnly 
        then input [name fc.fieldName, type_ "hidden", attribute "value" fc.value] []
        else text ""

      inputDT = 
        if (fc.hidden || fc.displayOnly)
        then inpt [(type_ "text")]
        else
          div [] 
          [(Input.datetimeLocal
            [ Input.small
            , Input.attrs ([(name fc.fieldName), disabled fc.disabled, required fc.required]++fc.inputArgs)
            ])
          , hiddenVal
          ]

      -- TODO
      --inputOpenedDate = inputDT [(onChange (\val -> (FormControlMsg (OpenedDateChange val))))]


      viewAction {actionName, typ, txt, onchk} = div [class "radio"] 
                  [ input [ type_ typ, name actionName, onCheck onchk ] []
                  , label [] [text txt]
                  ]

      --doseAmountExtraOptions = 
      --  if fc.allowOverride
      --  then
      --    [div []
      --          (List.map viewAction 
      --          [ ("doseAmountExtraOptions", "radio", "使用维持剂量", (\val -> (FormControlMsg (AccordingToMaintenance val))))
      --          , ("doseAmountExtraOptions", "radio", "按照体重算剂量", (\val -> (FormControlMsg (AccordingToWeight val))))
      --          --, ("doseAmountExtraOptions", "radio", "使用剩余剂量填写", (\val -> (FormControlMsg (UseRemainingDose val))))
      --          , ("doseAmountExtraOptions", "radio", "直接输入", (\val -> (FormControlMsg (AllowDoseManualInput val))))
      --          --, ("", "checkbox", "减去上次剂量填写", (\val -> (FormControlMsg (SubtractPreviousDose val))))
      --          ])
      --    ]
      --  else []

  in 
    case fc.inputType of
      Inpt typeValue -> wrapper (inpt ([(type_ typeValue)]++fc.inputArgs))
      DateInput -> wrapper inputDT
      --NumberInput -> wrapper inputNumber
      --DoseAmount -> wrapper inputDoseAmount
      --TextInput -> wrapper inputText
      --Weight -> wrapper inputWeight
      --OpenedDate -> wrapper inputOpenedDate
      --NewBottle -> wrapper inputNewBottle
      OptionsInput -> wrapper inputSelect
      _ -> wrapper (inpt fc.inputArgs)

