type functionType = (
  ~eventName: Js.String2.t=?,
  ~email: Js.String.t=?,
  ~description: option<string>=?,
  unit,
) => unit

let useSendEvent = () => {
  open HSwitchGlobalVars
  open HSLocalStorage
  open Window
  let fetchApi = AuthHooks.useApiFetcher()
  let url = RescriptReactRouter.useUrl()
  let name = getFromUserDetails("name")
  let deviceId = switch LocalStorage.getItem("deviceid")->Js.Nullable.toOption {
  | Some(id) => id
  | None => getFromUserDetails("email")
  }
  let currentUrl = `${hyperSwitchFEPrefix}/${url.path->Js.List.hd->Belt.Option.getWithDefault("")}`

  let parseEmail = email => {
    email->Js.String.length == 0 ? getFromMerchantDetails("email") : email
  }

  let featureFlagDetails = HyperswitchAtom.featureFlagAtom->Recoil.useRecoilValueFromAtom

  let environment = switch HSwitchGlobalVars.hostType {
  | Live => "production"
  | Sandbox => "sandbox"
  | Netlify => "netlify"
  | Local => "localhost"
  }

  let trackApi = async (~email, ~merchantId, ~description, ~requestId, ~statusCode, ~event) => {
    let body = {
      "event": event,
      "properties": {
        "token": mixpanelToken,
        "distinct_id": deviceId,
        "$device_id": deviceId->Js.String2.split(":")->Belt.Array.get(1),
        "$screen_height": Screen.screenHeight,
        "$screen_width": Screen.screenWidth,
        "name": email,
        "merchantName": name,
        "email": email,
        "mp_lib": "restapi",
        "merchantId": merchantId,
        "environment": environment,
        "description": description,
        "x-request-id": requestId,
        "responseStatusCode": statusCode,
        "$current_url": currentUrl,
        "lang": Navigator.browserLanguage,
        "$os": Navigator.platform,
        "$browser": Navigator.browserName,
      },
    }

    try {
      let _ = await fetchApi(
        `${dashboardUrl}/mixpanel/track`,
        ~method_=Fetch.Post,
        ~bodyStr=`data=${body
          ->Js.Json.stringifyAny
          ->Belt.Option.getWithDefault("")
          ->Js.Global.encodeURI}`,
        (),
      )
    } catch {
    | _ => ()
    }
  }

  (~eventName, ~email="", ~description=None, ~xRequestId=None, ~responseStatusCode=None, ()) => {
    let eventName = eventName->Js.String2.toLowerCase
    let someRequestId = xRequestId->Belt.Option.getWithDefault("")
    let someStatusCode = responseStatusCode->Belt.Option.getWithDefault(0)
    let merchantId = getFromMerchantDetails("merchant_id")

    if featureFlagDetails.mixPanel {
      MixPanel.track(
        eventName,
        {
          "email": email->parseEmail,
          "merchantId": merchantId,
          "environment": environment,
          "description": description,
          "x-request-id": someRequestId,
          "responseStatusCode": someStatusCode,
        },
      )
      trackApi(
        ~email={email->parseEmail},
        ~merchantId,
        ~description,
        ~requestId={someRequestId},
        ~statusCode={someStatusCode},
        ~event={eventName},
      )->ignore
    }
  }
}
