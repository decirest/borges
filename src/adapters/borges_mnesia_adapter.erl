-module(borges_mnesia_adapter).

-export([store/3,
         keys/1,
         fetch/2,
         create_table/1,
         remove/2]).

-include_lib("stdlib/include/qlc.hrl").

-behaviour(borges_adapter).

% Big todo: generalize from simple key/value storage

store(Key, Data, #{storage_adapter_config := StorageAdapterConfig}) ->
    TableName = maps:get(table_name, StorageAdapterConfig),
    StoreF = fun() -> mnesia:write({TableName, Key, Data}) end,
    {atomic, ok} = mnesia:transaction(StoreF),
    ok.

fetch(Key, #{storage_adapter_config := StorageAdapterConfig}) ->
    TableName = maps:get(table_name, StorageAdapterConfig),
    GetF =
        fun() ->
           Query = qlc:q([X || {_TN, K, _D} = X <- mnesia:table(TableName), K =:= Key]),
           qlc:e(Query)
        end,
    case mnesia:transaction(GetF) of
        {atomic, [{_, _, Data}]} -> {ok, Data};
        {atomic, []} -> {ok, not_found};
        Error -> {error, Error}
    end.

remove(Key, #{storage_adapter_config := StorageAdapterConfig}) ->
    TableName = maps:get(name, StorageAdapterConfig),
    ets:delete(TableName, Key),
    ok.

keys(#{storage_adapter_config := StorageAdapterConfig}) ->
    TableName = maps:get(table_name, StorageAdapterConfig),
    GetF =
        fun() ->
           Query = qlc:q([Key || {_TN, Key, _D} <- mnesia:table(TableName), true]),
           qlc:e(Query)
        end,
    case mnesia:transaction(GetF) of
        {atomic, Keys} when is_list(Keys) -> {ok, Keys};
        Error -> {error, Error}
    end.

create_table(Name) ->
    try
        mnesia:table_info(type, Name)
    catch
        exit:_ -> mnesia:create_table(Name, [{attributes, [key, data]}])
    end.
