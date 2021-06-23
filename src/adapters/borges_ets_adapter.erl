-module(borges_ets_adapter).

-export([keys/1,
         store/3,
         fetch/2,
         remove/2]).

-behaviour(borges_adapter).

-type storage_adapter_config() ::
    #{storage_adapter_config := #{table => atom()},
      _ => _}.
-type key() :: term().
-type data() :: term().

-spec store(key(), data(), storage_adapter_config()) -> ok.
store(Key, Data, #{storage_adapter_config := StorageAdapterConfig}) ->
    TableName = maps:get(name, StorageAdapterConfig),
    ets:insert(TableName, {Key, Data}),
    ok.

%-spec fetch(key(), storage_adapter_config()) -> {ok, term()}.
fetch(Key, #{storage_adapter_config := StorageAdapterConfig}) ->
    TableName = maps:get(name, StorageAdapterConfig),
    case ets:lookup(TableName, Key) of
        [{_, Data}] -> {ok, Data};
        _ -> {ok, not_found}
    end.

remove(Key, #{storage_adapter_config := StorageAdapterConfig}) ->
    TableName = maps:get(name, StorageAdapterConfig),
    ets:delete(TableName, Key),
    ok.

keys(#{storage_adapter_config := StorageAdapterConfig}) ->
    TableName = maps:get(name, StorageAdapterConfig),
    Keys =
        lists:flatten(
            ets:match(TableName, {'$1', '_'})),
    {ok, Keys}.
