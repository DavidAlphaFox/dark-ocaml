open Prelude

let apiRoot = "/api/"

let clientVersionHeader = (m: AppTypes.model): Tea_http.header => Header(
  "x-darklang-client-version",
  m.buildHash,
)

let apiCallNoParams = (
  m: AppTypes.model,
  ~decoder: Js.Json.t => 'resulttype,
  ~callback: Tea.Result.t<'resulttype, Tea.Http.error<string>> => AppTypes.msg,
  endpoint: string,
): AppTypes.cmd => {
  let url = apiRoot ++ Tea.Http.encodeUri(m.canvasName) ++ endpoint
  let request = Tea.Http.request({
    method': "POST",
    headers: list{
      Header("Content-type", "application/json"),
      Header("X-CSRF-Token", m.csrfToken),
      clientVersionHeader(m),
    },
    url: url,
    body: Web.XMLHttpRequest.EmptyBody,
    expect: Tea.Http.expectStringResponse(Decoders.wrapExpect(decoder)),
    timeout: None,
    withCredentials: false,
  })

  Tea.Http.send(callback, request)
}

let postJson = (
  decoder,
  ~withCredentials=false,
  ~headers=list{},
  csrfToken: string,
  url: string,
  body: Js.Json.t,
) =>
  Tea.Http.request({
    method': "POST",
    headers: list{
      Header("Content-type", "application/json"),
      Header("X-CSRF-Token", csrfToken),
      ...headers,
    },
    url: url,
    body: Web.XMLHttpRequest.StringBody(Json.stringify(body)),
    expect: Tea.Http.expectStringResponse(Decoders.wrapExpect(decoder)),
    timeout: None,
    withCredentials: withCredentials,
  })

let apiCall = (
  m: AppTypes.model,
  ~encoder: 'paramtype => Js.Json.t,
  ~params: 'paramtype,
  ~decoder: Js.Json.t => 'resulttype,
  ~callback: Tea.Result.t<'resulttype, Tea.Http.error<string>> => AppTypes.msg,
  endpoint: string,
): AppTypes.cmd => {
  let url = apiRoot ++ Tea.Http.encodeUri(m.canvasName) ++ endpoint
  let request = postJson(
    ~headers=list{clientVersionHeader(m)},
    decoder,
    m.csrfToken,
    url,
    encoder(params),
  )

  Tea.Http.send(callback, request)
}

let opsParams = (ops: list<PT.Op.t>, opCtr: int, clientOpCtrID: string): APIAddOps.Params.t => {
  ops: ops,
  opCtr: opCtr,
  clientOpCtrID: clientOpCtrID,
}

// -------------
// API calls
// -------------

let addOp = (
  m: AppTypes.model,
  focus: AppTypes.Focus.t,
  params: APIAddOps.Params.t,
): AppTypes.cmd =>
  apiCall(
    m,
    "/v1/add_op",
    ~decoder=APIAddOps.decode,
    ~encoder=APIAddOps.Params.encode,
    ~params,
    ~callback=x => AddOpsAPICallback(focus, params, x),
  )

let executeFunction = (m: AppTypes.model, params: APIExecution.Function.Params.t): AppTypes.cmd =>
  apiCall(
    m,
    "/v1/execute_function",
    ~decoder=APIExecution.Function.decode,
    ~encoder=APIExecution.Function.Params.encode,
    ~params,
    ~callback=x => ExecuteFunctionAPICallback(params, x),
  )

let uploadFn = (m: AppTypes.model, params: APIPackages.UploadFn.Params.t): AppTypes.cmd =>
  apiCall(
    m,
    "/packages/upload_function",
    ~decoder=_ => (),
    ~encoder=APIPackages.UploadFn.Params.encode,
    ~params,
    ~callback=x => UploadFnAPICallback(params, x),
  )

let loadPackages = (m: AppTypes.Model.t): AppTypes.cmd =>
  apiCallNoParams(
    m,
    "/v1/packages",
    ~decoder=APIPackages.AllPackages.decode,
    ~callback=x => LoadPackagesAPICallback(x),
  )

let triggerHandler = (m: AppTypes.model, params: APIExecution.Handler.Params.t): AppTypes.cmd =>
  apiCall(
    m,
    "/trigger_handler",
    ~decoder=APIExecution.Handler.decode,
    ~encoder=APIExecution.Handler.Params.encode,
    ~params,
    ~callback=x => TriggerHandlerAPICallback(params, x),
  )

let getUnlockedDBs = (m: AppTypes.model): AppTypes.cmd =>
  apiCallNoParams(
    m,
    "/get_unlocked_dbs",
    ~decoder=APIDBs.UnlockedDBs.decode,
    ~callback=x => GetUnlockedDBsAPICallback(x),
  )

let updateWorkerSchedule = (
  m: AppTypes.model,
  params: APIWorkers.Scheduler.Params.t,
): AppTypes.cmd =>
  apiCall(
    m,
    "/worker_schedule",
    ~decoder=APIWorkers.Scheduler.decode,
    ~encoder=APIWorkers.Scheduler.Params.encode,
    ~params,
    ~callback=x => UpdateWorkerScheduleCallback(x),
  )

let get404s = (m: AppTypes.model): AppTypes.cmd =>
  apiCallNoParams(m, "/get_404s", ~decoder=API404.Get.decode, ~callback=x => Get404sAPICallback(x))

let delete404 = (m: AppTypes.model, params: API404.Delete.Params.t): AppTypes.cmd =>
  apiCall(
    m,
    "/delete_404",
    ~decoder=_ => (),
    ~encoder=API404.Delete.Params.encode,
    ~params,
    ~callback=x => Delete404APICallback(params, x),
  )

let deleteToplevelForever = (
  m: AppTypes.model,
  params: APIToplevels.DeleteForever.Params.t,
): Tea.Cmd.t<AppTypes.msg> =>
  apiCall(
    m,
    "/delete-toplevel-forever",
    ~decoder=_ => (),
    ~encoder=APIToplevels.DeleteForever.Params.encode,
    ~params,
    ~callback=x => DeleteToplevelForeverAPICallback(params, x),
  )

let insertSecret = (m: AppTypes.model, params: APISecrets.Insert.Params.t): AppTypes.cmd =>
  apiCall(
    m,
    "/v1/insert_secret",
    ~encoder=APISecrets.Insert.Params.encode,
    ~decoder=APISecrets.Insert.decode,
    ~params,
    ~callback=x => InsertSecretCallback(x),
  )

let initialLoad = (m: AppTypes.model, focus: AppTypes.Focus.t): AppTypes.cmd =>
  apiCallNoParams(
    m,
    "/v1/initial_load",
    ~decoder=APIInitialLoad.decode,
    ~callback=x => InitialLoadAPICallback(focus, NoChange, x),
  )

let fetchAllTraces = (m: AppTypes.model): AppTypes.cmd =>
  apiCallNoParams(
    m,
    "/all_traces",
    ~decoder=APITraces.AllTraces.decode,
    ~callback=x => FetchAllTracesAPICallback(x),
  )

let logout = (m: AppTypes.model): AppTypes.cmd =>
  apiCallNoParams(m, "/logout", ~decoder=_ => (), ~callback=_ => LogoutAPICallback)

let saveTest = (m: AppTypes.model): AppTypes.cmd =>
  apiCallNoParams(m, "/save_test", ~decoder=APISaveTest.decode, ~callback=x => SaveTestAPICallback(
    x,
  ))

let integration = (m: AppTypes.model, name: string): AppTypes.cmd =>
  apiCallNoParams(
    m,
    "/initial_load",
    ~decoder=APIInitialLoad.decode,
    ~callback=x => InitialLoadAPICallback(FocusNothing, TriggerIntegrationTest(name), x),
  )

let sendPresence = (m: AppTypes.model, av: APIPresence.Params.t): AppTypes.cmd => {
  let url = "https://editor.darklang.com/presence"
  let request = postJson(
    ~headers=list{clientVersionHeader(m)},
    ~withCredentials=true,
    _ => (),
    m.csrfToken,
    url,
    APIPresence.Params.encode(av),
  )

  // If origin is https://darklang.com, then we're in prod (or ngrok, running against
  // prod) and editor.darklang.com's CORS rules will allow this request. If not,
  // we're in local, and both CORS and auth (session, canvas_id) will not work
  // against editor.darklang.com. By putting the conditional here instead of at the
  // beginning of the function, we still exercise the message and request generating
  // code locally.
  if m.origin == "https://darklang.com" {
    Tea.Http.send(x => AppTypes.Msg.TriggerSendPresenceCallback(x), request)
  } else {
    Tea.Cmd.none
  }
}

let sendInvite = (m: AppTypes.model, params: APISendInvite.Params.t): AppTypes.cmd => {
  let url = "https://accounts.darklang.com/send-invite"
  let request = postJson(
    ~headers=list{clientVersionHeader(m)},
    ~withCredentials=true,
    _ => (),
    m.csrfToken,
    url,
    APISendInvite.Params.encode(params),
  )

  // If origin is https://darklang.com, then we're in prod (or ngrok, running against
  // prod) and ops-adduser.darklang.com's CORS rules will allow this request. If not,
  // we're in local, and both CORS and auth (session, canvas_id) will not work
  // against ops-adduser.darklang.com. By putting the conditional here instead of at
  // the beginning of the function, we still exercise the message and request
  // generating code locally.
  if m.origin == "https://darklang.com" {
    Tea.Http.send(x => AppTypes.Msg.SettingsViewMsg(TriggerSendInviteCallback(x)), request)
  } else {
    Tea.Cmd.none
  }
}

// We do some dropping of ops based on clientOpCtrId+opCtr to preserve ordering.
// (opCtr is per-clientOpCtrId, and inc'd client-side; thus we know, when processing
// a set of ops whether this is the latest seen so far from a given client, or has
// come in out of order.) This is initially done server-side, to guard against ops
// being processed there out of order; but we also need to do this client-side, since
// messages coming in from Pusher are not guaranteed to be delivered in order.
//
// Ordering is determined by AppTypes.model.opCtrs, and we return a AppTypes.model so
// we can also update the opCtrs map.
let filterOpsAndResult = (
  m: AppTypes.model,
  params: APIAddOps.Params.t,
  result: option<APIAddOps.Result.t>,
): (AppTypes.model, list<PT.Op.t>, option<APIAddOps.Result.t>) => {
  // if the opCtr in params is greater than the one in the map, we'll create
  // an updated map
  let newOpCtrs = Map.update(m.opCtrs, ~key=params.clientOpCtrID, ~f=oldCtr =>
    switch (oldCtr, params.opCtr) {
    | (Some(oldCtr), paramsOpCtr) => Some(max(oldCtr, paramsOpCtr))
    | _ => Some(params.opCtr)
    }
  )

  let m2 = {...m, opCtrs: newOpCtrs}
  // if the new opCtrs map was updated by params.opCtr, then this msg was the
  // atest; otherwise, we need to filter out some ops from params */
  // temporarily _don't_ filter ops
  if Map.get(~key=params.clientOpCtrID, m2.opCtrs) == Some(params.opCtr) {
    (m2, params.ops, result)
  } else {
    // filter down to only those ops which can be applied out of order without
    // overwriting previous ops' state - eg, if we have SetHandler1 setting a
    // handler's value to "aaa", and then SetHandler2's value is "aa",
    // applying them out of order (SH2, SH1) will result in SH2's update being
    // overwritten
    // NOTE: DO NOT UPDATE WITHOUT UPDATING THE SERVER-SIDE LIST
    let filter_ops_received_out_of_order = List.filter(~f=op =>
      switch op {
      | PT.Op.SetHandler(_)
      | SetFunction(_)
      | SetType(_)
      | MoveTL(_)
      | SetDBColName(_)
      | ChangeDBColName(_)
      | ChangeDBColType(_)
      | SetExpr(_)
      | UndoTL(_)
      | RedoTL(_)
      | TLSavepoint(_)
      | RenameDBname(_) => false
      | CreateDB(_)
      | AddDBCol(_)
      | SetDBColType(_)
      | DeleteTL(_)
      | DeleteFunction(_)
      | DeleteDBCol(_)
      | CreateDBWithBlankOr(_)
      | DeleteType(_) => true
      }
    )

    let ops = params.ops |> filter_ops_received_out_of_order
    let opTlids = ops |> List.map(~f=op => PT.Op.tlidOf(op))
    // We also want to ignore the result of ops we ignored
    let result = Option.map(result, ~f=(result: APIAddOps.Result.t) => {
      ...result,
      handlers: result.handlers |> List.filter(~f=(h: PT.Handler.t) =>
        List.member(~value=h.tlid, opTlids)
      ),
      userFunctions: result.userFunctions |> List.filter(~f=(uf: PT.UserFunction.t) =>
        List.member(~value=uf.tlid, opTlids)
      ),
      userTypes: result.userTypes |> List.filter(~f=(ut: PT.UserType.t) =>
        List.member(~value=ut.tlid, opTlids)
      ),
    })

    (m2, ops, result)
  }
}
