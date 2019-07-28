module Data.DjangoResponse exposing(..)

import Json.Decode exposing(Decoder, string, andThen, field)
import Json.Decode.Pipeline exposing (decode, optional, optionalAt, required, requiredAt, hardcoded)

type DjangoResponse = Err String | Success String

decode_ : Decoder DjangoResponse
decode_ =
    let
        djangoDecoder status =
            case status of
                "success" ->
                    (decode Success
                    |> required "message" string)
                _ ->
                    decode Err
                    |> required "message" string
    in    
  field "status" string
    |> andThen djangoDecoder

toString res =
    case res of
        Err txt ->
            "服务器错误： "++txt
        Success txt ->
            "服务器成功： "++txt