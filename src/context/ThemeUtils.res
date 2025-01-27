let useThemeFromEvent = () => {
  let (eventTheme, setEventTheme) = React.useState(_ => None)

  React.useEffect0(() => {
    let setEventThemeVal = (eventName, dict) => {
      if eventName === "AuthenticationDetails" {
        let payloadDict = dict->Dict.get("payload")->Option.flatMap(obj => obj->JSON.Decode.object)
        let theme =
          payloadDict->Option.mapOr("", finalDict => LogicUtils.getString(finalDict, "theme", ""))
        setEventTheme(_ => Some(theme))
      } else if eventName == "themeToggle" {
        let theme = LogicUtils.getString(dict, "payload", "")
        setEventTheme(_ => Some(theme))
      } else {
        Js.log2(`Event name is ${eventName}`, dict)
      }
    }

    let handleEventMessage = (ev: Dom.event) => {
      let optionalDict = HandlingEvents.getEventDict(ev)
      switch optionalDict {
      | Some(dict) => {
          let optionalEventName =
            dict->Dict.get("eventType")->Option.flatMap(obj => obj->JSON.Decode.string)
          switch optionalEventName {
          | Some(eventName) => setEventThemeVal(eventName, dict)
          | None => Js.log2("Event Data is not found", dict)
          }
        }

      | None => ()
      }
    }

    Window.addEventListener("message", handleEventMessage)
    Some(() => Window.removeEventListener("message", handleEventMessage))
  })

  eventTheme
}
