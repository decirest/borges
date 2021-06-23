-module(borges_handler).

-behaviour(gen_server).

-export([start_link/1,
         handle_event/3,
         remove/2,
         ensure_consistency/1,
         ensure_consistency/2]).
-export([init/1,
         handle_call/3,
         handle_cast/2,
         handle_info/2,
         terminate/2,
         code_change/3]).

-record(state, {name :: term()}).

start_link(Name) -> gen_server:start_link(?MODULE, [Name], []).

handle_event(Name, Obj, OldObj) ->
    Pid = borges_spec:get_handler_pid(Name),
    gen_server:cast(Pid, {event, {Obj, OldObj}}).

remove(Name, Obj) ->
    Pid = borges_spec:get_handler_pid(Name),
    gen_server:cast(Pid, {remove, Obj}).

ensure_consistency(Name) ->
    Pid = borges_spec:get_handler_pid(Name),
    gen_server:cast(Pid, ensure_consistency).

ensure_consistency(Name, Filter) ->
    Pid = borges_spec:get_handler_pid(Name),
    gen_server:cast(Pid, {ensure_consistency, Filter}).

init([Name]) ->
    borges_spec:set_handler_pid(Name, self()),
    {ok, #state{name = Name}}.

handle_call(Msg, _From, State) ->
    logger:notice("out of bounds call ~p", [Msg]),
    {reply, ok, State}.

handle_cast({event, {Obj, OldObj}}, #state{name = ModelName} = State) ->
    handle_cast({remove, OldObj}, State),
    Subsets =
        maps:values(
            borges_spec:get_subsets(ModelName)),
    Function = fun subset_store/5,
    [maybe_apply_to_subset(Function, ModelName, Obj, Subset) || Subset <- Subsets],
    {noreply, State};
handle_cast({remove, not_found}, State) -> {noreply, State};
handle_cast({remove, Obj}, #state{name = ModelName} = State) ->
    Subsets =
        maps:values(
            borges_spec:get_subsets(ModelName)),
    Function = fun subset_remove/5,
    [maybe_apply_to_subset(Function, ModelName, Obj, Subset) || Subset <- Subsets],
    {noreply, State};
handle_cast(Msg, State) ->
    logger:notice("out of bounds cast ~p", [Msg]),
    {noreply, State}.

handle_info(Msg, State) ->
    logger:notice("out of bounds info ~p", [Msg]),
    {noreply, State}.

terminate(_Reason, #state{name = Name}) ->
    borges_spec:set_handler_pid(Name, undefined),
    ok.

code_change(_OldVsn, State, _Extra) -> {ok, State}.

maybe_apply_to_subset(F, ModelName, Obj, SubsetConfig) ->
    #{name := SubsetName,
      is_related := IsRelated,
      subset_keys_fun := SubsetKeysFun} =
        SubsetConfig,
    case IsRelated(Obj) of
        false -> ok;
        true ->
            PreppedData = maybe_prep_data(Obj, SubsetConfig),
            Inputs = SubsetKeysFun(Obj),
            % Store data at key
            [F(ModelName, SubsetName, Input, PreppedData, SubsetConfig) || Input <- Inputs],
            ok
    end.

subset_store(ModelName, SubsetName, Input, Data, SubsetConfig) ->
    {ok, OldSubset} = borges:get_subset(ModelName, SubsetName, Input),
    #{extend := ExtendFun} = SubsetConfig,
    Subset = ExtendFun(OldSubset, Data),
    borges_adapter:store_subset(ModelName, SubsetName, Input, Subset).

subset_remove(ModelName, SubsetName, Input, Data, SubsetConfig) ->
    {ok, OldSubset} = borges:get_subset(ModelName, SubsetName, Input),
    #{reduce := ReduceFun} = SubsetConfig,
    Subset = ReduceFun(OldSubset, Data),
    borges_adapter:store_subset(ModelName, SubsetName, Input, Subset).

maybe_prep_data(Obj, #{data_prep := F}) -> F(Obj);
maybe_prep_data(Obj, _) -> Obj.
